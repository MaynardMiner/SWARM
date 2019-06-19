function Global:Get-StatusLite {
    $screen = @()
    $(arg).Type | ForEach-Object {
        $screen += 
        "
########################
    Group: $($_)
########################
"
        $Table = $Global:Miners | Where-Object TYPE -eq $_ | Sort-Object -Property Profit -Descending
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
    $(vars).BestActiveMIners | % {
        if ($_.Profit_Day -ne "bench") { $ScreenProfit = "$(($_.Profit_Day * $(vars).Rates.$($(arg).Currency)).ToString("N2")) $($(arg).Currency)/Day" } else { $ScreenProfit = "Benchmarking" }
        $ProfitMessage = "Current Daily Profit For $($_.Type): $ScreenProfit"
        $ProfitMessage | Out-File ".\build\txt\minerstats.txt" -Append
        $ProfitMessage | Out-File ".\build\txt\charts.txt" -Append
    }
}


function Global:Get-Commands {
    $GetStatusAlgoBans = ".\timeout\algo_block\algo_block.txt"
    $GetStatusPoolBans = ".\timeout\pool_block\pool_block.txt"
    $GetStatusMinerBans = ".\timeout\miner_block\miner_block.txt"
    $GetStatusDownloadBans = ".\timeout\download_block\download_block.txt"
    if (Test-Path $GetStatusDownloadBans) { $StatusDownloadBans = Get-Content $GetStatusDownloadBans | ConvertFrom-Json }
    else { $StatusDownloadBans = $null }
    if (Test-Path $GetStatusAlgoBans) { $StatusAlgoBans = Get-Content $GetStatusAlgoBans | ConvertFrom-Json }
    else { $StatusAlgoBans = $null }
    if (Test-Path $GetStatusPoolBans) { $StatusPoolBans = Get-Content $GetStatusPoolBans | ConvertFrom-Json }
    else { $StatusPoolBans = $null }
    if (Test-Path $GetStatusMinerBans) { $StatusMinerBans = Get-Content $GetStatusMinerBans | ConvertFrom-Json }
    else { $StatusMinerBans = $null }
    $mcolor = "93"
    $me = [char]27
    $MiningStatus = "$me[${mcolor}mCurrently Mining $($global:bestminers_combo.Algo) Algorithm on $($global:bestminers_combo.MinerPool)${me}[0m"
    $MiningStatus | Out-File ".\build\txt\minerstats.txt" -Append
    $MiningStatus | Out-File ".\build\txt\charts.txt" -Append
    $(vars).Thresholds | Out-File ".\build\txt\minerstats.txt" -Append
    $(vars).Thresholds | Out-File ".\build\txt\charts.txt" -Append
    $BanMessage = @()
    $mcolor = "91"
    $me = [char]27
    if ($StatusAlgoBans) { $StatusAlgoBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from all pools${me}[0m" } }
    if ($StatusPoolBans) { $StatusPoolBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from $($_.MinerPool)${me}[0m" } }
    if ($StatusMinerBans) { $StatusMinerBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) is banned${me}[0m" } }
    if ($StatusDownloadBans) { $StatusDownloadBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) is banned: Download Failed${me}[0m" } }
    if ($GetDLBans) { $GetDLBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_) failed to download${me}[0m" } }
    if ($ConserveMessage) { $ConserveMessage | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_)${me}[0m" } }
    $BanMessage | Out-File ".\build\txt\minerstats.txt" -Append
    $BanMessage | Out-File ".\build\txt\charts.txt" -Append
    $StatusLite = Global:Get-StatusLite
    $StatusDate = Get-Date
    $StatusDate | Out-File ".\build\txt\minerstatslite.txt"
    $StatusLite | Out-File ".\build\txt\minerstatslite.txt" -Append
    $BanMessage | Out-File ".\build\txt\minerstatslite.txt" -Append
    $MiningStatus | Out-File ".\build\txt\minerstatslite.txt" -Append
}

function Global:Get-Logo {
    Global:Write-Log '
                                                                        (                    (      *     
                                                                         )\ ) (  (      (     )\ ) (  `    
                                                                         (()/( )\))(     )\   (()/( )\))(   
                                                                          /(_)|(_)()\ |(((_)(  /(_)|(_)()\  
                                                                         (_)) _(())\_)()\ _ )\(_)) (_()((_) 
                                                                         / __|\ \((_)/ (_)_\(_) _ \|  \/  | 
                                                                         \__ \ \ \/\/ / / _ \ |   /| |\/| | 
                                                                         |___/  \_/\_/ /_/ \_\|_|_\|_|  |_| 
                                                                                                          ' -foregroundcolor "DarkRed"
    Global:Write-Log '                                                           sudo apt-get lambo
                                                                                 
                                                                                 
                                                                                 
                                                                                 ' -foregroundcolor "Yellow"
}

function Global:Update-Logging {
    if ($(vars).LogNum -eq 12) {
        Remove-Item ".\logs\*miner*" -Force -ErrorAction SilentlyContinue
        Remove-Item ".\logs\*crash_report*" -Force -Recurse -ErrorAction SilentlyContinue
        $(vars).LogNum = 0
    }
    if((Get-ChildItem ".\logs" | Where BaseName -match "crash_report").count -gt 12){
        Remove-Item ".\logs\*crash_report*" -Force -Recurse -ErrorAction SilentlyContinue
    }
    if ($(vars).logtimer.Elapsed.TotalSeconds -ge 3600) {
        Start-Sleep -S 3
        if (Test-Path ".\logs\*active*") {
            $OldActiveFile = Get-ChildItem ".\logs" | Where BaseName -like "*active*"
            $OldActiveFile | ForEach-Object {
                $RenameActive = $_.fullname -replace ("-active", "")
                if (Test-Path $RenameActive) { Remove-Item $RenameActive -Force }
                Rename-Item $_.FullName -NewName $RenameActive -force
            }
        }
        $(vars).LogNum++
        $(vars).logname = ".\logs\miner$($(vars).LogNum)-active.log"
        $(vars).logtimer.Restart()
    }
}

function Global:Get-MinerActive {
    $(vars).ActiveMinerPrograms | Sort-Object -Descending Status,Instance | Select-Object -First (1 + 6 + 6) | Format-Table -Wrap -GroupBy Status (
        @{Label = "Name"; Expression = { "$($_.Name)" } },
        @{Label = "#"; Expression = { "$($_.Instance)" } },
        @{Label = "Active"; Expression = { "{0:hh} Hours {0:mm} Minutes" -f $(if ($null -eq $_.XProcess) { $_.Active }else { if ($_.XProcess.HasExited) { ($_.Active) }else { ($_.Active + ((Get-Date) - $_.XProcess.StartTime)) } }) }; Align = 'center' },
        @{Label = "Launched"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_ Times" } } }; Align = 'center' },
        @{Label = "Command"; Expression = { "$($_.MinerName) $($_.Devices) $($_.Arguments)" } }
    )
}
