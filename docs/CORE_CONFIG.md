# Core-Based Configuration Guide

## CPU Core Configuration Matrix

The MT4/MT5 Core Optimizer automatically adjusts its settings based on the number of CPU cores in your system:

| CPU Cores | Max Terminals Per Core | CPU Threshold |
|-----------|----------------------|---------------|
| 2 cores   | 3 terminals         | 75%           |
| 4 cores   | 2 terminals         | 70%           |
| 6 cores   | 2 terminals         | 65%           |
| 8 cores   | 2 terminals         | 60%           |

### How It Works

1. On startup, the optimizer:
   - Detects your CPU's core count
   - Applies the matching configuration
   - Logs the selected settings

2. For example, on an 8-core CPU:
   - Maximum 2 terminals per core
   - CPU usage threshold of 60%
   - Total capacity: 16 terminals (8 cores × 2 terminals)

### Configuration Logic

```powershell
# Core configuration matrix
$CoreConfigs = @{
    2 = @{ MaxPerCore = 3; CPUThreshold = 75 }
    4 = @{ MaxPerCore = 2; CPUThreshold = 70 }
    6 = @{ MaxPerCore = 2; CPUThreshold = 65 }
    8 = @{ MaxPerCore = 2; CPUThreshold = 60 }
}
```

### Default Settings

If your CPU core count doesn't match the matrix:
- Max Terminals Per Core: 2
- CPU Threshold: 70%

## Configuration Details

### Max Terminals Per Core
- Controls how many MT4/MT5 terminals can run on each core
- Higher core counts use lower values for stability
- 2-core systems allow more terminals per core due to typical usage patterns

### CPU Threshold
- Maximum allowed CPU usage percentage per core
- Lower thresholds on higher core counts for better stability
- Helps prevent system overload

## Monitoring

You can check the active configuration in the log file:
```
C:\Windows\Logs\MTOptimizer\optimizer.log
```

Look for this message at startup:
```
Using configuration for X cores: Max Y terminals per core, Z% threshold
```

## Best Practices

1. For 2-Core Systems:
   - Maximum 6 terminals total (3 per core)
   - Monitor CPU usage closely
   - Consider closing other applications

2. For 4-Core Systems:
   - Maximum 8 terminals total (2 per core)
   - Good balance of performance and capacity
   - Standard configuration for most users

3. For 6-Core Systems:
   - Maximum 12 terminals total (2 per core)
   - Lower threshold for better stability
   - Ideal for medium workloads

4. For 8-Core Systems:
   - Maximum 16 terminals total (2 per core)
   - Conservative threshold for reliability
   - Perfect for heavy workloads

## Performance Tips

1. Monitor System Load:
   - Check optimizer.log for assignments
   - Watch CPU usage in Task Manager
   - Look for stability issues

2. Adjust Terminal Count:
   - Start with fewer terminals
   - Add more gradually
   - Monitor performance impact

3. System Optimization:
   - Close unnecessary applications
   - Keep Windows updated
   - Monitor system resources