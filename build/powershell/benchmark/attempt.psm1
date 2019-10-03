function Global:Get-MinerTimeout($miner) {

    $reason = "unknown error"

    if ($Miner.hashrate -eq 0 -or $null -eq $Miner.hashrate) {
        if ($null -eq $miner.xprocess) { $reason = "no start" }
        else {
            if ($Miner.Type -ne "*ASIC*") {
                $MinerProc = Get-Process -Id $miner.xprocess.id -ErrorAction SilentlyContinue
                if ($null -eq $MinerProc) { $reason = "crashed" }
                else { $reason = "no hash" }
            }
            else { $Reason = "no hash" }
        }
    }
    $RejectCheck = Join-Path ".\timeout\warnings" "$($miner.Name)_$($miner.Algo)_rejection.txt"
    if (Test-Path $RejectCheck) { $reason = "rejections" }

    return $reason
}

function Global:Set-Warnings {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$command,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$name
    )

    switch ($command) {
        "clear" {
            if ([string]$(vars).Warnings.$name.bad -ne "") { $(vars).Warnings = $(vars).Warnings | Where $($_.keys -ne $name) }
        }
        "add" {
            if ([string]$(vars).Warnings.$name.bad -eq "") {
                $(vars).Warnings += @{ 
                    "$name" = @{ 
                        bad      = 1
                        ban_time = Get-Date
                    } 
                } 
            }
            else { $(vars).Warnings.$name.bad++; $(vars).Warnings.$name.ban_time = Get-Date }
        }
    }
    if ($(vars).Warnings.Count -eq 0) { $(vars).Warnings = @() }
}

function Global:Get-HiveWarning($HiveMessage) {
    $HiveWarning = @{result = @{command = "timeout" } }
    if ($(vars).WebSites) {
        $(vars).WebSites | ForEach-Object {
            $Sel = $_
            try {
                Global:Add-Module "$($(vars).web)\methods.psm1"
                Global:Get-WebModules $Sel
                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
            }
            catch { log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
            Global:Remove-WebModules $sel
        }
    }
}

function Global:Set-Power {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [String]$PwrType,
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$PwrDevices
    )
    $GPUPower = 0
    switch -Wildcard ($PwrType) {
        "*AMD*" { $GPUPower = (Global:Set-AMDStats).watts }
        "*NVIDIA*" { 
            $D = Global:Get-DeviceString -TypeCount $($(vars).GCount.NVIDIA.PSObject.Properties.Value.Count) -TypeDevices $PwrDevices
            $Power = (Global:Set-NvidiaStats).watts 
            for ($i = 0; $i -lt $D.Count; $i++) {
                $DI = $D[$i]
                $GPUPower += $Power[$DI]
            }
        }
    }
    $($GPUPower | Measure-Object -Sum).Sum
}

function Global:Get-Intensity {
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [String]$LogMiner,
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$LogAlgo,
        [Parameter(Position = 2, Mandatory = $false)]
        [String]$LogPath
    )

    $LogAlgo = $LogAlgo -replace "`/", "`-"
    $ParseLog = ".\logs\$($LogMiner).log"
    if (Test-Path $ParseLog) {
        $GetInfo = Get-Content $ParseLog
        $GetIntensity = $GetInfo | Select-String "intensity"
        $GetDifficulty = $GetInfo | Select-String "difficulty"
        $NotePath = Split-Path $LogPath
        if ($GetIntensity) { $GetIntensity | Set-Content "$NotePath\$($LogAlgo)_intensity.txt" }
        if ($GetDifficulty) { $GetDifficulty | Set-Content "$NotePath\$($LogAlgo)_difficulty.txt" }
    }
}

function Global:Start-WattOMeter {
    log "

  Starting Watt-O-Meter
       __________
      |   ____   |
      |  /    \  |
      | | .''. | |
      | |   /  | |
      |==========|
      |   WATT   |
      |__________|
  
        Note: 
  -WattOMeter No Does Not
  Stop Watt Calculations.
  
  `".\config\power.json`" must not have
  any values stored.

  Run clear_watts to remove watt readings.
  " -foregroundcolor yellow
}

function Global:Start-Benchmark {
    $(vars).BestActiveMIners | ForEach-Object {

        ## Bools for bans
        $MinerPoolBan = $false
        $MinerAlgoBan = $false
        $MinerBan = $false
        $TypeBan = $False
        $Global:Strike = $false
        $global:WasBenchmarked = $false

        ## Symbol for switching threshold
        $(vars).ActiveSymbol += $($_.Symbol)

        ## Reset Bans if last one occurred an hour ago.
        if ( [string]$(vars).Warnings."$($_.Name)".bad -ne "" ) {
            $FirstTime = [math]::Round( ( (Get-Date) - $(vars).Warnings."$($_.Name)".ban_time ).TotalSeconds )
            if ($FirstTime -ge 3600) {
                Global:Set-Warnings clear "$($_.Type)"
                Global:Set-Warnings clear "$($_.Name)"
                Global:Set-Warnings clear "$($_.Name)_$($_.Algo)"
                Global:Set-Warnings clear "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
            }
        }
        
        ## Attempt to benchmark
        if ($_.BestMiner -eq $true) {
            $NewName = $_.Algo -replace "`_", "`-"
            $NewName = $NewName -replace "`/", "`-"
            if ($null -eq $_.XProcess -or $_.XProcess.HasExited) {
                $_.Status = "Failed"
                $global:WasBenchmarked = $False
                $Global:Strike = $true
                log "Cannot Benchmark- Miner is not running" -ForegroundColor Red
            }
            else {
                $_.HashRate = 0
                $global:WasBenchmarked = $False
                $WasActive = [math]::Round(((Get-Date) - $_.XProcess.StartTime).TotalSeconds)
                if ($WasActive -ge $(vars).MinerStatInt) {
                    log "$($_.Name) $($_.Symbol) Was Active for $WasActive Seconds"
                    log "Attempting to record hashrate for $($_.Name) $($_.Symbol)" -foregroundcolor "Cyan"
                    for ($i = 0; $i -lt 4; $i++) {
                        $Miner_HashRates = Global:Get-HashRate -Type $_.Type
                        $_.HashRate = $Miner_HashRates
                        if ($global:WasBenchmarked -eq $False) {
                            $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($NewName)_hashrate.txt"
                            $NewHashrateFilePath = Join-Path ".\backup" "$($_.Name)_$($NewName)_hashrate.txt"
                            if (-not (Test-Path "backup")) { New-Item "backup" -ItemType "directory" | Out-Null }
                            log "$($_.Name) $($_.Symbol) Starting Bench"
                            if ($null -eq $Miner_HashRates -or $Miner_HashRates -eq 0) {
                                $Global:Strike = $true
                                log "Stat Attempt Yielded 0" -Foregroundcolor Red
                                Start-Sleep -S .25
                                $GPUPower = 0
                                if ($(arg).WattOMeter -eq "Yes" -and $_.Type -ne "CPU") {
                                    $GetWatts = Get-Content ".\config\power\power.json" | ConvertFrom-Json
                                    if ($GetWatts.$($_.Algo)) {
                                        $GetWatts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                        $GetWatts | ConvertTo-Json -Depth 3 | Set-Content ".\config\power\power.json"
                                    }
                                    else {
                                        $WattTypes = @{NVIDIA1_Watts = ""; NVIDIA2_Watts = ""; NVIDIA3_Watts = ""; AMD1_Watts = ""; CPU_Watts = "" }
                                        $GetWatts | Add-Member "$($_.Algo)" $WattTypes
                                        $GetWatts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                        $GetWatts | ConvertTo-Json -Depth 3 | Set-Content ".\config\power\power.json"
                                    }
                                }
                            }
                            else {
                                if ($(arg).WattOMeter -eq "Yes" -and $_.Type -ne "CPU") { try { $GPUPower = Global:Set-Power $($_.Type) $($_.Devices) }catch { log "WattOMeter Failed"; $GPUPower = 0 } }
                                else { $GPUPower = 1 }
                                if ($(arg).WattOMeter -eq "Yes" -and $_.Type -ne "CPU") {
                                    $GetWatts = Get-Content ".\config\power\power.json" | ConvertFrom-Json
                                    if ($GetWatts.$($_.Algo)) {
                                        $StatPower = Global:Set-Stat -Name "$($_.Name)_$($NewName)_Watts" -Value $GPUPower
                                        $GetWatts.$($_.Algo)."$($_.Type)_Watts" = "$($StatPower.Day)"
                                        $GetWatts | ConvertTo-Json -Depth 3 | Set-Content ".\config\power\power.json"
                                    }
                                    else {
                                        $StatPower = Global:Set-Stat -Name "$($_.Name)_$($NewName)_Watts" -Value $GPUPower
                                        $WattTypes = @{NVIDIA1_Watts = ""; NVIDIA2_Watts = ""; NVIDIA3_Watts = ""; AMD1_Watts = ""; CPU_Watts = "" }
                                        $GetWatts | Add-Member "$($_.Algo)" $WattTypes
                                        $GetWatts.$($_.Algo)."$($_.Type)_Watts" = "$($StatPower.Day)"
                                        $GetWatts | ConvertTo-Json -Depth 3 | Set-Content ".\config\power\power.json"
                                    }
                                }
                                $Stat = Global:Set-Stat -Name "$($_.Name)_$($NewName)_hashrate" -Value $Miner_HashRates -AsHashRate
                                Start-Sleep -s 1
                                $GetLiveStat = Global:Get-Stat "$($_.Name)_$($NewName)_hashrate"
                                $StatCheck = "$($GetLiveStat.Live)"
                                $ScreenCheck = "$($StatCheck | Global:ConvertTo-Hash)"
                                if ($ScreenCheck -eq "0.00 PH" -or $null -eq $StatCheck) {
                                    $Global:Strike = $true
                                    $global:WasBenchmarked = $False
                                    log "Stat Failed Write To File" -Foregroundcolor Red
                                }
                                else {
                                    log "Recorded Hashrate For $($_.Name) $($_.Symbol) Is $($ScreenCheck)" -foregroundcolor "magenta"
                                    if ($(arg).WattOMeter -eq "Yes") { log "Watt-O-Meter scored $($_.Name) $($_.Symbol) at $($GPUPower) Watts" -ForegroundColor magenta }
                                    if (-not (Test-Path $NewHashrateFilePath)) {
                                        Copy-Item $HashrateFilePath -Destination $NewHashrateFilePath -force
                                        log "$($_.Name) $($_.Symbol) Was Benchmarked And Backed Up" -foregroundcolor yellow
                                        log "if SWARM was able to record intesity and/or difficulty, it is in .\bin\$($_.name)" -foregroundcolor yellow
                                    }
                                    $global:WasBenchmarked = $True
                                    Global:Get-Intensity $_.Type $_.Symbol $_.Path
                                    log "Stat Written" -foregroundcolor green
                                    log "Was this stat not correct? You can run command 'bench miner $($_.Name)' or 'bench algorithm $($_.algo)' to reset benchmark" -foregroundcolor cyan
                                    if($IsWindows) { log "There is also a batch file labeled swarm_start_$($_.algo).bat for testing in .\bin\$($_.name)`n" -foregroundcolor cyan }
                                    if($IsLinux) { log "There is also a bash file labeled swarm_start_$($_.algo).sh for testing in .\bin\$($_.name)`n" -foregroundcolor cyan }
                                    $Global:Strike = $false
                                } 
                            }
                        }
                    }

                    ##Check For High Rejections
                    $Rj = Global:Get-Rejections -Type $_.Type
                    if($RJ) {
                    $Percent = $RJ -split "`:" | Select -First 1
                    $Shares = $RJ -Split "`:" | Select -Last 1
                    if ([Double]$Percent -gt $(arg).Rejections -and [Double]$Shares -gt 0) {
                        log "Rejection Percentage at $Percent out of $Shares shares- Adding Strike Against Miner" -Foreground Red
                        $Global:Strike = $True
                    }
                }
            }
        }

            ## If benchmark was successful- Reset the warnings
            if ($Global:Strike -ne $true) {
                Global:Set-Warnings clear "$($_.Type)"
                Global:Set-Warnings clear "$($_.Name)"
                Global:Set-Warnings clear "$($_.Name)_$($_.Algo)"
                Global:Set-Warnings clear "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
            }
     
            ## Strike-Out System. Will not work with Lite Mode
            if ($(arg).Lite -eq "No") {
                if ($Global:Strike -eq $true) {
                    if ($global:WasBenchmarked -eq $False) {

                        ## make dirs if they don't exit
                        $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($NewName)_hashrate.txt"
                        if (-not (Test-Path ".\timeout")) { New-Item "timeout" -ItemType "directory" | Out-Null }
                        if (-not (Test-Path ".\timeout\pool_block")) { New-Item -Path ".\timeout" -Name "pool_block" -ItemType "directory" | Out-Null }
                        if (-not (Test-Path ".\timeout\algo_block")) { New-Item -Path ".\timeout" -Name "algo_block" -ItemType "directory" | Out-Null }
                        if (-not (Test-Path ".\timeout\miner_block")) { New-Item -Path ".\timeout" -Name "miner_block" -ItemType "directory" | Out-Null }
                        if (-not (Test-Path ".\timeout\warnings")) { New-Item -Path ".\timeout" -Name "warnings" -ItemType "directory" | Out-Null }
                        Start-Sleep -S .25

                        ## Add To warnings is not present
                        Global:Set-Warnings add "$($_.Name)"
                        Global:Set-Warnings add "$($_.Name)_$($_.Algo)"
                        Global:Set-Warnings add "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
                        $n = $(vars).Warnings."$($_.Name)".bad

                        if ($(vars).Warnings."$($_.Name)".bad -ge $(arg).MinerBanCount) { $MinerBan = $true }
                        if ($(vars).Warnings."$($_.Name)_$($_.Algo)".bad -ge $(arg).AlgoBanCount) { $MinerAlgoBan = $true; }
                        if ($(vars).Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)".bad -ge $(arg).PoolBanCount) { $MinerPoolBan = $true }    

                        ##Strike One
                        if (-not $MinerPoolBan -and -not $MinerAlgoBan -and -not $MinerBan ) {
                            log "There was issue with benchmarking: Has occured $n times in an hour`n" -ForegroundColor DarkRed;
                        }
                            
                        ##Strike Two
                        if ($MinerPoolBan -eq $true) {
                            $reason = Global:Get-MinerTimeout($_)
                            $HiveMessage = "Ban: $($_.Algo):$($_.Name) From $($_.MinerPool)- $reason "
                            log "There was issue with benchmarking: Has occured $n times in the last hour" -ForegroundColor DarkRed;
                            log "$($_.Name) has exceeded Pool Ban Count: $HiveMessage `n" -ForegroundColor DarkRed                            
                            Global:Get-HiveWarning $HiveMessage
                            $NewPoolBlock = @()
                            if (Test-Path ".\timeout\pool_block\pool_block.txt") { $GetPoolBlock = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json }
                            Start-Sleep -S 1
                            if ($GetPoolBlock) { $GetPoolBlock | ForEach-Object { $NewPoolBlock += $_ } }
                            $NewPoolBlock += $_
                            $NewPoolBlock | ConvertTo-Json | Set-Content ".\timeout\pool_block\pool_block.txt"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
                            Start-Sleep -S 1
                        }
                            
                        ##Strike Three: He's Outta Here
                        if ($MinerAlgoBan -eq $true) {
                            $reason = Global:Get-MinerTimeout($_)
                            $HiveMessage = "Ban: $($_.Algo):$($_.Name) From All Pools- $reason "
                            log "There was issue with benchmarking: Has occured $n times in the last hour" -ForegroundColor DarkRed;
                            log "$($_.Name) has exceeded Algo Ban Count: $HiveMessage `n" -ForegroundColor DarkRed                            
                            Global:Get-HiveWarning $HiveMessage
                            $NewAlgoBlock = @()
                            if (Test-Path $HashRateFilePath) { Remove-Item $HashRateFilePath -Force }
                            if (Test-Path ".\timeout\algo_block\algo_block.txt") { $GetAlgoBlock = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json }
                            Start-Sleep -S 1
                            if ($GetAlgoBlock) { $GetAlgoBlock | ForEach-Object { $NewAlgoBlock += $_ } }
                            $NewAlgoBlock += $_
                            $NewAlgoBlock | ConvertTo-Json | Set-Content ".\timeout\algo_block\algo_block.txt"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)"
                            Start-Sleep -S 1
                        }

                        ##Strike Four: Miner is Finished
                        if ($MinerBan -eq $true) {
                            $HiveMessage = "Ban miner: $($_.Name):$($_.Type)- $reason "
                            log "There was issue with benchmarking: Has occured $n times in the last hour" -ForegroundColor DarkRed;
                            log "$($_.Name) has exceeded Miner Ban Count: $HiveMessage `n" -ForegroundColor DarkRed                            
                            log "$HiveMessage `n" -ForegroundColor DarkRed
                            Global:Get-HiveWarning $HiveMessage
                            $NewMinerBlock = @()
                            if (Test-Path $HashRateFilePath) { Remove-Item $HashRateFilePath -Force }
                            if (Test-Path ".\timeout\miner_block\miner_block.txt") { $GetMinerBlock = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json }
                            Start-Sleep -S 1
                            if ($GetMinerBlock) { $GetMinerBlock | ForEach-Object { $NewMinerBlock += $_ } }
                            $NewMinerBlock += $_
                            $NewMinerBlock | ConvertTo-Json | Set-Content ".\timeout\miner_block\miner_block.txt"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)"
                            Global:Set-Warnings clear "$($_.Name)"
                            Global:Set-Warnings add "$($_.Type)"
                            if ($(vars).Warnings."$($_.Type)".bad -ge $(arg).TypeBanCount ) { $TypeBan = $true }
                            Start-Sleep -S 1
                        }

                        ## Restart Computer
                        if ($TypeBan -eq $true) {
                            if ($_.Type -notlike "*ASIC*" -or $_.Type -ne "CPU") {
                                if ($(arg).Startup -eq "Yes") {
                                    $HiveMessage = "$($_.Type) Have timed out $( $(arg).TypeBanCount ) bad miners. Rebooting system..."
                                    log "$HiveMessage" -ForegroundColor Red
                                    Global:Get-HiveWarning $HiveMessage
                                    Start-Sleep -S 5
                                    Remove-Item ".\timeout" -Recurse -Force
                                    if ($IsWindows) { Restart-Computer -Force }
                                    elseif ($IsLinux) { Invoke-Expression "reboot" }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}