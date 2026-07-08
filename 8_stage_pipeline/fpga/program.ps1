# PowerShell script to program MAX 10 FPGA with RISC-V CPU

$ErrorActionPreference = "Stop"

# Check if quartus_pgm exists
if (-not (Get-Command "quartus_pgm" -ErrorAction SilentlyContinue)) {
    Write-Error "quartus_pgm not found in PATH. Please ensure Intel Quartus Prime is installed and added to your environment variables."
    Exit 1
}

# Find the programming cable dynamically
Write-Host "Checking for connected programming cables..."
$pgm_out = quartus_pgm -l
$cable = $null

foreach ($line in $pgm_out) {
    if ($line -match '\d+\)\s+(USB-Blaster.*)') {
        $cable = $Matches[1].Trim()
        break
    }
}

if ($null -eq $cable) {
    Write-Error "No USB-Blaster cable detected. Please check your FPGA connection and power."
    Exit 1
}

Write-Host "Found programming hardware: $cable"

# Verify SOF file exists
$sofPath = Join-Path $PSScriptRoot "output_files/cpu.sof"
if (-not (Test-Path $sofPath)) {
    Write-Error "Programming file '$sofPath' not found. Please compile the design first."
    Exit 1
}

Write-Host "Programming $sofPath..."
& quartus_pgm -c $cable -m JTAG -o "p;$sofPath"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Programming failed with exit code $LASTEXITCODE."
    Exit $LASTEXITCODE
}

Write-Host "Programming completed successfully."
