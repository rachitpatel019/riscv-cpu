# run_coverage.ps1 for 8-stage pipeline Verilator functional coverage
# Runs Verilator simulations inside WSL and reports functional coverage.

$originalDir = Get-Location
Set-Location $PSScriptRoot

# Verify that wsl is available
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Windows Subsystem for Linux (WSL) 'wsl' not found." -ForegroundColor Red
    Set-Location $originalDir
    exit 1
}

# Run the python runner script inside WSL
Write-Host "Launching Verilator coverage regression in WSL..." -ForegroundColor Cyan

# Use -u to prevent python from buffering stdout/stderr
wsl python3 -u "./run_coverage.py"
$exitCode = $LASTEXITCODE

Set-Location $originalDir

# Cleanup section
Write-Host "Cleaning up temporary simulation and compilation files..." -ForegroundColor Cyan
$covWorkDir = Join-Path $PSScriptRoot "..\logs\coverage_run"
if (Test-Path $covWorkDir) {
    Remove-Item -Recurse -Force $covWorkDir
}

# Clean up legacy coverage artifacts in workspace root
$rootFolder = (Get-Item (Join-Path $PSScriptRoot "..\..\..")).FullName
$legacyFiles = @("coverage.dat", "coverage.info", "program.hex")
foreach ($file in $legacyFiles) {
    $filePath = Join-Path $rootFolder $file
    if (Test-Path $filePath) {
        Remove-Item -Force $filePath
    }
}
$legacyObjDir = Join-Path $rootFolder "obj_dir"
if (Test-Path $legacyObjDir) {
    Remove-Item -Recurse -Force $legacyObjDir
}

if ($exitCode -ne 0) {
    Write-Host "Coverage regression completed with errors or failures." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Coverage regression completed successfully." -ForegroundColor Green
    exit 0
}
