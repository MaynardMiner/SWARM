
Function Get-NormalParams {
    $Global:config.params.Wallet1 = $global:Config.user_params.Wallet1
    $Global:config.params.Wallet2 = $global:Config.user_params.Wallet2
    $Global:config.params.Wallet3 = $global:Config.user_params.Wallet3
    $Global:config.params.AltWallet1 = $global:Config.user_params.AltWallet1
    $Global:config.params.AltWallet2 = $global:Config.user_params.AltWallet2
    $Global:config.params.AltWallet3 = $global:Config.user_params.AltWallet3
    $Global:config.params.AltPassword1 = $global:Config.user_params.AltPassword1
    $Global:config.params.AltPassword2 = $global:Config.user_params.AltPassword2
    $Global:config.params.AltPassword3 = $global:Config.user_params.AltPassword3
    $Global:config.params.NiceHash_Wallet1 = $global:Config.user_params.NiceHash_Wallet1
    $Global:config.params.NiceHash_Wallet2 = $global:Config.user_params.NiceHash_Wallet2
    $Global:config.params.Nicehash_Wallet3 = $global:Config.user_params.Nicehash_Wallet3
    $Global:config.params.RigName1 = $global:Config.user_params.RigName1
    $Global:config.params.RigName2 = $global:Config.user_params.RigName2
    $Global:config.params.RigName3 = $global:Config.user_params.RigName3
    $Global:config.params.Interval = $global:Config.user_params.Interval
    $Global:config.params.Passwordcurrency1 = $global:Config.user_params.Passwordcurrency1
    $Global:config.params.Passwordcurrency2 = $global:Config.user_params.Passwordcurrency2
    $Global:config.params.Passwordcurrency3 = $global:Config.user_params.Passwordcurrency3
    $Global:config.params.PoolName = $global:Config.user_params.PoolName
    $Global:DCheck = $false
}
Function Get-SpecialParams {
    $Global:config.params.Wallet1 = $BanPass1
    $Global:config.params.Wallet2 = $BanPass1
    $Global:config.params.Wallet3 = $BanPass1
    $Global:config.params.AltWallet1 = $BanPass1
    $Global:config.params.AltWallet2 = $BanPass1
    $Global:config.params.AltWallet3 = $BanPass1
    $Global:config.params.AltPassword1 = @("BTC")
    $Global:config.params.AltPassword2 = @("BTC")
    $Global:config.params.AltPassword3 = @("BTC")
    $Global:config.params.NiceHash_Wallet1 = $BanPass1
    $Global:config.params.NiceHash_Wallet2 = $BanPass1
    $Global:config.params.Nicehash_Wallet3 = $BanPass1
    $Global:config.params.RigName1 = "Donate"
    $Global:config.params.RigName2 = "Donate"
    $Global:config.params.RigName3 = "Donate"
    $Global:config.params.Interval = 300
    $Global:config.params.Passwordcurrency1 = @("BTC")
    $Global:config.params.Passwordcurrency2 = @("BTC")
    $Global:config.params.Passwordcurrency3 = @("BTC")
    $Global:config.params.PoolName = @("nlpool", "zergpool")
    $Global:DCheck = $true
    $Global:DWallet = $BanPass1
}

function Start-Poolbans {
    $BanCheck1 = Get-Content ".\build\data\conversion.conf" -Force
    $BanPass1 = "$($BanCheck1)"
    $GetBanCheck2 = Get-Content ".\build\data\verification.conf" -Force
    $BanCheck2 = $([Double]$GetBanCheck2[0] - 5 + ([Double]$GetBanCheck2[1] * 2))
    $BanPass2 = "$($BanCheck2)"
    $BanCheck3 = Get-Content ".\build\data\conversion2.conf" -Force
    $BanPass3 = "$($BanCheck3)"
    if (Test-Path ".\build\data\system.txt") { $PoolBanCheck = "$(Get-Content ".\build\data\system.txt")" }
    if (Test-Path ".\build\data\timetable.txt") { $LastRan = "$(Get-Content ".\build\data\timetable.txt")" }
    if ([Double]$global:Config.Params.Donate -gt 0) {
        $BanCount = [Double]$BanPass2 + [Double]$global:Config.Params.Donate
    }
    else { $BanCount = [Double]$BanPass2 }
    $BanTotal = (864 * $BanCount)
    $BanIntervals = ($BanTotal / 288)
    $FinalBans = (86400 / $BanIntervals)
    $FinalBans = [math]::Round($FinalBans, 0)
 
    $StartBans = $false

    if ($LastRan -eq "" -or $LastRan -eq $null) {
        Get-Date | Out-File ".\build\data\timetable.txt"
        Get-NormalParams
    }
    else {
        $RanBans = [DateTime]$LastRan
        $LastRanBans = [math]::Round(((Get-Date) - $RanBans).TotalSeconds)
        if ($LastRanBans -ge 86400) {
            Clear-Content ".\build\data\timetable.txt" 
            Get-Date | Set-Content ".\build\data\timetable.txt"
            Get-NormalParams
        }
        else {
            if ($PoolBanCheck -eq "" -or $PoolBanCheck -eq $null) {
                Get-Date | Set-Content ".\build\data\system.txt"
                Get-NormalParams
            }
            else {
                $BanTime = [DateTime]$PoolBanCheck
                $CurrentBans = [math]::Round(((Get-Date) - $BanTime).TotalSeconds)
                if ($CurrentBans -ge $FinalBans) { $StartBans = $true }
                if ($StartBans -eq $true) {
                    Get-SpecialParams
                    Get-Date | Set-Content ".\build\data\system.txt" -Force
                    Start-Sleep -s 1
                    Write-Log  "Entering Donation Mode" -foregroundColor "darkred"
                }
                else {
                    Get-NormalParams
                }
            }
        }
    }
}

function Set-Donation {
    if ($global:config.params.Rigname1 -eq "Donate") { $global:Donating = $True }
    else { $global:Donating = $False }
    if ($global:Donating -eq $True) {
        $global:Config.Params.Passwordcurrency1 = "BTC";
        $global:Config.Params.Passwordcurrency2 = "BTC";
        $global:Config.Params.Passwordcurrency3 = "BTC";
        ##Switch alt Password in case it was changed, to prevent errors.
        $global:Config.Params.AltPassword1 = "BTC";
        $global:Config.Params.AltPassword2 = "BTC";
        $global:Config.Params.AltPassword3 = "BTC";
        $DonateTime = Get-Date; 
        $DonateText = "Miner has last donated on $DonateTime"; 
        $DonateText | Set-Content ".\build\txt\donate.txt"
        if ($SWARMAlgorithm.Count -gt 0 -and $SWARMAlgorithm -ne "") { $SWARMAlgorithm = $Null }
        if ($global:Config.Params.Coin -gt 0) { $global:Config.Params.Coin = $Null }
    }
    elseif ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") {
        $global:Config.Params.Passwordcurrency1 = $global:Config.Params.Coin
        $global:Config.Params.Passwordcurrency2 = $global:Config.Params.Coin
        $global:Config.Params.Passwordcurrency3 = $global:Config.Params.Coin
    }
}
