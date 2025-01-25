# Technical Documentation

This document provides detailed technical information about the MT4/MT5 Core Optimizer's implementation and functionality.

## Core Components

### Process Detection
- Monitors running processes using `Get-Process`
- Filters for process names matching `^terminal$|^mt4$|^mt5$`
- Maintains process state in `$ProcessedPIDs` hashtable

### CPU Core Management
```powershell
$AffinityList = @()
for ($i = 0; $i -lt $TotalCores; $i++) {
   $AffinityList += [int]([math]::Pow(2, $i))
}
```
- Creates binary mask for each core (1, 2, 4, 8, etc.)
- Enables precise core affinity assignment
- Supports up to 64 logical processors

### Core Usage Monitoring
```powershell
function Get-CoreUsage {
   $CoreUsage = Get-Counter "\Processor(*)\% Processor Time"
   $UsageByCore = @{}
   foreach ($Sample in $CoreUsage) {
       if ($Sample.InstanceName -match "^\d+$") {
           $CoreID = [int]$Sample.InstanceName
           $UsageByCore[$CoreID] = $Sample.CookedValue
       }
   }
   return $UsageByCore
}
```
- Uses Windows Performance Counters
- Tracks per-core CPU utilization
- Updates every 5 seconds

## Core Allocation Strategy

### Dynamic Configuration
```powershell
$Config = @{
   1 = @{ MaxPerCore = 4; Threshold = 80 }
   2 = @{ MaxPerCore = 3; Threshold = 75 }
   4 = @{ MaxPerCore = 2; Threshold = 70 }
   6 = @{ MaxPerCore = 2; Threshold = 65 }
   8 = @{ MaxPerCore = 2; Threshold = 60 }
}
```
- Adapts to system specifications
- Balances load across available cores
- Prevents core saturation

### Process Assignment Logic
1. Identifies unassigned MT4/MT5 processes
2. Finds cores below usage threshold
3. Checks current instances per core
4. Assigns process to optimal core
5. Updates process tracking

## Installation Components

### Directory Structure
```
C:\Program Files\MTOptimizer\
└── system\
    └── mt_core_optimizer.ps1
```
- Hidden root directory
- Protected system subfolder
- Segregated script location

### Registry Integration
- Creates auto-start entry
- Path: `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`
- Key: `MTSystemOptimizer`
- Launches with hidden window

## Logging System

### Log Structure
- Timestamp
- Event type
- Process details
- Core assignments
- Error messages

### Log Location
```
C:\Windows\Logs\MTOptimizer\core_optimizer.log
```

## Safety Measures

### Cleanup Procedures
1. Registers PowerShell exit event
2. Captures termination signals
3. Resets all process affinities
4. Logs cleanup actions

### Error Handling
- Try-catch blocks for critical operations
- Detailed error logging
- Graceful service termination
- Automatic affinity reset

## Performance Considerations

### Resource Usage
- Minimal CPU overhead (~1%)
- Small memory footprint
- Efficient process monitoring
- Optimized counter polling

### Scalability
- Supports multiple MT4/MT5 instances
- Adapts to varying core counts
- Handles dynamic process creation/termination
- Maintains performance under load

## Security

### Elevation Requirements
- Requires administrator privileges
- Uses Windows security context
- Validates execution permissions
- Manages registry modifications safely

### System Integration
- Safe installation process
- Protected file locations
- Secure registry modifications
- Controlled process manipulation
