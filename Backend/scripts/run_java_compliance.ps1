# Loads Backend/.env and starts the Java compliance service.
$ErrorActionPreference = "Continue"

$BackendRoot = Split-Path $PSScriptRoot -Parent
$JavaRoot    = Join-Path $BackendRoot "Microservices\compliance_service"
$EnvFile     = Join-Path $BackendRoot ".env"

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line -match "^([^=]+)=(.*)$") {
            $name  = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "env:$name" -Value $value
        }
    }
}

if ($env:ARGUSX_DATABASE_URL -and -not $env:ARGUSX_DATABASE_ENABLED) {
    $env:ARGUSX_DATABASE_ENABLED = "true"
}

Write-Host "=== ArgusX Java Compliance Service (:8081) ===" -ForegroundColor Magenta
Write-Host "Working dir: $JavaRoot" -ForegroundColor DarkGray

if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: mvn not found in PATH. Install Maven or add it to PATH." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

if ($env:ARGUSX_DATABASE_URL) {
    Write-Host "Database URL configured (pooler)." -ForegroundColor DarkGray
}

Set-Location -LiteralPath $JavaRoot

try {
    mvn spring-boot:run
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Maven exited with code $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "Java service failed: $_" -ForegroundColor Red
}

Read-Host "Press Enter to close this window"
