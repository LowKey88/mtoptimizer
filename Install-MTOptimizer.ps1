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
$Config = @{
    MaxPerCore = 2
    StabilityMinutes = 5
    CheckIntervalSeconds = 30
    CPUThreshold = 75
}

# Simple state tracking
$State = @{
    LastCore = 0
    LastAssignment = Get-Date
    Processes = @{}
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

# Simple error handling
function Handle-Error {
    param($Operation, $Error)
    Write-Log "Error during $Operation`: $Error" -Important $true
    
    switch ($Operation) {
        "Assignment" {
            # Reset problem terminal
            try {
                $processId = $Error.TargetObject.Id
                $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                if ($process) {
                    $process.ProcessorAffinity = [IntPtr]::new(-1)
                    Write-Log "Reset affinity for problematic terminal: $processId"
                }
            } catch {
                Write-Log "Could not reset problematic terminal: $_"
            }
        }
        "CoreSelection" {
            # Reset state
            $State.LastCore = 0
            $State.LastAssignment = Get-Date
            Write-Log "Reset core selection state"
        }
    }
}

# Core selection
function Get-NextCore {
    param($TotalCores)
    
    try {
        # Check stability period
        if ((Get-Date).Subtract($State.LastAssignment).TotalMinutes -lt $Config.StabilityMinutes) {
            return $State.LastCore
        }
        
        # Simple round-robin
        $State.LastCore = ($State.LastCore + 1) % $TotalCores
        $State.LastAssignment = Get-Date
        
        return $State.LastCore
    } catch {
        Handle-Error "CoreSelection" $_
        return 0
    }
}

# Process management
function Set-TerminalAffinity {
    param($Terminal, $CoreId)
    
    try {
        $Terminal.ProcessorAffinity = [IntPtr](1 -shl $CoreId)
        $State.Processes[$Terminal.Id] = @{
            Core = $CoreId
            Time = Get-Date
        }
        Write-Log "Assigned terminal $($Terminal.Id) to core $CoreId"
    } catch {
        Handle-Error "Assignment" $_
    }
}

# Main loop
try {
    Write-Log "MT4/MT5 Core Optimizer v$ScriptVersion Started" -Important $true
    
    while ($true) {
        # Get terminals and core count
        $terminals = Get-Process | Where-Object { $_.ProcessName -eq "terminal" }
        $totalCores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
        
        foreach ($terminal in $terminals) {
            # Check if terminal needs assignment
            if (-not $State.Processes[$terminal.Id] -or 
                (Get-Date).Subtract($State.Processes[$terminal.Id].Time).TotalMinutes -gt $Config.StabilityMinutes) {
                
                $nextCore = Get-NextCore -TotalCores $totalCores
                Set-TerminalAffinity -Terminal $terminal -CoreId $nextCore
            }
        }
        
        # Cleanup old entries
        $State.Processes.Keys.Clone() | ForEach-Object {
            if (-not (Get-Process -Id $_ -ErrorAction SilentlyContinue)) {
                $State.Processes.Remove($_)
                Write-Log "Removed tracking for terminated terminal: $_"
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
    Write-Host "CPU Cores: $((Get-CimInstance Win32_Processor).NumberOfLogicalProcessors)"
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
