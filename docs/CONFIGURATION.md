# Configuration Guide

This document details the configuration options and customization possibilities for the MT4/MT5 Core Optimizer.

## Default Configuration

The optimizer uses a predefined configuration based on CPU core count:

```powershell
$Config = @{
   1 = @{ MaxPerCore = 4; Threshold = 80 }
   2 = @{ MaxPerCore = 3; Threshold = 75 }
   4 = @{ MaxPerCore = 2; Threshold = 70 }
   6 = @{ MaxPerCore = 2; Threshold = 65 }
   8 = @{ MaxPerCore = 2; Threshold = 60 }
}
```

### Configuration Parameters

#### MaxPerCore
- Defines maximum MT4/MT5 instances allowed per CPU core
- Higher values allow more terminals per core
- Lower values provide better performance per terminal
- Default ranges from 2-4 based on core count

#### Threshold
- Maximum CPU usage percentage per core
- New terminals assigned only when core usage below threshold
- Higher thresholds allow more intensive usage
- Lower thresholds ensure smoother operation
- Default ranges from 60-80% based on core count

## Custom Configuration

To modify the default configuration:

1. Stop the optimizer service
2. Navigate to `C:\Program Files\MTOptimizer\system\`
3. Edit `mt_core_optimizer.ps1`
4. Locate the `$Config` hashtable
5. Modify values as needed
6. Save and restart the service

### Example Custom Configurations

#### High-Performance Configuration
```powershell
$Config = @{
   1 = @{ MaxPerCore = 3; Threshold = 70 }
   2 = @{ MaxPerCore = 2; Threshold = 65 }
   4 = @{ MaxPerCore = 1; Threshold = 60 }
   6 = @{ MaxPerCore = 1; Threshold = 55 }
   8 = @{ MaxPerCore = 1; Threshold = 50 }
}
```
- Prioritizes performance per terminal
- Reduces instances per core
- Lower thresholds for smoother operation

#### High-Density Configuration
```powershell
$Config = @{
   1 = @{ MaxPerCore = 5; Threshold = 85 }
   2 = @{ MaxPerCore = 4; Threshold = 80 }
   4 = @{ MaxPerCore = 3; Threshold = 75 }
   6 = @{ MaxPerCore = 3; Threshold = 70 }
   8 = @{ MaxPerCore = 3; Threshold = 65 }
}
```
- Maximizes number of terminals
- Higher instances per core
- Higher thresholds for maximum utilization

## Advanced Settings

### Polling Interval
```powershell
Start-Sleep -Seconds 5  # Default polling interval
```
- Controls how often CPU usage is checked
- Lower values provide more responsive allocation
- Higher values reduce system overhead
- Default: 5 seconds

### Process Detection
```powershell
$Processes = Get-Process | Where-Object { $_.ProcessName -match "^terminal$|^mt4$|^mt5$" }
```
- Regex pattern determines which processes are managed
- Can be modified to include/exclude specific terminal versions
- Default matches standard MT4/MT5 process names

### Logging Configuration
```powershell
$LogPath = "C:\Windows\Logs\MTOptimizer"
$LogFile = Join-Path $LogPath "core_optimizer.log"
```
- Customize log location and filename
- Modify logging detail level
- Configure log rotation/cleanup

## Installation Options

### Registry Configuration
```powershell
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
```
- Controls auto-start behavior
- Can be modified for different startup methods
- Supports custom startup parameters

### Installation Paths
```powershell
$optimizerPath = "C:\Program Files\MTOptimizer"
$hiddenPath = "$optimizerPath\system"
```
- Customize installation location
- Modify system integration
- Configure file protection settings

## Best Practices

### Performance Optimization
1. Start with default configuration
2. Monitor system performance
3. Adjust thresholds based on CPU usage patterns
4. Fine-tune instances per core based on trading needs
5. Consider system resources used by other applications

### Security Considerations
1. Maintain administrator privileges
2. Protect configuration files
3. Monitor log files for issues
4. Regular backup of custom configurations
5. Document any configuration changes

### Troubleshooting
1. Check log files for errors
2. Verify process detection
3. Monitor core allocation patterns
4. Test different configurations
5. Reset to defaults if issues occur
