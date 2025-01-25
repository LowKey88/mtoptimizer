# Install-MTOptimizer.ps1
#
# Description: PowerShell script to optimize CPU core usage for MetaTrader terminals
# by managing process affinity. This ensures optimal distribution of terminal processes
# across available CPU cores to prevent overload and maintain performance.

# Script Version
$ScriptVersion = "2.0.2"

# Ensure running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    Start-Process powershell -Verb runAs -ArgumentList "& '$($myinvocation.mycommand.definition)'"
    Break
}

# Installation paths
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
$ScriptVersion = "2.0.2"

# State Management
class ProcessState {
    [int]$ProcessID
    [int]$AssignedCore
    [datetime]$LastAssignmentTime
    [int]$AssignmentCount
    [double]$LastCPUUsage
    [bool]$IsActive

    ProcessState([int]$pid, [int]$core) {
        $this.ProcessID = $pid
        $this.AssignedCore = $core
        $this.LastAssignmentTime = Get-Date
        $this.AssignmentCount = 1
        $this.LastCPUUsage = 0
        $this.IsActive = $true
    }
}

class CoreState {
    [int]$CoreID
    [double]$CurrentUsage
    [int]$AssignedProcessCount
    [datetime]$LastUpdateTime
    [System.Collections.Generic.List[int]]$AssignedPIDs

    CoreState([int]$id) {
        $this.CoreID = $id
        $this.CurrentUsage = 0
        $this.AssignedProcessCount = 0
        $this.LastUpdateTime = Get-Date
        $this.AssignedPIDs = [System.Collections.Generic.List[int]]::new()
    }

    [void] AddProcess([int]$pid) {
        if (-not $this.AssignedPIDs.Contains($pid)) {
            $this.AssignedPIDs.Add($pid)
            $this.AssignedProcessCount = $this.AssignedPIDs.Count
        }
    }

    [void] RemoveProcess([int]$pid) {
        $this.AssignedPIDs.Remove($pid)
        $this.AssignedProcessCount = $this.AssignedPIDs.Count
    }
}

# Configuration
class OptimizerConfig {
    [int]$TotalCores
    [int]$MaxInstancesPerCore
    [double]$CPUThreshold
    [double]$HysteresisBuffer
    [timespan]$StabilityPeriod
    [timespan]$MonitoringInterval
    [string]$LogPath
    [int]$MaxLogSizeMB
    [int]$LogRetentionCount
    [hashtable]$AffinityMasks

    OptimizerConfig() {
        $this.Initialize()
    }

    [void] Initialize() {
        # Get CPU info
        $processor = Get-CimInstance -ClassName Win32_Processor
        $this.TotalCores = ($processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

        # Core settings based on total cores
        $coreSettings = @{
            2 = @{ MaxPerCore = 2; CPUThreshold = 70 }
            4 = @{ MaxPerCore = 2; CPUThreshold = 70 }
            6 = @{ MaxPerCore = 2; CPUThreshold = 70 }
            8 = @{ MaxPerCore = 2; CPUThreshold = 70 }
        }

        $settings = $coreSettings[$this.TotalCores]
        if (-not $settings) {
            $settings = @{ MaxPerCore = 2; CPUThreshold = 70 }
        }

        $this.MaxInstancesPerCore = $settings.MaxPerCore
        $this.CPUThreshold = $settings.CPUThreshold
        $this.HysteresisBuffer = 10
        $this.StabilityPeriod = [timespan]::FromMinutes(5)
        $this.MonitoringInterval = [timespan]::FromSeconds(15)
        $this.LogPath = "C:\Windows\Logs\MTOptimizer"
        $this.MaxLogSizeMB = 10
        $this.LogRetentionCount = 5

        # Generate affinity masks
        $this.AffinityMasks = @{}
        for ($i = 0; $i -lt $this.TotalCores; $i++) {
            $this.AffinityMasks[$i] = [int]([math]::Pow(2, $i))
        }
    }
}

# Core Optimizer Class
class CoreOptimizer {
    [OptimizerConfig]$Config
    [System.Collections.Generic.Dictionary[int,ProcessState]]$ProcessStates
    [System.Collections.Generic.Dictionary[int,CoreState]]$CoreStates
    [System.Collections.Queue]$LogQueue
    [System.Threading.Mutex]$LogMutex
    [string]$LogFile
    [hashtable]$LastCoreUsages
    [int]$LastTerminalCount

    CoreOptimizer() {
        $this.Config = [OptimizerConfig]::new()
        $this.ProcessStates = [System.Collections.Generic.Dictionary[int,ProcessState]]::new()
        $this.CoreStates = [System.Collections.Generic.Dictionary[int,CoreState]]::new()
        $this.LogQueue = [System.Collections.Queue]::new()
        $this.LogMutex = [System.Threading.Mutex]::new($false, "MTOptimizerLogMutex")
        $this.LogFile = Join-Path $this.Config.LogPath "core_optimizer.log"
        $this.LastCoreUsages = @{}
        $this.LastTerminalCount = 0

        # Initialize core states
        for ($i = 0; $i -lt $this.Config.TotalCores; $i++) {
            $this.CoreStates[$i] = [CoreState]::new($i)
        }

        # Ensure log directory exists
        if (-not (Test-Path $this.Config.LogPath)) {
            New-Item -ItemType Directory -Path $this.Config.LogPath -Force | Out-Null
        }
    }

    # Core selection logic
    [int] SelectBestCore([int]$processId) {
        # Check if process was recently assigned
        if ($this.ProcessStates.ContainsKey($processId)) {
            $state = $this.ProcessStates[$processId]
            if ((Get-Date) - $state.LastAssignmentTime -lt $this.Config.StabilityPeriod) {
                return $state.AssignedCore
            }
        }

        # Find available cores under threshold
        $availableCores = $this.CoreStates.Values | Where-Object {
            $_.CurrentUsage -lt ($this.Config.CPUThreshold - $this.Config.HysteresisBuffer) -and
            $_.AssignedProcessCount -lt $this.Config.MaxInstancesPerCore
        }

        if ($availableCores) {
            # Select core with lowest load and process count
            return ($availableCores | 
                Sort-Object { $_.AssignedProcessCount }, { $_.CurrentUsage } | 
                Select-Object -First 1).CoreID
        }

        # Fallback: select least loaded core
        return ($this.CoreStates.Values | 
            Sort-Object { $_.CurrentUsage } | 
            Select-Object -First 1).CoreID
    }

    # Process management
    [void] AssignProcessToCore([System.Diagnostics.Process]$process, [int]$coreId) {
        try {
            $process.ProcessorAffinity = $this.Config.AffinityMasks[$coreId]
            
            # Update process state
            if (-not $this.ProcessStates.ContainsKey($process.Id)) {
                $this.ProcessStates[$process.Id] = [ProcessState]::new($process.Id, $coreId)
            } else {
                $state = $this.ProcessStates[$process.Id]
                $state.AssignedCore = $coreId
                $state.LastAssignmentTime = Get-Date
                $state.AssignmentCount++
            }

            # Update core state
            $this.CoreStates[$coreId].AddProcess($process.Id)

            $this.WriteLog("Successfully assigned terminal (PID: $($process.Id)) to Core $coreId (Usage: $([math]::Round($this.CoreStates[$coreId].CurrentUsage, 2))%)", $true)
        }
        catch {
            $this.WriteLog("Error assigning PID $($process.Id) to Core $coreId: $_", $true)
        }
    }

    [void] HandleProcessTermination([int]$processId) {
        if ($this.ProcessStates.ContainsKey($processId)) {
            $state = $this.ProcessStates[$processId]
            $coreId = $state.AssignedCore

            $this.WriteLog("Terminal process ended (PID: $processId) on Core $coreId", $true)
            
            # Update core state
            if ($this.CoreStates.ContainsKey($coreId)) {
                $this.CoreStates[$coreId].RemoveProcess($processId)
            }

            # Remove process state
            $this.ProcessStates.Remove($processId)
        }
    }

    # System monitoring
    [void] UpdateSystemState() {
        # Get current CPU usage for each core
        $counters = Get-Counter "\Processor(*)\% Processor Time" -ErrorAction SilentlyContinue
        if ($counters) {
            foreach ($counter in $counters.CounterSamples) {
                if ($counter.InstanceName -match '^\d+$') {
                    $coreId = [int]$counter.InstanceName
                    if ($this.CoreStates.ContainsKey($coreId)) {
                        $this.CoreStates[$coreId].CurrentUsage = $counter.CookedValue
                        $this.CoreStates[$coreId].LastUpdateTime = Get-Date
                    }
                }
            }
        }

        # Update process states
        $terminals = Get-Process | Where-Object { $_.ProcessName -eq "terminal" }
        
        # Log significant changes
        $terminalCount = $terminals.Count
        $usageChanged = $false
        $significantChange = $false
        $lastLogTime = if ($this.LastCoreUsages.Count -gt 0) { Get-Date } else { [DateTime]::MinValue }
        $minLogInterval = [TimeSpan]::FromSeconds(30)

        if ((Get-Date) - $lastLogTime -gt $minLogInterval) {
            foreach ($core in $this.CoreStates.Values) {
                if (-not $this.LastCoreUsages.ContainsKey($core.CoreID) -or 
                    [Math]::Abs($this.LastCoreUsages[$core.CoreID] - $core.CurrentUsage) -gt 25) {
                    $usageChanged = $true
                    # Check if usage crossed threshold boundaries
                    if ($core.CurrentUsage -gt $this.Config.CPUThreshold -or 
                        ($this.LastCoreUsages.ContainsKey($core.CoreID) -and 
                         $this.LastCoreUsages[$core.CoreID] -gt $this.Config.CPUThreshold)) {
                        $significantChange = $true
                        break
                    }
                }
            }

            if ($significantChange -or 
                $terminalCount -ne $this.LastTerminalCount -or 
                (Get-Date) - $lastLogTime -gt [TimeSpan]::FromMinutes(1)) {
                $this.WriteLog("System Status - Terminals: $terminalCount", $true)
                foreach ($core in $this.CoreStates.Values) {
                    $this.WriteLog("Core $($core.CoreID) - Usage: $([Math]::Round($core.CurrentUsage, 2))%, Instances: $($core.AssignedProcessCount)", $significantChange)
                    $this.LastCoreUsages[$core.CoreID] = $core.CurrentUsage
                }
            }
            $this.LastTerminalCount = $terminalCount
        }

        # Check for terminated processes
        $this.ProcessStates.Keys.Clone() | ForEach-Object {
            if (-not (Get-Process -Id $_ -ErrorAction SilentlyContinue)) {
                $this.HandleProcessTermination($_)
            }
        }
    }

    # Logging
    [void] WriteLog([string]$message, [bool]$important) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$timestamp - $message"
        $this.LogQueue.Enqueue($logMessage)

        if ($important -or $this.LogQueue.Count -ge 10) {
            $this.FlushLogQueue()
        }
    }

    [void] FlushLogQueue() {
        if ($this.LogQueue.Count -eq 0) { return }

        try {
            $this.LogMutex.WaitOne() | Out-Null

            # Check log size and rotate if needed
            if ((Test-Path $this.LogFile) -and ((Get-Item $this.LogFile).Length/1MB -gt $this.Config.MaxLogSizeMB)) {
                for ($i = $this.Config.LogRetentionCount; $i -gt 0; $i--) {
                    $oldLog = "$($this.LogFile).$i"
                    $newLog = "$($this.LogFile).$($i+1)"
                    if (Test-Path $oldLog) {
                        if ($i -eq $this.Config.LogRetentionCount) {
                            Remove-Item $oldLog -Force
                        } else {
                            Move-Item $oldLog $newLog -Force
                        }
                    }
                }
                Move-Item $this.LogFile "$($this.LogFile).1" -Force
            }

            Add-Content -Path $this.LogFile -Value ($this.LogQueue.ToArray())
            $this.LogQueue.Clear()
        }
        finally {
            $this.LogMutex.ReleaseMutex()
        }
    }

    # Main optimization loop
    [void] Start() {
        $this.WriteLog("MT4/MT5 Core Optimizer v$ScriptVersion Started", $true)
        $this.WriteLog("CPU Configuration: $($this.Config.TotalCores) cores", $true)
        $this.WriteLog("Settings - Max Instances Per Core: $($this.Config.MaxInstancesPerCore)", $true)
        $this.WriteLog("Per Core - CPU Threshold: $($this.Config.CPUThreshold)%", $true)

        try {
            while ($true) {
                # Update system state
                $this.UpdateSystemState()

                # Process new terminals
                Get-Process | Where-Object { $_.ProcessName -eq "terminal" } | ForEach-Object {
                    if (-not $this.ProcessStates.ContainsKey($_.Id)) {
                        $targetCore = $this.SelectBestCore($_.Id)
                        $this.AssignProcessToCore($_, $targetCore)
                    }
                }

                $this.FlushLogQueue()
                Start-Sleep -Seconds $this.Config.MonitoringInterval.TotalSeconds
            }
        }
        catch {
            $this.WriteLog("Critical Error: $_", $true)
            throw
        }
        finally {
            $this.Cleanup()
        }
    }

    # Cleanup
    [void] Cleanup() {
        $this.WriteLog("Core Optimizer cleanup initiated", $true)
        
        Get-Process | Where-Object { $_.ProcessName -eq "terminal" } | ForEach-Object {
            try {
                $_.ProcessorAffinity = [IntPtr]::new(-1)
                if ($this.ProcessStates.ContainsKey($_.Id)) {
                    $state = $this.ProcessStates[$_.Id]
                    $this.WriteLog("Reset affinity for terminal (PID: $($_.Id)) from Core $($state.AssignedCore)", $true)
                }
            }
            catch {
                $this.WriteLog("Error resetting affinity for PID $($_.Id): $_", $true)
            }
        }

        $this.ProcessStates.Clear()
        foreach ($core in $this.CoreStates.Values) {
            $core.AssignedPIDs.Clear()
            $core.AssignedProcessCount = 0
        }

        $this.WriteLog("Core Optimizer service stopped at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')", $true)
        $this.FlushLogQueue()
    }
}

# Start the optimizer
$optimizer = [CoreOptimizer]::new()
$optimizer.Start()
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