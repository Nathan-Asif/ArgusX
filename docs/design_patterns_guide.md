# ArgusX Design Patterns — Submission & Viva Guide

Brief reference for explaining **what patterns we use, where they live, and why** during project demo or invigilator Q&A.

---

## 30-second elevator pitch

> **ArgusX** is a decoupled **N-tier** motorcycle safety HUD. The **Flutter** client streams camera + GPS over **WebSocket** to a **FastAPI + LangGraph** agent pipeline (perception → context RAG → routing engine). **WARNING/CRITICAL** events are sent asynchronously to a **Java compliance microservice** that implements our **SDA lab patterns** (Singleton, Factory, Builder, Composite, Null Object, Mediator, Observer). **Supabase** stores users, rides, and live fleet positions for the **Next.js** admin portal.

---

## LangGraph multi-agent kernel (3 agents)

Every Safety Pulse frame from the Flutter HUD passes through **three sequential agents** compiled in `Backend/graph/argusx_agent_graph.py`:

```
START → [1] Perception → [2] Context RAG → [3] Routing Engine → END
```

| # | Agent name | Graph node ID | Source file | Role | Key outputs |
|---|------------|---------------|-------------|------|-------------|
| **1** | **Perception Agent** (spatial awareness) | `perception` | `graph/nodes/argusx_perception.py` | Analyses camera `frame_data` (live JPEG or `fixture:*` tokens) via **Gemini** or demo fixtures; detects hazards such as pedestrians, opening doors, cross-traffic | `hazards[]`, `perception_source` |
| **2** | **Context RAG Agent** | `context_rag` | `graph/nodes/argusx_context_rag.py` | Enriches the scene with **FAISS** spatial-zone lookup at GPS coordinates; merges navigation, destination, and hazard context into a narrative; skips SF demo zones when Google Maps nav is active | `spatial_context[]`, `enriched_context`, `pinned_pois[]` |
| **3** | **Routing Engine Agent** | `routing_engine` | `graph/nodes/argusx_routing_engine.py` | Decides **threat level** (`NORMAL` / `WARNING` / `CRITICAL`), **HUD mode**, turn-by-turn **navigation** + **voice_prompt**, and **UI commands** (e.g. show map, trigger alerts) | `threat_level`, `hud_mode`, `navigation`, `ui_commands` |

**How to say it in viva:** *"Agent 1 sees hazards in the camera feed. Agent 2 adds location and route context from FAISS and GPS. Agent 3 decides threat level, navigation arrows, and what the HUD should show — including spoken turn instructions."*

**Downstream:** If Agent 3 sets `WARNING` or `CRITICAL`, FastAPI asynchronously dispatches a threat event to the **Java compliance microservice** (Mediator → Factory → Builder → Observer).

---

## System layers (N-Tier / Layered Architecture)

| Layer | Technology | Responsibility |
|-------|------------|----------------|
| **Presentation** | Flutter, Next.js | UI, camera HUD, admin fleet map, auth screens |
| **Application** | FastAPI, LangGraph | WebSocket pulse, agent reasoning, navigation API |
| **Microservice** | Java Spring Boot | Compliance audit, threat reports, HUD menu tree |
| **Data** | Supabase PostgreSQL, FAISS | Users, rides, fleet pins, spatial zone vectors |

**Where:** whole repo structure — `Frontend/`, `Backend/`, `Backend/Microservices/`, `supabase/`

**How to say it:** *"We separated UI, business logic, audit microservice, and database so each layer can change independently — classic layered architecture."*

**General definition (Layered / N-Tier):** An architectural style that splits the system into horizontal layers (presentation, business logic, data access), where each layer only talks to the layer directly below it. This improves maintainability, testability, and team separation.

---

## General pattern definitions (textbook)

Use these when the invigilator asks *"What is this pattern in general?"* before you explain the ArgusX example.

| Pattern | General definition |
|---------|-------------------|
| **Layered (N-Tier)** | Organizes code into stacked layers with clear responsibilities; upper layers depend on lower layers, not the reverse. |
| **Singleton** | Ensures a class has only **one instance** in the application and provides a global access point to it. |
| **Factory** | Delegates object creation to a dedicated creator class/method so callers request a type by name or key instead of using `new` everywhere. |
| **Builder** | Constructs a **complex object step-by-step** using a fluent interface; separates construction from the final representation. |
| **Composite** | Composes objects into **tree structures** so clients treat individual objects and groups of objects the **same way** via a shared interface. |
| **Null Object** | Provides a **do-nothing substitute** object instead of `null`, so calling code does not need null checks and avoids runtime errors. |
| **Mediator** | Defines an object that **encapsulates how other objects interact**, promoting loose coupling by preventing classes from referring to each other explicitly. |
| **Observer** | Defines a **one-to-many dependency**: when one object (subject) changes state, all dependents (observers) are **notified automatically**. |
| **Pipeline / Chain of Responsibility** | Passes a request along a **chain of handlers**; each handler processes part of the work and passes the result to the next. |
| **Template Method** | Defines the **skeleton of an algorithm** in a base class, letting subclasses override specific steps without changing the overall structure. |
| **Composition Root** | A single place in the application where all object **dependencies are constructed and wired** together before use. |
| **Dependency Injection (DI)** | Supplies a class with its dependencies from the **outside** (constructor/setter) instead of the class creating them itself. |
| **Event-Driven** | Components communicate by **producing and consuming events** asynchronously rather than calling each other directly in a rigid sequence. |
| **Facade** | Provides a **simplified unified interface** to a complex subsystem, hiding internal details from the client. |
| **Repository** | Mediates between the domain/business logic and data mapping, acting like an **in-memory collection** of domain objects backed by a database. |
| **Service Layer** | Groups **application-specific business logic** behind service classes so UI/controllers stay thin and reusable. |
| **Strategy** | Defines a family of **interchangeable algorithms**, encapsulates each one, and lets the client choose which to use at runtime. |
| **MVVM** | Separates UI (**View**) from display logic/state (**ViewModel**) and data (**Model**) so the view reacts to data changes without tight coupling. |
| **Context / Provider** | Shares global application state (e.g. auth) down a component tree without passing props through every level. |
| **Row Level Security (RLS)** | A database feature that **restricts which rows** each user can read/write based on policies, enforcing access at the data layer. |

---

## Pattern map (quick reference)

| Pattern | Primary location | SDA lab |
|---------|------------------|---------|
| **Singleton** | Java `DatabaseConnectionPool` | Lab 2 |
| **Factory** | Java `ThreatIncidentFactory` | Lab 3 |
| **Builder** | Java `SafetyReportBuilder` | Lab 4 |
| **Composite** | Java `HudMenuBranch` / `HudMenuLeaf` | Lab 6 |
| **Null Object** | Java `NullCoordinates` | Lab 8 |
| **Mediator** | Java `ComplianceMediator` | Lab 9 |
| **Observer** | Java `DashboardObserver` | Lab 9 |
| **Pipeline / Chain** | Python LangGraph agent nodes | — |
| **Template Method** | Python `ArgusXBaseNode` | — |
| **Composition Root** | Python `ArgusXApplication` | — |
| **Dependency Injection** | Spring Boot, `ArgusXApplication` wiring | — |
| **Event-Driven** | WebSocket pulse, async compliance POST | — |
| **Facade** | `ArgusXGoogleMapsClient`, `ArgusXWebSocketService` | — |
| **Repository-style** | `ArgusXPersistence` → Supabase RPC | — |
| **Service Layer** | Flutter `*_service.dart` files | — |
| **Strategy-like** | `ArgusXRoutingEngineNode` nav resolution | — |

---

## Java microservice — SDA patterns (show these first)

All under: `Backend/Microservices/compliance_service/src/main/java/com/argusx/compliance/`

### 1. Singleton (Lab 2)

**General definition:** Guarantees a single shared instance of a class (e.g. one connection pool) with controlled global access.

**Class:** `config/DatabaseConnectionPool.java`

**What:** One shared database connection pool per JVM.

**Why:** Avoids opening multiple pools and leaking connections when many threat events arrive.

**Demo line:** *"When a threat event arrives, we call `connectionPool.connect()` — always the same singleton instance."*

---

### 2. Factory (Lab 3)

**General definition:** A creation pattern that instantiates the correct concrete class based on input (e.g. threat level) without exposing creation logic to the caller.

**Class:** `factory/ThreatIncidentFactory.java`

**What:** Creates the correct threat object from a string level (`CRITICAL`, `WARNING`, `NORMAL`).

**Why:** Callers don't need `if/else` for each threat type; the factory encapsulates creation rules.

**Demo line:** *"FastAPI sends `threat_level: CRITICAL` — the factory returns a `CriticalThreatIncident` with the right behaviour."*

---

### 3. Builder (Lab 4)

**General definition:** Builds a complex object piece by piece through chained setter methods, then returns the final immutable/product object via `.build()`.

**Classes:** `builder/SafetyReportBuilder.java` → `SafetyReport.java`

**What:** Builds a complex audit report step-by-step (event ID, session, rider, coords, hazards, timestamp).

**Why:** The report has many optional fields; the builder keeps construction readable and safe.

**Demo line:** *"We chain `.eventId().sessionId().threatLevel()...build()` before persisting or notifying observers."*

---

### 4. Composite (Lab 6)

**General definition:** Models part-whole hierarchies (trees) so leaves and containers implement the same interface and can be treated uniformly.

**Classes:** `composite/HudMenuBranch.java`, `HudMenuLeaf.java`, `HudMenuTreeFactory.java`

**What:** HUD settings menu is a **tree** — branches contain leaves; both share `HudMenuComponent`.

**Why:** Admin/rider menu config (overlays, voice, alerts) is hierarchical; Composite treats branch and leaf uniformly.

**Demo line:** *"Menu config API returns a nested JSON tree built from branches and leaves — same interface for folders and settings."*

**Try it:** `POST http://127.0.0.1:8081/api/compliance/menu-config`

---

### 5. Null Object (Lab 8)

**General definition:** Replaces `null` references with a special object that implements the same interface but performs safe default/no-op behaviour.

**Classes:** `model/NullCoordinates.java`, `CoordinatesResolver.java`

**What:** Missing or corrupt GPS returns `NullCoordinates.INSTANCE` instead of `null`.

**Why:** Downstream code never crashes on null; it gets a safe object with `describe()` = "NULL_COORDINATES".

**Demo line:** *"If the rider payload has no lat/lng, we don't throw — we use the null object and still build the report."*

---

### 6. Mediator (Lab 9)

**General definition:** Central hub that coordinates communication between multiple components so they do not reference each other directly.

**Class:** `mediator/ComplianceMediator.java`

**What:** Central coordinator — receives threat event, uses Factory + Builder + Singleton pool, then notifies observers.

**Why:** Controller doesn't talk to Factory, Builder, DB, and Dashboard directly; one mediator reduces coupling.

**Demo line:** *"The REST controller only calls `mediator.processThreatEvent()` — the mediator orchestrates everything else."*

---

### 7. Observer (Lab 9)

**General definition:** Subject notifies registered observers automatically when its state changes; observers react without the subject knowing their internal details.

**Classes:** `mediator/ComplianceObserver.java`, `DashboardObserver.java`

**What:** When a safety report is persisted, all registered observers are notified.

**Why:** Fleet dashboard / audit log can react without the mediator knowing UI details.

**Demo line:** *"After a report is saved, `DashboardObserver` appends it to the audit log — that's Observer pattern."*

**Try it:** `GET http://127.0.0.1:8081/api/compliance/audit-log`

---

## Python backend — architecture patterns

### Pipeline / Chain of Responsibility (LangGraph)

**General definition:** Each processing stage handles its part of the work and forwards the enriched result to the next stage in a fixed or dynamic chain.

**Where:** `Backend/graph/argusx_agent_graph.py`

**Flow:**
```
START → perception → context_rag → routing_engine → END
```

Each node reads shared `ArgusXState` and returns a partial update.

**Demo line:** *"Every camera frame goes through three agents in order — (1) Perception, (2) Context RAG, (3) Routing Engine — see the multi-agent table at the top of this doc."*

**The 3 agents:**

| Agent | Node file |
|-------|-----------|
| Perception Agent | `argusx_perception.py` |
| Context RAG Agent | `argusx_context_rag.py` |
| Routing Engine Agent | `argusx_routing_engine.py` |

---

### Template Method

**General definition:** Parent class defines the overall algorithm flow; child classes override specific steps while the sequence stays the same.

**Where:** `Backend/graph/nodes/argusx_base_node.py`

**What:** Abstract `ArgusXBaseNode` defines `run()`; each agent implements it. `__call__` is the LangGraph entrypoint.

**Demo line:** *"All agents share the same contract — `run(state) → dict` — but each implements different logic."*

---

### Composition Root + Dependency Injection

**General definition (Composition Root):** One module/class responsible for creating and connecting all dependencies at application startup.

**General definition (DI):** Objects receive collaborators from outside rather than constructing them internally — improves testability and swapping implementations.

**Where:** `Backend/core/argusx_application.py`

**What:** `ArgusXApplication` constructs database, vector store, agent graph, compliance client, maps client, and registers routes in one place.

**Demo line:** *"We don't create dependencies inside routes — the application class wires everything at startup."*

---

### Event-Driven / Fire-and-forget

**General definition:** Producers emit events (pulses, threats); consumers react asynchronously without blocking the main real-time path.

**Where:**
- `Backend/api/argusx_websocket_routes.py` — bi-directional Safety Pulse
- `Backend/services/argusx_compliance_client.py` — `asyncio.create_task()` for threat POST
- `Backend/database/argusx_persistence.py` — async DB writes without blocking HUD

**Demo line:** *"The HUD WebSocket never waits for Java or Supabase — events are dispatched in the background so the ride stays smooth."*

---

### Facade

**General definition:** A single simplified API in front of a complex subsystem (maps API, WebSocket protocol, etc.).

**Where:**
- `Backend/services/argusx_google_maps_client.py` — geocode, directions, static map behind one client
- `Frontend/App/lib/services/websocket_service.dart` — hides WebSocket wire format from UI

**Demo line:** *"Screens call `resolveRoute()` or `sendPulse()` — they don't deal with Google URLs or raw JSON framing."*

---

### Strategy-like navigation

**General definition:** Selects one of several algorithms (map nav, hazard override, zone nav) at runtime based on context, without changing the client code.

**Where:** `Backend/graph/nodes/argusx_routing_engine.py`

**What:** Chooses navigation strategy based on context:
- Map route (Google Directions)
- Hazard override (CRITICAL)
- Zone-based (FAISS spatial context)

**Demo line:** *"The routing engine picks map navigation, hazard override, or zone guidance depending on threat level and destination."*

---

## Flutter mobile — patterns

### Service Layer

**General definition:** Encapsulates business and integration logic (API calls, auth, voice) in dedicated classes separate from UI widgets.

**Where:** `Frontend/App/lib/services/`
- `auth_service.dart` — Supabase login/register
- `websocket_service.dart` — Safety Pulse client
- `navigation_service.dart` — REST route resolve
- `voice_destination_service.dart` — STT + TTS voice flow
- `navigation_voice_service.dart` — turn-by-turn TTS

**Demo line:** *"UI screens don't call APIs directly — services encapsulate HTTP, WebSocket, and voice."*

---

### Model → View flow (MVVM-ish)

**General definition (MVVM):** UI renders state; a model/config object holds ride data; screens observe and update without mixing network logic into widgets.

**Where:**
- `models/sim_launch_config.dart` — data passed Ride Setup → Camera HUD
- `views/camera_hud_view.dart` — setup screen
- `screens/camera_simulation_screen.dart` — live HUD

**Demo line:** *"Ride Setup builds a `SimLaunchConfig` model; the camera screen consumes it — clear separation of setup vs live ride."*

---

## Next.js web portal — patterns

### Context Provider (auth state)

**General definition:** A React pattern (variant of Observer + shared state) that injects global data like logged-in user into any child component.

**Where:** `Frontend/Web/src/lib/AuthContext.tsx`

**What:** React Context supplies `user`, `login`, `logout` to admin and user portals.

**Demo line:** *"Auth state is global via Context — guards and dashboards read the same session."*

---

### Observer / realtime (planned + partial)

**General definition:** Subscribers (admin dashboard) listen for data changes; the database/channel publishes updates when fleet rows change — same Observer idea at infrastructure level.

**Where:** Admin fleet tracking page; Supabase Realtime on `fleet_positions` (see `supabase/migrations/005_realtime.sql`)

**Demo line:** *"Admin map subscribes to fleet position changes — when a rider moves, the dashboard updates like an observer reacting to events."*

---

## Database — patterns

### Repository-style persistence

**General definition:** Hides SQL/table details behind a persistence API (`ensure_active_ride`, `upsert_fleet_position`) so application code deals with domain operations, not raw queries.

**Where:** `Backend/database/argusx_persistence.py` + Supabase RPC functions in `supabase/migrations/003_functions_triggers.sql`

**What:** Backend calls `ensure_active_ride`, `upsert_fleet_position`, `record_safety_event` instead of raw SQL in Python.

**Demo line:** *"Pulse telemetry goes through named database functions — one place for ride and fleet rules."*

---

### Row Level Security (RLS)

**General definition:** PostgreSQL/Supabase enforces per-user data access rules in the database itself (e.g. customers see only their rides; admins see all).

**Where:** `supabase/migrations/004_rls_policies.sql`

**What:** Customers see only their data; admins see all via `is_admin()` policy.

**Demo line:** *"Supabase enforces access at the database — customers can't read other riders' rides."*

---

## End-to-end flow to draw on whiteboard

```
[Rider Flutter] 
    │ voice: "Argus set location for Saddar"
    │ POST /navigation/resolve
    │ WebSocket /ws/pulse (camera + GPS)
    ▼
[FastAPI LangGraph]
    perception → context_rag → routing_engine
    │                    │
    │ WARNING/CRITICAL   │ navigation + hazards JSON
    ▼                    ▼
[Java Compliance]    [Flutter HUD overlays]
 Mediator→Factory→Builder→Observer
    │
    ▼
[Supabase] profiles, rides, fleet_positions, safety_events
    │
    ▼
[Next.js Admin] fleet map + user management
```

---

## Viva cheat sheet — likely questions

| Question | Short answer |
|----------|--------------|
| **What is Singleton in general?** | One shared instance of a class with global controlled access — we use it for the DB connection pool. |
| **What is Factory in general?** | Creates the right object type based on input — we use it for CRITICAL/WARNING threat objects. |
| **What is Observer in general?** | One-to-many notify-on-change — audit log updates when a safety report is saved. |
| **What is Mediator in general?** | Central coordinator so components don't talk to each other directly — `ComplianceMediator`. |
| **Why microservices?** | Python handles real-time AI/streaming; Java isolates academic SDA patterns and compliance audit. |
| **What are the 3 agents?** | (1) **Perception** — hazard detection from camera; (2) **Context RAG** — FAISS zones + enriched context; (3) **Routing Engine** — threat, HUD mode, navigation, UI commands. |
| **Why LangGraph?** | Multi-step agent pipeline with shared `ArgusXState` — cleaner than one giant function. |
| **Where is Observer?** | `DashboardObserver` notified when `ComplianceMediator` persists a report. |
| **Where is Mediator?** | `ComplianceMediator` — single entry for threat processing. |
| **Why Null Object?** | Safe GPS fallback when mobile/web has no real location. |
| **How does admin see riders?** | `fleet_positions` updated each pulse; Realtime subscription on web. |
| **Is it event-driven?** | Yes — WebSocket pulses and async threat dispatch; observers react to reports. |

---

## Files to open during demo

1. **Java patterns:** `ComplianceMediator.java` (Mediator ties all labs together)
2. **Agent pipeline:** `argusx_agent_graph.py`
3. **Live integration:** `argusx_websocket_routes.py`
4. **Mobile flow:** `camera_hud_view.dart` → `camera_simulation_screen.dart`
5. **Database:** `supabase/migrations/002_tables.sql`
6. **Architecture doc:** `docs/argusx_prd.md` §6

---

## Related docs

- `docs/argusx_prd.md` — full system blueprint
- `docs/database_schema_plan.md` — tables and auth flow
- `Backend/Microservices/compliance_service/README.md` — Java pattern class list
- `docs/flutter_integration_plan.md` — mobile ↔ backend contract
