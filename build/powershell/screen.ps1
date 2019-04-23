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


function Get-Charts {
    $Status = @()
    $Status += ""
    $Power = "|"
    $Power_Levels = @{ }
    $WattTable = $false
    $ProfitTable | ForEach-Object { if ($_.Power -ne 0) { $WattTable = $True } }

    $Type | ForEach-Object {
        $Table = $ProfitTable | Where-Object TYPE -eq $_;
        $global:index = $Table.Count
    
        $Table | ForEach-Object { $Power_Levels.Add("$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)", @{ }) }
        ##Profit Levels
        $Level = $null
        $Table | Sort-Object -Property Profits | ForEach-Object { if ($Null -ne $_.Profits) { $Profit = ($_.Profits * $Rates.$Currency).ToString("N2"); $MinerName = "$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("Profit", "$Level $Profit $Currency/Day"); } }
        $Level = $null
        if($CoinExchange){$Table | Sort-Object -Property Pool_Estimate | ForEach-Object { if ($_.Pool_Estimate -gt 0) { $Profit = ($_.Pool_Estimate / $BTCExchangeRate).ToString("N5"); $MinerName = "$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("Alt_Profit", "$Level $Profit $Y/Day"); } }}
        $Level = $null
        $Table | Sort-Object -Property Profits | ForEach-Object { if ($Null -ne $_.Profits) { $Profit = ($_.Profits).ToString("N5"); $MinerName = "$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("BTC_Profit", "$Level $Profit BTC/Day"); } }
        $Level = $null
        $Table | Sort-Object -Property HashRates | ForEach-Object { if ($Null -ne $_.HashRates) { $HashRate = "$($_.HashRates | ConvertTo-Hash)/s"; $MinerName = "$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("Hashrate", "$Level $Hashrate"); } }
        $Level = $null
        $Table | Sort-Object -Property Shares | ForEach-Object { if ($Null -ne $_.Shares) { if ($_.Shares -eq "N/A") { $_.Shares = 0 }else { $_.Shares = $($_.Shares -as [Decimal]).ToString("N3") }; $Shares = "$($_.Shares)"; $MinerName = "$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; if ($_.Shares -ne 0) { $Level = $Level + $Power }else { $Level = "|" }; $Power_Levels.$MinerName.Add("Shares", "$Level $Shares %"); } }
        $Level = $null
        if ($WattTable -eq $true) { $Table | Sort-Object -Property Power | ForEach-Object { if ($_.Power -ne 0) { $Pwatts = ($_.Power * $Rates.$Currency).ToString("N2"); $MinerName = "$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"; $Level = $Level + $Power; $Power_Levels.$MinerName.Add("Watts", "$Level $PWatts $Currency/Day"); } }}
    }

    $Type | ForEach-Object {
        $Table = $ProfitTable | Where-Object TYPE -eq $_;
        $Border_Lt = @()
        $Status += "GROUP $($_)"
        $Status += ""
    
        $Table | ForEach-Object {
            $MinerName = "$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"
            $Border_Lt += $($Power_Levels.$MinerName.BTC_Profit | Measure-Object -Character).Characters  
        }
        $Border = $($Border_Lt | Measure-Object -Maximum).Maximum + 15
        $Table | Sort-Object -Property Profits -Descending | ForEach-Object {
            $MinerName = "$($_.Name)_$($_.Miner)_$($_.MinerPool)_$($_.Type)"
            $me = [char]27;
            $white = "37";
            $blue = "34";
            $yellow = "33";
            $green = "32";
            $cyan = "36";
            $red = "31";
            $magenta = "35";
            $HLevel = "Hashrate:"
            $HStat = if ($Null -ne $_.Hashrates) { "$me[${red};1m$($Power_Levels.$MinerName.Hashrate)${me}[0m" }else { "$me[${red};1mBenchmarking${me}[0m" }
            $CLevel = "$Currency Profit:"
            $CStat = if ($Null -ne $_.Profits) { "$me[${green};1m$($Power_Levels.$MinerName.Profit)${me}[0m" }else { "$me[${green};1mBenchmarking${me}[0m" }
            $BLevel = "BTC Profit:"
            $BStat = if ($Null -ne $_.Profits) { "$me[${yellow};1m$($Power_Levels.$MinerName.BTC_Profit)${me}[0m" }else { "$me[${yellow};1mBenchmarking${me}[0m" }
            if($CoinExchange) {
                $ALevel = "$CoinExchange Profit:"
                $AStat = if ($_.Pool_Estimate -gt 0) { "$me[${cyan};1m$($Power_Levels.$MinerName.ALT_Profit)${me}[0m" }else { "$me[${cyan};1mBenchmarking${me}[0m" }
                }
            $SLevel = "Shares:"
            $SStat = if ($Null -ne $_.Shares) { "$me[${blue};1m$($Power_Levels.$MinerName.Shares)${me}[0m" }else { "$me[${blue};1mBenchmarking${me}[0m" }
            if($WattTable -eq $true) {
            $Wlevel = "Watts:"
            $WStat = if ($_.Power -ne 0) { "$me[${magenta};1m$($Power_Levels.$MinerName.Watts)${me}[0m" }else { "$me[${magenta};1mBenchmarking${me}[0m" }
            }
            $Table_Item = @();
            $TableName = "$me[${white};1mName: $($_.Miner)${me}[0m"; 
            $TableSymbol = "$me[${white};1mCoin: $($_.Name)${me}[0m"; 
            $TablePool = "$me[${white};1mPool: $($_.MinerPool)${me}[0m"; 
            $Table_Item += "$($TableName.PadRight(40," ")) $($TableSymbol.PadRight(40," ")) $TablePool"
            $Table_Item += "".PadLeft($Border, "*")
            $Table_Item += "$me[${white};1m$($HLevel.PadRight(14))${me}[0m $HStat"
            $Table_Item += "$me[${white};1m$($CLevel.PadRight(14))${me}[0m $CStat"
            $Table_Item += "$me[${white};1m$($SLevel.PadRight(14))${me}[0m $SStat"
            $Table_Item += "$me[${white};1m$($BLevel.PadRight(14))${me}[0m $BStat"
            if($CoinExchange) {
            $Table_Item += "$me[${white};1m$($ALevel.PadRight(14))${me}[0m $AStat"
            }
            if($WattTable -eq $true) {
                $Table_Item += "$me[${white};1m$($WLevel.PadRight(14))${me}[0m $WStat"
            }
            $Table_Item += "".PadLeft($Border, "*")
            $Status += $Table_Item
        }
        $Status += ""
        $Status += ""
    }
    $Status
} 


function Get-MinerStatus {
    $WattTable = $false
    $ProfitTable | ForEach-Object { if ($_.Power -gt 0) { $WattTable = $True } }
    $Type | ForEach-Object {
        $Table = $ProfitTable | Where-Object TYPE -eq $_;
        $global:index = 0
        if ($WattTable) {
            if ($CoinExchange) {
                $Table | Sort-Object -Property Profits -Descending | Format-Table -GroupBy Type (
                    @{Label = "Miner"; Expression = { "$global:index $($_.Miner)"; $global:index += 1 }; },
                    @{Label = "Coin"; Expression = { $($_.Name) } },
                    @{Label = "Speed"; Expression = { $($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$($_ | ConvertTo-Hash)/s" }else { "Bench" } } }; Align = 'center' },
                    @{Label = "Watt/Day"; Expression = { $($_.Power) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.$Currency).ToString("N2") }else { "Bench" } } }; Align = 'center' },
                    @{Label = "BTC/Day"; Expression = { $($_.Profits) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } } }; Align = 'right' },
                    @{Label = "$Y/Day"; Expression = { $($_.Pool_Estimate) | ForEach-Object { if ($null -ne $_) { ($_ / $BTCExchangeRate).ToString("N5") }else { "Bench" } } }; Align = 'right' },
                    @{Label = "$Currency/Day"; Expression = { $($_.Profits) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.$Currency).ToString("N2") }else { "Bench" } } }; Align = 'center' },
                    @{Label = "Pool"; Expression = { $($_.MinerPool) }; Align = 'center' },
                    @{Label = "Shares"; Expression = { $($_.Shares -as [Decimal]).ToString("N2") }; Align = 'center' },
                    @{Label = "Vol."; Expression = { $($_.Volume) | ForEach-Object { if ($null -ne $_) { $_.ToString("N2") }else { "Bench" } } }; Align = 'left' }
                )
            }
            else {
                $Table | Sort-Object -Property Profits -Descending | Format-Table -GroupBy Type (
                    @{Label = "Miner"; Expression = { "$global:index $($_.Miner)"; $global:index += 1 }; },
                    @{Label = "Coin"; Expression = { $($_.Name) } },
                    @{Label = "Speed"; Expression = { $($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$($_ | ConvertTo-Hash)/s" }else { "Bench" } } }; Align = 'center' },
                    @{Label = "Watt/Day"; Expression = { $($_.Power) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.$Currency).ToString("N2") }else { "Bench" } } }; Align = 'center' },
                    @{Label = "BTC/Day"; Expression = { $($_.Profits) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } } }; Align = 'right' },
                    @{Label = "$Currency/Day"; Expression = { $($_.Profits) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.$Currency).ToString("N2") }else { "Bench" } } }; Align = 'center' },
                    @{Label = "Pool"; Expression = { $($_.MinerPool) }; Align = 'center' },
                    @{Label = "Shares"; Expression = { $($_.Shares -as [Decimal]).ToString("N2") }; Align = 'center' },
                    @{Label = "Vol."; Expression = { $($_.Volume) | ForEach-Object { if ($null -ne $_) { $_.ToString("N2") }else { "Bench" } } }; Align = 'left' }
                )
            }
        }
        else {
            if ($CoinExchange) {
                $Table | Sort-Object -Property Profits -Descending | Format-Table -GroupBy Type (
                    @{Label = "Miner"; Expression = { "$global:index $($_.Miner)"; $global:index += 1 }; },
                    @{Label = "Coin"; Expression = { $($_.Name) } },
                    @{Label = "Speed"; Expression = { $($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$($_ | ConvertTo-Hash)/s" }else { "Bench" } } }; Align = 'center' },
                    @{Label = "BTC/Day"; Expression = { $($_.Profits) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } } }; Align = 'right' },
                    @{Label = "$Y/Day"; Expression = { $($_.Pool_Estimate) | ForEach-Object { if ($null -ne $_) { ($_ / $BTCExchangeRate).ToString("N5") }else { "Bench" } } }; Align = 'right' },
                    @{Label = "$Currency/Day"; Expression = { $($_.Profits) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.$Currency).ToString("N2") }else { "Bench" } } }; Align = 'center' },
                    @{Label = "Pool"; Expression = { $($_.MinerPool) }; Align = 'center' },
                    @{Label = "Shares"; Expression = { $($_.Shares -as [Decimal]).ToString("N2") }; Align = 'center' },
                    @{Label = "Vol."; Expression = { $($_.Volume) | ForEach-Object { if ($null -ne $_) { $_.ToString("N2") }else { "Bench" } } }; Align = 'left' }
                )
            }
            else {
                $Table | Sort-Object -Property Profits -Descending | Format-Table -GroupBy Type (
                    @{Label = "Miner"; Expression = { "$global:index $($_.Miner)"; $global:index += 1 }; },
                    @{Label = "Coin"; Expression = { $($_.Name) } },
                    @{Label = "Speed"; Expression = { $($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$($_ | ConvertTo-Hash)/s" }else { "Bench" } } }; Align = 'center' },
                    @{Label = "BTC/Day"; Expression = { $($_.Profits) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } } }; Align = 'right' },
                    @{Label = "$Currency/Day"; Expression = { $($_.Profits) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.$Currency).ToString("N2") }else { "Bench" } } }; Align = 'center' },
                    @{Label = "Pool"; Expression = { $($_.MinerPool) }; Align = 'center' },
                    @{Label = "Shares"; Expression = { $($_.Shares -as [Decimal]).ToString("N2") }; Align = 'center' },
                    @{Label = "Vol."; Expression = { $($_.Volume) | ForEach-Object { if ($null -ne $_) { $_.ToString("N2") }else { "Bench" } } }; Align = 'left' }
                )
            }

        }
    }
}

function Get-StatusLite {
    $screen = @()
    $Type | ForEach-Object {
        $screen += 
        "
########################
    Group: $($_)
########################
"
        $Table = $ProfitTable | Where-Object TYPE -eq $_ | Sort-Object -Property Profits -Descending
        $statindex = 1

        $Table | ForEach-Object { 

            if ($statindex -eq 1) { $Screen += "# 1 Miner:" }
            else { $Screen += "Postion $($statindex): " }

            $Screen += 
            "        Miner: $($_.Miner)
        Speed: $($_.HashRates | ForEach-Object {if ($null -ne $_) {"$($_ | ConvertTo-Hash)/s"}else {"Benchmarking"}})
        Profit: $($_.Profits | ForEach-Object {if ($null -ne $_) {"$(($_ * $Rates.$Currency).ToString("N2")) $Currency/Day"}else {"Bench"}}) 
        Pool: $($_.MinerPool)
        Shares: $($($_.Shares -as [Decimal]).ToString("N3"))
"
        
            $statindex++
        }
        $screen += "
########################
########################

" 
    }
    $screen
}

function Invoke-MinerWarning {
    ##Notify User Of Failures
    Write-Host "
       
There are miners that have failed! Check Your Settings And Arguments!
" -ForegroundColor DarkRed
    if ($Platform -eq "linux") {
        Write-Host "Type `'mine`' in another terminal to see background miner, and its reason for failure.
You may also view logs with in the "logs" directory, or 'get-screen [Type]'
If miner is not your primary miner (AMD1 or NVIDIA1), type 'screen -r [Type]'
https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration) >> Right Click 'Open URL In Browser'
" -ForegroundColor Darkred
    }
    elseif ($Platform -eq "windows") {
        Write-Host "SWARM attempted to catch screen output, and is stored in 'logs' folder.
 SWARM has also created a executable called 'swarm-start.bat' located in the 'bin'
 directory and folder of the miner. 'swarm-start.bat' starts miner with last known settings, 
 and window stays open, so you may view issue.
" -ForegroundColor DarkRed
    }
    Start-Sleep -s 10
}

function Invoke-MinerSuccess1 {
    Write-Host "         
        
                         //\\  _______
                        //  \\//~//.--|
                        Y   /\\~~//_  |
                       _L  |_((_|___L_|
                      (/\)(____(_______)      
Waiting 15 Seconds For Miners To Load & Restarting Background Tracking
" -ForegroundColor Magenta
    if ($Platform -eq "linux") {
        Write-Host "Type 'mine' in another terminal to see miner working- This is NOT a remote command!

Type 'get-screen [MinerType]' to see last 100 lines of log- This IS a remote command!

https://github.com/MaynardMiner/SWARM/wiki/Commands-&-Suggested-Apps For More Info'  

" -ForegroundColor Magenta
    }
    elseif ($Platform -eq "windows") {
        Write-Host "There is now a new window where miner is working. The output may be different from

using without SWARM, as SWARM is logging miner data. Agent window will show SWARM real time

tracking of algorithms and GPU information. It can be used to observe issues, if any.
" -foreground Magenta
    }
    Start-Sleep -s 15
}

function Invoke-MinerSuccess2 {
    Write-Host "         
         
                        //\\  _______
                       //  \\//~//.--|
                       Y   /\\~~//_  |
                      _L  |_((_|___L_|
                     (/\)(____(_______)      
Waiting 20 Seconds For Miners To Load & Restarting Background Tracking"
    Start-Sleep -s 15
}

function Invoke-NoChange {
    Write-Host "
        
        
Most Profitable Miners Are Running


" -foreground DarkCyan
    Start-Sleep -s 5
}

function Print-Benchmarking {
    $Message = 
    "

SWARM is now benchmarking miners. It will only be able to 
properly calculate stats once miners finish benchmarking.
   
Note: Only one miner per algorithm and platform will show on stats 
screen. While benchmarking, miner will choose a miner that needs to be
benched, leaving previously benchmarked miners to vanish from stats 
screen. They will return if benchmarks were higher than current miner.
    
This is normal behavior.
   
To see all miner benchmarks that have been performed use:
get benchmarks
command"

    $Message | Out-File ".\build\txt\minerstats.txt" -Append     
}


function Get-MinerActive {

    $ActiveMinerPrograms | Sort-Object -Descending Status,
    { if ($null -eq $_.XProcess) { [DateTime]0 }else {$_.XProcess.StartTime }
    } | Select-Object -First (1 + 6 + 6) | Format-Table -Wrap -GroupBy Status (
        @{Label = "Name"; Expression = { "$($_.Name)" } },
        @{Label = "Active"; Expression = { "{0:dd} Days {0:hh} Hours {0:mm} Minutes" -f $(if ($null -eq $_.XProcess) { $_.Active }else { if ($_.XProcess.HasExited) { ($_.Active) }else { ($_.Active + ((Get-Date) - $_.XProcess.StartTime)) } }) } },
        @{Label = "Launched"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_ Times" } } } },
        @{Label = "Command"; Expression = { "$($_.MinerName) $($_.Devices) $($_.Arguments)" } }
    )
}

function Get-Logo {
    Write-Host '
                                                                        (                    (      *     
                                                                         )\ ) (  (      (     )\ ) (  `    
                                                                         (()/( )\))(     )\   (()/( )\))(   
                                                                          /(_)|(_)()\ |(((_)(  /(_)|(_)()\  
                                                                         (_)) _(())\_)()\ _ )\(_)) (_()((_) 
                                                                         / __|\ \((_)/ (_)_\(_) _ \|  \/  | 
                                                                         \__ \ \ \/\/ / / _ \ |   /| |\/| | 
                                                                         |___/  \_/\_/ /_/ \_\|_|_\|_|  |_| 
                                                                                                                                                  ' -foregroundcolor "DarkRed"
    Write-Host "                                                                                  sudo apt-get lambo" -foregroundcolor "Yellow"
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
}

function Restart-Miner {
    $BestActiveMiners | ForEach-Object {
        $Restart = $false
        if ($_.XProcess -eq $null -or $_.XProcess.HasExited -and $Lite -eq "No") {
            if ($TimeDeviation -ne 0) {
                $Restart = $true
                $_.Activated++
                $_.InstanceName = "$($_.Type)-$($Instance)"
                $Current = $_ | ConvertTo-Json -Compress
                if($_.Type -ne "ASIC"){$PreviousPorts = $PreviousMinerPorts | ConvertTo-Json -Compress}
                if($_.Type -ne "ASIC"){$_.Xprocess = Start-LaunchCode -PP $PreviousPorts -Platforms $Platform -NewMiner $Current}
                else{$_.Xprocess = Start-LaunchCode -Platforms $Platform -NewMiner $Current -AIP $ASIC_IP}
                $Instance++
            }
            if ($Restart -eq $true) {
                if ($null -eq $_.XProcess -or $_.XProcess.HasExited) {
                    $_.Status = "Failed"
                    $NoMiners = $true
                    Write-Host "$($_.MinerName) Failed To Launch" -ForegroundColor Darkred
                }
                else {
                    $_.Status = "Running"
                    Write-Host "[$(Get-Date)]: " -foreground yellow -nonewline
                    Write-Host "$($_.MinerName) Is Running!" -ForegroundColor Green
                }
                Write-Host "
           
                 //\\  _______
                //  \\//~//.--|
                Y   /\\~~//_  |
               _L  |_((_|___L_|
              (/\)(____(_______)        
           
     Waiting 20 Seconds For Miners To Fully Load
   
      " 
                Start-Sleep -s 20
            }
        }
     }
  }

function Get-MinerHashRate {
    $BestActiveMiners | ForEach-Object {
        if($_.Profit_Day -ne "bench"){ $ScreenProfit = "$(($_.Profit_Day * $Rates.$Currency).ToString("N2")) $Currency/Day" } else{ $ScreenProfit = "Benchmarking" }
        if($_.Fiat_Day -ne "bench"){ $CurrentProfit = "$($_.Fiat_Day) $Currency/Day" } else { $CurrentProfit = "Benchmarking" }
        if ($null -eq $_.Xprocess -or $_.XProcess.HasExited) { $_.Status = "Failed" }
        $Miner_HashRates = Get-HashRate -Type $_.Type
        $GetDayStat = Get-Stat "$($_.Name)_$($_.Algo)_HashRate"
        $DayStat = "$($GetDayStat.Day)"
        $MinerPrevious = "$($DayStat | ConvertTo-Hash)"
        $ScreenHash = "$($Miner_HashRates | ConvertTo-Hash)"
        Write-Host "[$(Get-Date)]: " -foreground yellow -nonewline
        Write-Host "$($_.Type) is currently" -foreground green -nonewline
        if ($_.Status -eq "Running") { $MinerStatus = Write-Host " Running: " -ForegroundColor green -nonewline }
        if ($_.Status -eq "Failed") { $MinerStatus = Write-Host " Not Running: " -ForegroundColor darkred -nonewline } 
        $MinerStatus
        Write-Host "$($_.Name) current hashrate for $($_.Symbol) is" -nonewline
        Write-Host " $ScreenHash/s" -foreground green
        Write-Host "[$(Get-Date)]: " -foreground yellow -nonewline
        Write-Host "$($_.Type) is currently mining on $($_.MinerPool)" -foregroundcolor Cyan
        Write-Host "[$(Get-Date)]: " -foreground yellow -nonewline
        Write-Host "$($_.Type) previous hashrates for $($_.Symbol) is" -nonewline
        Write-Host " $MinerPrevious/s" -foreground yellow
        Write-Host "[$(Get-Date)]: " -foreground yellow -nonewline
        Write-Host "Current Profit Rating: $CurrentProfit"
        Write-Host "[$(Get-Date)]: " -foreground yellow -nonewline
        Write-Host "Current Daily Profit: $ScreenProfit
"
    }
}

function Set-Countdown {
    if ($SWARM_Mode -eq "Yes" -and $BenchmarkMode -eq $false) { $CountDown = Invoke-SWARMMode $SwitchTime; $CountDown = $Countdown * -1 }
    else { $Countdown = ([math]::Round(($MinerInterval - 20) - $MinerWatch.Elapsed.TotalSeconds)) }
    if ($SWARM_Mode -eq "Yes" -and $BenchmarkMode -eq $false) { $CountMessage = "SWARM Mode Starts: $($Countdown) seconds" }
    else { $CountMessage = "Time Left Until Database Starts: $($Countdown) seconds" }
    Write-Host "[$(Get-Date)]: " -foreground yellow -nonewline
    Write-Host "$CountMessage 
"-foreground DarkMagenta
}

function Restart-Database {
    $Restart = "No"
    $BestActiveMiners | ForEach-Object {
            if ($null -eq $_.XProcess -or $_.XProcess.HasExited) {
                $_.Status = "Failed"
                $Restart = "Yes"
            }
        else {
            $Miner_HashRates = Get-HashRate -Type $_.Type
            $ScreenHash = "$($Miner_HashRates | ConvertTo-Hash)"
            if ($ScreenHash -eq "0.00PH" -or $ScreenHash -eq '') {
                if ($BenchmarkMode -eq $false) {
                    $_.Status = "Failed"
                    $Restart = "Yes"
                }
            }
        }
    }
    $Restart
}

function Get-VM {
    ps powershell* | Select-Object *memory* | Format-Table -auto `
    @{Name = 'Virtual Memory Size (MB)'; Expression = { ($_.VirtualMemorySize64) / 1MB }; Align = 'center' }, `
    @{Name = 'Private Memory Size (MB)'; Expression = { (  $_.PrivateMemorySize64) / 1MB }; Align = 'center' },
    @{Name = 'Memory Used This Session (MB)'; Expression = { ([System.gc]::gettotalmemory("forcefullcollection") / 1MB) }; Align = 'center' }
}

function Print-WattOMeter {
    Write-Host "

  Starting Watt-O-Meter
       __________
      |   ____   |
      |  /    \  |
      | | .''. | |
      | |   /  | |
      |==========|
      |   WATT   |
      |__________|
    
  " -foregroundcolor yellow
}