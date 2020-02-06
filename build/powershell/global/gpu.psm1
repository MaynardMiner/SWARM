function Global:Get-DeviceString {
    param(
        [Parameter(Mandatory = $false)]
        [String]$TypeDevices = "none",
        [Parameter(Mandatory = $false)]
        [String]$TypeCount
    )

    if ($TypeDevices -ne "none") {
        $TypeDevices = $TypeDevices -replace (",", " ")
        if ($TypeDevices -match " ") { $NewDevices = $TypeDevices -split " " }else { $NewDevices = $TypeDevices -split "" }
        $NewDevices = Switch ($NewDevices) { "a" { "10" }; "b" { "11" }; "c" { "12" }; "e" { "13" }; "f" { "14" }; "g" { "15" }; "h" { "16" }; "i" { "17" }; "j" { "18" }; "k" { "19" }; "l" { "20" }; default { "$_" }; }
        if ($TypeDevices -match " ") { $TypeGPU = $NewDevices }else { $TypeGPU = $NewDevices | ? { $_.trim() -ne "" } }
        $TypeGPU = $TypeGPU | % { iex $_ }
    }
    else {
        $TypeGPU = @()
        $GetDevices = 0
        for ($global:i = 0; $global:i -lt $TypeCount; $global:i++) { $TypeGPU += $GetDevices++ }
    }

    $TypeGPU
}

function Global:Set-NvidiaStats {

    Switch ($(arg).Platform) {
        "linux" {
            switch ($(arg).HiveOS) {
                "No" {
                    timeout -s9 10 ./build/apps/VII/VII-smi | Tee-Object -Variable getstats | Out-Null
                    if ($getstats) {
                        $nvidiai = $getstats | ConvertFrom-StringData
                        $nvinfo = @{ }
                        $nvinfo.Add("Fans", @())
                        $nvinfo.Add("Temps", @())
                        $nvinfo.Add("Watts", @())
                        $nvidiai.keys | ForEach-Object { if ($_ -like "*fan*") { $nvinfo.Fans += $nvidiai.$_ } }
                        $nvidiai.keys | ForEach-Object { if ($_ -like "*temperature*") { $nvinfo.Temps += $nvidiai.$_ } }
                        $nvidiai.keys | ForEach-Object { if ($_ -like "*power*") { if ($nvidiai.$_ -eq "failed to get") { $nvinfo.Watts += "75" }else { $nvinfo.Watts += $nvidiai.$_ } } }
                    }
                }
                "Yes" {
                    $HiveStats = "/run/hive/gpu-stats.json"
                    do {
                        for ($global:i = 0; $global:i -lt 20; $global:i++) {
                            if (Test-Path $HiveStats) { try { $GetHiveStats = Get-Content $HiveStats | ConvertFrom-Json -ErrorAction Stop }catch { $GetHiveStats = $null } }
                            if ($GetHiveStats -ne $null) {
                                $nvinfo = @{ }
                                $nvinfo.Add("Fans", $( $GetHiveStats.fan | ForEach-Object { if ($_ -ne 0) { $_ } } ) )
                                $nvinfo.Add("Temps", $( $GetHiveStats.temp | ForEach-Object { if ($_ -ne 0) { $_ } } ) )
                                $nvinfo.Add("Watts", $( $GetHiveStats.power | ForEach-Object { if ($_ -ne 0) { $_ } } ) )
                            }
                            Start-Sleep -S .5
                        }
                    }while ($GetHiveStats.temp.count -lt 1 -and $GetHiveStats.fan.count -lt 1)
                }
            }
        }

        "windows" {
            $nvidiaout = @()
            try {
                $smi = "$($env:ProgramFiles)\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
                $info = [System.Diagnostics.ProcessStartInfo]::new()
                $info.FileName = $smi
                $info.Arguments = "--query-gpu=power.draw,fan.speed,temperature.gpu --format=csv"
                $info.UseShellExecute = $false
                $info.RedirectStandardOutput = $true
                $info.Verb = "runas"
                $Proc = [System.Diagnostics.Process]::New()
                $proc.StartInfo = $Info
                $timer = [System.Diagnostics.Stopwatch]::New()
                $timer.Restart();
                $proc.Start() | Out-Null
                while (-not $Proc.StandardOutput.EndOfStream) {
                    $nvidiaout += $Proc.StandardOutput.ReadLine();
                    if ($timer.Elapsed.Seconds -gt 15) {
                        $proc.kill() | Out-Null;
                        break;
                    }
                }
                $Proc.Dispose();            
            }
            catch { Write-Host "WARNING: Failed to get nvidia stats" -ForegroundColor DarkRed }
            if ($nvidiaout.count -gt 0) { 
                $ninfo = $nvidiaout | ConvertFrom-CSV
                $NVIDIAFans = $ninfo.'fan.speed [%]' | ForEach-Object { $_ -replace ("\%", "") }
                $NVIDIATemps = $ninfo.'temperature.gpu'
                $NVIDIAPower = $ninfo.'power.draw [W]' | ForEach-Object { $_ -replace ("\[Not Supported\]", "75") } | ForEach-Object { $_ -replace (" W", "") }        
                $NVIDIAStats = @{ }
                $NVIDIAStats.Add("Fans", $NVIDIAFans)
                $NVIDIAStats.Add("Temps", $NVIDIATemps)
                $NVIDIAStats.Add("Watts", $NVIDIAPower)
                $nvinfo = $NVIDIAStats  
            }
            else {
                Write-Host "WARNING: Failed to get amd gpu stats" -ForegroundColor DarkRed
                break
            }
        }
    }
    $nvinfo
}

## AMD HWMON
function Global:Set-AMDStats {
    $AMDStats = @{ }
    $AMDFans = @()
    $AMDTemps = @()
    $AMDWatts = @()

    switch ($(arg).Platform) {
        "windows" {
            $amdout = @()
            try {
                if ([Environment]::Is64BitOperatingSystem) {
                    $odvii = ".\build\apps\odvii\odvii_x64.exe"
                } 
                else {
                    $odvii = ".\build\apps\odvii\odvii_x86.exe"
                }
                $info = [System.Diagnostics.ProcessStartInfo]::new()
                $info.FileName = $odvii
                $info.UseShellExecute = $false
                $info.RedirectStandardOutput = $true
                $info.Verb = "runas"
                $Proc = [System.Diagnostics.Process]::New()
                $proc.StartInfo = $Info
                $timer = [System.Diagnostics.Stopwatch]::New()
                $timer.Restart();
                $proc.Start() | Out-Null
                while (-not $Proc.StandardOutput.EndOfStream) {
                    $amdout += $Proc.StandardOutput.ReadLine();
                    if ($timer.Elapsed.Seconds -gt 15) {
                        $proc.kill() | Out-Null;
                        break;
                    }
                }
                $Proc.Dispose();            
            }
            catch { 
                Write-Host "WARNING: Failed to query driver for gpu stats" -ForegroundColor DarkRed; 
            }
            if ($amdout.count -gt 0) {
                $amdinfo = $amdout | ConvertFrom-Json
                if ($amdinfo.count -gt 0) { 
                    $amdinfo | ForEach-Object {
                        if ($_.'Fan Speed %') { $AMDFans += $_.'Fan Speed %' }else { $AMDFans += "511" }
                        if ($_.'Temperature') { $AMDTemps += $_.'Temperature' }else { $AMDTemps += "511" }
                        if ($_.'Wattage') { $AMDWatts += $_.'Wattage' }else { $AMDWatts += "5111" }
                    }
                }
                else {
                    Write-Host "Queried Driver For Stats, But It Returned NULL" -ForegroundColor DarkRed
                }    
            }
            else {
                Write-Host "WARNING: Failed to query driver for gpu stats" -ForegroundColor DarkRed
            }
        }

        "linux" {
            switch ($(arg).HiveOS) {
                "Yes" {
                    $HiveStats = "/run/hive/gpu-stats.json"
                    do {
                        for ($global:i = 0; $global:i -lt 20; $global:i++) {
                            if (Test-Path $HiveStats) { try { $GetHiveStats = Get-Content $HiveStats | ConvertFrom-Json -ErrorAction Stop }catch { $GetHiveStats = $null } }
                            if ($GetHiveStats -ne $null) {
                                $AMDFans = $( $GetHiveStats.fan | ForEach-Object { if ($_ -ne 0) { $_ } } )
                                $AMDTemps = $( $GetHiveStats.temp | ForEach-Object { if ($_ -ne 0) { $_ } } )
                                $AMDWatts = $( $GetHiveStats.power | ForEach-Object { if ($_ -ne 0) { $_ } } )
                            }
                            Start-Sleep -S .5
                        }
                    }while ($GetHiveStats.temp.count -lt 1 -and $GetHiveStats.fan.count -lt 1 -and $GetHiveStats.power.count -lt 1)
                }
                "No" {
                    timeout -s9 10 rocm-smi -f | Tee-Object -Variable AMDFans | Out-Null
                    $AMDFans = $AMDFans | Select-String "%" | ForEach-Object { $_ -split "\(" | Select-Object -Skip 1 -first 1 } | ForEach-Object { $_ -split "\)" | Select-Object -first 1 }
                    timeout -s9 10 rocm-smi -t | Tee-Object -Variable AMDTemps | Out-Null
                    $AMDTemps = $AMDTemps | Select-String -CaseSensitive "Temperature" | ForEach-Object { $_ -split ":" | Select-Object -skip 2 -First 1 } | ForEach-Object { $_ -replace (" ", "") } | ForEach-Object { $_ -replace ("c", "") }
                    timeout -s9 10 rocm-smi -P | Tee-Object -Variable AMDWatts | Out-Null
                    $AMDWatts = $AMDWatts | Select-String -CaseSensitive "W" | foreach { $_ -split (":", "") | Select -skip 2 -first 1 } | foreach { $_ -replace ("W", "") }
                }
            }
        }
    }

    $AMDStats.Add("Fans", $AMDFans)
    $AMDStats.Add("Temps", $AMDTemps)
    $AMDStats.Add("Watts", $AMDWatts)

    $AMDStats

}

function Global:Get-OhNo {
    Write-Host "Failed To Collect Miner Data" -ForegroundColor Red
}

function Global:Remove-ASICPools {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$AIP,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Port,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Name
    )

    $ASIC_Pools = @{ }

    Switch ($Name) {
        "cgminer" {
            $ASICM = "cgminer"
            log "Clearing all previous cgminer pools." -ForegroundColor "Yellow"
            $ASIC_Pools.Add($ASICM, @{ })
            ##First we need to discover all pools
            $Commands = @{command = "pools"; parameter = 0 } | ConvertTo-Json -Compress
            $response = $Null
            $response = Global:Get-TCP -Server $AIP -Port $Port -Message $Commands -Timeout 10
            if ($response) {
                ##Windows screws up last character
                if ($response[-1] -notmatch "}") { $response = $Response.Substring(0, $Response.Length - 1) }
                $PoolList = $response | ConvertFrom-Json
                $PoolList = $PoolList.POOLS
                $PoolList | ForEach-Object { $ASIC_Pools.$ASICM.Add("Pool_$($_.Pool)", $_.Pool) }
                $ASIC_Pools.$ASICM.keys | ForEach-Object {
                    $PoolNo = $($ASIC_Pools.$ASICM.$_)
                    $Commands = @{command = "removepool"; parameter = "$PoolNo" } | ConvertTo-Json -Compress; 
                    $response = $Null; 
                    $response = Global:Get-TCP -Server $AIP -Port $Port -Message $Commands -Timeout 10
                    $response
                }
            }
            else { log "WARNING: Failed To Gather cgminer Pool List!" -ForegroundColor Yellow }
        }
    }
}