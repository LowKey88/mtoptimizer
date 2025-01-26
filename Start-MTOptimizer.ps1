# Start-MTOptimizer.ps1
#
# Description: Starts the MT4/MT5 Core Optimizer service

# Ensure running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    Write-Host "Error: Administrator rights required."
    Write-Host "Please run this script as Administrator."
    Break
}

Write-Host "MT4/MT5 Core Optimizer Service Start"
Write-Host "--------------------------------"

# Define paths
$optimizerPath = "C:\Program Files\MTOptimizer"
$scriptPath = "$optimizerPath\mt_core_optimizer.ps1"

# Verify installation
if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: Optimizer script not found at: $scriptPath"
    Write-Host "Please ensure MTOptimizer is properly installed"
    Break
}

# Check if already running
$existing = Get-WmiObject Win32_Process -Filter "Name = 'powershell.exe'" | 
            Where-Object { $_.CommandLine -like "*mt_core_optimizer.ps1*" }
if ($existing) {
    Write-Host "Warning: Optimizer service is already running"
    Write-Host "Please run Stop-MTOptimizer.ps1 first if you want to restart the service"
    Break
}

# Start the optimizer
Write-Host "Starting optimizer service..."
try {
    Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden
    Write-Host "Optimizer service started successfully"
} catch {
    Write-Host "Error starting optimizer: $_"
    Break
}

Write-Host "--------------------------------"
Write-Host "Start operation completed"