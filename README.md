<div align="center">

# ArgusX

### Guardentic Vision System for Real-Time Rider Safety

*A distributed, edge-cloud AI co-pilot that turns a motorcycle helmet into a situational-awareness HUD.*

[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Orchestrator-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![LangGraph](https://img.shields.io/badge/LangGraph-Agent%20Kernel-1C3C3C)](https://langchain-ai.github.io/langgraph/)
[![Flutter](https://img.shields.io/badge/Flutter-HUD%20Client-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Next.js](https://img.shields.io/badge/Next.js-Web%20Portal-000000?logo=nextdotjs&logoColor=white)](https://nextjs.org/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Status](https://img.shields.io/badge/Status-In%20Development-yellow)](#roadmap)

</div>

---

## Overview

**ArgusX** is a real-time *"Guardentic"* vision system engineered to dramatically elevate situational awareness for vehicle operators, initially prototyped for **motorcycle helmets**. Operating as a split **edge-cloud** system, it uses a multimodal AI core to interpret live environmental data and deliver **proactive safety interventions** through a cinematic 16:9 landscape Heads-Up Display (HUD).

Beyond individual rider assistance, ArgusX scales to ecosystem-level management with a centralized orchestration server and a Tesla-inspired **fleet management portal** for real-time monitoring, data aggregation, and administrative oversight.

> The backend is a class-based **FastAPI + LangGraph** orchestrator: each subsystem (config, database, vector store, agent graph, routers) is an independently swappable class wired together by a single composition root.

---

## Table of Contents

- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Surface](#api-surface)
- [Agent Graph](#agent-graph)
- [Team](#team)
- [Roadmap](#roadmap)

---

## Key Features

### HUD & Operator Experience (Mobile)
- **16:9 Obsidian Void HUD** — cinematic, landscape interface with a 30% glass-morphism overlay that keeps the rider's field of view unobstructed.
- **The Argus Ring** — a central pulsing digital iris that shifts neon color profiles based on system health and threat level.
- **Passive Sentry Vision** — continuous, non-blocking analysis that isolates hazards like opening vehicle doors or distracted pedestrians.
- **Spatial Grounding & Pinning** — real-world POIs pinned stereoscopically with 3D holographic data bubbles.
- **Autonomous UI Navigation** — a context-aware state machine that declutters at speed and expands telemetry during complex maneuvers.

### Orchestration & Administrative Ecosystem (Server & Web)
- **Centralized Sentry Orchestration** — highly concurrent Python hub coordinating streaming data and agentic reasoning.
- **Tesla-Style Fleet Tracking** — live global visualization of active users, location, connectivity, and safety telemetry.
- **Universal User Portal** — secure onboarding, profile config, and historical ride analytics.
- **Agentic Authentication** — stateless, token-based (JWT) auth across mobile and web.

---

## System Architecture

```
+-----------------------------------------------------------------------+
|                          PRESENTATION LAYER                           |
|   Flutter Mobile Client (HUD)        Next.js Web Portals (Admin/User) |
+----------------------|------------------------------|-----------------+
                       | Bi-Directional WebSockets     | REST / DB Listeners
+----------------------v------------------------------v-----------------+
|              FASTAPI APPLICATION LAYER & AGENT KERNEL                  |
|   LangGraph State Matrix:                                             |
|     Perception  ->  Context RAG  ->  Routing Engine                  |
+----------------------|------------------------------|-----------------+
        | Relational DB Pipeline           | Local Vector Queries
+-------v------------------------------+---v-----------------------------+
|                              DATA LAYER                                |
|   Supabase (PostgreSQL)              Local FAISS Vector Store         |
+-----------------------------------------------------------------------+
```

A three-tier, event-driven design: **Presentation** (Flutter / Next.js) -> **Application** (FastAPI / LangGraph) -> **Data** (Supabase / FAISS).

---

## Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile HUD | Flutter (Dart 3.x) |
| Web Portals | Next.js, Tailwind CSS |
| Backend / API | Python 3.11+, FastAPI, Uvicorn |
| Agent Kernel | LangGraph, LangChain Core |
| Multimodal AI | Gemini Live (multimodal inference) |
| Database | Supabase (PostgreSQL), JWT auth |
| Vector Store | FAISS (local, low-latency RAG) |
| Tooling | uv (env & packaging), Spec-Kit (SDD) |

---

## Project Structure

```
ArgusX/
├── .specify/          # Specification-Driven Development (specs, plans, tasks)
├── Backend/           # FastAPI + LangGraph orchestrator (class-based, argusx_ prefix)
│   ├── argusx_main.py     # ASGI entrypoint
│   ├── core/              # ArgusXApplication composition root + lifespan
│   ├── config/            # Typed settings (.env)
│   ├── database/          # Supabase relational layer
│   ├── vector_store/      # Local FAISS index
│   ├── graph/             # LangGraph state, agent graph, nodes
│   └── api/               # Health + WebSocket routers
├── Frontend/
│   ├── App/           # Flutter mobile HUD client
│   └── Web/           # Next.js admin & user web portal
└── docs/
    └── prd.md         # Product Requirements & System Blueprint
```

---

## Getting Started

### Prerequisites
- [Python 3.11+](https://www.python.org/)
- [uv](https://docs.astral.sh/uv/) (virtual environment & package manager)

### Backend

```bash
cd Backend

# Create the virtual environment and install dependencies
uv venv
uv pip install -r requirements.txt

# Configure environment
cp .env.example .env        # then fill in your secrets

# Run the orchestrator
uv run uvicorn argusx_main:app --reload
```

The server starts on `http://localhost:8000`. Interactive API docs are available at `http://localhost:8000/docs`.

> Frontend (`Frontend/App` and `Frontend/Web`) is currently scaffolded as placeholders and will be implemented in a later phase.

---

## API Surface

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/health` | Service + subsystem (database, vector store) health |
| `WS` | `/ws/pulse` | Real-time Safety Pulse telemetry stream |
| `GET` | `/docs` | Interactive Swagger UI |

**Inbound telemetry (WebSocket):**

```json
{
  "speed": "float",
  "coordinates": { "lat": "float", "lng": "float" },
  "frame_data": "base64_encoded_string"
}
```

**Outbound action command (WebSocket):**

```json
{
  "threat_level": "NORMAL | WARNING | CRITICAL",
  "ui_commands": ["TRIGGER_HUD_ALERTS", "PRUNE_NON_ESSENTIAL_WIDGETS"],
  "enriched_context": "string"
}
```

---

## Agent Graph

Each inbound frame flows through a compiled LangGraph pipeline:

```
START -> perception -> context_rag -> routing_engine -> END
```

| Node | Responsibility |
| --- | --- |
| **Perception** | Proxies the live feed into Gemini Live to extract a hazard array. |
| **Context RAG** | Queries the local FAISS index for spatial profiles & route-safety metrics. |
| **Routing Engine** | Computes the threat level and emits UI command arrays to the HUD. |

---

## Team

| Role | Responsibilities |
| --- | --- |
| **Lead Engineer** | Backend foundation, database integration, LangGraph multi-agent architecture, FAISS RAG. |
| **Backend & Mobile Support** | JWT auth pipelines, auxiliary routes, Flutter integration support. |
| **Frontend Design & Dev (x2)** | 16:9 glass-morphic HUD, Next.js fleet/user portals, camera & telemetry pipelines. |

---

## Roadmap

- [x] Class-based FastAPI + LangGraph backend foundation
- [x] Compiled agent graph (Perception -> Context RAG -> Routing Engine)
- [ ] Gemini Live multimodal perception integration
- [ ] FAISS embedding ingestion & spatial RAG
- [ ] Supabase auth & relational schemas
- [ ] Flutter Obsidian Void HUD
- [ ] Next.js fleet tracking & analytics portals

---

<div align="center">

Built as a Software Design & Analysis (SDA) semester project.

</div>
