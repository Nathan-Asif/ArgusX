@echo off
REM Start ArgusX backend servers from project root
cd /d "%~dp0Backend"
call start_servers.bat
