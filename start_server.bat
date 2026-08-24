@echo off
title Kantin Digital Backend & Database Server
color 0A

echo ====================================================
echo   KANTIN DIGITAL - SERVER STARTER (Go + PostgreSQL)
echo ====================================================
echo.

:: 1. Start PostgreSQL Engine if not running
echo [*] Memeriksa & Mengaktifkan Database PostgreSQL...
if exist "C:\laragon\bin\postgresql\pgsql\bin\pg_ctl.exe" (
    "C:\laragon\bin\postgresql\pgsql\bin\pg_ctl.exe" -D "C:\laragon\bin\postgresql\data" -l "C:\laragon\bin\postgresql\logfile.log" start >nul 2>&1
)

:: 2. Stop old backend instance if any
taskkill /F /IM api.exe >nul 2>&1
taskkill /F /IM server.exe >nul 2>&1

:: 3. Build and Start Go Backend API
echo [*] Menjalankan Go Backend API Server (Port 8000)...
cd /d "%~dp0backend"
if exist "server.exe" (
    start "Kantin Digital API (Port 8000)" "%~dp0backend\server.exe"
) else if exist "api.exe" (
    start "Kantin Digital API (Port 8000)" "%~dp0backend\api.exe"
) else (
    go build -o server.exe ./cmd/api
    start "Kantin Digital API (Port 8000)" "%~dp0backend\server.exe"
)

echo.
echo ====================================================
echo   [SUCCESS] Backend & Database Berhasil Dijalankan!
echo   API URL: http://127.0.0.1:8000
echo   WebSocket: ws://127.0.0.1:8000/ws
echo ====================================================
echo.
timeout /t 3 >nul
exit
