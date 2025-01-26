# Install-MTOptimizer.ps1
#
# Description: PowerShell script to optimize CPU core usage for MetaTrader terminals
# by managing process affinity using a simple round-robin approach.

# Script Version
$ScriptVersion = "2.0.3"

# Ensure running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    Write-Host "Error: Administrator rights required."
    Write-Host "Please run this script as Administrator."
    Break
}

# Installation paths
$optimizerPath = "C:\Program Files\MTOptimizer"
$logPath = "C:\Windows\Logs\MTOptimizer"
$scriptPath = "$optimizerPath\mt_core_optimizer.ps1"

# Clean up old installation
function Remove-OldInstallation {
    Write-Host "Checking for existing installation..."
    
    # Stop existing processes
    Get-Process | Where-Object { $_.ProcessName -eq "mt_core_optimizer" -or $_.Path -like "*MTOptimizer*" } | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force
            Write-Host "Stopped process: $($_.Id)"
        } catch {
            Write-Host "Warning: Could not stop process $($_.Id): $_"
        }
    }

    # Reset terminal affinities
    Get-Process | Where-Object { $_.ProcessName -eq "terminal" } | ForEach-Object {
        try {
            $_.ProcessorAffinity = [IntPtr]::new(-1)
            Write-Host "Reset affinity for terminal: $($_.Id)"
        } catch {
            Write-Host "Warning: Could not reset affinity for $($_.Id): $_"
        }
    }

    # Remove old files
    if (Test-Path $optimizerPath) {
        Write-Host "Removing old installation files..."
        Remove-Item $optimizerPath -Recurse -Force
    }

    # Remove auto-start registry entry
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Get-ItemProperty -Path $regPath -Name "MTSystemOptimizer" -ErrorAction SilentlyContinue) {
        Write-Host "Removing old auto-start configuration..."
        Remove-ItemProperty -Path $regPath -Name "MTSystemOptimizer"
    }
}

# Core optimizer script
$optimizerScript = @'
# Script Version and Configuration
$ScriptVersion = "2.0.3"

# Core-based configuration matrix
$CoreConfigs = @{
    2 = @{ MaxPerCore = 3; CPUThreshold = 75 }
    4 = @{ MaxPerCore = 2; CPUThreshold = 70 }
    6 = @{ MaxPerCore = 2; CPUThreshold = 65 }
    8 = @{ MaxPerCore = 2; CPUThreshold = 60 }
}

# Default configuration
$Config = @{
    CheckIntervalSeconds = 30
    MaxPerCore = 2        # Will be updated based on core count
    CPUThreshold = 70     # Will be updated based on core count
}

# Simple state tracking
$State = @{
    CurrentCore = 0       # Simple round-robin counter
    Processes = @{}       # Track assigned processes
}

# Get total CPU cores
function Get-TotalCores {
    try {
        $processor = Get-CimInstance -ClassName Win32_Processor
        $cores = ($processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        return [int]$cores
    } catch {
        Write-Log "Error getting core count: $_" -Important $true
        return 2  # Safe fallback
    }
}

# Basic logging
function Write-Log {
    param(
        [string]$Message,
        [bool]$Important = $false
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    
    # Write to log file
    try {
        Add-Content -Path "C:\Windows\Logs\MTOptimizer\optimizer.log" -Value $logMessage
        if ($Important) {
            Write-Host $logMessage
        }
    } catch {
        Write-Host "Error writing to log: $_"
    }
}

# Process management
function Set-TerminalAffinity {
    param($Terminal, [int]$TotalCores)

    try {
        # Simple round-robin core selection
        [int]$CoreId = [int]$State.CurrentCore
        $State.CurrentCore = ([int]$State.CurrentCore + 1) % [int]$TotalCores
        
        # Set affinity mask for the core
        $affinityMask = 1 -shl $CoreId
        $Terminal.ProcessorAffinity = [IntPtr]$affinityMask
        
        # Track the process
        $State.Processes[$Terminal.Id] = $CoreId

        Write-Log "Assigned terminal $($Terminal.Id) to core $CoreId"
    } catch {
        Write-Log "Error assigning terminal $($Terminal.Id): $_"
        try {
            # Simple fallback - use core 0
            $Terminal.ProcessorAffinity = [IntPtr]1
            $State.Processes[$Terminal.Id] = 0
            Write-Log "Fallback: Set terminal $($Terminal.Id) to core 0"
        } catch {
            Write-Log "Failed to set fallback affinity: $_" -Important $true
        }
    }
}

# Main loop
try {
    Write-Log "MT4/MT5 Core Optimizer v$ScriptVersion Started" -Important $true
    
    # Get CPU core count and set configuration
    $totalCores = Get-TotalCores
    Write-Log "Detected $totalCores CPU cores" -Important $true
    
    # Set configuration based on core count
    if ($CoreConfigs.ContainsKey($totalCores)) {
        $Config.MaxPerCore = $CoreConfigs[$totalCores].MaxPerCore
        $Config.CPUThreshold = $CoreConfigs[$totalCores].CPUThreshold
        Write-Log "Using configuration for $totalCores cores: Max $($Config.MaxPerCore) terminals per core, $($Config.CPUThreshold)% threshold" -Important $true
    } else {
        Write-Log "Using default configuration for $totalCores cores" -Important $true
    }
    
    while ($true) {
        # Get all MT terminals
        $terminals = Get-Process | Where-Object { $_.ProcessName -eq "terminal" }
        
        foreach ($terminal in $terminals) {
            # Only assign if not already tracked
            if (-not $State.Processes.ContainsKey($terminal.Id)) {
                Set-TerminalAffinity -Terminal $terminal -TotalCores $totalCores
            }
        }
        
        # Clean up terminated processes
        $processIds = @($State.Processes.Keys)
        foreach ($processId in $processIds) {
            if (-not (Get-Process -Id $processId -ErrorAction SilentlyContinue) -and 
                $State.Processes.Remove($processId)) {
                Write-Log "Removed tracking for terminated terminal: $processId"
            }
        }
        
        Start-Sleep -Seconds $Config.CheckIntervalSeconds
    }
} catch {
    Write-Log "Critical error in main loop: $_" -Important $true
} finally {
    Write-Log "Optimizer stopping - resetting terminal affinities..." -Important $true
    Get-Process | Where-Object { $_.ProcessName -eq "terminal" } | ForEach-Object {
        try {
            $_.ProcessorAffinity = [IntPtr]::new(-1)
            Write-Log "Reset affinity for terminal: $($_.Id)"
        } catch {
            Write-Log "Warning: Could not reset affinity for $($_.Id): $_"
        }
    }
}
'@

# Installation
try {
    Write-Host "MT4/MT5 Core Optimizer v$ScriptVersion Installation"
    Write-Host "----------------------------------------"

    # Clean up old installation
    Remove-OldInstallation
    
    # Create directories
    Write-Host "Creating directories..."
    try {
        # Create and set permissions for optimizer directory
        New-Item -ItemType Directory -Path $optimizerPath -Force | Out-Null
        
        # Create and set permissions for log directory
        if (-not (Test-Path $logPath)) {
            New-Item -ItemType Directory -Path $logPath -Force | Out-Null
            # Ensure Everyone has write permissions for logs
            $acl = Get-Acl $logPath
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","Modify","ContainerInherit,ObjectInherit","None","Allow")
            $acl.AddAccessRule($rule)
            Set-Acl $logPath $acl
        }
    } catch { throw "Failed to create directories: $_" }

    # Save script
    Write-Host "Installing optimizer script..."
    $optimizerScript | Out-File $scriptPath -Force

    # Set registry for auto-start
    Write-Host "Configuring auto-start..."
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $regPath -Name "MTSystemOptimizer" -Value "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`"" -Force

    # Start optimizer
    Write-Host "Starting optimizer..."
    Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden

    Write-Host "----------------------------------------"
    Write-Host "MT4/MT5 Core Optimizer v$ScriptVersion installed successfully"
    
    # Show detected cores
    $cores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
    Write-Host "Detected CPU Cores: $cores"
} catch {
    Write-Host "Installation failed: $_"
    
    # Attempt cleanup on failure
    if (Test-Path $optimizerPath) {
        Remove-Item $optimizerPath -Recurse -Force
    }
    if (Get-ItemProperty -Path $regPath -Name "MTSystemOptimizer" -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $regPath -Name "MTSystemOptimizer"
    }
    
    throw
}