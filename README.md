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

## Detailed Installation Guide

### Download Options

1. **Direct Download**:
   - Visit [GitHub Releases](https://github.com/LowKey88/mtoptimizer/releases)
   - Download `Install-MTOptimizer.ps1` from the latest release
   - Save to a known location (e.g., Downloads folder)

2. **Using PowerShell**:
   ```powershell
   # Create directory
   New-Item -ItemType Directory -Path "$env:USERPROFILE\Downloads\MTOptimizer" -Force
   
   # Download script
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/LowKey88/mtoptimizer/main/Install-MTOptimizer.ps1" -OutFile "$env:USERPROFILE\Downloads\MTOptimizer\Install-MTOptimizer.ps1"
   ```

### Installation Steps

1. **Prepare PowerShell**:
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"
   - Verify you have administrator rights:
     ```powershell
     # Should show True
     ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
     ```

2. **Set Execution Policy**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
   ```
   - Select 'Y' when prompted

3. **Run Installation**:
   - Navigate to script location:
     ```powershell
     cd "$env:USERPROFILE\Downloads\MTOptimizer"
     ```
   - Run the script:
     ```powershell
     .\Install-MTOptimizer.ps1
     ```

4. **Verify Installation**:
   - Check service status:
     ```powershell
     Get-Process | Where-Object { $_.ProcessName -eq "mt_core_optimizer" }
     ```
   - Check log file:
     ```powershell
     Get-Content "C:\Windows\Logs\MTOptimizer\core_optimizer.log" -Tail 10
     ```

### Update Instructions

1. **Download New Version**:
   - Follow the download steps above to get the latest version

2. **Install Update**:
   - Run the new installer
   - The script will automatically:
     * Stop existing optimizer
     * Clean up old files
     * Reset terminal affinities
     * Install new version
     * Start the service

3. **Verify Update**:
   - Check log file for version:
     ```powershell
     Get-Content "C:\Windows\Logs\MTOptimizer\core_optimizer.log" -Tail 20
     ```
   - Should show new version number in startup message

## Configuration

The optimizer automatically configures itself based on your CPU cores:

| CPU Cores | Instances Per Core | CPU Usage Threshold |
|-----------|-------------------|-------------------|
| 2 cores   | 3 instances      | 75%              |
| 4 cores   | 3 instances      | 75%              |
| 6 cores   | 3 instances      | 75%              |
| 8+ cores  | 3 instances      | 75%              |

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

## Troubleshooting Guide

### 1. Installation Issues

a) **Access Denied Errors**:
   ```powershell
   # Verify administrator rights
   Start-Process powershell -Verb RunAs
   ```

b) **Execution Policy Errors**:
   ```powershell
   # Check current policy
   Get-ExecutionPolicy
   
   # Set correct policy
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
   ```

### 2. Service Not Starting

a) **Check Process**:
   ```powershell
   Get-Process | Where-Object { $_.ProcessName -eq "mt_core_optimizer" }
   ```

b) **Check Logs**:
   ```powershell
   Get-Content "C:\Windows\Logs\MTOptimizer\core_optimizer.log" -Tail 50
   ```

c) **Manual Start**:
   ```powershell
   Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File 'C:\Program Files\MTOptimizer\system\mt_core_optimizer.ps1'" -WindowStyle Hidden
   ```

### 3. Performance Issues

a) **Check Core Assignments**:
   ```powershell
   Get-Process | Where-Object { $_.ProcessName -eq "terminal" } | Select-Object Id, ProcessorAffinity
   ```

b) **Monitor CPU Usage**:
   ```powershell
   Get-Counter "\Processor(*)\% Processor Time" -SampleInterval 2 -MaxSamples 3
   ```

### 4. Clean Reinstall

If you need to completely remove and reinstall:

```powershell
# Stop service
Get-Process | Where-Object { $_.ProcessName -eq "mt_core_optimizer" } | Stop-Process -Force

# Remove files
Remove-Item "C:\Program Files\MTOptimizer" -Recurse -Force
Remove-Item "C:\Windows\Logs\MTOptimizer" -Recurse -Force

# Remove registry entry
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "MTSystemOptimizer" -ErrorAction SilentlyContinue

# Reinstall
.\Install-MTOptimizer.ps1
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
