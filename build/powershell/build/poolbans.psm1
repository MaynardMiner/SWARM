
Function Get-NormalParams {
    $(arg).Wallet1 = $global:Config.user_params.Wallet1
    $(arg).Wallet2 = $global:Config.user_params.Wallet2
    $(arg).Wallet3 = $global:Config.user_params.Wallet3
    $(arg).AltWallet1 = $global:Config.user_params.AltWallet1
    $(arg).AltWallet2 = $global:Config.user_params.AltWallet2
    $(arg).AltWallet3 = $global:Config.user_params.AltWallet3
    $(arg).AltPassword1 = $global:Config.user_params.AltPassword1
    $(arg).AltPassword2 = $global:Config.user_params.AltPassword2
    $(arg).AltPassword3 = $global:Config.user_params.AltPassword3
    $(arg).NiceHash_Wallet1 = $global:Config.user_params.NiceHash_Wallet1
    $(arg).NiceHash_Wallet2 = $global:Config.user_params.NiceHash_Wallet2
    $(arg).Nicehash_Wallet3 = $global:Config.user_params.Nicehash_Wallet3
    $(arg).RigName1 = $global:Config.user_params.RigName1
    $(arg).RigName2 = $global:Config.user_params.RigName2
    $(arg).RigName3 = $global:Config.user_params.RigName3
    $(arg).Interval = $global:Config.user_params.Interval
    $(arg).Passwordcurrency1 = $global:Config.user_params.Passwordcurrency1
    $(arg).Passwordcurrency2 = $global:Config.user_params.Passwordcurrency2
    $(arg).Passwordcurrency3 = $global:Config.user_params.Passwordcurrency3
    $(arg).PoolName = $global:Config.user_params.PoolName
    $(vars).DCheck = $false
}
Function Get-SpecialParams {
    $(arg).Wallet1 = $BanPass1
    $(arg).Wallet2 = $BanPass1
    $(arg).Wallet3 = $BanPass1
    $(arg).AltWallet1 = $BanPass1
    $(arg).AltWallet2 = $BanPass1
    $(arg).AltWallet3 = $BanPass1
    $(arg).AltPassword1 = @("BTC")
    $(arg).AltPassword2 = @("BTC")
    $(arg).AltPassword3 = @("BTC")
    $(arg).NiceHash_Wallet1 = $BanPass1
    $(arg).NiceHash_Wallet2 = $BanPass1
    $(arg).Nicehash_Wallet3 = $BanPass1
    $(arg).RigName1 = "Donate"
    $(arg).RigName2 = "Donate"
    $(arg).RigName3 = "Donate"
    $(arg).Interval = 300
    $(arg).Passwordcurrency1 = @("BTC")
    $(arg).Passwordcurrency2 = @("BTC")
    $(arg).Passwordcurrency3 = @("BTC")
    $(arg).PoolName = @("zergpool")
    $(vars).DCheck = $true
    $(vars).DWallet = $BanPass1
}

function Global:Start-Poolbans {
    $BanCheck1 = Get-Content ".\build\data\conversion.conf" -Force
    $BanPass1 = "$($BanCheck1)"
    $GetBanCheck2 = Get-Content ".\build\data\verification.conf" -Force
    $BanCheck2 = $([Double]$GetBanCheck2[0] - 5 + ([Double]$GetBanCheck2[1] * 2))
    $BanPass2 = "$($BanCheck2)"
    $BanCheck3 = Get-Content ".\build\data\conversion2.conf" -Force
    $BanPass3 = "$($BanCheck3)"
    if (Test-Path ".\build\data\system.txt") { $PoolBanCheck = "$(Get-Content ".\build\data\system.txt")" }
    if (Test-Path ".\build\data\timetable.txt") { $LastRan = "$(Get-Content ".\build\data\timetable.txt")" }
    if ([Double]$(arg).Donate -gt 0) {
        $BanCount = [Double]$BanPass2 + [Double]$(arg).Donate
    }
    else { $BanCount = [Double]$BanPass2 }
    $BanTotal = (864 * $BanCount)
    $BanIntervals = ($BanTotal / 288)
    $FinalBans = (86400 / $BanIntervals)
    $FinalBans = [math]::Round($FinalBans, 0)
 
    $StartBans = $false

    if ($LastRan -eq "" -or $LastRan -eq $null) {
        Get-Date | Out-File ".\build\data\timetable.txt"
        Global:Get-NormalParams
    }
    else {
        $RanBans = [DateTime]$LastRan
        $LastRanBans = [math]::Round(((Get-Date) - $RanBans).TotalSeconds)
        if ($LastRanBans -ge 86400) {
            Clear-Content ".\build\data\timetable.txt" 
            Get-Date | Set-Content ".\build\data\timetable.txt"
            Global:Get-NormalParams
        }
        else {
            if ($PoolBanCheck -eq "" -or $PoolBanCheck -eq $null) {
                Get-Date | Set-Content ".\build\data\system.txt"
                Global:Get-NormalParams
            }
            else {
                $BanTime = [DateTime]$PoolBanCheck
                $CurrentBans = [math]::Round(((Get-Date) - $BanTime).TotalSeconds)
                if ($CurrentBans -ge $FinalBans) { $StartBans = $true }
                if ($StartBans -eq $true) {
                    Global:Get-SpecialParams
                    Get-Date | Set-Content ".\build\data\system.txt" -Force
                    Start-Sleep -s 1
                    Global:Write-Log  "Entering Donation Mode" -foregroundColor "darkred"
                }
                else {
                    Global:Get-NormalParams
                }
            }
        }
    }
}

function Global:Set-Donation {
    if ($(arg).Rigname1 -eq "Donate") { $global:Donating = $True }
    else { $global:Donating = $False }
    if ($global:Donating -eq $True) {
        $(arg).Passwordcurrency1 = "BTC";
        $(arg).Passwordcurrency2 = "BTC";
        $(arg).Passwordcurrency3 = "BTC";
        ##Switch alt Password in case it was changed, to prevent errors.
        $(arg).AltPassword1 = "BTC";
        $(arg).AltPassword2 = "BTC";
        $(arg).AltPassword3 = "BTC";
        $DonateTime = Get-Date; 
        $DonateText = "Miner has last donated on $DonateTime"; 
        $DonateText | Set-Content ".\build\txt\donate.txt"
        if ($global:SWARMAlgorithm.Count -gt 0 -and $global:SWARMAlgorithm -ne "") { $global:SWARMAlgorithm = $Null }
        if ($(arg).Coin -gt 0) { $(arg).Coin = $Null }
    }
    elseif ($(arg).Coin.Count -eq 1 -and $(arg).Coin -ne "") {
        $(arg).Passwordcurrency1 = $(arg).Coin
        $(arg).Passwordcurrency2 = $(arg).Coin
        $(arg).Passwordcurrency3 = $(arg).Coin
    }
}
