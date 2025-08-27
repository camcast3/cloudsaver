# Clean up homelab after EmuDeck migration

Write-Host "🧹 Cleaning up EmuDeck files from homelab..." -ForegroundColor Blue

$filesToRemove = @(
    "emudeck-*.sh",
    "install.sh",
    "run-all-tests.sh", 
    "test-suite.sh",
    "setup-tests.ps1",
    "Run-Tests.ps1",
    "check-bazzite-environment.sh",
    "test-real-emulators.sh",
    "transfer-config.sh",
    "*DEPLOYMENT*.md",
    "README-EmuDeck-Sync.md",
    "MIGRATION-GUIDE.md",
    "migrate-emudeck.ps1"
)

foreach ($pattern in $filesToRemove) {
    $files = Get-ChildItem $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        Remove-Item $file.FullName -Force
        Write-Host "  ❌ Removed: $($file.Name)" -ForegroundColor Red
    }
}

# Remove tests directory
if (Test-Path "tests") {
    Remove-Item "tests" -Recurse -Force
    Write-Host "  ❌ Removed: tests/ directory" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Cleanup complete! EmuDeck files removed from homelab." -ForegroundColor Green
Write-Host "Your homelab repository is now clean and focused on Docker services." -ForegroundColor Green
