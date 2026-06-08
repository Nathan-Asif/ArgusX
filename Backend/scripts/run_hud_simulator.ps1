# Launch ArgusX Pygame + OpenCV HUD simulator.
# Requires FastAPI running on port 8000 (.\start_servers.ps1).

$ErrorActionPreference = "Stop"
$BackendRoot = Split-Path -Parent $PSScriptRoot
Set-Location $BackendRoot

Write-Host "Starting ArgusX HUD simulator (Google Maps + Safety Pulse)..." -ForegroundColor Cyan
Write-Host "Ensure .\start_servers.ps1 is running and ARGUSX_GOOGLE_MAPS_API_KEY is set." -ForegroundColor Yellow
Write-Host "In the simulator: press D to start Nazimabad -> Saddar Google navigation." -ForegroundColor Yellow
uv run python scripts/argusx_hud_simulator.py @args
