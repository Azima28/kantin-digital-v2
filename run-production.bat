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

echo [3/3] Memeriksa Cloudflare Tunnel...
docker compose -f docker-compose.prod.yml ps cloudflared
echo.
echo Tunnel jalan sebagai container kantin_tunnel dengan restart otomatis,
echo jadi jendela ini TIDAK perlu dibiarkan terbuka lagi.
echo Situs publik: https://kantin.zitech.web.id
echo.
echo Cadangan, kalau perlu tunnel dari host tanpa Docker:
echo    cloudflared tunnel --config cloudflared.config.yml run

pause
