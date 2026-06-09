# ArgusX Database Schema Plan (Supabase / PostgreSQL)

## Goals

- **Customer** registers on Flutter mobile → `auth.users` + `profiles` row (`role = customer`)
- **Admin** logs in on Web portal → sees all customers, live map positions, ride history
- Each **simulation / safety ride** creates a `rides` row with origin, destination, metrics
- Each **WebSocket pulse** updates `fleet_positions` (who is online, where on the map)
- **Threat events** from the compliance pipeline land in `safety_events`

## Role model

| DB value (`profiles.role`) | Flutter | Web portal |
|--------------------------|---------|------------|
| `customer` | default on signup | shown as `user` / rider |
| `admin` | — | admin dashboard access |

Promote the first admin manually in Supabase SQL (see `supabase/README.md`).

## Tables

```
auth.users (Supabase managed)
    └── profiles (1:1) — name, role, status, safety_score, last_known_location
            ├── devices (1:N) — helmet / app instance per customer
            ├── rides (1:N) — each Start Safety Ride session
            │       └── safety_events (1:N) — WARNING/CRITICAL during ride
            └── fleet_positions (1:1 live) — realtime map pin for admin
```

### `profiles`
Extends Supabase Auth. Created automatically on signup via trigger.

### `devices`
Logical helmet / handset running ArgusX software. Optional but supports multi-device customers.

### `rides`
One row per `session_id` when a customer starts a safety ride.

| Key fields | Source |
|------------|--------|
| `origin_*`, `destination_*` | Ride Setup + `/navigation/resolve` |
| `route_polyline` | `route_visualization.polyline` |
| `max_threat_level`, `threats_count` | aggregated from pulses / safety_events |
| `status` | `active` → `completed` on WS disconnect |

### `fleet_positions`
Upserted every Safety Pulse. Admin fleet map subscribes via Supabase Realtime.

### `safety_events`
Persisted when Java compliance receives WARNING/CRITICAL (and from FastAPI side-channel).

## What runs where

| Action | Runner |
|--------|--------|
| Signup → profile | Supabase trigger `handle_new_user` |
| Start ride | FastAPI WS first pulse → `ensure_active_ride` RPC |
| Live GPS on map | FastAPI WS each pulse → `upsert_fleet_position` RPC |
| End ride | FastAPI WS disconnect → `complete_ride_session` RPC |
| Threat log | FastAPI compliance dispatch → `record_safety_event` RPC |

## Files to apply (in order)

1. `supabase/migrations/001_extensions_enums.sql`
2. `supabase/migrations/002_tables.sql`
3. `supabase/migrations/003_functions_triggers.sql`
4. `supabase/migrations/004_rls_policies.sql`
5. `supabase/migrations/005_realtime.sql`

See `supabase/README.md` for Supabase Dashboard steps and env vars.
