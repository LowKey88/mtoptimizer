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

# Reset terminal affinities
Write-Host "Resetting terminal affinities..."
Get-Process | Where-Object { $_.ProcessName -like "*terminal*" -or $_.ProcessName -like "*Terminal*" } | ForEach-Object {
    try {
        # Get the number of processors in the system
        $processorCount = [System.Environment]::ProcessorCount
        
        # Calculate the mask that enables all processors (2^n - 1)
        $affinityMask = [Math]::Pow(2, $processorCount) - 1
        
        # Convert to IntPtr
        $affinityPtr = [IntPtr]::new($affinityMask)
        
        # Set the affinity
        $_.ProcessorAffinity = $affinityPtr
        Write-Host "Reset affinity for terminal process: $($_.ProcessName) (ID: $($_.Id))"
    } catch {
        Write-Host "Warning: Could not reset affinity for $($_.ProcessName) (ID: $($_.Id)): $_"
    }
    Start-Sleep -Milliseconds 100  # Add small delay between operations
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
Write-Host "Note: You may need to restart your computer for all changes to take effect."