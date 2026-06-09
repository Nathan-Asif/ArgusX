-- Promote an existing Supabase Auth user to admin.
-- Replace the email before running.

UPDATE public.profiles
SET role = 'admin', updated_at = NOW()
WHERE email = 'nathanasif@gmail.com';

-- Verify
SELECT id, email, full_name, role, status, total_rides
FROM public.profiles
WHERE email = 'nathanasif4@gmail.com';
