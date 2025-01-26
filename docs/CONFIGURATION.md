# Configuration Guide

This document details the simple configuration options for the MT4/MT5 Core Optimizer.

## Core Settings

The optimizer uses a basic configuration based on CPU core count:

```powershell
$Config = @{
    2 = @{ MaxPerCore = 3; Threshold = 75 }
    4 = @{ MaxPerCore = 2; Threshold = 70 }
    6 = @{ MaxPerCore = 2; Threshold = 65 }
    8 = @{ MaxPerCore = 2; Threshold = 60 }
}
```

### Settings Explained

#### MaxPerCore
- Maximum MT4/MT5 terminals per CPU core
- Higher values = more terminals, lower performance
- Lower values = fewer terminals, better performance
- Default: 2-3 terminals per core

#### Threshold
- Maximum CPU usage percentage per core
- Higher values allow more intensive usage
- Lower values ensure smoother operation
- Default: 60-75% based on cores

## Basic Configuration

To modify settings:

1. Stop the optimizer
2. Edit `C:\Program Files\MTOptimizer\optimizer.ps1`
3. Change values in `$Config`
4. Save and restart

## Example Configurations

### Performance Focus
```powershell
$Config = @{
    2 = @{ MaxPerCore = 2; Threshold = 65 }
    4 = @{ MaxPerCore = 1; Threshold = 60 }
    6 = @{ MaxPerCore = 1; Threshold = 55 }
    8 = @{ MaxPerCore = 1; Threshold = 50 }
}
```
- Better performance per terminal
- Lower CPU usage
- Smoother operation

### Capacity Focus
```powershell
$Config = @{
    2 = @{ MaxPerCore = 4; Threshold = 80 }
    4 = @{ MaxPerCore = 3; Threshold = 75 }
    6 = @{ MaxPerCore = 3; Threshold = 70 }
    8 = @{ MaxPerCore = 3; Threshold = 65 }
}
```
- More terminals per core
- Higher CPU usage allowed
- Maximum capacity

## Basic Settings

### Check Interval
```powershell
Start-Sleep -Seconds 30  # How often to check terminals
```
- Default: 30 seconds
- Lower = more responsive
- Higher = less overhead

### Log Settings
```powershell
$LogPath = "C:\Windows\Logs\MTOptimizer"
$LogFile = "optimizer.log"
```
- Simple log file location
- Basic error logging
- Status messages

### Installation
```powershell
$InstallPath = "C:\Program Files\MTOptimizer"
$AutoStart = $true
```
- Standard install location
- Auto-start with Windows

## Best Practices

1. Start Simple
   - Use default configuration
   - Monitor performance
   - Adjust if needed

2. Performance Tips
   - Start with fewer terminals
   - Increase gradually
   - Watch CPU usage

3. Maintenance
   - Check logs regularly
   - Clear old logs
   - Monitor stability

4. Troubleshooting
   - Check error messages
   - Verify settings
   - Reset to defaults if needed
