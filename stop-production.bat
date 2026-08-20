@echo off
title Kantin Digital - Stop Production
echo ========================================================
echo   MENGHENTIKAN PRODUCTION DOCKER & CLOUDFLARE TUNNEL
echo ========================================================
echo.

echo Menghentikan Docker Containers...
docker compose -f docker-compose.prod.yml down

echo Menghentikan proses cloudflared...
taskkill /F /IM cloudflared.exe >nul 2>&1

echo Selesai. Seluruh layanan produksi telah dimatikan.
pause
