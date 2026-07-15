# run_power_analysis.ps1
# Automates the Quartus Power Analyzer execution and displays summary results.

# Set execution directory to this script's path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$originalDir = Get-Location
Set-Location $scriptDir

# 1. Environment & Pre-requisites Checks
Write-Host "Checking environment and prerequisites..." -ForegroundColor Cyan

# Check if quartus_pow is available in PATH
if (-not (Get-Command quartus_pow -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Quartus Power Analyzer executable 'quartus_pow' not found in system PATH." -ForegroundColor Red
    Set-Location $originalDir
    exit 1
}

# Verify that power.vcd exists (since it's configured as input in QSF)
$vcdPath = Join-Path $scriptDir "power.vcd"
if (-not (Test-Path $vcdPath)) {
    Write-Host "Warning: power.vcd not found in $scriptDir. Running simulation first to generate it..." -ForegroundColor Yellow
    $simScript = Join-Path $scriptDir "run_power_sim.ps1"
    if (Test-Path $simScript) {
        & powershell -ExecutionPolicy Bypass -File $simScript
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Simulation failed to generate power.vcd." -ForegroundColor Red
            Set-Location $originalDir
            exit 1
        }
    } else {
        Write-Host "Error: Cannot find simulation script run_power_sim.ps1 to generate power.vcd." -ForegroundColor Red
        Set-Location $originalDir
        exit 1
    }
}

# Verify Quartus project files exist
if (-not (Test-Path "cpu.qpf") -or -not (Test-Path "cpu.qsf")) {
    Write-Host "Error: Quartus project file(s) cpu.qpf or cpu.qsf not found in $scriptDir." -ForegroundColor Red
    Set-Location $originalDir
    exit 1
}

# 2. Run Power Analyzer
Write-Host "Starting Quartus Power Analyzer..." -ForegroundColor Cyan

$process = Start-Process quartus_pow `
    -ArgumentList "cpu" `
    -PassThru -NoNewWindow -Wait `
    -ErrorAction SilentlyContinue

$exitCode = 0
if ($null -eq $process) {
    Write-Host "Error: Failed to start quartus_pow process." -ForegroundColor Red
    $exitCode = 1
} else {
    $exitCode = $process.ExitCode
}

# 3. Report Results
$reportFile = Join-Path $scriptDir "output_files/cpu.pow.rpt"
if ($exitCode -eq 0 -and (Test-Path $reportFile)) {
    Write-Host "Power analysis completed successfully!" -ForegroundColor Green
    
    # Extract and display the summary from the report
    Write-Host "`nPower Analyzer Summary:" -ForegroundColor Cyan
    $rptContent = Get-Content $reportFile
    $inSummary = $false
    foreach ($line in $rptContent) {
        if ($line -match '^;\s*Power Analyzer Summary') {
            $inSummary = $true
            continue
        }
        if ($inSummary) {
            if ($line -match '^\s*$') {
                break
            }
            if ($line -match '^;\s*[^;]') {
                $clean = $line.Trim().Trim(';')
                Write-Host $clean -ForegroundColor White
            }
        }
    }
    
    Set-Location $originalDir
    exit 0
} else {
    Write-Host "Power analysis failed with exit code $exitCode." -ForegroundColor Red
    Set-Location $originalDir
    exit 1
}
