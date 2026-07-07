# run_all.ps1 for 8-stage pipeline
# Sequential simulation runner with summary reporting.
# All output is printed to the terminal; no log files are generated.

$originalDir = Get-Location
Set-Location $PSScriptRoot

# Verify that vsim tool exists in PATH
if (-not (Get-Command vsim -ErrorAction SilentlyContinue)) {
    Write-Host "Error: ModelSim/QuestaSim executable 'vsim' not found in system PATH." -ForegroundColor Red
    Set-Location $originalDir
    exit 1
}

# Ensure logs directory exists (used as the working directory for simulations)
$logsDir = Join-Path $PSScriptRoot "../logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$scripts = @(
    "run_pc_update.do",
    "run_instr_mem.do",
    "run_control.do",
    "run_imm_gen.do",
    "run_decode.do",
    "run_regfile.do",
    "run_bht.do",
    "run_data_sel.do",
    "run_alu.do",
    "run_branch_eval.do",
    "run_pc_target_calc.do",
    "run_data_mem.do",
    "run_writeback.do",
    "run_hazard_detection_unit.do",
    "run_forwarding_unit.do",
    "run_core_integrated.do"
)

$passed = @()
$failed = @()

Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Starting 8-Stage RISC-V CPU Simulation Regression" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan

foreach ($script in $scripts) {
    $scriptPath = Join-Path $PSScriptRoot $script
    if (-not (Test-Path $scriptPath)) {
        Write-Host "Warning: $script not found at $scriptPath. Skipping..." -ForegroundColor Yellow
        continue
    }

    Write-Host "`n>>> Executing $script..." -ForegroundColor Cyan

    # Run from the logs directory so the work library and copied files land there.
    Push-Location $logsDir

    # Run vsim in batch mode, printing output directly to the terminal.
    # No -l flag so no log file is generated.
    $process = Start-Process vsim `
        -ArgumentList "-batch", "-l", "vsim.log", "-do", "$scriptPath" `
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

    # Clean up copied files in the logs directory
    $logsIni = Join-Path $logsDir "modelsim.ini"
    if (Test-Path $logsIni) { Remove-Item -Path $logsIni -Force -ErrorAction SilentlyContinue }
    $logsHex = Join-Path $logsDir "program.hex"
    if (Test-Path $logsHex) { Remove-Item -Path $logsHex -Force -ErrorAction SilentlyContinue }
    $logsLog = Join-Path $logsDir "vsim.log"
    if (Test-Path $logsLog) { Remove-Item -Path $logsLog -Force -ErrorAction SilentlyContinue }

    # Remove any ModelSim-generated transcript stubs from the scripts directory
    $transcriptPath = Join-Path $PSScriptRoot "transcript"
    if (Test-Path $transcriptPath) {
        Remove-Item -Path $transcriptPath -Force -ErrorAction SilentlyContinue
    }

    if ($exitCode -ne 0 -or $timeoutOccurred) {
        Write-Host "RESULT: $script FAILED" -ForegroundColor Red
        $failed += $script
        if ($timeoutOccurred) {
            Write-Host "Reason: Process did not exit cleanly." -ForegroundColor Yellow
        }
    } else {
        Write-Host "RESULT: $script PASSED" -ForegroundColor Green
        $passed += $script
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "REGRESSION SUMMARY" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($failed.Count -eq 0) {
    Write-Host "ALL TESTS PASSED ($($passed.Count)/$($scripts.Count))" -ForegroundColor Green

    # Clean up the work directory now that all tests have passed
    $workDir = Join-Path $logsDir "work"
    if (Test-Path $workDir) {
        Write-Host "Cleaning up work directory..." -ForegroundColor Cyan
        Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Work directory removed." -ForegroundColor Cyan
    }

    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Regression complete." -ForegroundColor Cyan
    Set-Location $originalDir
    exit 0
} else {
    Write-Host "SOME TESTS FAILED ($($failed.Count)/$($scripts.Count))" -ForegroundColor Red
    Write-Host "`nPassed Testbenches:" -ForegroundColor Green
    foreach ($p in $passed) { Write-Host "  [+] $p" }

    Write-Host "`nFailing Testbenches:" -ForegroundColor Red
    foreach ($f in $failed) { Write-Host "  [-] $f" }
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Regression complete." -ForegroundColor Cyan
    Set-Location $originalDir
    exit 1
}
