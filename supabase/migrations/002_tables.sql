-- ArgusX: core tables
-- Run after 001_extensions_enums.sql

-- ---------------------------------------------------------------------------
-- profiles — one row per auth.users (customer or admin)
-- ---------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  full_name     TEXT,
  role          public.user_role NOT NULL DEFAULT 'customer',
  status        public.account_status NOT NULL DEFAULT 'active',
  phone         TEXT,
  avatar_url    TEXT,
  safety_score  NUMERIC(5, 2) NOT NULL DEFAULT 100.00,
  total_rides   INTEGER NOT NULL DEFAULT 0,
  last_active_at TIMESTAMPTZ,
  last_lat      DOUBLE PRECISION,
  last_lng      DOUBLE PRECISION,
  location_label TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX profiles_role_idx ON public.profiles (role);
CREATE INDEX profiles_status_idx ON public.profiles (status);
CREATE INDEX profiles_email_idx ON public.profiles (email);

-- ---------------------------------------------------------------------------
-- devices — helmet / handset running ArgusX software
-- ---------------------------------------------------------------------------
CREATE TABLE public.devices (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  device_label  TEXT NOT NULL DEFAULT 'ArgusX Device',
  platform      public.device_platform NOT NULL DEFAULT 'unknown',
  app_version   TEXT,
  is_online     BOOLEAN NOT NULL DEFAULT FALSE,
  battery_pct   SMALLINT CHECK (battery_pct IS NULL OR (battery_pct >= 0 AND battery_pct <= 100)),
  last_seen_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, device_label)
);

CREATE INDEX devices_user_id_idx ON public.devices (user_id);

-- ---------------------------------------------------------------------------
-- rides — one safety-ride / simulation session
-- ---------------------------------------------------------------------------
CREATE TABLE public.rides (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  device_id           UUID REFERENCES public.devices (id) ON DELETE SET NULL,
  session_id          TEXT NOT NULL UNIQUE,
  status              public.ride_status NOT NULL DEFAULT 'active',
  origin_label        TEXT,
  origin_lat          DOUBLE PRECISION,
  origin_lng          DOUBLE PRECISION,
  destination_label   TEXT,
  destination_lat     DOUBLE PRECISION,
  destination_lng     DOUBLE PRECISION,
  route_polyline      TEXT,
  distance_m          INTEGER,
  duration_s          INTEGER,
  avg_speed_kmh       NUMERIC(6, 2),
  max_threat_level    public.threat_level NOT NULL DEFAULT 'NORMAL',
  threats_count       INTEGER NOT NULL DEFAULT 0,
  safety_score        NUMERIC(5, 2),
  started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at            TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX rides_user_id_idx ON public.rides (user_id);
CREATE INDEX rides_status_idx ON public.rides (status);
CREATE INDEX rides_started_at_idx ON public.rides (started_at DESC);

-- ---------------------------------------------------------------------------
-- fleet_positions — live map pin (one row per rider, upserted each pulse)
-- ---------------------------------------------------------------------------
CREATE TABLE public.fleet_positions (
  user_id             UUID PRIMARY KEY REFERENCES public.profiles (id) ON DELETE CASCADE,
  ride_id             UUID REFERENCES public.rides (id) ON DELETE SET NULL,
  session_id          TEXT,
  device_id           UUID REFERENCES public.devices (id) ON DELETE SET NULL,
  lat                 DOUBLE PRECISION NOT NULL,
  lng                 DOUBLE PRECISION NOT NULL,
  speed_kmh           NUMERIC(6, 2) NOT NULL DEFAULT 0,
  threat_level        public.threat_level NOT NULL DEFAULT 'NORMAL',
  hud_mode            TEXT,
  heading_deg         SMALLINT,
  is_online           BOOLEAN NOT NULL DEFAULT TRUE,
  battery_pct         SMALLINT,
  destination_label   TEXT,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX fleet_positions_online_idx ON public.fleet_positions (is_online);
CREATE INDEX fleet_positions_updated_at_idx ON public.fleet_positions (updated_at DESC);

-- ---------------------------------------------------------------------------
-- safety_events — WARNING/CRITICAL compliance + agent events
-- ---------------------------------------------------------------------------
CREATE TABLE public.safety_events (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id          TEXT NOT NULL UNIQUE,
  ride_id           UUID REFERENCES public.rides (id) ON DELETE SET NULL,
  user_id           UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  session_id        TEXT NOT NULL,
  threat_level      public.threat_level NOT NULL,
  lat               DOUBLE PRECISION,
  lng               DOUBLE PRECISION,
  speed_kmh         NUMERIC(6, 2),
  hazards           JSONB NOT NULL DEFAULT '[]'::JSONB,
  enriched_context  TEXT,
  ui_commands       JSONB NOT NULL DEFAULT '[]'::JSONB,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX safety_events_user_id_idx ON public.safety_events (user_id);
CREATE INDEX safety_events_ride_id_idx ON public.safety_events (ride_id);
CREATE INDEX safety_events_created_at_idx ON public.safety_events (created_at DESC);
CREATE INDEX safety_events_threat_level_idx ON public.safety_events (threat_level);

-- ---------------------------------------------------------------------------
-- updated_at trigger helper
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER devices_set_updated_at
  BEFORE UPDATE ON public.devices
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER rides_set_updated_at
  BEFORE UPDATE ON public.rides
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
