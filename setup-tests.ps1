# PowerShell script to set up EmuDeck Sync test environment on Windows

Write-Host "EmuDeck Save Sync - Test Suite Setup" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = $ScriptDir

Write-Host "Setting up test environment..." -ForegroundColor Cyan

# Check if WSL is available
$WSLAvailable = $false
try {
    $wslVersion = wsl --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $WSLAvailable = $true
        Write-Host "✅ WSL detected and available" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ WSL not available" -ForegroundColor Red
}

# Check for Git Bash
$GitBashAvailable = $false
$GitBashPath = ""
$PossibleGitBashPaths = @(
    "${env:ProgramFiles}\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "${env:LOCALAPPDATA}\Programs\Git\bin\bash.exe"
)

foreach ($Path in $PossibleGitBashPaths) {
    if (Test-Path $Path) {
        $GitBashAvailable = $true
        $GitBashPath = $Path
        Write-Host "✅ Git Bash found at: $GitBashPath" -ForegroundColor Green
        break
    }
}

if (-not $GitBashAvailable) {
    Write-Host "❌ Git Bash not found" -ForegroundColor Red
}

# Display options
Write-Host ""
Write-Host "Test Execution Options:" -ForegroundColor Yellow
Write-Host ""

if ($WSLAvailable) {
    Write-Host "1. Run tests in WSL (Recommended)" -ForegroundColor Green
    Write-Host "   wsl -- bash ./run-all-tests.sh"
    Write-Host ""
}

if ($GitBashAvailable) {
    Write-Host "2. Run tests with Git Bash" -ForegroundColor Green
    Write-Host "   `"$GitBashPath`" ./run-all-tests.sh"
    Write-Host ""
}

Write-Host "3. Manual setup for Linux environment" -ForegroundColor Green
Write-Host "   Copy files to a Linux system and run:"
Write-Host "   chmod +x *.sh tests/*.sh"
Write-Host "   ./run-all-tests.sh"
Write-Host ""

# Create batch files for easy execution
Write-Host "Creating Windows batch files..." -ForegroundColor Cyan

# Create main test runner batch file
if ($WSLAvailable) {
    $BatchContent = @"
@echo off
cd /d "%~dp0"
echo Running EmuDeck Save Sync Tests in WSL...
wsl -- bash ./run-all-tests.sh %*
pause
"@
    $BatchContent | Out-File -FilePath "$ProjectRoot\run-tests.bat" -Encoding ASCII
    Write-Host "✅ Created run-tests.bat (WSL)" -ForegroundColor Green
}

if ($GitBashAvailable) {
    $GitBashContent = @"
@echo off
cd /d "%~dp0"
echo Running EmuDeck Save Sync Tests with Git Bash...
"$GitBashPath" ./run-all-tests.sh %*
pause
"@
    $GitBashContent | Out-File -FilePath "$ProjectRoot\run-tests-gitbash.bat" -Encoding ASCII
    Write-Host "✅ Created run-tests-gitbash.bat (Git Bash)" -ForegroundColor Green
}

# Create individual test suite runners
$TestSuites = @(
    @{Name="Unit"; Script="tests/unit-tests.sh"; Description="Unit Tests"},
    @{Name="Integration"; Script="tests/integration-tests.sh"; Description="Integration Tests"},
    @{Name="Performance"; Script="tests/performance-tests.sh"; Description="Performance Tests"},
    @{Name="Security"; Script="tests/security-tests.sh"; Description="Security Tests"},
    @{Name="Main"; Script="test-suite.sh"; Description="Main Test Suite"}
)

foreach ($Suite in $TestSuites) {
    if ($WSLAvailable) {
        $SuiteBatchContent = @"
@echo off
cd /d "%~dp0"
echo Running $($Suite.Description) in WSL...
wsl -- bash ./$($Suite.Script)
pause
"@
        $SuiteBatchContent | Out-File -FilePath "$ProjectRoot\run-$($Suite.Name.ToLower())-tests.bat" -Encoding ASCII
    }
}

if ($WSLAvailable -or $GitBashAvailable) {
    Write-Host "✅ Batch files created successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor Yellow
    if ($WSLAvailable) {
        Write-Host "  • Double-click 'run-tests.bat' to run all tests" -ForegroundColor White
        Write-Host "  • Or run individual test suites with 'run-*-tests.bat'" -ForegroundColor White
    } else {
        Write-Host "  • Double-click 'run-tests-gitbash.bat' to run all tests" -ForegroundColor White
    }
} else {
    Write-Host "❌ No suitable bash environment found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install one of the following:" -ForegroundColor Yellow
    Write-Host "  • Windows Subsystem for Linux (WSL)" -ForegroundColor White
    Write-Host "  • Git for Windows (includes Git Bash)" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run this setup script again." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Prerequisites for testing:" -ForegroundColor Yellow
Write-Host "  • rclone installed in your bash environment" -ForegroundColor White
Write-Host "  • bc calculator (for performance tests)" -ForegroundColor White
Write-Host ""
Write-Host "Install in WSL/Linux:" -ForegroundColor Cyan
Write-Host "  sudo apt install rclone bc        # Ubuntu/Debian" -ForegroundColor Gray
Write-Host "  sudo dnf install rclone bc        # Fedora" -ForegroundColor Gray
Write-Host "  sudo pacman -S rclone bc          # Arch" -ForegroundColor Gray

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green

# Create PowerShell runner script
$PowerShellRunner = @"
# PowerShell Test Runner for EmuDeck Save Sync
# This script provides an alternative to batch files

param(
    [string]`$TestSuite = "all",
    [switch]`$Verbose,
    [switch]`$WSL = `$true,
    [switch]`$GitBash = `$false
)

`$ProjectRoot = Split-Path -Parent `$MyInvocation.MyCommand.Path

if (`$GitBash) {
    `$GitBashPath = Get-Command "bash" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not `$GitBashPath) {
        Write-Error "Git Bash not found in PATH"
        exit 1
    }
    
    Set-Location `$ProjectRoot
    switch (`$TestSuite.ToLower()) {
        "all" { & "`$GitBashPath" ./run-all-tests.sh }
        "unit" { & "`$GitBashPath" ./tests/unit-tests.sh }
        "integration" { & "`$GitBashPath" ./tests/integration-tests.sh }
        "performance" { & "`$GitBashPath" ./tests/performance-tests.sh }
        "security" { & "`$GitBashPath" ./tests/security-tests.sh }
        "main" { & "`$GitBashPath" ./test-suite.sh }
        default { 
            Write-Error "Unknown test suite: `$TestSuite"
            Write-Host "Available: all, unit, integration, performance, security, main"
            exit 1
        }
    }
} else {
    # Use WSL (default)
    Set-Location `$ProjectRoot
    switch (`$TestSuite.ToLower()) {
        "all" { wsl -- bash ./run-all-tests.sh }
        "unit" { wsl -- bash ./tests/unit-tests.sh }
        "integration" { wsl -- bash ./tests/integration-tests.sh }
        "performance" { wsl -- bash ./tests/performance-tests.sh }
        "security" { wsl -- bash ./tests/security-tests.sh }
        "main" { wsl -- bash ./test-suite.sh }
        default { 
            Write-Error "Unknown test suite: `$TestSuite"
            Write-Host "Available: all, unit, integration, performance, security, main"
            exit 1
        }
    }
}
"@

$PowerShellRunner | Out-File -FilePath "$ProjectRoot\Run-Tests.ps1" -Encoding UTF8
Write-Host "✅ Created Run-Tests.ps1 (PowerShell runner)" -ForegroundColor Green

Write-Host ""
Write-Host "Additional PowerShell usage:" -ForegroundColor Yellow
Write-Host "  .\Run-Tests.ps1                    # Run all tests in WSL" -ForegroundColor White
Write-Host "  .\Run-Tests.ps1 -TestSuite unit    # Run unit tests only" -ForegroundColor White  
Write-Host "  .\Run-Tests.ps1 -GitBash           # Use Git Bash instead of WSL" -ForegroundColor White
