# MTOptimizer Code Improvement Plan

## Current Code Analysis

### Strengths
1. Basic functionality works
2. Core detection implemented
3. Process monitoring in place
4. Basic logging exists

### Areas for Improvement

1. Core Assignment Logic
```powershell
# Current: Complex core selection with many parameters
# Simplify to:
function Select-NextCore {
    param($TotalCores)
    $NextCore = ($script:LastCore + 1) % $TotalCores
    return $NextCore
}
```

2. Process State Tracking
```powershell
# Current: Complex state management classes
# Simplify to:
$ProcessAssignments = @{
    LastCore = 0
    Assignments = @{}  # ProcessId -> @{Core, Time}
}
```

3. Error Handling
```powershell
# Current: Scattered try-catch blocks
# Consolidate to:
function Handle-Error {
    param($Operation, $Error)
    Write-Log "Error during $Operation: $Error"
    if ($Operation -eq "Assignment") {
        Reset-TerminalAffinity
    }
}
```

## Implementation Steps

### Phase 1: Core Logic Cleanup
1. Replace complex CoreOptimizer class with simple functions
2. Implement basic round-robin core selection
3. Add 5-minute stability check
4. Remove unnecessary state tracking

### Phase 2: Process Management
1. Simplify process detection
2. Add basic error recovery
3. Improve affinity assignment
4. Add simple status reporting

### Phase 3: Installation/Cleanup
1. Streamline installation process
2. Add basic uninstallation
3. Improve error messages
4. Add simple backup/restore

## Code Changes

### 1. Main Script Structure
```powershell
# Configuration
$Config = @{
    MaxPerCore = 2
    StabilityMinutes = 5
    CheckIntervalSeconds = 30
}

# State
$State = @{
    LastCore = 0
    LastAssignment = Get-Date
    Processes = @{}
}

# Main loop
while ($true) {
    try {
        Update-Terminals
        Start-Sleep -Seconds $Config.CheckIntervalSeconds
    } catch {
        Handle-Error "MainLoop" $_
    }
}
```

### 2. Core Functions
```powershell
function Update-Terminals {
    $terminals = Get-Process | Where-Object { $_.ProcessName -eq "terminal" }
    foreach ($terminal in $terminals) {
        if (Need-Assignment $terminal) {
            Set-TerminalCore $terminal
        }
    }
}

function Need-Assignment {
    param($Terminal)
    if (-not $State.Processes[$Terminal.Id]) {
        return $true
    }
    $lastAssign = $State.Processes[$Terminal.Id].Time
    return (Get-Date).Subtract($lastAssign).TotalMinutes -gt $Config.StabilityMinutes
}

function Set-TerminalCore {
    param($Terminal)
    try {
        $core = Get-NextCore
        $Terminal.ProcessorAffinity = [IntPtr](1 -shl $core)
        $State.Processes[$Terminal.Id] = @{
            Core = $core
            Time = Get-Date
        }
        Write-Log "Assigned terminal $($Terminal.Id) to core $core"
    } catch {
        Handle-Error "Assignment" $_
    }
}
```

### 3. Installation Improvements
```powershell
function Install-MTOptimizer {
    # Basic checks
    if (-not (Test-Prerequisites)) {
        return
    }

    # Cleanup old version
    Remove-OldVersion

    # Setup new version
    try {
        Copy-Files
        Set-AutoStart
        Start-Optimizer
        Write-Log "Installation successful"
    } catch {
        Handle-Error "Installation" $_
        Rollback-Installation
    }
}

function Test-Prerequisites {
    # Admin rights
    if (-not (Test-AdminRights)) {
        Write-Log "Error: Administrator rights required"
        return $false
    }
    
    # Paths
    if (-not (Test-InstallPaths)) {
        Write-Log "Error: Invalid installation paths"
        return $false
    }
    
    return $true
}
```

## Testing Plan

1. Basic Functionality
   - Start/stop optimizer
   - Core assignment
   - Process monitoring

2. Error Handling
   - Process termination
   - Access denied
   - Invalid states

3. Installation
   - Clean install
   - Upgrade
   - Uninstall

## Timeline

1. Week 1: Core Logic
   - Implement simplified core selection
   - Add basic state management
   - Test core functionality

2. Week 2: Process Management
   - Add error handling
   - Improve logging
   - Test process handling

3. Week 3: Installation
   - Update installer
   - Add uninstaller
   - Final testing

## Success Metrics

1. Stability
   - No random core changes
   - Consistent assignments
   - Clean error recovery

2. Performance
   - Quick terminal detection
   - Efficient core assignment
   - Low resource usage

3. Usability
   - Clear error messages
   - Simple configuration
   - Easy installation/removal