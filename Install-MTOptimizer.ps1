# Install-MTOptimizer.ps1
#
# Description: PowerShell script to optimize CPU core usage for MetaTrader terminals
# by managing process affinity. This ensures optimal distribution of terminal processes
# across available CPU cores to prevent overload and maintain performance.

# Script Version
$ScriptVersion = "1.2.3"

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    Start-Process powershell -Verb runAs -ArgumentList "& '$($myinvocation.mycommand.definition)'"
    Break
}

$optimizerPath = "C:\Program Files\MTOptimizer"
$hiddenPath = "$optimizerPath\system"
$logPath = "C:\Windows\Logs\MTOptimizer"
$versionFile = "$hiddenPath\version.txt"
$maxLogSizeMB = 10
$logRetentionCount = 5

# Clean up old installation
function Remove-OldInstallation {
    Write-Host "Checking for existing installation..."
    
    # Stop existing service
    $processName = "mt_core_optimizer"
    $existingProcess = Get-Process | Where-Object { $_.ProcessName -eq $processName -or $_.Path -like "*$processName*" }
    if ($existingProcess) {
        Write-Host "Stopping existing optimizer process..."
        $existingProcess | ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force
                Write-Host "Stopped process ID: $($_.Id)"
            }
            catch {
                Write-Host "Warning: Could not stop process ID: $($_.Id)"
            }
        }
    }

    # Reset any existing terminal affinities
    Get-Process | Where-Object { $_.ProcessName -eq "terminal" } | ForEach-Object {
        try {
            $_.ProcessorAffinity = [IntPtr]::new(-1)
            Write-Host "Reset affinity for terminal PID: $($_.Id)"
        }
        catch {
            Write-Host "Warning: Could not reset affinity for PID: $($_.Id)"
        }
    }

    # Remove old files
    if (Test-Path $optimizerPath) {
        Write-Host "Removing old installation files..."
        Remove-Item $optimizerPath -Recurse -Force
    }

    # Remove auto-start registry entry
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Get-ItemProperty -Path $regPath -Name "MTSystemOptimizer" -ErrorAction SilentlyContinue) {
        Write-Host "Removing old auto-start configuration..."
        Remove-ItemProperty -Path $regPath -Name "MTSystemOptimizer"
    }
}

$optimizerScript = @'
# Script Version
$ScriptVersion = "1.2.3"

# Get CPU info
$Processor = Get-CimInstance -ClassName Win32_Processor
$TotalCores = ($Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

# Create affinity list with integer values
$AffinityList = @()
for ($i = 0; $i -lt $TotalCores; $i++) {
    $AffinityList += [int]([math]::Pow(2, $i))
}

# Core settings
$Config = @{
    2 = @{ MaxPerCore = 3; CPUThreshold = 75 }  # CPU 0 and CPU 1, 3 terminals each
    4 = @{ MaxPerCore = 3; CPUThreshold = 75 }  # CPU 0-3, 3 terminals each
    6 = @{ MaxPerCore = 3; CPUThreshold = 75 }  # CPU 0-5, 3 terminals each
    8 = @{ MaxPerCore = 3; CPUThreshold = 75 }  # CPU 0-7, 3 terminals each
}

$CoreConfig = $Config[$TotalCores]
if ($null -eq $CoreConfig) {
    $CoreConfig = @{ MaxPerCore = 3; CPUThreshold = 75 }  # Default configuration
}

$ProcessedPIDs = @{}
$MaxCoreUsageThreshold = $CoreConfig.CPUThreshold
$InstancesPerCore = $CoreConfig.MaxPerCore
$LastTerminalCount = 0
$LastCoreUsages = @{}

$LogPath = "C:\Windows\Logs\MTOptimizer"
$LogFile = Join-Path $LogPath "core_optimizer.log"
$maxLogSizeMB = 10
$logRetentionCount = 5

if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force
}

function Write-LogMessage {
    param(
        [string]$Message,
        [switch]$Important
    )
    
    # Check log size and rotate if needed
    if ((Test-Path $LogFile) -and ((Get-Item $LogFile).Length/1MB -gt $maxLogSizeMB)) {
        # Rotate logs
        for ($i = $logRetentionCount; $i -gt 0; $i--) {
            $oldLog = "$LogFile.$i"
            $newLog = "$LogFile.$($i+1)"
            if (Test-Path $oldLog) {
                if ($i -eq $logRetentionCount) {
                    Remove-Item $oldLog -Force
                } else {
                    Move-Item $oldLog $newLog -Force
                }
            }
        }
        Move-Item $LogFile "$LogFile.1" -Force
    }

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$TimeStamp - $Message"
    Add-Content -Path $LogFile -Value $LogMessage
}

function Get-CoreUsage {
    $CoreUsage = Get-Counter "\Processor(*)\% Processor Time" -ErrorAction SilentlyContinue | 
        Select-Object -ExpandProperty CounterSamples
    $UsageByCore = @{}
    foreach ($Sample in $CoreUsage) {
        if ($Sample.InstanceName -match "^\d+$") {
            $CoreID = [int]$Sample.InstanceName
            $UsageByCore[$CoreID] = $Sample.CookedValue
        }
    }
    return $UsageByCore
}

function Get-CoreInstanceCount {
    param (
        [hashtable]$ProcessedPIDs,
        [int]$CoreID
    )
    return ($ProcessedPIDs.Values | Where-Object { $_.Core -eq $CoreID } | Measure-Object).Count
}

function Write-SystemStatus {
    param (
        [hashtable]$CoreUsage,
        [int]$TerminalCount
    )
    
    # Only log if there are significant changes
    $usageChanged = $false
    foreach ($core in $CoreUsage.Keys) {
        if (-not $LastCoreUsages.ContainsKey($core) -or 
            [Math]::Abs($LastCoreUsages[$core] - $CoreUsage[$core]) -gt 10) {
            $usageChanged = $true
            break
        }
    }

    if ($usageChanged -or $TerminalCount -ne $LastTerminalCount) {
        Write-LogMessage "System Status - Terminals: $TerminalCount" -Important
        foreach ($core in $CoreUsage.Keys | Sort-Object) {
            $usage = [Math]::Round($CoreUsage[$core], 2)
            $instances = Get-CoreInstanceCount -ProcessedPIDs $ProcessedPIDs -CoreID $core
            Write-LogMessage "Core $core - Usage: $usage%, Instances: $instances" -Important
        }
        $LastCoreUsages = $CoreUsage.Clone()
        $LastTerminalCount = $TerminalCount
    }
}

Write-LogMessage "MT4/MT5 Core Optimizer v$ScriptVersion Started" -Important
Write-LogMessage "CPU Configuration: $TotalCores cores" -Important
Write-LogMessage "Settings - Instances Per Core: $InstancesPerCore" -Important
Write-LogMessage "Per Core - Max Instances: $InstancesPerCore, CPU Threshold: $MaxCoreUsageThreshold%" -Important

# Register shutdown event
$null = Register-EngineEvent PowerShell.Exiting -Action {
    Write-LogMessage "Core Optimizer service stopping..." -Important
    Get-Process | Where-Object { $_.ProcessName -eq "terminal" } | ForEach-Object {
        Write-LogMessage "Resetting affinity for PID: $($_.Id)" -Important
        $_.ProcessorAffinity = [IntPtr]::new(-1)
    }
    Write-LogMessage "Core Optimizer service stopped at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Important
} -SupportEvent

try {
    while ($true) {
        $Processes = Get-Process | Where-Object { $_.ProcessName -eq "terminal" }
        $CoreUsage = Get-CoreUsage
        
        # Log system status with changes only
        Write-SystemStatus -CoreUsage $CoreUsage -TerminalCount $Processes.Count
        
        foreach ($Process in $Processes) {
            if (-not $ProcessedPIDs.ContainsKey($Process.Id)) {
                $AvailableCores = $CoreUsage.Keys | 
                    Where-Object { 
                        ($CoreUsage[$_] -lt $MaxCoreUsageThreshold) -and 
                        ((Get-CoreInstanceCount -ProcessedPIDs $ProcessedPIDs -CoreID $_) -lt $InstancesPerCore)
                    } | 
                    Sort-Object { $CoreUsage[$_] }

                $TargetCore = $AvailableCores | Select-Object -First 1
                
                if ($null -ne $TargetCore) {
                    try {
                        $Process.ProcessorAffinity = $AffinityList[$TargetCore]
                        $ProcessedPIDs[$Process.Id] = @{
                            Core = $TargetCore
                            Timestamp = Get-Date
                            ProcessName = $Process.ProcessName
                        }
                        Write-LogMessage "Assigned terminal (PID: $($Process.Id)) to Core $TargetCore" -Important
                        Write-LogMessage "Status - Core $TargetCore Usage: $([math]::Round($CoreUsage[$TargetCore], 2))%" -Important
                    }
                    catch {
                        Write-LogMessage "Error setting affinity for PID $($Process.Id): $_" -Important
                    }
                }
                else {
                    Write-LogMessage "No available cores for terminal (PID: $($Process.Id)) - All cores at threshold or max instances per core" -Important
                }
            }
        }

        $ProcessedPIDs.Clone().Keys | ForEach-Object {
            if (-not (Get-Process -Id $_ -ErrorAction SilentlyContinue)) {
                $ProcessInfo = $ProcessedPIDs[$_]
                Write-LogMessage "Terminal terminated - PID: $_ from Core $($ProcessInfo.Core)" -Important
                $ProcessedPIDs.Remove($_)
            }
        }

        Start-Sleep -Seconds 5
    }
}
catch {
    Write-LogMessage "Critical Error: $_" -Important
    Write-LogMessage "Script terminated unexpectedly" -Important
    throw
}
finally {
    Write-LogMessage "Core Optimizer cleanup initiated" -Important
    Get-Process | Where-Object { $_.ProcessName -eq "terminal" } | ForEach-Object {
        Write-LogMessage "Resetting affinity for PID: $($_.Id)" -Important
        $_.ProcessorAffinity = [IntPtr]::new(-1)
    }
    Write-LogMessage "Core Optimizer service stopped at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Important
}
'@

# Installation
try {
    Write-Host "MT4/MT5 Core Optimizer v$ScriptVersion Installation"
    Write-Host "----------------------------------------"

    # Clean up old installation
    Remove-OldInstallation
    
    # Create and hide directories
    Write-Host "Creating directories..."
    New-Item -ItemType Directory -Path $optimizerPath -Force | Out-Null
    attrib +h $optimizerPath
    New-Item -ItemType Directory -Path $hiddenPath -Force | Out-Null
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null

    # Save version info
    Write-Host "Saving version information..."
    $ScriptVersion | Out-File $versionFile -Force

    # Save script
    Write-Host "Installing optimizer script..."
    $optimizerScript | Out-File "$hiddenPath\mt_core_optimizer.ps1" -Force

    # Set registry for auto-start
    Write-Host "Configuring auto-start..."
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if(Get-ItemProperty -Path $regPath -Name "MTSystemOptimizer" -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $regPath -Name "MTSystemOptimizer"
    }
    New-ItemProperty -Path $regPath -Name "MTSystemOptimizer" -Value "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$hiddenPath\mt_core_optimizer.ps1`"" -PropertyType String -Force

    # Set execution policy and start
    Write-Host "Starting optimizer service..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
    Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$hiddenPath\mt_core_optimizer.ps1`"" -WindowStyle Hidden

    Write-Host "----------------------------------------"
    Write-Host "MT4/MT5 Core Optimizer v$ScriptVersion installed successfully"
    Write-Host "CPU Cores: $((Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)"
}
catch {
    Write-Host "Installation failed: $_"
    throw
}