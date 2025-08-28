# CloudSaver Sync Script for Windows
# This script makes it easier to run CloudSaver sync commands

param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("upload", "download", "bidirectional")]
    [string]$Direction = "bidirectional",

    [Parameter(Mandatory=$false)]
    [string]$Emulator = "",

    [Parameter(Mandatory=$false)]
    [switch]$Help
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$cliPath = Join-Path $scriptPath "dist\cli\index.js"

function Show-Help {
    Write-Host "CloudSaver Sync Script"
    Write-Host "======================"
    Write-Host ""
    Write-Host "Usage: .\run-sync.ps1 [-Direction <upload|download|bidirectional>] [-Emulator <emulator>] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Direction      : Sync direction (upload, download, or bidirectional). Default is bidirectional."
    Write-Host "  -Emulator       : Specific emulator to sync. If not specified, syncs all detected emulators."
    Write-Host "  -Help           : Show this help message."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\run-sync.ps1                            # Sync all emulators bidirectionally"
    Write-Host "  .\run-sync.ps1 -Direction upload          # Upload all emulator saves to cloud"
    Write-Host "  .\run-sync.ps1 -Direction download -Emulator retroarch  # Download only RetroArch saves"
    exit
}

if ($Help) {
    Show-Help
}

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "Using Node.js $nodeVersion"
} catch {
    Write-Host "Error: Node.js is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Check if the CLI path exists
if (-not (Test-Path $cliPath)) {
    Write-Host "Error: CloudSaver CLI not found at $cliPath" -ForegroundColor Red
    Write-Host "Make sure you have built the project with 'npm run build'" -ForegroundColor Red
    exit 1
}

# Build the command
$command = "node `"$cliPath`" advanced-sync --direction $Direction"
if ($Emulator) {
    $command += " --emulator $Emulator"
}

# Run the command
Write-Host "Running: $command" -ForegroundColor Cyan
Invoke-Expression $command
