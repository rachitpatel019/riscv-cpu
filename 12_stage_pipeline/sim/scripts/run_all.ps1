# run_all.ps1 for 12-stage pipeline
# Sequential simulation runner with summary reporting and UVM support.

Set-Location $PSScriptRoot

$scripts = @(
    "run_pc_update.do",
    "run_instr_mem.do",
    "run_control.do",
    "run_imm_gen.do",
    "run_decode.do",
    "run_regfile.do",
    "run_data_sel.do",
    "run_alu.do",
    "run_pc_target_calc.do",
    "run_data_mem.do",
    "run_writeback.do",
    "run_core.do"
)

$passed = @()
$failed = @()

Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Starting 12-Stage RISC-V CPU Simulation Regression" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan

foreach ($script in $scripts) {
    if (-not (Test-Path $script)) {
        Write-Host "Warning: $script not found. Skipping..." -ForegroundColor Yellow
        continue
    }

    Write-Host "`n>>> Executing $script..." -ForegroundColor Cyan
    
    # Run from the logs directory
    Push-Location "../logs"
    
    # Guardrails: -batch for non-interactive, -do to run and exit
    # We add a timeout of 60 seconds per test to prevent hanging
    $logFile = "$($script.Replace('.do', '.log'))"
    $process = Start-Process vsim -ArgumentList "-batch", "-do", "../scripts/$script", "-l", "$logFile" -PassThru -NoNewWindow
    
    # Wait for completion with timeout
    $process | Wait-Process -Timeout 60 -ErrorAction SilentlyContinue
    
    $timeoutOccurred = $false
    if (-not $process.HasExited) {
        $timeoutOccurred = $true
        $process | Stop-Process -Force -ErrorAction SilentlyContinue
        $exitCode = -1
    } else {
        $exitCode = $process.ExitCode
    }
    
    Pop-Location
    
    # Scan log for failures
    $logPath = "../logs/$logFile"
    $hasFailureKeyword = $false
    if (Test-Path $logPath) {
        $logContent = Get-Content $logPath
        $hasFailureKeyword = $logContent | Select-String -Pattern "UVM_ERROR", "UVM_FATAL", "FAIL", "FAILURE", "Error\s*:\s*[1-9]", "\*\* Error" -Quiet
    }

    if ($exitCode -ne 0 -or $hasFailureKeyword -or $timeoutOccurred) {
        Write-Host "RESULT: $script FAILED" -ForegroundColor Red
        $failed += $script
        if ($timeoutOccurred) {
            Write-Host "Reason: Timeout (60s exceeded)" -ForegroundColor Yellow
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
} else {
    Write-Host "SOME TESTS FAILED ($($failed.Count)/$($scripts.Count))" -ForegroundColor Red
    Write-Host "`nPassed Testbenches:" -ForegroundColor Green
    foreach ($p in $passed) { Write-Host "  [+] $p" }
    
    Write-Host "`nFailing Testbenches:" -ForegroundColor Red
    foreach ($f in $failed) { Write-Host "  [-] $f" }
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Regression complete." -ForegroundColor Cyan
