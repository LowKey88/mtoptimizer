# MT4/MT5 Core Optimizer - Visual Installation Guide

## Installation Steps

### 1. Download and Prepare
```
Desktop/
└── MTOptimizer/
    ├── Install-MTOptimizer.ps1
    └── Uninstall-MTOptimizer.ps1
```

### 2. Run Installer
```
Right-click Menu:
┌─────────────────────────┐
│ Open                    │
│ Open with >            │
│ Run with PowerShell     │ ← Select this
│ Run as administrator    │
│ Cut                     │
│ Copy                    │
└─────────────────────────┘
```

### 3. Security Prompt
```
┌─────────────────────────────────────────┐
│ Windows Protected Your PC                │
│                                         │
│ Running scripts can be dangerous...      │
│                                         │
│ [More info]                             │
│ [Run anyway]  ← Click this              │
└─────────────────────────────────────────┘
```

### 4. Admin Rights
```
┌─────────────────────────────────────────┐
│ User Account Control                     │
│                                         │
│ Do you want to allow this app to make   │
│ changes to your device?                 │
│                                         │
│ [Yes]  ← Click this    [No]             │
└─────────────────────────────────────────┘
```

### 5. Installation Progress
```
MT4/MT5 Core Optimizer v2.0.3 Installation
----------------------------------------
Checking for existing installation...
Creating directories...
Installing optimizer script...
Configuring auto-start...
Starting optimizer...
----------------------------------------
MT4/MT5 Core Optimizer installed successfully
CPU Cores: 4
```

### 6. Verify Installation
```
C:\Program Files\MTOptimizer\
├── mt_core_optimizer.ps1
└── system/

C:\Windows\Logs\MTOptimizer\
└── optimizer.log
```

## Uninstallation Steps

### 1. Run Uninstaller
```
Right-click Menu:
┌─────────────────────────┐
│ Open                    │
│ Open with >            │
│ Run with PowerShell     │ ← Select this
│ Run as administrator    │
│ Cut                     │
│ Copy                    │
└─────────────────────────┘
```

### 2. Uninstallation Progress
```
MT4/MT5 Core Optimizer Uninstaller
--------------------------------
Stopping optimizer processes...
Resetting terminal affinities...
Removing auto-start configuration...
Removing files and directories...
--------------------------------
Uninstallation complete.
```

## Common Messages

### Success Messages
```
2025-01-26 09:00:00 - MT4/MT5 Core Optimizer Started
2025-01-26 09:00:30 - Assigned terminal 1234 to core 0
2025-01-26 09:01:00 - Assigned terminal 5678 to core 1
```

### Error Messages
```
Error: Administrator rights required
Warning: Could not stop process 1234
Error: Could not create directory
```

## File Locations

### Installation Files
```
C:\Program Files\MTOptimizer\
├── mt_core_optimizer.ps1  ← Main script
└── system/               ← System files

C:\Windows\Logs\MTOptimizer\
└── optimizer.log         ← Activity log
```

### Registry Entry
```
Path: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
Name: MTSystemOptimizer
Type: String
Data: powershell -WindowStyle Hidden -File "C:\Program Files\MTOptimizer\mt_core_optimizer.ps1"