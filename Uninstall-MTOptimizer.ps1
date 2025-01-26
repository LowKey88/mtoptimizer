# Uninstall-MTOptimizer.ps1
#
# Description: Removes the MT4/MT5 Core Optimizer and cleans up all related files and settings

# Ensure running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    Write-Host "Error: Administrator rights required."
    Write-Host "Please run this script as Administrator."
    Break
}

Write-Host "MT4/MT5 Core Optimizer Uninstaller"
Write-Host "--------------------------------"

# Stop running processes
Write-Host "Stopping optimizer processes..."
Get-Process | Where-Object { $_.ProcessName -eq "mt_core_optimizer" -or $_.Path -like "*MTOptimizer*" } | ForEach-Object {
    try {
        Stop-Process -Id $_.Id -Force
        Write-Host "Stopped process: $($_.Id)"
    } catch {
        Write-Host "Warning: Could not stop process $($_.Id): $_"
    }
}

# Remove auto-start registry entry
Write-Host "Removing auto-start configuration..."
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
if (Get-ItemProperty -Path $regPath -Name "MTSystemOptimizer" -ErrorAction SilentlyContinue) {
    Remove-ItemProperty -Path $regPath -Name "MTSystemOptimizer"
}

# Remove all files and directories
Write-Host "Removing files and directories..."
$paths = @(
    "C:\Program Files\MTOptimizer",
    "C:\Windows\Logs\MTOptimizer"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        try {
            Remove-Item $path -Recurse -Force
            Write-Host "Removed: $path"
        } catch {
            Write-Host "Warning: Could not remove $path`: $_"
        }
    }
}

Write-Host "--------------------------------"
Write-Host "Uninstallation complete."

# Verify uninstallation
Write-Host "`nVerifying uninstallation status..."
Write-Host "--------------------------------"

# Check for remaining processes
$remainingProcesses = Get-Process | Where-Object { 
    $_.ProcessName -eq "mt_core_optimizer" -or 
    $_.Path -like "*MTOptimizer*" 
} | Select-Object Id, ProcessName, Path

if ($remainingProcesses) {
    Write-Host "Warning: Found remaining processes:"
    $remainingProcesses | ForEach-Object {
        Write-Host "- Process ID: $($_.Id), Name: $($_.ProcessName)"
    }
} else {
    Write-Host "Status: No optimizer processes found"
}

# Check for PowerShell instances running optimizer
$runningServices = Get-Process -Name powershell | Where-Object { 
    $_.CommandLine -like "*MTOptimizer*" 
} | Select-Object Id, ProcessName

if ($runningServices) {
    Write-Host "Warning: Found running services:"
    $runningServices | ForEach-Object {
        Write-Host "- Service ID: $($_.Id), Name: $($_.ProcessName)"
    }
} else {
    Write-Host "Status: No optimizer services running"
}

# Check installation directory
if (Test-Path "C:\Program Files\MTOptimizer") {
    Write-Host "Warning: Installation directory still exists"
} else {
    Write-Host "Status: Installation directory removed"
}

# Check registry entry
if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "MTSystemOptimizer" -ErrorAction SilentlyContinue) {
    Write-Host "Warning: Auto-start registry entry still exists"
} else {
    Write-Host "Status: Auto-start registry entry removed"
}

Write-Host "--------------------------------"
Write-Host "Note: You may need to restart your computer for all changes to take effect."