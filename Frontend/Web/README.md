# ArgusX Web Portal (`Frontend/Web`)

Next.js admin and user portals for fleet tracking, system analytics, and operator settings.

## Setup

```bash
cd Frontend/Web
npm install
cp .env.example .env.local   # adjust URLs if needed
```

## Run

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). Fleet tracking connects to the backend Safety Pulse socket configured in `.env.local`:

- `NEXT_PUBLIC_ARGUSX_API_URL` — REST base (default `http://127.0.0.1:8000`)
- `NEXT_PUBLIC_ARGUSX_WS_URL` — WebSocket pulse endpoint (default `ws://127.0.0.1:8000/ws/pulse`)

Start the backend before testing live fleet connectivity:

```bash
cd Backend
uv run uvicorn argusx_main:app --reload
```
