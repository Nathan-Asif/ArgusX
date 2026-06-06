# ArgusX – System Engineering Blueprint & Implementation Canvas

- **System Version:** 1.0
- **Architecture Style:** Decoupled N-Tier & Event-Driven Graph
- **Development Methodology:** Specification-Driven Development (SDD) via GitHub Spec-Kit
- **Target Environment:** Python 3.11+ (FastAPI) | Flutter (Dart 3.x) | Supabase PostgreSQL

---

## 1. System Topology Canvas

```text
[ ARGUSX SYSTEM CANVAS ]

+-----------------------------------------------------------------------------------------+
|                                   PRESENTATION LAYER                                    |
|                                                                                         |
|   +---------------------------------------+     +-----------------------------------+   |
|   |         FLUTTER MOBILE CLIENT         |     |        NEXT.JS WEB PORTALS        |   |
|   |  - 16:9 Obsidian UI Engine            |     |  - Tesla-Style Fleet Dashboard    |   |
|   |  - Camera Frame Pipeline (Bi-WS)      |     |  - Relational Analytics Views     |   |
|   |  - Telemetry Accumulator Stream       |     |  - Admin Control Station          |   |
|   +-------------------+-------------------+     +-----------------+-----------------+   |
+-----------------------|-------------------------------------------|---------------------+
                        | Bi-Directional WebSockets                 | REST API / DB Listeners
+-----------------------|-------------------------------------------|---------------------+
|                       v                                           v                     |
|   +---------------------------------------------------------------------------------+   |
|   |                      FASTAPI APPLICATION LAYER & AGENT KERNEL                   |   |
|   |                                                                                 |   |
|   |   +-------------------------------------------------------------------------+   |   |
|   |   |                        LANGGRAPH STATE MANAGEMENT MATRIX                |   |   |
|   |   |                                                                         |   |   |
|   |   |    [State Object Input] -> (Perception Node) -> (Context RAG Node)      |   |   |
|   |   |                                                      |                  |   |   |
|   |   |    [Action JSON Output] <- (Broadcast Routing Node) <+                  |   |   |
|   +---+------------------------------------+------------------------------------+---+   |
+-------|------------------------------------|------------------------------------|-------+
        |                                    |                                    |
        | HTTP / REST                        | Relational DB Pipeline             | Local Vector Queries
        v                                    v                                    v
+-------+------------------------------------+------------------------------------+-------+
|                                           DATA LAYER                                    |
|                                                                                         |
|         +------------------------------------+   +--------------------------------+     |
|         |    SUPABASE (POSTGRESQL MATRIX)    |   |    LOCAL VECTOR STORAGE        |     |
|         |  - Relational Schemas & Indexing   |   |  - FAISS Vector Embeddings     |     |
|         |  - JWT Stateless Session Auth      |   |  - Low-Latency Context Cache   |     |
|         +------------------------------------+   +--------------------------------+     |
+-----------------------------------------------------------------------------------------+
```

---

## 2. Project File Structure Architecture

```text
ArgusX/
├── .github/                       # IDE/Copilot custom context & instructions mapping
├── .specify/                      # Specification-Driven Development (SDD) Engine Directory
│   ├── memory/
│   │   └── constitution.md        # Core engineering, design, and pattern constraints
│   ├── specs/
│   │   ├── 01_safety_pulse_stream.md
│   │   └── 02_agentic_routing.md
│   ├── plans/
│   │   ├── 01_fastapi_langgraph_backend.md
│   │   └── 02_flutter_hud_interface.md
│   └── tasks/
│       ├── backend_tasks.md
│       └── frontend_tasks.md
├── Backend/                       # FastAPI + LangGraph orchestrator (class-based, argusx_ prefix)
│   ├── argusx_main.py             # ASGI entrypoint -> exposes `app`
│   ├── config/
│   │   └── argusx_settings.py     # ArgusXSettings (typed env/.env config)
│   ├── core/
│   │   └── argusx_application.py  # ArgusXApplication: composition root + lifespan
│   ├── database/
│   │   └── argusx_database.py     # ArgusXDatabase: Supabase relational layer
│   ├── vector_store/
│   │   └── argusx_faiss_store.py  # ArgusXVectorStore: local FAISS index
│   ├── graph/
│   │   ├── argusx_state.py        # ArgusXState: shared, type-safe state
│   │   ├── argusx_agent_graph.py  # ArgusXAgentGraph: builds + compiles the graph
│   │   └── nodes/
│   │       ├── argusx_base_node.py
│   │       ├── argusx_perception.py
│   │       ├── argusx_context_rag.py
│   │       └── argusx_routing_engine.py
│   ├── api/
│   │   ├── argusx_health_routes.py
│   │   └── argusx_websocket_routes.py
│   ├── .env.example
│   ├── requirements.txt
│   └── README.md
└── Frontend/
    ├── App/                       # Flutter mobile HUD client
    │   ├── android/
    │   ├── ios/
    │   ├── lib/
    │   │   ├── components/
    │   │   │   ├── argus_ring.dart
    │   │   │   └── glass_panel.dart
    │   │   ├── viewports/
    │   │   │   └── hud_viewport.dart
    │   │   ├── services/
    │   │   │   └── websocket_service.dart
    │   │   └── main.dart
    │   └── pubspec.yaml
    └── Web/                        # Next.js admin & user web portal
        ├── app/
        │   ├── admin/
        │   │   └── fleet-tracking/
        │   ├── user/
        │   │   └── analytics/
        │   └── layout.tsx
        ├── package.json
        └── tailwind.config.js
```

---

## 3. Executive Summary & Project Vision

ArgusX is a distributed, real-time "Guardentic" vision system engineered to dramatically elevate situational awareness for vehicle operators, initially prototyped for motorcycle helmets. Operating as a split edge-cloud system, ArgusX utilizes a multimodal AI core to interpret live environmental data and deliver proactive safety interventions through a specialized 16:9 landscape Heads-Up Display (HUD).

Beyond individual rider assistance, the project addresses ecosystem-level management by incorporating a centralized orchestration server and a Tesla-inspired fleet management portal for real-time monitoring, data aggregation, and administrative oversight.

---

## 4. Team Structure & Component Ownership

The project is executed by a 4-member engineering team distributed across specialized frontend and backend modules to enforce a clean separation of concerns and maximize code generation efficiency using tools like Cursor Pro:

- **Lead Engineer (You):**
  - Project baseline foundation initialization, backend setup, and database integration.
  - Core graph-based multi-agent layout architecture design using LangGraph.
  - Independent development of agentic graph nodes and local FAISS RAG operations.
- **Backend & Mobile Support Engineer (4th Member):**
  - Implementing stateless token-based authentication pipelines (JWT) across web and mobile platforms.
  - Building auxiliary backend routes, server maintenance scripts, and endpoints.
  - Cross-supporting the frontend team with Flutter interface integration.
- **Frontend Design & Development Team (2 Members):**
  - Prototyping and rendering the responsive 16:9 landscape glass-morphic HUD in Flutter.
  - Constructing interactive administrative web interfaces (Fleet Tracking) and user management platforms via Next.js.
  - Handling high-concurrency video frame capturing, client-side camera pipelines, and telemetry ingestion loops.

---

## 5. Core Features & Functional Requirements

### 5.1 HUD & Operator Experience (Mobile Client)

- **16:9 Obsidian Void HUD:** A cinematic, landscape-oriented mobile application interface designed with a 30% opacity glass-morphism overlay. It presents critical safety parameters and navigational data transparently, keeping the rider's field of view completely unobstructed.
- **The Argus Ring:** A central, pulsing digital iris serving as the visual anchor. The ring dynamically shifts its neon color profiles (utilizing Quantum Violet gradients) depending on system health metrics and external threat levels.
- **Passive Sentry Vision:** Continuous, non-blocking real-time analysis of the surrounding road environment to proactively isolate and highlight immediate hazards, such as opening vehicle doors or distracted pedestrians.
- **Spatial Grounding & Pinning:** Real-world points of interest (POIs) are discovered through camera streams and "pinned" stereoscopically with 3D holographic data bubbles displaying live contextual data.
- **Autonomous UI Navigation:** A context-aware state machine that dynamically manages UI clutter. The interface hides non-essential widgets during high-speed travel and broadens critical telemetry/navigation overlays during complex maneuvers.

### 5.2 Orchestration & Administrative Ecosystem (Server & Web)

- **Centralized Sentry Orchestration:** A highly concurrent, Python-based backend hub that coordinates streaming data flows, handles stateless protocols, and routes agentic reasoning requests between active mobile clients and cloud intelligence layers.
- **Tesla-Style Fleet Tracking:** An administrative command dashboard supplying real-time global visualizations of all active users, detailing precise location data, active connectivity status, and streaming safety telemetry.
- **Universal User Portal:** A web interface tailored for secure user onboarding, system profile configurations, and historical ride telemetry/safety analytics.
- **Agentic Authentication:** Secure, encrypted signup and sign-in flows spanning both mobile and web clients using stateless, token-based verification protocols.

---

## 6. Architectural Component Blueprint

### 6.1 Specification-Driven Development (SDD) Contract Specs

To maintain unblocked parallel progress across all 4 team members, the system relies on strict code-first schemas located inside the `.specify/` layer before individual module production begins:

- **Inbound Client Telemetry Schema (WebSocket):**

```json
{
  "speed": "float",
  "coordinates": { "lat": "float", "lng": "float" },
  "frame_data": "base64_encoded_string"
}
```

- **Outbound Action Command Schema (WebSocket):**

```json
{
  "threat_level": "NORMAL | WARNING | CRITICAL",
  "ui_commands": ["TRIGGER_HUD_ALERTS", "PRUNE_NON_ESSENTIAL_WIDGETS"],
  "enriched_context": "string"
}
```

### 6.2 Backend Modules (FastAPI + LangGraph + Supabase + FAISS)

- **Database Ingress Layer (`database.py`)**
  - **Purpose:** Establishes the relational persistence foundation and database client hooks.
  - **Key Actions:** Manages live database connections to Supabase, verifies backend-to-database handshakes during startup, and handles relational database queries.
- **LangGraph Core Orchestration Matrix (`agent_graph.py`)**
  - **Purpose:** Coordinates state preservation and edge routing through an internal, stateful execution graph.
  - **Key Actions:** Maintains a unified, type-safe system state structure tracking frame indicators, telemetry array elements, local vector context, and live threat categories.
  - **Node 1 (Perception Node):** Proxies the live multimedia feed into the Gemini 3.1 Flash Live orchestration layer to extract hazard arrays (e.g., opening vehicle doors, distracted pedestrians).
  - **Node 2 (Context RAG Node):** Ingests coordinates and queries the localized FAISS index to append spatial profiles, track anomalies, or fetch historical route safety metrics.
  - **Node 3 (Routing Engine Node):** Computes state transitions for interface optimization and triggers command arrays back to the HUD interface.
- **Application Engine Infrastructure (`main.py`)**
  - **Purpose:** Handles continuous real-time ingestion streams and asynchronous WebSocket pipeline orchestration.
  - **Key Actions:** Manages concurrent connections from the fleet, routes data packets through the LangGraph engine, and handles data transfers without blocking system execution threads.

### 6.3 Frontend Modules (Flutter + Next.js)

- **Flutter Interface Pipeline Shell (`main.dart`)**
  - **Purpose:** Forces high-frame landscape orientation and acts as the structural root for the hardware client application.
  - **Key Actions:** Configures hardware overlays, locks viewports to cinematic 16:9 profiles, and boots the client display loop.
- **Flutter Obsidian Glass HUD Display (`hud_viewport.dart`)**
  - **Purpose:** Controls responsive layout layers, glass-morphism opacity configurations, and visual event feedback widgets.
  - **Key Actions:** Renders the dynamic visual indicators of the Argus Ring, scales custom telemetry trackers based on speed inputs, and monitors connection status.
- **Next.js Fleet Command Hub Portal**
  - **Purpose:** Renders the web views for administrative oversight and tracking controls.
  - **Key Actions:** Connects to real-time database listener channels to refresh mapping visualizers instantly whenever coordinates update in the data layer.

---

## 7. Software Design & Analysis (SDA) Compliance Matrix

To satisfy academic evaluation guidelines, the project components map directly to the following software design primitives:

- **Layered (N-Tier) Architectural Style:** Complete separation between layout presentation routines (Flutter/Next.js), application logic loops (FastAPI/LangGraph), and data layers (Supabase/FAISS).
- **Event-Driven Architecture (EDA) & The Observer Pattern:** System critical events (e.g., hazard warnings from Gemini) broadcast state alterations immediately to tracking platforms. The Admin Dashboard functions as an Observer object subscribing directly to real-time changes in Supabase to refresh information instantly.
- **State Machine Management:** The operational life-cycle of the HUD mobile interface is bounded by an explicit state machine transitioning predictably across distinct modes: `Standby → Sentry_Active → Hazard_Alert → Navigation`.
- **Activity Modeling ("Safety Pulse"):** Tracks the highly deterministic, time-critical lifecycle of a single camera frame from capture to evaluation and user warning:

\[
\text{Camera Frame Capture (Flutter)} \longrightarrow \text{Asynchronous Ingress (FastAPI)} \longrightarrow \text{Multimodal Inference (Gemini Live)} \longrightarrow \text{HUD Overlay Action}
\]

- **Sequence Design:** Formally structures the duplex asynchronous structural handshake across the Multimodal WebSocket Stream to enforce strict latency limits.

---

## 8. Visual Theme Primitives: "Obsidian Void"

- **Layout:** 16:9 Landscape Orientation (Cinematic Viewports).
- **Primary Contrast Palette:**
  - **Void Black:** Hex `#000000` set to a 30% alpha opacity glass-morphism structure.
  - **Quantum Violet:** Neon-inspired system gradients used exclusively to track data focus and system active tracking indicators.
  - **Clean Data White:** High-contrast, sharp typography optimized for high-speed legibility.
