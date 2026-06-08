# Stops processes listening on ArgusX ports 8000 (FastAPI) and 8081 (Java).
# Usage: .\scripts\stop_argusx_servers.ps1

function Stop-PortListener([int]$Port) {
    $lines = netstat -ano | Select-String ":$Port\s" | Select-String "LISTENING"
    foreach ($line in $lines) {
        $processId = ($line -split '\s+')[-1]
        if ($processId -match '^\d+$') {
            Write-Host "Stopping PID $processId on port $Port..."
            taskkill /PID $processId /F 2>$null
        }
    }
}

Write-Host "Stopping ArgusX servers..." -ForegroundColor Yellow
Stop-PortListener -Port 8081
Stop-PortListener -Port 8000
Start-Sleep -Seconds 2
Write-Host "Done." -ForegroundColor Green
