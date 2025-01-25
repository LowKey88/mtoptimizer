# MT4/MT5 Core Optimizer - Technical Improvements

## Current Issues

### 1. Log File Access
Problem: Log file is being locked, preventing read access
Root Cause: Continuous file access without proper stream management
Solution:
- Implement proper file stream handling with `using` blocks
- Add file rotation with exclusive access periods
- Implement a separate logging queue to batch writes

### 2. CPU Core Assignment Instability
Problem: Random core changes affecting terminal performance
Root Cause: Oversensitive core selection algorithm
Solution:
- Add hysteresis to prevent frequent core changes
- Implement minimum time threshold between reassignments
- Consider historical core assignments
- Separate instance count and CPU usage priorities

## Architectural Improvements

### 1. Enhanced Core Selection Algorithm
```powershell
function Get-BestCore {
    param (
        [hashtable]$CoreUsage,
        [hashtable]$ProcessedPIDs,
        [hashtable]$CoreHistory
    )
    
    # First: Check historical assignment
    if ($CoreHistory -and (Get-Date).Subtract($CoreHistory.LastChange).TotalMinutes -lt 5) {
        return $CoreHistory.LastCore
    }
    
    # Second: Find cores under threshold
    $AvailableCores = $CoreUsage.Keys | Where-Object { 
        $CoreUsage[$_] -lt ($MaxCoreUsageThreshold - 10) # Add hysteresis
    }
    
    # Third: Check instance limits separately
    $ValidCores = $AvailableCores | Where-Object {
        (Get-CoreInstanceCount -ProcessedPIDs $ProcessedPIDs -CoreID $_) -lt $InstancesPerCore
    }
    
    if ($ValidCores) {
        # Sort by instance count first, then by usage
        return ($ValidCores | 
            Sort-Object { 
                Get-CoreInstanceCount -ProcessedPIDs $ProcessedPIDs -CoreID $_ 
            } | 
            Select-Object -First 1)
    }
    
    # Fallback: Least loaded core with minimum reassignment time
    return ($CoreUsage.Keys | 
        Where-Object { 
            -not $CoreHistory -or 
            (Get-Date).Subtract($CoreHistory.LastChange).TotalMinutes -ge 5 
        } |
        Sort-Object { $CoreUsage[$_] } | 
        Select-Object -First 1)
}
```

### 2. Improved Logging System
```powershell
# Logging queue for batched writes
$LogQueue = New-Object System.Collections.Queue
$LogFlushInterval = 30 # seconds
$LastLogFlush = Get-Date

function Write-LogMessage {
    param(
        [string]$Message,
        [switch]$Important
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$TimeStamp - $Message"
    
    # Add to queue instead of writing directly
    $LogQueue.Enqueue($LogMessage)
    
    # Flush if important or interval reached
    if ($Important -or (Get-Date).Subtract($LastLogFlush).TotalSeconds -ge $LogFlushInterval) {
        Flush-LogQueue
    }
}

function Flush-LogQueue {
    if ($LogQueue.Count -eq 0) { return }
    
    try {
        # Use a mutex for thread-safe file access
        $mutex = New-Object System.Threading.Mutex($false, "MTOptimizerLogMutex")
        $mutex.WaitOne() | Out-Null
        
        # Batch write all queued messages
        $messages = @()
        while ($LogQueue.Count -gt 0) {
            $messages += $LogQueue.Dequeue()
        }
        
        Add-Content -Path $LogFile -Value $messages
        $LastLogFlush = Get-Date
    }
    finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}
```

### 3. Core History Tracking
```powershell
$CoreHistory = @{
    LastCore = $null
    LastChange = [DateTime]::MinValue
    Changes = @{}
}

function Update-CoreHistory {
    param(
        [int]$CoreID,
        [int]$ProcessID
    )
    
    $CoreHistory.LastCore = $CoreID
    $CoreHistory.LastChange = Get-Date
    
    if (-not $CoreHistory.Changes.ContainsKey($ProcessID)) {
        $CoreHistory.Changes[$ProcessID] = @()
    }
    
    $CoreHistory.Changes[$ProcessID] += @{
        Time = Get-Date
        Core = $CoreID
    }
    
    # Cleanup old history
    $CoreHistory.Changes = $CoreHistory.Changes.Clone()
    foreach ($pid in $CoreHistory.Changes.Keys) {
        $CoreHistory.Changes[$pid] = $CoreHistory.Changes[$pid] |
            Where-Object { 
                (Get-Date).Subtract($_.Time).TotalHours -lt 1 
            }
    }
}
```

## Implementation Steps

1. Update the core selection logic to include hysteresis and history
2. Implement the new logging system with queued writes
3. Add core history tracking to prevent frequent reassignments
4. Update the main loop to use these new components

## Expected Benefits

1. More stable core assignments
   - Minimum 5-minute threshold between changes
   - Historical assignment consideration
   - Hysteresis in CPU threshold checks

2. Improved logging reliability
   - No file locking issues
   - Batched writes for better performance
   - Thread-safe file access

3. Better resource utilization
   - More intelligent core selection
   - Reduced overhead from frequent changes
   - Better load distribution

## Monitoring and Maintenance

1. Core stability metrics
   - Track frequency of core changes
   - Monitor duration of assignments
   - Log load distribution patterns

2. Performance indicators
   - CPU usage per core
   - Number of terminals per core
   - Core change frequency

3. Log file management
   - Automatic rotation
   - Size-based cleanup
   - Access monitoring
