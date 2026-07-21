# run_benchmark.ps1
# Simulation runner for the 8-stage balanced pipeline benchmark simulation.
# All output is printed to the terminal; temporary logs/files are cleaned up.

$originalDir = Get-Location
$scriptDir = $PSScriptRoot

# Verify that vsim tool exists in PATH
if (-not (Get-Command vsim -ErrorAction SilentlyContinue)) {
    Write-Host "Error: ModelSim/QuestaSim executable 'vsim' not found in system PATH." -ForegroundColor Red
    Set-Location $originalDir
    exit 1
}

# Verify that required input files exist in the benchmark directory
$doScript = Join-Path $scriptDir "run_benchmark.do"
$tbFile = Join-Path $scriptDir "tb_benchmark.sv"
$hexFile = Join-Path $scriptDir "program.hex"

$requiredFiles = @($doScript, $tbFile, $hexFile)
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "Error: Required file '$file' is missing." -ForegroundColor Red
        Set-Location $originalDir
        exit 1
    }
}

Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Starting 8-Stage RISC-V CPU Benchmark Simulation" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan

# Run from the benchmark directory so the relative paths and hex file load correctly.
Push-Location $scriptDir

# Run vsim in batch mode, printing output directly to the terminal.
$process = Start-Process vsim `
    -ArgumentList "-batch", "-l", "vsim.log", "-do", "$doScript" `
    -PassThru -NoNewWindow -Wait `
    -ErrorAction SilentlyContinue

$timeoutOccurred = $false
if ($null -eq $process -or -not $process.HasExited) {
    # Fallback: process did not exit cleanly
    $timeoutOccurred = $true
    if ($null -ne $process) { $process | Stop-Process -Force -ErrorAction SilentlyContinue }
    $exitCode = -1
} else {
    $exitCode = $process.ExitCode
}

Pop-Location

# Remove any ModelSim-generated transcript stubs from the benchmark directory
$transcriptPath = Join-Path $scriptDir "transcript"
if (Test-Path $transcriptPath) {
    Remove-Item -Path $transcriptPath -Force -ErrorAction SilentlyContinue
}

# Remove any work directory that might have been left over if cleanup inside DO failed
$workDir = Join-Path $scriptDir "work"
if (Test-Path $workDir) {
    Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($exitCode -ne 0 -or $timeoutOccurred) {
    Write-Host "RESULT: Benchmark Simulation FAILED" -ForegroundColor Red
    if ($timeoutOccurred) {
        Write-Host "Reason: Simulation process did not exit cleanly or was interrupted." -ForegroundColor Yellow
    } else {
        Write-Host "Reason: vsim exited with non-zero code ($exitCode)." -ForegroundColor Yellow
    }
    Write-Host "Check 'vsim.log' for details." -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Cyan
    Set-Location $originalDir
    exit 1
} else {
    # Clean up intermediate simulation logs on success
    $logFile = Join-Path $scriptDir "vsim.log"
    if (Test-Path $logFile) {
        Remove-Item -Path $logFile -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "RESULT: Benchmark Simulation PASSED" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan
    Set-Location $originalDir
    exit 0
}
