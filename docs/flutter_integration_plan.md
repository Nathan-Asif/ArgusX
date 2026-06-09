# ArgusX Flutter Integration Plan

Connects the teammate UI shell to the FastAPI + LangGraph + Java compliance backend.

## Interaction flow (primary — voice)

```
Login (Supabase) → Simulation Settings → Voice: "Argus set location for Saddar"
  → ArgusX TTS: "Setting destination to Saddar. Is that correct?"
  → User: "Yes"
  → POST /navigation/resolve (origin from GPS or geocode, destination Saddar)
  → Launch Camera HUD (landscape)
  → WebSocket /ws/pulse every 1.5s with frame + destination + route_context
  → Backend: perception → context_rag → routing → Java compliance (WARNING/CRITICAL)
  → HUD: hazard boxes (from agents), nav arrow, map panel, Argus Ring threat color
```

## Simulation settings (replaces sci-fi labels)

| Old (teammate) | New (functional) |
|----------------|------------------|
| PRE-SIMULATION PROTOCOL | **Ride Setup** |
| TARGET_GRID_ZONE | **Destination** (text + voice) |
| PROBE_DENSITY_LOD | **Camera quality** (low/med/high) |
| TACTICAL_SYNC_OVERLAY | **Show GPS on HUD** |
| INITIALIZE NEURAL SIMULATION | **Start Safety Ride** |

## Camera HUD overlay layout

| Region | Content | Data source |
|--------|---------|-------------|
| Top center | **ArgusX** + nav arrow + instruction | `navigation` |
| Top left | Speed, threat, connection | telemetry + `threat_level` |
| Left/center | Hazard bounding boxes | `hazards[]` from perception agent |
| Bottom right | **Route map** (static map image) | `route_visualization.static_map_url` |
| Bottom left | Destination + coords | session + GPS |
| Center | Argus Ring (optional) | `threat_level` |

Removed sci-fi: VELOCITY, VECTOR NODE, RECHARGE MATRIX, CYBER-GRID, right-side warning box.

## WebSocket contract (full)

**Outbound:** `speed`, `coordinates`, `frame_data`, `session_id`, `rider_id`, `destination`, `route_context`, `route_visualization`, `route_step_index`

**Inbound:** `threat_level`, `hud_mode`, `ui_commands`, `enriched_context`, `navigation`, `pinned_pois`, `hazards`, `destination`, `route_visualization`

## Build & run

```bash
cd Frontend/App
flutter pub get
flutter run \
  --dart-define=ARGUSX_WS_URL=ws://10.0.2.2:8000/ws/pulse \
  --dart-define=ARGUSX_API_URL=http://10.0.2.1:8000 \
  --dart-define=ARGUSX_SUPABASE_URL=<url> \
  --dart-define=ARGUSX_SUPABASE_ANON_KEY=<key>
```

Use `127.0.0.1` for web/desktop; `10.0.2.2` for Android emulator; LAN IP for physical device.

## Phase 2 (later)

- Second interaction path (manual map picker)
- Gemini live voice on backend
- Real hazard bounding boxes from vision model
- iOS permissions and build
