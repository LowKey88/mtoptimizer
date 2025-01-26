# Core-Based Configuration Guide

## VPS Plan Optimization

The MT4/MT5 Core Optimizer is specifically optimized for VPS Forex plans with standardized resource allocation:

| VPS Plan     | CPU Cores | Total Terminals | Terminals Per Core | CPU Threshold |
|--------------|-----------|-----------------|-------------------|---------------|
| Forex Lite   | 2 cores   | 6 terminals     | 3 terminals      | 75%           |
| Forex Pro    | 4 cores   | 12 terminals    | 3 terminals      | 75%           |
| Forex Plus   | 6 cores   | 18 terminals    | 3 terminals      | 75%           |
| Forex Max    | 8 cores   | 18 terminals    | 3 terminals      | 75%           |

### How It Works

1. On startup, the optimizer:
   - Detects your CPU's core count
   - Applies the standardized configuration
   - Enforces VPS plan terminal limits
   - Logs the active settings

2. For example, on a VPS Forex Pro (4 cores):
   - 3 terminals per core
   - CPU usage threshold of 75%
   - Total capacity: 12 terminals (4 cores × 3 terminals)

### Configuration Logic

```powershell
# Core configuration matrix
$CoreConfigs = @{
    2 = @{ MaxPerCore = 3; CPUThreshold = 75 }  # VPS Forex Lite
    4 = @{ MaxPerCore = 3; CPUThreshold = 75 }  # VPS Forex Pro
    6 = @{ MaxPerCore = 3; CPUThreshold = 75 }  # VPS Forex Plus
    8 = @{ MaxPerCore = 3; CPUThreshold = 75 }  # VPS Forex Max
}
```

### Standardized Settings

All VPS plans use consistent settings:
- 3 Terminals Per Core
- 75% CPU Threshold
- 25% CPU Headroom for system tasks

## Configuration Details

### Terminals Per Core
- Standard 3 terminals per core across all plans
- Consistent performance per terminal
- Predictable resource allocation
- Easy capacity planning

### CPU Threshold
- Unified 75% threshold for all configurations
- Consistent 25% system headroom
- Balanced performance and stability
- Reliable terminal operation

## Monitoring

You can check the active configuration in the log file:
```
C:\Windows\Logs\MTOptimizer\optimizer.log
```

Look for these messages:
```
Using configuration for X cores: Max 3 terminals per core, 75% threshold
Terminal count changed: [old] -> [new]
Terminal [ID] assigned to core [number]
```

## Best Practices

1. For VPS Forex Lite (2 Cores):
   - Maximum 6 terminals total
   - Monitor CPU usage
   - Close unnecessary applications

2. For VPS Forex Pro (4 Cores):
   - Maximum 12 terminals total
   - Good balance of performance and capacity
   - Ideal for medium workloads

3. For VPS Forex Plus (6 Cores):
   - Maximum 18 terminals total
   - Perfect for larger workloads
   - Optimal terminal distribution

4. For VPS Forex Max (8 Cores):
   - Maximum 18 terminals total (limited)
   - Highest performance configuration
   - Best for intensive trading

## Performance Tips

1. Monitor System Load:
   - Check optimizer.log for assignments
   - Watch CPU usage in Task Manager
   - Monitor terminal performance

2. Terminal Management:
   - Stay within VPS plan limits
   - Monitor terminal resource usage
   - Check core assignments

3. System Optimization:
   - Close unnecessary applications
   - Keep Windows updated
   - Monitor system resources
   - Regular log review