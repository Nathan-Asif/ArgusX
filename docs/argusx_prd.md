# ArgusX – System Engineering Blueprint & Implementation Canvas
* **System Version:** 1.1
* **Architecture Style:** Decoupled N-Tier, Hybrid Microservices & Event-Driven Graph
* **Development Methodology:** Specification-Driven Development (SDD) via GitHub Spec-Kit
* **Target Environment:** Python 3.11+ (FastAPI) | Java 17+ (Spring Boot / Core Microservice) | Flutter (Dart 3.x) | Supabase PostgreSQL

---

## 1. System Topology Canvas

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
|                       ▼                                           ▼                     |
|   +---------------------------------------------------------------------------------+   |
|   |               FASTAPI APPLICATION LAYER & CORE AGENT KERNEL                     |   |
|   |  - High-Concurrency Asynchronous Streaming Handlers                             |   |
|   |  - LangGraph 3-Agent Pipeline (Perception → Context RAG → Routing Engine)       |   |
|   +-------------------+-------------------------------------------------------------+   |
+-----------------------|-----------------------------------------------------------------+
                        | Asynchronous Event Egress (REST HTTP POST)
                        ▼
+-----------------------------------------------------------------------------------------+
|                     JAVA COMPLIANCE & AUDITING MICROSERVICE LAYER                       |
|  - Concrete Implementation Layer for Target SDA Design Patterns                          |
|  - Singleton Database Ingress | Threat Factory | Safety Report Builder Engine           |
+-----------------------+-------------------------------------------+---------------------+
                        | SQL Connection Pooling                    | Local Vector Queries
                        ▼                                           ▼
+-----------------------+-------------------------------------------+---------------------+
|                                           DATA LAYER                                    |
|                                                                                         |
|         +------------------------------------+   +--------------------------------+     |
|         |    SUPABASE (POSTGRESQL MATRIX)    |   |    LOCAL VECTOR STORAGE        |     |
|         |  - Relational Schemas & Indexing   |   |  - FAISS Vector Embeddings     |     |
|         |  - JWT Stateless Session Auth      |   |  - Low-Latency Context Cache   |     |
|         +------------------------------------+   +--------------------------------+     |
+-----------------------------------------------------------------------------------------+

---

## 2. Project File Structure Architecture

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
│   │   └── 02_java_compliance_service.md
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
│   ├── Microservices/             # Isolated sub-services layer
│   │   └── compliance_service/    # Java Compliance Engine (Executes Academic SDA Labs)
│   │       ├── src/main/java/com/argusx/compliance/
│   │       │   ├── config/        # Singleton Database Connection Pooling (Lab 2)
│   │       │   ├── factory/       # Threat Incident Factory Matrix (Lab 3)
│   │       │   ├── builder/       # Audit Safety Report Builder Engine (Lab 4)
│   │       │   ├── composite/     # Menu Configuration Component Tree (Lab 6)
│   │       │   ├── model/         # Context Fallbacks & Null Objects (Lab 8)
│   │       │   ├── mediator/      # Inner Service Message Coordination (Lab 9)
│   │       │   └── ComplianceApplication.java
│   │       └── pom.xml            # Maven dependency management
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
    └── Web/                       # Next.js admin & user web portal
        ├── app/
        │   ├── admin/
        │   │   └── fleet-tracking/
        │   ├── user/
        │   │   └── analytics/
        │   └── layout.tsx
        ├── package.json
        └── tailwind.config.js


---

## 3. Executive Summary & Project Vision
ArgusX is a distributed, real-time "Guardentic" vision system engineered to dramatically elevate situational awareness for vehicle operators, initially prototyped for motorcycle helmets[cite: 5]. Operating as a split hybrid-cloud system, ArgusX utilizes a multimodal AI core to interpret live environmental data and deliver proactive safety interventions through a specialized 16:9 landscape Heads-Up Display (HUD)[cite: 6]. 

Beyond individual rider assistance, the project addresses ecosystem-level management by incorporating a highly concurrent processing center, a dedicated Java compliance layer, and a Tesla-inspired fleet management portal for real-time monitoring and administrative oversight[cite: 7].

---

## 4. Team Structure & Component Ownership
The project is executed by a 4-member engineering team distributed across specialized frontend and backend modules to enforce a clean separation of concerns:

* **Lead Engineer (You):**
    * Project baseline foundation initialization, backend integration setup, and Python/Java interaction loop.
    * Core graph-based multi-agent layout architecture design using LangGraph.
    * Independent development of agentic graph nodes and local FAISS RAG operations.
* **Backend & Mobile Support Engineer (4th Member):**
    * Implementing stateless token-based authentication pipelines (JWT) across web, mobile, and Java microservice spaces[cite: 16, 21].
    * Developing core components within the Java Compliance Microservice to align explicitly with academic SDA lab patterns.
    * Cross-supporting the frontend team with Flutter interface execution hooks.
* **Frontend Design & Development Team (2 Members):**
    * Prototyping and rendering the responsive 16:9 landscape glass-morphic HUD in Flutter[cite: 13, 40].
    * Constructing interactive administrative web interfaces (Fleet Tracking) and user portals via Next.js[cite: 11, 12, 20].
    * Handling high-concurrency video frame capturing, client-side camera pipelines, and telemetry ingestion loops.

---

## 5. Core Features & Functional Requirements

### 5.1 HUD & Operator Experience (Mobile Client)
* **16:9 Obsidian Void HUD:** A cinematic, landscape-oriented mobile application interface designed with a 30% opacity glass-morphism overlay[cite: 13, 40]. It presents critical safety parameters and navigational data transparently, keeping the rider's field of view completely unobstructed.
* **The Argus Ring:** A central, pulsing digital iris serving as the visual anchor[cite: 42]. The ring dynamically shifts its neon color profiles (utilizing Quantum Violet gradients) depending on system health metrics and external threat levels[cite: 40, 42].
* **Passive Sentry Vision:** Continuous, non-blocking real-time analysis of the surrounding road environment to proactively isolate and highlight immediate hazards, such as opening vehicle doors or distracted pedestrians[cite: 9].
* **Spatial Grounding & Pinning:** Real-world points of interest (POIs) are discovered through camera streams and "pinned" stereoscopically with 3D holographic data bubbles displaying live contextual data[cite: 14].
* **Autonomous UI Navigation:** A context-aware state machine that dynamically manages UI clutter[cite: 15, 35]. The interface hides non-essential widgets during high-speed travel and broadens critical telemetry/navigation overlays during complex maneuvers[cite: 15].

### 5.2 LangGraph Multi-Agent Pipeline (3 Agents)

Each Safety Pulse telemetry frame from the mobile client is processed through a **linear LangGraph state machine** (`Backend/graph/argusx_agent_graph.py`). All agents share a typed `ArgusXState` object and run in this order:

```
START → perception → context_rag → routing_engine → END
```

| # | Agent | Node ID | Implementation | Responsibility | Primary outputs |
|---|-------|---------|----------------|----------------|-----------------|
| **1** | **Perception Agent** | `perception` | `graph/nodes/argusx_perception.py` | Spatial awareness — analyses live camera frames (base64 JPEG) or demo `fixture:*` tokens using **Gemini Flash**; extracts hazards (pedestrians, opening doors, cross-traffic, etc.) | `hazards[]`, `perception_source` |
| **2** | **Context RAG Agent** | `context_rag` | `graph/nodes/argusx_context_rag.py` | Retrieval-augmented grounding — queries the local **FAISS** vector index for nearby high-risk spatial zones; builds `enriched_context` from GPS, destination, route step, and hazards; emits pinned POIs (skipped for SF demo zones when Google Maps navigation is active) | `spatial_context[]`, `enriched_context`, `pinned_pois[]` |
| **3** | **Routing Engine Agent** | `routing_engine` | `graph/nodes/argusx_routing_engine.py` | Decision & HUD orchestration — computes `threat_level` (NORMAL/WARNING/CRITICAL), selects `hud_mode`, produces turn-by-turn `navigation` (arrow, instruction, `voice_prompt`), and issues `ui_commands` (e.g. `SHOW_ROUTE_MAP`, `TRIGGER_HUD_ALERTS`) | `threat_level`, `hud_mode`, `navigation`, `ui_commands` |

**Compliance hand-off:** When the Routing Engine sets `threat_level` to `WARNING` or `CRITICAL`, the FastAPI orchestrator asynchronously POSTs a threat event to the **Java Compliance Microservice** for audit logging (SDA patterns: Mediator, Factory, Builder, Observer).

**WebSocket contract:** Inbound pulse carries `speed`, `coordinates`, `frame_data`, `session_id`, `rider_id`, `destination`, `route_context`; outbound response returns agent outputs above plus `route_visualization` and `hazards` for the Flutter HUD overlays.

### 5.3 Orchestration & Administrative Ecosystem (Server & Web)
* **Centralized Sentry Orchestration:** A highly concurrent, Python-based backend hub that coordinates streaming data flows, handles stateless protocols, and routes agentic reasoning requests between active mobile clients and cloud intelligence layers[cite: 10].
* **Java Compliance & Auditing Service:** A reliable microservice that intercepts validated threat flags to calculate compliance records, manage historical data packages, and process records using formal software design methodologies.
* **Tesla-Style Fleet Tracking:** An administrative command dashboard supplying real-time global visualizations of all active users, detailing precise location data, active connectivity status, and streaming safety telemetry[cite: 11].
* **Universal User Portal:** A web interface tailored for secure user onboarding, system profile configurations, and historical ride telemetry/safety analytics[cite: 12].

---

## 6. Software Design & Analysis (SDA) Compliance Matrix
To satisfy academic evaluation guidelines, the project explicitly instantiates the following patterns within the **Java Microservice Architecture Layer**:

* **Layered (N-Tier) Architectural Style:** Complete separation between layout presentation routines (Flutter/Next.js), application logic loops (FastAPI/LangGraph), and specialized backend audit microservices (Java) connected to database architectures[cite: 28].
* **Singleton Pattern (Lab 2):** Enforces a singular, centralized connection state lifecycle tracking transactions targeting the remote database to prevent thread pooling leaks.
* **Factory Pattern (Lab 3):** Instantiates structural event payloads based on runtime classifications (`CRITICAL`, `WARNING`, `INFO`) forwarded by the agent logic layer.
* **Builder Pattern (Lab 4):** Constructs unified safety report objects step-by-step, appending tracking coordinates and telemetry snapshots before database ingestion.
* **Composite Pattern (Lab 6):** Uniformly maps hierarchical menu parameters and multi-tier system settings using an intuitive branch-and-leaf layout engine.
* **Null Object Pattern (Lab 8):** Injects predictable "do-nothing" behavior models when an incident report passes corrupt or null coordinate properties, preventing application runtime crashes.
* **Mediator & Observer Patterns (Lab 9):** The microservice employs an internal event mediator to decouple system routines, while the web interface uses active listeners to capture data modifications automatically[cite: 30, 32].

---

## 7. Visual Theme Primitives: "Obsidian Void"
* **Layout:** 16:9 Landscape Orientation (Cinematic Viewports)[cite: 39].
* **Primary Contrast Palette:**
    * **Void Black:** Hex #000000 set to a 30% alpha opacity glass-morphism structure[cite: 40].
    * **Quantum Violet:** Neon-inspired system gradients used exclusively to track data focus and system active tracking indicators[cite: 40].
    * **Clean Data White:** High-contrast, sharp typography optimized for high-speed legibility[cite: 41].