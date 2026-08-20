@echo off
title Kantin Digital - Production Runner
echo ========================================================
echo   KANTIN DIGITAL v2.0 - PRODUCTION DOCKER & CLOUDFLARE
echo ========================================================
echo.

echo [1/3] Menjalankan Docker Production Containers (PostgreSQL, Go Backend, Nginx Web)...
docker compose -f docker-compose.prod.yml up -d --build
if %errorlevel% neq 0 (
    echo [ERROR] Gagal menjalankan Docker. Pastikan Docker Desktop aktif.
    pause
    exit /b %errorlevel%
)

echo [2/3] Memeriksa status container...
docker compose -f docker-compose.prod.yml ps

echo [3/3] Menjalankan Cloudflare Tunnel (zitech.web.id)...
echo Tunnel ID: 7576e167-9a46-4928-8dc6-a3281abef804
cloudflared tunnel --config cloudflared.config.yml run

pause
