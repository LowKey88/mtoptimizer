# Stop-MTOptimizer.ps1
#
# Description: Stops the MT4/MT5 Core Optimizer service

# Ensure running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    Write-Host "Error: Administrator rights required."
    Write-Host "Please run this script as Administrator."
    Break
}

Write-Host "MT4/MT5 Core Optimizer Service Stop"
Write-Host "--------------------------------"

# Stop existing processes
Write-Host "Stopping optimizer processes..."
try {
    $processes = Get-WmiObject Win32_Process -Filter "Name = 'powershell.exe'" | 
                Where-Object { $_.CommandLine -like "*mt_core_optimizer.ps1*" }
    if ($processes) {
        $processes | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
        Write-Host "Optimizer processes stopped successfully"
    } else {
        Write-Host "No running optimizer processes found"
    }
} catch {
    Write-Host "Error stopping processes: $_"
    Break
}

Write-Host "--------------------------------"
Write-Host "Stop operation completed"