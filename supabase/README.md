# ArgusX Supabase Setup

## 1. Create project

1. Go to [supabase.com](https://supabase.com) → New project
2. Copy **Project URL** and keys into `Backend/.env`:

```env
ARGUSX_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
ARGUSX_SUPABASE_KEY=YOUR_SERVICE_ROLE_KEY
ARGUSX_DATABASE_URL=postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres
ARGUSX_DATABASE_ENABLED=true
```

Flutter / Web use the **anon** key (not service role):

```env
# Flutter --dart-define
ARGUSX_SUPABASE_URL=...
ARGUSX_SUPABASE_ANON_KEY=...

# Web .env.local
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

## 2. Run migrations (SQL Editor)

In Supabase Dashboard → **SQL Editor**, run each file **in order**:

| # | File |
|---|------|
| 1 | `migrations/001_extensions_enums.sql` |
| 2 | `migrations/002_tables.sql` |
| 3 | `migrations/003_functions_triggers.sql` |
| 4 | `migrations/004_rls_policies.sql` |
| 5 | `migrations/005_realtime.sql` |

Or paste the combined script: `migrations/000_run_all.sql`

## 3. Create your first admin

Register a normal account on Flutter or Web, then in SQL Editor:

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'your-email@example.com';
```

## 4. Verify

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected: `devices`, `fleet_positions`, `profiles`, `rides`, `safety_events`

## 5. Auth signup metadata

Flutter signup sends `full_name` and `role: customer` in user metadata.
The trigger always sets `profiles.role = customer` for new signups (admins are promoted manually).

## 6. Admin fleet map (Web — next integration step)

Subscribe to realtime changes:

```ts
supabase.channel('fleet')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'fleet_positions' }, handler)
  .subscribe();
```

Query active riders:

```sql
SELECT fp.*, p.full_name, p.email
FROM fleet_positions fp
JOIN profiles p ON p.id = fp.user_id
WHERE fp.is_online = true;
```
