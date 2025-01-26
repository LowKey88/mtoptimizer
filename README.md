# MT4/MT5 Core Optimizer

A simple PowerShell script to optimize CPU core usage for MetaTrader 4 and 5 terminals by managing process affinity.

## Features

- Automatic CPU core detection
- Simple round-robin core assignment
- Stable terminal-to-core allocation
- Basic load monitoring
- Clear error handling

## Requirements

- Windows Operating System
- Administrator rights
- PowerShell
- MetaTrader 4 or 5 terminal

## Detailed Installation Guide

### Step 1: Download
1. Create a new folder on your Desktop named "MTOptimizer"
2. Download these files into the folder:
   - Install-MTOptimizer.ps1
   - Uninstall-MTOptimizer.ps1

### Step 2: Prepare Installation
1. Close all MetaTrader terminals
2. Open Windows Task Manager (Ctrl+Shift+Esc)
3. Check if any "terminal.exe" processes are running
4. If found, right-click and select "End Task"

### Step 3: Run Installer
1. Right-click on "Install-MTOptimizer.ps1"
2. Select "Run with PowerShell"
3. If you see a security warning:
   - Click "More info"
   - Click "Run anyway"
4. When prompted for Administrator rights:
   - Click "Yes"

### Step 4: Verify Installation
1. Check these locations exist:
   - C:\Program Files\MTOptimizer
   - C:\Windows\Logs\MTOptimizer
2. Open the log file:
   - Navigate to C:\Windows\Logs\MTOptimizer
   - Open optimizer.log
   - You should see "Optimizer Started" message

### Step 5: Test Installation
1. Start your MetaTrader terminal
2. Wait 30 seconds
3. Check optimizer.log - you should see core assignment message

The installation will:
- Create necessary directories
- Install the optimizer service
- Start core optimization automatically
- Configure auto-start on Windows startup

## How It Works

The optimizer:
1. Detects available CPU cores
2. Monitors MT4/MT5 terminals
3. Assigns each terminal to a specific core
4. Maintains assignments for 5 minutes for stability
5. Uses round-robin assignment for new terminals

## Core Configuration

The optimizer automatically adjusts its settings based on your CPU:

- 2 cores: 3 terminals per core, 75% threshold
- 4 cores: 2 terminals per core, 70% threshold
- 6 cores: 2 terminals per core, 65% threshold
- 8 cores: 2 terminals per core, 60% threshold

For detailed configuration information, see:
- [Core Configuration Guide](docs/CORE_CONFIG.md)

The settings are automatically detected and applied at startup.
## Monitoring

The optimizer logs its activity to:
```
C:\Windows\Logs\MTOptimizer\optimizer.log
```

Important messages include:
- Terminal assignments
- Error conditions
- Status updates

## Detailed Uninstallation Guide

### Step 1: Prepare Uninstallation
1. Close all MetaTrader terminals
2. Open Task Manager
3. End any running "terminal.exe" processes

### Step 2: Run Uninstaller
1. Right-click on "Uninstall-MTOptimizer.ps1"
2. Select "Run with PowerShell"
3. Click "Yes" for Administrator rights
4. Wait for completion message

### Step 3: Verify Uninstallation
1. Check these locations are removed:
   - C:\Program Files\MTOptimizer
   - C:\Windows\Logs\MTOptimizer
2. Optional: Restart computer

The uninstaller will:
- Stop all optimizer processes
- Reset terminal CPU assignments
- Remove all files and settings
- Clean registry entries

## What Gets Installed
The script will:
- Stop the optimizer
- Reset all terminal affinities
- Remove all files and settings
- Clean up registry entries

## Troubleshooting

### Installation Issues
1. "PowerShell security error":
   - Right-click script
   - Properties
   - Check "Unblock" box
   - Click Apply

2. "Access Denied":
   - Make sure you clicked "Yes" for admin rights
   - Try right-click > Run as Administrator

3. "Script won't run":
   - Open PowerShell as Administrator
   - Run: Set-ExecutionPolicy Bypass
   - Type Y and press Enter

### Runtime Issues
1. "Terminals not assigned":
   - Open optimizer.log
   - Look for error messages
   - Verify process name is "terminal.exe"
   - Try restarting terminal

2. "High CPU usage":
   - Check number of terminals per core
   - Look for core assignments in log
   - Restart the optimizer if needed

3. "Optimizer not starting":
   - Check C:\Windows\Logs\MTOptimizer exists
   - Verify you have admin rights
   - Try uninstall and reinstall

## License

See LICENSE file for details.
