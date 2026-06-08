@echo off
REM Starts ArgusX Java + FastAPI servers in separate PowerShell windows.
REM Double-click this file or run: scripts\start_argusx_servers.bat

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_argusx_servers.ps1"
pause
