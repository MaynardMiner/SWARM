<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>
function Global:Get-MinerTimeout($miner) {

    $reason = "unknown error"

    if ($Miner.hashrate -eq 0 -or $null -eq $Miner.hashrate) {
        if ($null -eq $miner.xprocess) { $reason = "no start" }
        else {
            if ($Miner.Type -ne "*ASIC*") {
                $MinerProc = Get-Process | Where-Object Id -eq $miner.xprocess.id
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
            if ([string]$(vars).Warnings.$name.bad -ne "") { $(vars).Warnings = $(vars).Warnings | Where-Object $($_.keys -ne $name) }
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
    if (!$(vars).Downloads -and !$(vars).FirstRun) {
        $(vars).Previous_Miners = @()
        $(vars).BestActiveMiners | ForEach-Object {
            $(vars).Previous_Miners += $_
            ## Bools for bans
            $MinerPoolBan = $false
            $MinerAlgoBan = $false
            $MinerBan = $false
            $TypeBan = $False
            $Global:Strike = $false
            $global:WasBenchmarked = $false

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
                $Do_Benchmark = $false;
                if ($(vars).BenchmarkMode) {
                    if ($_.Hashrates -eq 0 -and $WasActive -ge ($(arg).Benchmark * 60)) {
                        $Do_Benchmark = $true
                    }
                    elseif ( $WasActive -ge $(vars).MinerStatInt) {
                        $Do_Benchmark = $true
                    }    
                }
                elseif ( $WasActive -ge $(vars).MinerStatInt) {
                    $Do_Benchmark = $true
                }
                if ($Do_Benchmark) {
                    log "$($_.Name) $($_.Symbol) Was Active for $WasActive Seconds"
                    log "Attempting to record hashrate for $($_.Name) $($_.Symbol)" -foregroundcolor "Cyan"
                    ##Check For High Rejections
                    $Rj = Global:Get-Rejections -Type $_.Type
                    $Percent = $RJ -split "`:" | Select-Object -First 1
                    $Percent = $RJ.replace("NaN", "0").Split(':') | Select-Object -First 1
                    $Shares = $RJ.Split(':') | Select-Object -Last 1
                    if ([Double]$Percent -gt $(arg).Rejections -and [Double]$Shares -gt 0) {
                        log "Rejection Percentage at $Percent out of $Shares shares- Adding Strike Against Miner" -Foreground Red
                        $Global:Strike = $True
                    }
                    for ($i = 0; $i -lt 4; $i++) {
                        $Miner_HashRates = $(Vars).Hashtable.$($_.Type).Hashrate;
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
                                $No_Watts = @("CPU", "ASIC")
                                if ($(arg).WattOMeter -eq "Yes" -and $_.Type -notin $No_Watts) {
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
                                $No_Watts = @("CPU", "ASIC")
                                if ($(arg).WattOMeter -eq "Yes" -and $_.Type -notin $No_Watts) { $GPUPower = "$($(vars).Hashtable.$($_.Type).watts.ToString("N2"))"; }
                                else { 
                                    $GPUPower = 1 
                                }
                                $No_Watts = @("CPU", "ASIC")
                                if ($(arg).WattOMeter -eq "Yes" -and $_.Type -notin $No_Watts) {
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
                                $Stat = Global:Set-Stat -Name "$($_.Name)_$($NewName)_hashrate" -Value $Miner_HashRates -Rejects $Percent -AsHashRate
                                $GetLiveStat = Global:Get-Stat "$($_.Name)_$($NewName)_hashrate"
                                $StatCheck = "$($GetLiveStat.Live.ToString("N2"))"
                                $ScreenCheck = "$($StatCheck | Global:ConvertTo-Hash)"
                                if ($ScreenCheck -eq "0.00 PH" -or $null -eq $StatCheck) {
                                    $Global:Strike = $true
                                    $global:WasBenchmarked = $False
                                    log "Stat Failed Write To File" -Foregroundcolor Red
                                }
                                else {
                                    log "Recorded Hashrate For $($_.Name) $($_.Symbol) Is $($ScreenCheck)" -foregroundcolor "magenta"
                                    $No_Watts = @("CPU", "ASIC")
                                    if ($(arg).WattOMeter -eq "Yes" -and $_.Type -notin $No_Watts) {
                                        log "Watt-O-Meter scored $($_.Name) $($_.Symbol) at $($GPUPower) Watts" -ForegroundColor magenta 
                                    }
                                    if (-not (Test-Path $NewHashrateFilePath)) {
                                        Copy-Item $HashrateFilePath -Destination $NewHashrateFilePath -force
                                        log "$($_.Name) $($_.Symbol) Was Benchmarked And Backed Up" -foregroundcolor yellow
                                    }
                                    $global:WasBenchmarked = $True
                                    log "Stat Written" -foregroundcolor green
                                    log "Was this stat not correct? You can run command 'bench miner $($_.Name) $($_.algo)' to reset benchmark" -foregroundcolor cyan
                                    if ($IsWindows) { log "There is also a batch file labeled swarm_start_$($_.algo).bat for testing in .\bin\$($_.name)`n" -foregroundcolor cyan }
                                    if ($IsLinux) { log "There is also a bash file labeled swarm_start_$($_.algo).sh for testing in .\bin\$($_.name)`n" -foregroundcolor cyan }
                                    $Global:Strike = $false
                                    $i = 5;
                                } 
                            }
                        }
                    }
                }
                else {
                    log "$($_.Name) $($_.Symbol) has not ran for $($(vars).MinerStatInt) seconds, skipping benchmark" -Foreground magenta
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

                        ## Add To warnings is not present
                        Global:Set-Warnings add "$($_.Name)"
                        Global:Set-Warnings add "$($_.Name)_$($_.Algo)"
                        Global:Set-Warnings add "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
                        $n = $(vars).Warnings."$($_.Name)".bad

                        if ($(vars).Warnings."$($_.Name)".bad -ge $(arg).MinerBanCount) { $MinerBan = $true }
                        if ($(vars).Warnings."$($_.Name)_$($_.Algo)".bad -ge $(arg).AlgoBanCount) { $MinerAlgoBan = $true; }
                        if ($(arg).Poolname.Count -gt 1) { if ($(vars).Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)".bad -ge $(arg).PoolBanCount) { $MinerPoolBan = $true } }

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
                            if ($GetPoolBlock) { $GetPoolBlock | ForEach-Object { $NewPoolBlock += $_ | Select-Object -ExcludeProperty Xprocess } }
                            $NewPoolBlock += $_
                            $NewPoolBlock | ConvertTo-Json | Set-Content ".\timeout\pool_block\pool_block.txt"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
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
                            if ($GetAlgoBlock) { $GetAlgoBlock | ForEach-Object { $NewAlgoBlock += $_ | Select-Object -ExcludeProperty Xprocess } }
                            $NewAlgoBlock += $_
                            $NewAlgoBlock | ConvertTo-Json | Set-Content ".\timeout\algo_block\algo_block.txt"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)"
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
                            if ($GetMinerBlock) { $GetMinerBlock | ForEach-Object { $NewMinerBlock += $_ | Select-Object -ExcludeProperty Xprocess } }
                            $NewMinerBlock += $_
                            $NewMinerBlock | ConvertTo-Json | Set-Content ".\timeout\miner_block\miner_block.txt"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)_$($_.MinerPool)"
                            Global:Set-Warnings clear "$($_.Name)_$($_.Algo)"
                            Global:Set-Warnings clear "$($_.Name)"
                            Global:Set-Warnings add "$($_.Type)"
                            if ($(vars).Warnings."$($_.Type)".bad -ge $(arg).TypeBanCount ) { $TypeBan = $true }
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
    else {
        log "SWARM does not benchmark right after a miner was downloaded" -Foreground Yellow;
        $(vars).Downloads = $false;
    }
}