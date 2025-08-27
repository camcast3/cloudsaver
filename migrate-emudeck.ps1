# EmuDeck Save Sync - File Migration Script
# Run this from your homelab directory to copy all EmuDeck files to a new repository

param(
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath
)

Write-Host "🚀 EmuDeck Save Sync - Repository Migration" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue

# Verify destination exists
if (-not (Test-Path $DestinationPath)) {
    Write-Host "❌ Destination path does not exist: $DestinationPath" -ForegroundColor Red
    Write-Host "Please create the directory first or check the path." -ForegroundColor Red
    exit 1
}

Write-Host "📁 Destination: $DestinationPath" -ForegroundColor Green
Write-Host ""

# Define files to migrate
$coreFiles = @(
    "emudeck-sync.sh",
    "emudeck-wrapper.sh", 
    "emudeck-setup.sh",
    "emudeck-steam-launch.sh",
    "emudeck-sync@.service",
    "emudeck-sync@.timer"
)

$testFiles = @(
    "run-all-tests.sh",
    "test-suite.sh",
    "setup-tests.ps1",
    "Run-Tests.ps1"
)

$deploymentFiles = @(
    "check-bazzite-environment.sh",
    "test-real-emulators.sh", 
    "transfer-config.sh",
    "BAZZITE-DEPLOYMENT.md",
    "DEPLOYMENT-GUIDE.md"
)

$miscFiles = @(
    "install.sh",
    "README-EmuDeck-Sync.md",
    "LICENSE"
)

# Function to copy files with status
function Copy-FilesWithStatus {
    param($fileList, $category)
    
    Write-Host "📋 Copying $category..." -ForegroundColor Yellow
    
    foreach ($file in $fileList) {
        if (Test-Path $file) {
            Copy-Item $file $DestinationPath -Force
            Write-Host "  ✅ $file" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  $file (not found)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Copy file groups
Copy-FilesWithStatus $coreFiles "Core EmuDeck Sync Scripts"
Copy-FilesWithStatus $testFiles "Testing Framework"
Copy-FilesWithStatus $deploymentFiles "Deployment Scripts"
Copy-FilesWithStatus $miscFiles "Additional Files"

# Copy tests directory
Write-Host "📋 Copying tests directory..." -ForegroundColor Yellow
if (Test-Path "tests") {
    Copy-Item -Recurse "tests" $DestinationPath -Force
    Write-Host "  ✅ tests/ directory copied" -ForegroundColor Green
    
    # List test files
    $testFiles = Get-ChildItem "$DestinationPath/tests" -File
    foreach ($file in $testFiles) {
        Write-Host "    📄 $($file.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️  tests/ directory not found" -ForegroundColor Yellow
}
Write-Host ""

# Rename README
Write-Host "📋 Renaming documentation..." -ForegroundColor Yellow
$readmeSource = Join-Path $DestinationPath "README-EmuDeck-Sync.md"
$readmeTarget = Join-Path $DestinationPath "README.md"

if (Test-Path $readmeSource) {
    if (Test-Path $readmeTarget) {
        Remove-Item $readmeTarget -Force
    }
    Rename-Item $readmeSource "README.md"
    Write-Host "  ✅ README-EmuDeck-Sync.md → README.md" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  README-EmuDeck-Sync.md not found" -ForegroundColor Yellow
}
Write-Host ""

# Count copied files
$copiedFiles = Get-ChildItem $DestinationPath -File | Where-Object { $_.Name -match "(emudeck|test|check|transfer|install|README|DEPLOYMENT|BAZZITE|Run-Tests|setup-tests)" }
$fileCount = $copiedFiles.Count

Write-Host "🎉 Migration Complete!" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green
Write-Host "✅ Copied $fileCount files to: $DestinationPath" -ForegroundColor Green
Write-Host ""

# Show next steps
Write-Host "🔧 Next Steps:" -ForegroundColor Blue
Write-Host "1. Navigate to the new repository:" -ForegroundColor White
Write-Host "   cd `"$DestinationPath`"" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Make scripts executable (if on Linux/WSL):" -ForegroundColor White  
Write-Host "   chmod +x *.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test the migration:" -ForegroundColor White
Write-Host "   ./check-bazzite-environment.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Initialize git and commit:" -ForegroundColor White
Write-Host "   git init" -ForegroundColor Gray
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m `"Initial commit - EmuDeck Save Sync`"" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Add remote and push:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/your-username/emudeck-save-sync.git" -ForegroundColor Gray
Write-Host "   git push -u origin main" -ForegroundColor Gray
Write-Host ""

Write-Host "📂 Copied Files:" -ForegroundColor Blue
$copiedFiles | Sort-Object Name | ForEach-Object { Write-Host "  📄 $($_.Name)" -ForegroundColor Gray }

Write-Host ""
Write-Host "🎯 Your EmuDeck Save Sync is ready for its own repository!" -ForegroundColor Green
