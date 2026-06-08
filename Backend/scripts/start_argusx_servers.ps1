# Starts ArgusX Java compliance service + Python FastAPI orchestrator in separate windows.
#
# From scripts folder:  .\start_argusx_servers.ps1
# From Backend folder:  .\start_servers.ps1  or  start_servers.bat

$ErrorActionPreference = "Stop"

$BackendRoot  = Split-Path $PSScriptRoot -Parent
$JavaRoot     = Join-Path $BackendRoot "Microservices\compliance_service"
$JavaLauncher = Join-Path $PSScriptRoot "run_java_compliance.ps1"

function Test-PortListening([int]$Port) {
    $found = netstat -ano | Select-String ":$Port\s" | Select-String "LISTENING"
    return [bool]$found
}

Write-Host "ArgusX - starting backend servers..." -ForegroundColor Cyan
Write-Host "  Backend: $BackendRoot"
Write-Host "  Java:    $JavaRoot"
Write-Host ""

# Free ports from previous runs (fixes "Port 8081 was already in use")
$StopScript = Join-Path $PSScriptRoot "stop_argusx_servers.ps1"
if (Test-Path $StopScript) {
    Write-Host "Clearing ports 8081 and 8000 from any previous run..." -ForegroundColor DarkGray
    & $StopScript
}

# Java compliance service (port 8081)
# Use ExecutionPolicy Bypass + quoted path (required for paths with spaces)
$javaArgs = "-NoExit -ExecutionPolicy Bypass -File `"$JavaLauncher`""
Start-Process -FilePath "powershell.exe" -ArgumentList $javaArgs -WindowStyle Normal

Write-Host "Waiting for Java on :8081 (up to 45s)..." -ForegroundColor Yellow
$javaReady = $false
for ($i = 0; $i -lt 45; $i++) {
    if (Test-PortListening -Port 8081) {
        $javaReady = $true
        break
    }
    Start-Sleep -Seconds 1
}

if ($javaReady) {
    Write-Host "Java compliance service is up on :8081" -ForegroundColor Green
} else {
    Write-Host "WARNING: Java did not start on :8081 yet." -ForegroundColor Red
    Write-Host "  Check the other PowerShell window titled Java for Maven errors." -ForegroundColor Red
    Write-Host "  Or run manually: .\scripts\run_java_compliance.ps1" -ForegroundColor Yellow
}

# Python FastAPI orchestrator (port 8000)
$fastApiArgs = "-NoExit -ExecutionPolicy Bypass -Command ""Set-Location -LiteralPath '$BackendRoot'; Write-Host '=== ArgusX FastAPI Orchestrator (:8000) ===' -ForegroundColor Green; uv run uvicorn argusx_main:app --reload --host 0.0.0.0 --port 8000"""
Start-Process -FilePath "powershell.exe" -ArgumentList $fastApiArgs -WindowStyle Normal

Write-Host ""
Write-Host "Server windows launched." -ForegroundColor Green
Write-Host "  FastAPI:  http://127.0.0.1:8000/health"
Write-Host "  Java:     http://127.0.0.1:8081/api/compliance/health"
Write-Host "  API docs: http://127.0.0.1:8000/docs"
Write-Host ""
Write-Host "Run tests in a third terminal:" -ForegroundColor Cyan
Write-Host ('  cd ' + $BackendRoot)
Write-Host '  uv run python scripts/test_compliance_dispatch.py'
