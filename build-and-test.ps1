# Quick build and test script for CloudSaver on Windows

$ErrorActionPreference = "Stop"  # Exit on any error

Write-Host "📦 Building CloudSaver..." -ForegroundColor Cyan
npm run build

Write-Host "🧪 Running basic tests..." -ForegroundColor Cyan
npm test

Write-Host "✨ Testing emulator detection..." -ForegroundColor Cyan
node dist/cli/index.js detect

Write-Host "🔍 Getting current configuration..." -ForegroundColor Cyan
node dist/cli/index.js config get

Write-Host ""
Write-Host "✅ Build and test complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Configure a cloud provider: node dist/cli/index.js config set cloudProvider <your-provider>"
Write-Host "  2. Run a sync: node dist/cli/index.js advanced-sync"
Write-Host "  3. Try a wrapper script: .\cloudsaver-wrapper.ps1 <emulator> <emulator-command>"
Write-Host ""
