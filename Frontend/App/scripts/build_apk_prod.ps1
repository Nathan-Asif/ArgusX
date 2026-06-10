# Build release APK for production VPS + Supabase.
# Secrets: create Frontend/App/.dart_defines.local (gitignored) OR set env vars.

$ErrorActionPreference = "Stop"
$AppRoot = Split-Path -Parent $PSScriptRoot
Set-Location $AppRoot

$definesFile = Join-Path $AppRoot ".dart_defines.local"
if (Test-Path $definesFile) {
    Get-Content $definesFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        if ($_ -match '^\s*([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
        }
    }
}

$apiUrl = $env:ARGUSX_API_URL
if (-not $apiUrl) { $apiUrl = "https://argusx-api.codemelodies.com" }

$wsUrl = $env:ARGUSX_WS_URL
if (-not $wsUrl) { $wsUrl = "wss://argusx-api.codemelodies.com/ws/pulse" }

$supabaseUrl = $env:ARGUSX_SUPABASE_URL
$supabaseAnon = $env:ARGUSX_SUPABASE_ANON_KEY
if (-not $supabaseAnon) { $supabaseAnon = $env:ARGUSX_SUPABASE_KEY }

if (-not $supabaseUrl -or -not $supabaseAnon) {
    Write-Host "ERROR: Set ARGUSX_SUPABASE_URL and ARGUSX_SUPABASE_ANON_KEY in .dart_defines.local" -ForegroundColor Red
    Write-Host "Copy .dart_defines.local.example and fill values from Supabase Dashboard > API keys." -ForegroundColor Yellow
    exit 1
}

Write-Host "Building ArgusX production APK..." -ForegroundColor Cyan
Write-Host "  API: $apiUrl"
Write-Host "  WS:  $wsUrl"
Write-Host "  Supabase: $supabaseUrl"

flutter pub get
flutter build apk --release `
  --dart-define=ARGUSX_API_URL=$apiUrl `
  --dart-define=ARGUSX_WS_URL=$wsUrl `
  --dart-define=ARGUSX_SUPABASE_URL=$supabaseUrl `
  --dart-define=ARGUSX_SUPABASE_ANON_KEY=$supabaseAnon

$apk = Join-Path $AppRoot "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Write-Host ""
    Write-Host "APK ready:" -ForegroundColor Green
    Write-Host "  $apk"
} else {
    Write-Host "Build finished but APK not found at expected path." -ForegroundColor Yellow
    exit 1
}
