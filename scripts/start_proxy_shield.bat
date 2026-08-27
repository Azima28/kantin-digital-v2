@echo off
title Antigravity Claude Proxy Shield
echo ========================================================
echo   ANTIGRAVITY CLAUDE PROXY SHIELD (AUTO-HEALING DAEMON)
echo ========================================================
echo.
echo Menjalankan watchdog pemantau proxy di latar belakang...
powershell -ExecutionPolicy Bypass -File "%~dp0antigravity_proxy_shield.ps1"
pause
