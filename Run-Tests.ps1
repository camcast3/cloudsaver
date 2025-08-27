# PowerShell Test Runner for EmuDeck Save Sync
# This script provides an alternative to batch files

param(
    [string]$TestSuite = "all",
    [switch]$Verbose,
    [switch]$WSL = $true,
    [switch]$GitBash = $false
)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($GitBash) {
    $GitBashPath = Get-Command "bash" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $GitBashPath) {
        Write-Error "Git Bash not found in PATH"
        exit 1
    }
    
    Set-Location $ProjectRoot
    switch ($TestSuite.ToLower()) {
        "all" { & "$GitBashPath" ./run-all-tests.sh }
        "unit" { & "$GitBashPath" ./tests/unit-tests.sh }
        "integration" { & "$GitBashPath" ./tests/integration-tests.sh }
        "performance" { & "$GitBashPath" ./tests/performance-tests.sh }
        "security" { & "$GitBashPath" ./tests/security-tests.sh }
        "main" { & "$GitBashPath" ./test-suite.sh }
        default { 
            Write-Error "Unknown test suite: $TestSuite"
            Write-Host "Available: all, unit, integration, performance, security, main"
            exit 1
        }
    }
} else {
    # Use WSL (default)
    Set-Location $ProjectRoot
    switch ($TestSuite.ToLower()) {
        "all" { wsl -- bash ./run-all-tests.sh }
        "unit" { wsl -- bash ./tests/unit-tests.sh }
        "integration" { wsl -- bash ./tests/integration-tests.sh }
        "performance" { wsl -- bash ./tests/performance-tests.sh }
        "security" { wsl -- bash ./tests/security-tests.sh }
        "main" { wsl -- bash ./test-suite.sh }
        default { 
            Write-Error "Unknown test suite: $TestSuite"
            Write-Host "Available: all, unit, integration, performance, security, main"
            exit 1
        }
    }
}
