# MTOptimizer Architecture Review

## Core Functionality
The MTOptimizer should focus on its primary purpose:
1. Detect CPU cores
2. Monitor MT4/MT5 terminals
3. Assign terminals to cores based on simple rules
4. Maintain stable core assignments

## Identified Issues

### 1. Core Assignment
- Random core changes affecting terminal performance
- No minimum time between reassignments
- Missing simple load balancing

### 2. Installation/Uninstallation
- Missing basic error handling
- No cleanup on uninstall
- Incomplete process termination

### 3. Monitoring
- Basic logging needs improvement
- No simple status reporting
- Missing error notifications

## Simple Solutions

### 1. Core Assignment
- Keep terminals on same core for at least 5 minutes
- Simple round-robin assignment for new terminals
- Basic load check before assignment

Example:
```powershell
# Simple core selection
function Select-NextCore {
    param($LastCore, $TotalCores)
    
    # Round-robin selection
    $NextCore = if ($LastCore -ge ($TotalCores - 1)) { 0 } else { $LastCore + 1 }
    
    # Basic load check
    $Usage = Get-Counter "\Processor($NextCore)\% Processor Time"
    if ($Usage.CounterSamples.CookedValue -gt 75) {
        # Try next core if too busy
        $NextCore = if ($NextCore -ge ($TotalCores - 1)) { 0 } else { $NextCore + 1 }
    }
    
    return $NextCore
}
```

### 2. Installation
- Basic error checks
- Simple file cleanup
- Clear success/failure messages

Example:
```powershell
# Basic installation checks
function Test-InstallPrereqs {
    # Check admin rights
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
    if (-not $IsAdmin) {
        Write-Host "Error: Administrator rights required"
        return $false
    }
    
    # Check install path
    if (-not (Test-Path "C:\Program Files")) {
        Write-Host "Error: Invalid installation path"
        return $false
    }
    
    return $true
}
```

### 3. Monitoring
- Simple log file
- Basic error reporting
- Clear status messages

Example:
```powershell
# Simple logging
function Write-OptimizeLog {
    param($Message)
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Add-Content "C:\Windows\Logs\MTOptimizer\optimizer.log"
    
    # Also write important messages to console
    if ($Message -match "Error|Warning|Success") {
        Write-Host "$Timestamp - $Message"
    }
}
```

## Testing Needs
1. Basic functionality
   - Core detection works
   - Terminal assignment works
   - Load monitoring works

2. Installation/uninstallation
   - Clean install works
   - Clean uninstall works
   - Error messages clear

3. Stability checks
   - Runs without errors
   - Handles restarts
   - Basic recovery works

## Next Steps
1. Simplify core assignment logic
2. Add basic error handling
3. Create uninstall script
4. Improve basic logging
5. Test core functionality
