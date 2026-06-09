#!/usr/bin/env bash
# Post-deploy: FastAPI via uvicorn under systemd (Apache proxies :8025).
set -euo pipefail

APP_DIR="${1:-/var/www/html/argusx-api.codemelodies.com}"
cd "$APP_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required on the VPS."
  exit 1
fi

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install -U pip -q
pip install -r requirements.txt -q

if [ ! -f .env ]; then
  echo "WARNING: $APP_DIR/.env is missing. Copy from .env.example and fill secrets before production use."
fi

if command -v sudo >/dev/null 2>&1 && systemctl list-unit-files | grep -q '^argusx-api.service'; then
  sudo systemctl restart argusx-api
  sudo systemctl status argusx-api --no-pager || true
else
  echo "systemd unit argusx-api not installed yet. See deploy/systemd/argusx-api.service"
fi

if command -v sudo >/dev/null 2>&1 && sudo apache2ctl configtest >/dev/null 2>&1; then
  sudo apache2ctl configtest && sudo systemctl reload apache2 || true
fi
