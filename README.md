# MT4/MT5 Core Optimizer

A PowerShell-based CPU core optimization tool specifically designed for MetaTrader 4 and MetaTrader 5 trading terminals. This tool intelligently manages CPU core affinity to optimize performance and prevent terminal overload on multi-core systems.

## Features

- **Intelligent Core Allocation**: Dynamically assigns MT4/MT5 terminals to specific CPU cores based on current usage and load
- **Adaptive Configuration**: Automatically adjusts settings based on the number of available CPU cores
- **Load Balancing**: Prevents CPU core saturation by distributing terminals across available cores
- **Real-time Monitoring**: Continuously monitors process status and core usage
- **Automatic Recovery**: Handles process termination and maintains optimal core distribution
- **Detailed Logging**: Comprehensive logging system for troubleshooting and monitoring
- **Auto-start Capability**: Automatically starts with Windows
- **Safe Cleanup**: Proper cleanup of core affinities on service stop

## System Requirements

- Windows 7/8/10/11
- PowerShell 5.1 or later
- Administrator privileges
- MetaTrader 4 or MetaTrader 5 terminal(s)

## Installation

1. Download `Install-MTOptimizer.ps1`
2. Right-click the file and select "Run with PowerShell"
3. If prompted, click "Yes" to allow administrator access

The script will automatically:
- Create necessary directories
- Configure auto-start settings
- Start the optimization service

## Configuration

The optimizer automatically configures itself based on your CPU cores:

| CPU Cores | Instances Per Core | CPU Usage Threshold |
|-----------|-------------------|-------------------|
| 2 cores   | 3 instances      | 75%              |
| 4 cores   | 3 instances      | 75%              |
| 6 cores   | 3 instances      | 75%              |
| 8+ cores  | 3 instances      | 75%              |

For systems with different core counts, it defaults to:
- 3 instances per core
- 75% CPU usage threshold

The optimizer will:
- Assign terminals evenly across available cores
- Monitor CPU usage to prevent overload
- Dynamically adjust assignments based on system load
- Continue optimizing beyond initial assignments when capacity is available

## Logging

Logs are stored in `C:\Windows\Logs\MTOptimizer\core_optimizer.log` and include:
- Core assignments
- Process changes
- Error messages
- Service start/stop events

## Important Notes

- **Administrator Rights**: The script requires administrator privileges to manage core affinities
- **Auto-start**: The optimizer is configured to start automatically with Windows
- **System Impact**: The tool only affects MT4/MT5 terminals and doesn't modify other processes
- **Termination**: The optimizer automatically resets all core affinities when stopped
- **Core Assignment**: Each core can handle up to 3 terminals while maintaining performance
- **Load Management**: Terminals are assigned based on current CPU usage and core capacity

## Troubleshooting

1. **Installation Fails**:
   - Ensure you're running PowerShell as Administrator
   - Check Windows Event Viewer for detailed error messages

2. **Optimizer Not Starting**:
   - Verify the service is listed in Task Manager
   - Check the log file for error messages
   - Ensure Windows PowerShell execution policy allows script execution

3. **Performance Issues**:
   - Review the log file for core allocation patterns
   - Verify your system meets the minimum requirements
   - Check if antivirus software is interfering with the process

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
