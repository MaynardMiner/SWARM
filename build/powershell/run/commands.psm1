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

function Global:Get-StatusLite {
    $screen = @()
    $(arg).Type | ForEach-Object {
        $screen += 
        "
########################
    Group: $($_)
########################
"
        $Table = $(vars).Miners | Where-Object TYPE -eq $_ | Sort-Object -Property Profit -Descending
        $statindex = 1

        $Table | ForEach-Object { 

            if ($statindex -eq 1) { $Screen += "# 1 Miner:" }
            else { $Screen += "Postion $($statindex): " }

            $Screen += 
            "        Miner: $($_.Name)
        Mining: $($_.ScreenName)
        Speed: $($_.HashRates | ForEach-Object {if ($null -ne $_) {"$($_ | Global:ConvertTo-Hash)/s"}else {"Benchmarking"}})
        Profit: $($_.Profit | ForEach-Object {if ($null -ne $_) {"$(($_ * $(vars).Rates.$($(arg).Currency)).ToString("N2")) $($(arg).Currency)/Day"}else {"Bench"}}) 
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

function Global:Get-PriceMessage {
    $Total = 0;
    $(vars).BestActiveMIners | ForEach-Object {
        if ($_.Profit_Day -ne "bench") { $ScreenProfit = "$($Value = $_.Profit_Day * $(vars).Rates.$($(arg).Currency); $Total += $Value; $Value.ToString("N2")) $($(arg).Currency)/Day" } else { $ScreenProfit = "Benchmarking" }
        $ProfitMessage = "Current Daily Profit For $($_.Type): $ScreenProfit"
        $ProfitMessage | Out-File ".\debug\minerstats.txt" -Append
        $ProfitMessage | Out-File ".\debug\charts.txt" -Append
    }
    $ProfitMessage = "Current Daily Profit For Rig: $($Total.ToString("N2")) $($(arg).Currency)/Day"
    $ProfitMessage | Out-File ".\debug\minerstats.txt" -Append
    $ProfitMessage | Out-File ".\debug\charts.txt" -Append
}


function Global:Get-Commands {
    $GetStatusAlgoBans = ".\timeout\algo_block\algo_block.txt"
    $GetStatusPoolBans = ".\timeout\pool_block\pool_block.txt"
    $GetStatusMinerBans = ".\timeout\miner_block\miner_block.txt"
    $GetStatusDownloadBans = ".\timeout\download_block\download_block.txt"
    $StatusDownloadBans = $null
    $StatusAlgoBans = $null
    $StatusPoolBans = $null
    $StatusMinerBans = $null
    if (Test-Path $GetStatusDownloadBans) { $StatusDownloadBans = Get-Content $GetStatusDownloadBans | ConvertFrom-Json }
    if (Test-Path $GetStatusAlgoBans) { $StatusAlgoBans = Get-Content $GetStatusAlgoBans | ConvertFrom-Json }
    if (Test-Path $GetStatusPoolBans) { $StatusPoolBans = Get-Content $GetStatusPoolBans | ConvertFrom-Json }
    if (Test-Path $GetStatusMinerBans) { $StatusMinerBans = Get-Content $GetStatusMinerBans | ConvertFrom-Json }
    $mcolor = "93"
    $me = [char]27
    $MiningStatus = "$me[${mcolor}mCurrently Mining $($(vars).bestminers_combo.Algo) Algorithm on $($(vars).bestminers_combo.MinerPool)${me}[0m"
    $MiningStatus | Out-File ".\debug\minerstats.txt" -Append
    $MiningStatus | Out-File ".\debug\charts.txt" -Append
    $(vars).Thresholds | Out-File ".\debug\minerstats.txt" -Append
    $(vars).Thresholds | Out-File ".\debug\charts.txt" -Append
    $BanMessage = @()
    $mcolor = "91"
    $me = [char]27
    if ($StatusAlgoBans) { $StatusAlgoBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from all pools${me}[0m" } }
    if ($StatusPoolBans) { $StatusPoolBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from $($_.MinerPool)${me}[0m" } }
    if ($StatusMinerBans) { $StatusMinerBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) is banned${me}[0m" } }
    if ($StatusDownloadBans) { $StatusDownloadBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) is banned: Download Failed${me}[0m" } }
    if ($GetDLBans) { $GetDLBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_) failed to download${me}[0m" } }
    if ($ConserveMessage) { $ConserveMessage | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_)${me}[0m" } }
    $BanMessage | Out-File ".\debug\minerstats.txt" -Append
    $BanMessage | Out-File ".\debug\charts.txt" -Append
    $StatusLite = Global:Get-StatusLite
    $StatusDate = Get-Date
    $StatusDate | Out-File ".\debug\minerstatslite.txt"
    $StatusLite | Out-File ".\debug\minerstatslite.txt" -Append
    $BanMessage | Out-File ".\debug\minerstatslite.txt" -Append
    $MiningStatus | Out-File ".\debug\minerstatslite.txt" -Append
}

function Global:Get-Logo {
    log '
                                                                        (                    (      *     
                                                                         )\ ) (  (      (     )\ ) (  `
                                                                         (()/( )\))(     )\   (()/( )\))(   
                                                                          /(_)|(_)()\ |(((_)(  /(_)|(_)()\  
                                                                         (_)) _(())\_)()\ _ )\(_)) (_()((_) 
                                                                         / __|\ \((_)/ (_)_\(_) _ \|  \/  | 
                                                                         \__ \ \ \/\/ / / _ \ |   /| |\/| | 
                                                                         |___/  \_/\_/ /_/ \_\|_|_\|_|  |_| 
                                                                                                          ' -foregroundcolor "DarkRed"
    log '                                                           sudo apt-get lambo
                                                                                 
                                                                                 
                                                                                 
                                                                                 ' -foregroundcolor "Yellow"
}

function Global:Get-MinerActive {
    $(vars).ActiveMinerPrograms | Sort-Object -Descending Status, Instance | Select-Object -First (1 + 6 + 6) | Format-Table -Wrap -GroupBy Status (
        @{Label = "Name"; Expression = { "$($_.Name)" } },
        @{Label = "#"; Expression = { "$($_.Instance)" } },
        @{Label = "Active"; Expression = { "{0:hh} Hours {0:mm} Minutes" -f $(if ($null -eq $_.XProcess) { $_.Active }else { if ($_.XProcess.HasExited) { ($_.Active) }else { ($_.Active + ((Get-Date) - $_.XProcess.StartTime)) } }) }; Align = 'center' },
        @{Label = "Launched"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_ Times" } } }; Align = 'center' },
        @{Label = "Command"; Expression = { "$($_.MinerName) $($_.Devices) $($_.Arguments)" } }
    )
}
