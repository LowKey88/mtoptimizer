# MT4/MT5 Core Optimizer - Simple Technical Guide

## Current Issues

### 1. CPU Core Assignment
Problem: Random core changes affecting terminal performance
Root Cause: Complex core selection logic
Solution:
- Use simple round-robin assignment
- Keep terminals on same core longer
- Basic load checking only

### 2. Basic Logging
Problem: Log file access issues
Root Cause: Complex logging system
Solution:
- Simple log file writing
- Basic error reporting
- Clear status messages

## Simple Implementation

### 1. Simple Core Selection
```powershell
# Track last used core
$script:LastCore = 0
$script:LastAssignmentTime = Get-Date

function Get-NextCore {
    param($TotalCores)

    # Check if enough time has passed
    if ((Get-Date).Subtract($script:LastAssignmentTime).TotalMinutes -lt 5) {
        return $script:LastCore
    }

    # Simple round-robin
    $script:LastCore = ($script:LastCore + 1) % $TotalCores
    $script:LastAssignmentTime = Get-Date

    return $script:LastCore
}
```

### 2. Simple Process Management
```powershell
function Set-TerminalAffinity {
    param($ProcessId, $CoreId)
    
    try {
        $process = Get-Process -Id $ProcessId
        $process.ProcessorAffinity = [IntPtr](1 -shl $CoreId)
        Write-Log "Assigned terminal $ProcessId to core $CoreId"
    } catch {
        Write-Log "Error assigning terminal $ProcessId to core $CoreId: $_"
    }
}
```

### 3. Simple Logging
```powershell
function Write-Log {
    param($Message)
    
    $logFile = "C:\Windows\Logs\MTOptimizer\optimizer.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Simple log write
    "$timestamp - $Message" | Add-Content $logFile
    
    # Show important messages
    if ($Message -match "Error|Warning|Success") {
        Write-Host "$timestamp - $Message"
    }
}
```

### 4. Simple Installation
```powershell
function Install-Optimizer {
    # Basic checks
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Host "Error: Administrator rights required"
        return
    }
    
    # Create directories
    New-Item -ItemType Directory -Force -Path "C:\Program Files\MTOptimizer"
    New-Item -ItemType Directory -Force -Path "C:\Windows\Logs\MTOptimizer"
    
    # Set auto-start
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $regPath -Name "MTOptimizer" -Value "powershell -WindowStyle Hidden -File `"C:\Program Files\MTOptimizer\optimizer.ps1`""
    
    Write-Host "Installation complete"
}
```

## Main Loop
```powershell
# Simple monitoring loop
while ($true) {
    # Get all MT4/MT5 terminals
    $terminals = Get-Process | Where-Object { $_.ProcessName -eq "terminal" }
    $totalCores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    
    foreach ($terminal in $terminals) {
        # Check if terminal needs core assignment
        if (-not $terminal.ProcessorAffinity) {
            $nextCore = Get-NextCore -TotalCores $totalCores
            Set-TerminalAffinity -ProcessId $terminal.Id -CoreId $nextCore
        }
    }
    
    # Simple sleep between checks
    Start-Sleep -Seconds 30
}
```

## Testing Guide

1. Basic Tests
   - Start/stop optimizer
   - Launch MT4/MT5 terminals
   - Check core assignments

2. Error Cases
   - Invalid core numbers
   - Process access denied
   - Log write failures

3. Stability
   - Run multiple terminals
   - Check assignment stability
   - Monitor logs
