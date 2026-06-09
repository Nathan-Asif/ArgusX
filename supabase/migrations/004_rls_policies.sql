-- ArgusX: Row Level Security
-- Run after 003_functions_triggers.sql

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_events ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- Helper: is current user an admin?
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
      AND status = 'active'
  );
$$;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
CREATE POLICY profiles_select_own
  ON public.profiles FOR SELECT
  USING (auth.uid() = id OR public.is_admin());

CREATE POLICY profiles_update_own
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())
  );

CREATE POLICY profiles_admin_update
  ON public.profiles FOR UPDATE
  USING (public.is_admin());

-- ---------------------------------------------------------------------------
-- devices
-- ---------------------------------------------------------------------------
CREATE POLICY devices_select
  ON public.devices FOR SELECT
  USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY devices_insert_own
  ON public.devices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY devices_update_own
  ON public.devices FOR UPDATE
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- rides
-- ---------------------------------------------------------------------------
CREATE POLICY rides_select
  ON public.rides FOR SELECT
  USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY rides_insert_own
  ON public.rides FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY rides_update_own
  ON public.rides FOR UPDATE
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- fleet_positions — customers see own pin; admins see all
-- ---------------------------------------------------------------------------
CREATE POLICY fleet_positions_select
  ON public.fleet_positions FOR SELECT
  USING (auth.uid() = user_id OR public.is_admin());

-- Inserts/updates from mobile go through service-role RPC (backend).
-- Allow customers to read only; backend uses service role key.

-- ---------------------------------------------------------------------------
-- safety_events
-- ---------------------------------------------------------------------------
CREATE POLICY safety_events_select
  ON public.safety_events FOR SELECT
  USING (auth.uid() = user_id OR public.is_admin());

-- Writes via service-role RPC only (record_safety_event).

-- ---------------------------------------------------------------------------
-- Grant usage to authenticated users
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.devices TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.rides TO authenticated;
GRANT SELECT ON public.fleet_positions TO authenticated;
GRANT SELECT ON public.safety_events TO authenticated;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
