-- ArgusX: auth trigger + RPC helpers for backend (service role)
-- Run after 002_tables.sql

-- ---------------------------------------------------------------------------
-- Auto-create profile when a user signs up via Supabase Auth
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(
      NEW.raw_user_meta_data ->> 'full_name',
      NEW.raw_user_meta_data ->> 'name',
      split_part(COALESCE(NEW.email, 'user'), '@', 1)
    ),
    'customer'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Threat severity helper
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.threat_rank(level public.threat_level)
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE level
    WHEN 'NORMAL' THEN 0
    WHEN 'WARNING' THEN 1
    WHEN 'CRITICAL' THEN 2
  END;
$$;

-- ---------------------------------------------------------------------------
-- Ensure device row exists (upsert by user + label)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ensure_device(
  p_user_id UUID,
  p_device_label TEXT DEFAULT 'ArgusX Device',
  p_platform public.device_platform DEFAULT 'unknown'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_device_id UUID;
BEGIN
  INSERT INTO public.devices (user_id, device_label, platform, is_online, last_seen_at)
  VALUES (p_user_id, p_device_label, p_platform, TRUE, NOW())
  ON CONFLICT (user_id, device_label)
  DO UPDATE SET
    platform = EXCLUDED.platform,
    is_online = TRUE,
    last_seen_at = NOW(),
    updated_at = NOW()
  RETURNING id INTO v_device_id;
  RETURN v_device_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Start or resume an active ride for a session
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ensure_active_ride(
  p_user_id UUID,
  p_session_id TEXT,
  p_device_id UUID DEFAULT NULL,
  p_origin_label TEXT DEFAULT NULL,
  p_origin_lat DOUBLE PRECISION DEFAULT NULL,
  p_origin_lng DOUBLE PRECISION DEFAULT NULL,
  p_destination_label TEXT DEFAULT NULL,
  p_destination_lat DOUBLE PRECISION DEFAULT NULL,
  p_destination_lng DOUBLE PRECISION DEFAULT NULL,
  p_route_polyline TEXT DEFAULT NULL,
  p_distance_m INTEGER DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ride_id UUID;
BEGIN
  SELECT id INTO v_ride_id
  FROM public.rides
  WHERE session_id = p_session_id
  LIMIT 1;

  IF v_ride_id IS NOT NULL THEN
    UPDATE public.rides
    SET
      device_id = COALESCE(p_device_id, device_id),
      destination_label = COALESCE(p_destination_label, destination_label),
      destination_lat = COALESCE(p_destination_lat, destination_lat),
      destination_lng = COALESCE(p_destination_lng, destination_lng),
      route_polyline = COALESCE(p_route_polyline, route_polyline),
      distance_m = COALESCE(p_distance_m, distance_m),
      updated_at = NOW()
    WHERE id = v_ride_id;
    RETURN v_ride_id;
  END IF;

  INSERT INTO public.rides (
    user_id, device_id, session_id, status,
    origin_label, origin_lat, origin_lng,
    destination_label, destination_lat, destination_lng,
    route_polyline, distance_m
  )
  VALUES (
    p_user_id, p_device_id, p_session_id, 'active',
    p_origin_label, p_origin_lat, p_origin_lng,
    p_destination_label, p_destination_lat, p_destination_lng,
    p_route_polyline, p_distance_m
  )
  RETURNING id INTO v_ride_id;

  RETURN v_ride_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Live fleet map position (upsert each Safety Pulse)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upsert_fleet_position(
  p_user_id UUID,
  p_ride_id UUID,
  p_session_id TEXT,
  p_device_id UUID,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_speed_kmh NUMERIC DEFAULT 0,
  p_threat_level public.threat_level DEFAULT 'NORMAL',
  p_hud_mode TEXT DEFAULT NULL,
  p_destination_label TEXT DEFAULT NULL,
  p_battery_pct SMALLINT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.fleet_positions (
    user_id, ride_id, session_id, device_id,
    lat, lng, speed_kmh, threat_level, hud_mode,
    destination_label, battery_pct, is_online, updated_at
  )
  VALUES (
    p_user_id, p_ride_id, p_session_id, p_device_id,
    p_lat, p_lng, p_speed_kmh, p_threat_level, p_hud_mode,
    p_destination_label, p_battery_pct, TRUE, NOW()
  )
  ON CONFLICT (user_id)
  DO UPDATE SET
    ride_id = EXCLUDED.ride_id,
    session_id = EXCLUDED.session_id,
    device_id = COALESCE(EXCLUDED.device_id, fleet_positions.device_id),
    lat = EXCLUDED.lat,
    lng = EXCLUDED.lng,
    speed_kmh = EXCLUDED.speed_kmh,
    threat_level = EXCLUDED.threat_level,
    hud_mode = EXCLUDED.hud_mode,
    destination_label = EXCLUDED.destination_label,
    battery_pct = COALESCE(EXCLUDED.battery_pct, fleet_positions.battery_pct),
    is_online = TRUE,
    updated_at = NOW();

  UPDATE public.profiles
  SET
    last_active_at = NOW(),
    last_lat = p_lat,
    last_lng = p_lng,
    location_label = COALESCE(p_destination_label, location_label),
    updated_at = NOW()
  WHERE id = p_user_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Update ride metrics during an active session
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_ride_pulse(
  p_session_id TEXT,
  p_speed_kmh NUMERIC,
  p_threat_level public.threat_level DEFAULT 'NORMAL'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.rides
  SET
    avg_speed_kmh = CASE
      WHEN avg_speed_kmh IS NULL THEN p_speed_kmh
      ELSE (avg_speed_kmh + p_speed_kmh) / 2
    END,
    max_threat_level = CASE
      WHEN public.threat_rank(p_threat_level) > public.threat_rank(max_threat_level)
        THEN p_threat_level
      ELSE max_threat_level
    END,
    threats_count = threats_count + CASE
      WHEN p_threat_level IN ('WARNING', 'CRITICAL') THEN 1
      ELSE 0
    END,
    duration_s = EXTRACT(EPOCH FROM (NOW() - started_at))::INTEGER,
    updated_at = NOW()
  WHERE session_id = p_session_id
    AND status = 'active';
END;
$$;

-- ---------------------------------------------------------------------------
-- Record compliance / agent safety event
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_safety_event(
  p_event_id TEXT,
  p_user_id UUID,
  p_session_id TEXT,
  p_threat_level public.threat_level,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_speed_kmh NUMERIC DEFAULT NULL,
  p_hazards JSONB DEFAULT '[]'::JSONB,
  p_enriched_context TEXT DEFAULT NULL,
  p_ui_commands JSONB DEFAULT '[]'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ride_id UUID;
  v_event_row_id UUID;
BEGIN
  SELECT id INTO v_ride_id
  FROM public.rides
  WHERE session_id = p_session_id
  LIMIT 1;

  INSERT INTO public.safety_events (
    event_id, ride_id, user_id, session_id, threat_level,
    lat, lng, speed_kmh, hazards, enriched_context, ui_commands
  )
  VALUES (
    p_event_id, v_ride_id, p_user_id, p_session_id, p_threat_level,
    p_lat, p_lng, p_speed_kmh, p_hazards, p_enriched_context, p_ui_commands
  )
  ON CONFLICT (event_id) DO NOTHING
  RETURNING id INTO v_event_row_id;

  IF v_ride_id IS NOT NULL THEN
    UPDATE public.rides
    SET
      max_threat_level = CASE
        WHEN public.threat_rank(p_threat_level) > public.threat_rank(max_threat_level)
          THEN p_threat_level
        ELSE max_threat_level
      END,
      threats_count = threats_count + 1,
      status = CASE
        WHEN p_threat_level = 'CRITICAL' THEN 'flagged'::public.ride_status
        ELSE status
      END,
      updated_at = NOW()
    WHERE id = v_ride_id;
  END IF;

  RETURN v_event_row_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Complete ride when WebSocket disconnects
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_ride_session(p_session_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  UPDATE public.rides
  SET
    status = 'completed',
    ended_at = NOW(),
    duration_s = EXTRACT(EPOCH FROM (NOW() - started_at))::INTEGER,
    updated_at = NOW()
  WHERE session_id = p_session_id
    AND status = 'active'
  RETURNING user_id INTO v_user_id;

  IF v_user_id IS NOT NULL THEN
    UPDATE public.profiles
    SET
      total_rides = total_rides + 1,
      updated_at = NOW()
    WHERE id = v_user_id;

    UPDATE public.fleet_positions
    SET is_online = FALSE, updated_at = NOW()
    WHERE user_id = v_user_id;

    UPDATE public.devices
    SET is_online = FALSE, last_seen_at = NOW(), updated_at = NOW()
    WHERE user_id = v_user_id;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Mark rider offline without completing ride (e.g. crash)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_rider_offline(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.fleet_positions
  SET is_online = FALSE, updated_at = NOW()
  WHERE user_id = p_user_id;

  UPDATE public.devices
  SET is_online = FALSE, last_seen_at = NOW(), updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$;
