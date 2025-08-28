# CloudSaver Emulator Wrapper Script for Windows
# Automatically syncs saves before and after emulator execution
# Usage: .\cloudsaver-wrapper.ps1 [emulator_name] [emulator_command] [args...]

param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$EmulatorName,
    
    [Parameter(Mandatory=$true, Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$EmulatorCommand
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Version = "1.1.1"
$CliScript = Join-Path $ScriptDir "dist\cli\index.js"
$LogDir = Join-Path $env:USERPROFILE ".config\cloudsaver\logs"
$WrapperLog = Join-Path $LogDir "wrapper.log"
$LockFile = Join-Path $env:TEMP "cloudsaver-wrapper.lock"

# Ensure log directory exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Logging function
function Write-WrapperLog {
    param (
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File -Append -FilePath $WrapperLog
    
    switch ($Level) {
        "ERROR" { 
            Write-Host "[ERROR] $Message" -ForegroundColor Red 
        }
        "WARN" { 
            Write-Host "[WARN] $Message" -ForegroundColor Yellow 
        }
        "INFO" { 
            Write-Host "[INFO] $Message" -ForegroundColor Green 
        }
    }
}

# Show usage
function Show-Usage {
    Write-Host "CloudSaver Emulator Wrapper v$Version"
    Write-Host ""
    Write-Host "This script wraps emulator execution with automatic save syncing."
    Write-Host ""
    Write-Host "Usage: .\cloudsaver-wrapper.ps1 [emulator_name] [emulator_command] [args...]"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\cloudsaver-wrapper.ps1 retroarch 'C:\RetroArch\retroarch.exe'"
    Write-Host "  .\cloudsaver-wrapper.ps1 dolphin 'C:\Program Files\Dolphin\Dolphin.exe'"
    Write-Host "  .\cloudsaver-wrapper.ps1 pcsx2 'C:\Program Files\PCSX2\pcsx2.exe'"
}

# Check for node.js and required commands
function Test-Prerequisites {
    if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
        Write-WrapperLog "ERROR" "Node.js is required but not installed"
        Write-Host "Error: Node.js is required but not installed" -ForegroundColor Red
        Write-Host "Please install Node.js from https://nodejs.org/"
        exit 1
    }
    
    if (-not (Test-Path $CliScript)) {
        Write-WrapperLog "ERROR" "CloudSaver CLI script not found at $CliScript"
        Write-Host "Error: CloudSaver CLI script not found" -ForegroundColor Red
        Write-Host "Please run 'npm run build' in the CloudSaver directory"
        exit 1
    }
}

# Check prerequisites
Test-Prerequisites

# Combine emulator command and arguments
$EmulatorCmdString = $EmulatorCommand -join " "

# Lock file to prevent multiple syncs
if (Test-Path $LockFile) {
    $lockPid = Get-Content $LockFile
    try {
        $process = Get-Process -Id $lockPid -ErrorAction Stop
        Write-WrapperLog "WARN" "Another sync operation is in progress (PID: $lockPid)"
        Write-Host "Warning: Another sync operation is in progress" -ForegroundColor Yellow
        Write-Host "Continuing without syncing saves first"
        # Skip pre-sync, but still do post-sync
    }
    catch {
        # Stale lock file
        Remove-Item $LockFile -Force
        $PID | Out-File -FilePath $LockFile
        Write-WrapperLog "INFO" "Created lock file: $LockFile"
    }
}
else {
    $PID | Out-File -FilePath $LockFile
    Write-WrapperLog "INFO" "Created lock file: $LockFile"
}

# Log the wrapper execution
Write-WrapperLog "INFO" "Starting wrapper for emulator: $EmulatorName"
Write-WrapperLog "INFO" "Emulator command: $EmulatorCmdString"

# Download saves before starting emulator
Write-Host "CloudSaver: Downloading saves for $EmulatorName..." -ForegroundColor Cyan
Write-WrapperLog "INFO" "Downloading saves for $EmulatorName"
node "$CliScript" advanced-sync --emulator "$EmulatorName" --direction download

# Run the emulator
Write-Host "CloudSaver: Starting $EmulatorName..." -ForegroundColor Green
Write-WrapperLog "INFO" "Starting emulator: $EmulatorCmdString"

$process = Start-Process -FilePath "powershell" -ArgumentList "-Command", "& {$EmulatorCmdString}" -PassThru -Wait
$emulatorExitCode = $process.ExitCode
Write-WrapperLog "INFO" "Emulator exited with code: $emulatorExitCode"

# Upload saves after emulator exits
Write-Host "CloudSaver: Uploading saves for $EmulatorName..." -ForegroundColor Cyan
Write-WrapperLog "INFO" "Uploading saves for $EmulatorName"
node "$CliScript" advanced-sync --emulator "$EmulatorName" --direction upload

# Remove lock file
if (Test-Path $LockFile) {
    Remove-Item $LockFile -Force
    Write-WrapperLog "INFO" "Removed lock file: $LockFile"
}

Write-Host "CloudSaver: Sync complete!" -ForegroundColor Green
exit $emulatorExitCode
