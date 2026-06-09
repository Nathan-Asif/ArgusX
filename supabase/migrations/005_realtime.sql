-- ArgusX: enable Supabase Realtime for admin fleet map
-- Run after 004_rls_policies.sql

ALTER PUBLICATION supabase_realtime ADD TABLE public.fleet_positions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rides;
ALTER PUBLICATION supabase_realtime ADD TABLE public.safety_events;

-- Admin fleet overview (run manually to verify)
-- SELECT fp.*, p.full_name, p.email, p.role
-- FROM public.fleet_positions fp
-- JOIN public.profiles p ON p.id = fp.user_id
-- WHERE fp.is_online = TRUE
-- ORDER BY fp.updated_at DESC;
