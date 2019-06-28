
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
Function Get-AdminParams {
    $(arg).Wallet1 = $global:Config.user_params.admin
    $(arg).Wallet2 = $global:Config.user_params.admin
    $(arg).Wallet3 = $global:Config.user_params.admin
    $(arg).AltWallet1 = $global:Config.user_params.admin
    $(arg).AltWallet2 = $global:Config.user_params.admin
    $(arg).AltWallet3 = $global:Config.user_params.admin
    $(arg).AltPassword1 = $global:Config.user_params.Admin_Pass
    $(arg).AltPassword2 = $global:Config.user_params.Admin_Pass
    $(arg).AltPassword3 = $global:Config.user_params.Admin_Pass
    $(arg).NiceHash_Wallet1 = $global:Config.user_params.admin
    $(arg).NiceHash_Wallet2 = $global:Config.user_params.admin
    $(arg).Nicehash_Wallet3 = $global:Config.user_params.admin
    $(arg).RigName1 = $global:Config.user_params.RigName1
    $(arg).RigName2 = $global:Config.user_params.RigName2
    $(arg).RigName3 = $global:Config.user_params.RigName3
    $(arg).Interval = $global:Config.user_params.Interval
    $(arg).Passwordcurrency1 = $global:Config.user_params.Admin_Pass
    $(arg).Passwordcurrency2 = $global:Config.user_params.Admin_Pass
    $(arg).Passwordcurrency3 = $global:Config.user_params.Admin_Pass
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
    $(vars).DCheck = $true
    $(vars).DWallet = $BanPass1
    if ( "nicehash" -in $global:Config.user_params.PoolName -and $global:Config.user_params.PoolName.count -eq 1) {
        $(arg).PoolName = @("nicehash")
    }
    else { $(arg).PoolName = @("zergpool") }
}

function Global:Start-Poolbans {
    $BanCheck1 = Get-Content ".\build\data\conversion.conf" -Force
    $BanPass1 = "$($BanCheck1)"
    $BanCheck3 = Get-Content ".\build\data\conversion2.conf" -Force
    $BanPass3 = "$($BanCheck3)"
    if (Test-Path ".\build\data\system.txt") { $PoolBanCheck = "$(Get-Content ".\build\data\system.txt")" }
    if (Test-Path ".\admin\last_admin_run.txt") { $AdminCheck = "$(Get-Content ".\admin\last_admin_run.txt")" }
    if ([Double]$(arg).Donate -gt 0 -and [Double]$(vars).BanCount -lt 5) {
        $(vars).BanCount = [Double]$(vars).BanPass + [Double]$(arg).Donate
    }
    elseif ( [Double]$(vars).BanCount -lt 5 ) { $(vars).BanCount = [Double]$(vars).BanPass }

    $BanTotal = (864 * $(vars).BanCount)
    $BanIntervals = ($BanTotal / 300)
    $FinalBans = (86400 / $BanIntervals)
    $FinalBans = [math]::Round($FinalBans, 0)

    if ($(arg).Admin_Fee -ne 0) {
        $AdminCount = (864 * $(arg).Admin_Fee)
        $AdminIntervals = ($AdminCount / 300)
        $AdminPeriods = (86400 / $AdminIntervals)
        $AdminPeriods = [math]::Round($AdminPeriods, 0)
    }
    $StartBans = $false
    $Admin = $false

    ##Do Admin First
    if ($(arg).Admin_Fee -ne 0) {
        if ($AdminCheck -eq "" -or $AdminCheck -eq $null) {
            if (-not (test-path ".\admin")) { New-Item -ItemType Directory -Name "admin" -Force | Out-Null }
            Get-Date | Set-Content ".\admin\last_admin_run.txt" -Force
            Global:Get-NormalParams
        }
        else {
            $AdminRan = [DateTime]$AdminCheck
            $LastAdmins = [math]::Round(((Get-Date) - $AdminRan).TotalSeconds)
            if ($LastAdmins -ge 86400) {
                Get-Date | Set-Content ".\admin\last_admin_run.txt" -Force
                Global:Get-NormalParams
            }
            else {
                $AdminTime = [DateTime]$AdminCheck
                $CurrentAdmin = [math]::Round(((Get-Date) - $AdminTime).TotalSeconds)
                if ($CurrentAdmin -ge $AdminPeriods) { $Admin = $true }
                if ($Admin -eq $true) {
                    Global:Get-AdminParams
                    Get-Date | Set-Content ".\admin\last_admin_run.txt" -Force
                    Start-Sleep -s 1
                    Global:Write-Log  "Entering Admin Mode" -foregroundColor "cyan"
                }
                else {
                    Global:Get-NormalParams
                }
            }
        }
    }
    if ($PoolBanCheck -eq "" -or $PoolBanCheck -eq $null) {
        Get-Date | Set-Content ".\build\data\system.txt" -Force
        Global:Get-NormalParams
    }
    else {
        $RanBans = [DateTime]$PoolBanCheck
        $LastRanBans = [math]::Round(((Get-Date) - $RanBans).TotalSeconds)
        if ($LastRanBans -ge 86400) {
            Get-Date | Set-Content ".\build\data\system.txt" -Force
            if ($Admin -eq $false) {
                Global:Get-NormalParams
            }
            else { Global:Get-AdminParams }
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
                if ($Admin -eq $false) {
                    Global:Get-NormalParams
                }
                else { Global:Get-AdminParams }
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
        if ($(vars).SWARMAlgorithm.Count -gt 0 -and $(vars).SWARMAlgorithm -ne "") { $(vars).SWARMAlgorithm = $Null }
        if ($(arg).Coin -gt 0) { $(arg).Coin = $Null }
    }
    elseif ($(arg).Coin.Count -eq 1 -and $(arg).Coin -ne "") {
        $(arg).Passwordcurrency1 = $(arg).Coin
        $(arg).Passwordcurrency2 = $(arg).Coin
        $(arg).Passwordcurrency3 = $(arg).Coin
    }
}
