# run_all.ps1
# Sequential simulation runner for RISC-V CPU stages with summary reporting.

# Ensure we are in the script's directory
Set-Location $PSScriptRoot

$scripts = @(
    "run_fetch.do",
    "run_decode.do",
    "run_execute.do",
    "run_memory.do",
    "run_writeback.do",
    "run_core.do"
)

$passed = @()
$failed = @()

Write-Host "--------------------------------------------------" -ForegroundColor Cyan
Write-Host "Starting RISC-V CPU Simulation Regression" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor Cyan

foreach ($script in $scripts) {
    if (-not (Test-Path $script)) {
        Write-Host "Warning: $script not found. Skipping..." -ForegroundColor Yellow
        continue
    }

    Write-Host "`n>>> Executing $script..." -ForegroundColor Cyan
    
    # Run from the logs directory so even the initial transcript is placed there
    Push-Location "../logs"
    
    # Guardrails:
    # 1. -batch: Non-interactive mode
    # 2. -do: Runs the script and exits automatically
    # 3. -l: Explicitly log to transcript in the logs folder
    $output = vsim -batch -do "../scripts/$script" -l transcript.log 2>&1
    $exitCode = $LASTEXITCODE
    
    Pop-Location
    
    # Logic to determine pass/fail:
    # 1. Check exit code (compilation/sim errors)
    # 2. Scan output for common failure keywords in testbenches
    # Use -Pattern that avoids matching "# Errors: 0"
    $hasFailureKeyword = $output | Select-String -Pattern "FAIL", "FAILURE", "Error\s*:\s*[1-9]", "\*\* Error" -Quiet

    if ($exitCode -ne 0 -or $hasFailureKeyword) {
        Write-Host "RESULT: $script FAILED" -ForegroundColor Red
        $failed += $script
        # Optional: Print the specific failure lines if found
        $output | Select-String -Pattern "FAIL", "FAILURE", "Error" | Write-Host -ForegroundColor Yellow
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
