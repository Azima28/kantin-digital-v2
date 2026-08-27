# ==============================================================================
# Antigravity Claude Proxy Shield (Auto-Healing Watchdog Daemon)
# ==============================================================================
# Script ini secara otomatis memantau health dari antigravity-claude-proxy
# Jika proxy mati atau mengalami crash, script ini langsung membangkitkannya kembali.
# ==============================================================================

$port = 8080
$proxyUrl = "http://127.0.0.1:$port"

Write-Host "🛡️ [SHIELD ACTIVE] Antigravity Claude Proxy Watchdog is running..." -ForegroundColor Cyan
Write-Host "🎯 Monitoring $proxyUrl every 2 seconds..." -ForegroundColor Gray

function Test-ProxyHealth {
    try {
        $response = Invoke-WebRequest -Uri $proxyUrl -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500)
    } catch {
        return $false
    }
}

function Start-ProxyDaemon {
    Write-Host "⚠️ Proxy is offline or unresponsive! Reviving proxy now..." -ForegroundColor Yellow
    try {
        # Jalankan restart proxy
        npx antigravity-claude-proxy@latest start
        Start-Sleep -Seconds 2
        if (Test-ProxyHealth) {
            Write-Host "✅ [SHIELD REVIVED] Antigravity Claude Proxy successfully restored on port $port!" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Error restarting proxy: $_" -ForegroundColor Red
    }
}

# Inisialisasi awal jika belum hidup
if (-not (Test-ProxyHealth)) {
    Start-ProxyDaemon
} else {
    Write-Host "✅ Proxy is currently healthy and active on port $port." -ForegroundColor Green
}

# Infinite watchdog loop
while ($true) {
    Start-Sleep -Seconds 2
    if (-not (Test-ProxyHealth)) {
        Start-ProxyDaemon
    }
}
