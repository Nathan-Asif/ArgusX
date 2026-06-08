# ArgusX Backend — Orchestrator

The FastAPI + LangGraph orchestration kernel for ArgusX. Every subsystem is a
self-contained class wired together by a single composition root
(`core/argusx_application.py`), so modules stay independently swappable.

## Architecture

```
argusx_main.py                 # ASGI entrypoint -> exposes `app`
core/argusx_application.py      # ArgusXApplication: composition root + lifespan
config/argusx_settings.py       # ArgusXSettings: typed env/.env configuration
database/argusx_database.py     # ArgusXDatabase: Supabase relational layer
vector_store/argusx_faiss_store.py  # ArgusXVectorStore: local FAISS index
graph/                          # LangGraph core
  argusx_state.py               #   ArgusXState: shared, type-safe state
  argusx_agent_graph.py         #   ArgusXAgentGraph: builds + compiles the graph
  nodes/                        #   one class per node (perception/RAG/routing)
api/                            # class-based routers (health + websocket + compliance proxy)
services/                       # ArgusXComplianceClient (async Java egress)
Microservices/compliance_service/  # Java SDA pattern microservice (port 8081)
```

The agent graph is the linear Safety Pulse pipeline:

```
START -> perception -> context_rag -> routing_engine -> END
```

## Setup (uv + virtual environment)

```bash
# from the Backend/ directory
uv venv                                  # create .venv
uv pip install -r requirements.txt       # install dependencies
cp .env.example .env                     # then fill in real secrets
```

## Run

```bash
uv run uvicorn argusx_main:app --reload   # dev server
# or
uv run python argusx_main.py
```

- Health check: `GET http://localhost:8000/health`
- Safety Pulse socket: `ws://localhost:8000/ws/pulse`
- Compliance menu proxy: `POST http://localhost:8000/compliance/menu-config`

### Java compliance service

```bash
cd Microservices/compliance_service
mvn spring-boot:run
```

Test the Python → Java loop:

```bash
uv run python scripts/test_compliance_dispatch.py
```

## Notes

- `database`, `vector_store`, and the Gemini model client all import their
  heavy/native dependencies lazily, so the server boots even before those are
  configured. Node bodies are stubbed (TODO markers) — the graph wiring,
  lifecycle, and contracts are complete and runnable.
