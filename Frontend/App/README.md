# ArgusX Flutter HUD (`Frontend/App`)

16:9 landscape Heads-Up Display client for the ArgusX Safety Pulse stream.

## Run

```bash
cd Frontend/App
flutter pub get
flutter run
```

## Backend connection

Defaults to `ws://127.0.0.1:8000/ws/pulse`. Override with `--dart-define`:

```bash
flutter run \
  --dart-define=ARGUSX_WS_URL=ws://192.168.1.10:8000/ws/pulse \
  --dart-define=ARGUSX_API_URL=http://192.168.1.10:8000
```

See `.env.example` for the variable names. Start the backend first:

```bash
cd Backend
uv run uvicorn argusx_main:app --reload
```
