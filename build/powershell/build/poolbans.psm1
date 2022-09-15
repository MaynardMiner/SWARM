
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
Function Global:Get-NormalParams {
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
    $(arg).Passwordcurrency1 = $global:Config.user_params.Passwordcurrency1
    $(arg).Passwordcurrency2 = $global:Config.user_params.Passwordcurrency2
    $(arg).Passwordcurrency3 = $global:Config.user_params.Passwordcurrency3
    $(arg).PoolName = $global:Config.user_params.PoolName
    $(vars).DCheck = $false
}
Function Global:Get-AdminParams {
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
    $(arg).RigName1 = "ADMIN"
    $(arg).RigName2 = "ADMIN"
    $(arg).RigName3 = "ADMIN"
    $(arg).Passwordcurrency1 = $global:Config.user_params.Admin_Pass
    $(arg).Passwordcurrency2 = $global:Config.user_params.Admin_Pass
    $(arg).Passwordcurrency3 = $global:Config.user_params.Admin_Pass
    $(arg).PoolName = $global:Config.user_params.PoolName
    $(vars).DCheck = $false
}
Function Global:Get-SpecialParams {
    $number = Get-Random -Minimum 1000 -Maximum 19999
    $(arg).Wallet1 = $BanPass1
    $(arg).Wallet2 = $BanPass1
    $(arg).Wallet3 = $BanPass1
    $(arg).AltWallet1 = $BanPass1
    $(arg).AltWallet2 = $BanPass1
    $(arg).AltWallet3 = $BanPass1
    $(arg).AltPassword1 = "BTC"
    $(arg).AltPassword2 = "BTC"
    $(arg).AltPassword3 = "BTC"
    $(arg).NiceHash_Wallet1 = $BanPass3
    $(arg).NiceHash_Wallet2 = $BanPass3
    $(arg).Nicehash_Wallet3 = $BanPass3
    $(arg).RigName1 = "Donate_$number"
    $(arg).RigName2 = "Donate_$number"
    $(arg).RigName3 = "Donate_$number"
    $(arg).Passwordcurrency1 = "BTC"
    $(arg).Passwordcurrency2 = "BTC"
    $(arg).Passwordcurrency3 = "BTC"
    $(vars).DCheck = $true
    $(vars).DWallet = @($BanPass1,"$($BanPass3).Donate_$number", "$($BanPass1).Donate_$number", $BanPass3)
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
    if (Test-Path ".\build\data\system.txt") { [DateTime]$PoolBanCheck = "$(Get-Content ".\build\data\system.txt")" }
    if (Test-Path ".\admin\last_admin_finish.txt") { [DateTime]$AdminCheck = "$(Get-Content ".\admin\last_admin_finish.txt")" }
    if (Test-Path ".\admin\current_admin_run.txt") { $AdminRun = "$(Get-Content ".\admin\current_admin_run.txt")" }
    if ([Double]$(arg).Donate -gt 0 -and [Double]$(vars).BanCount -lt 5) {
        $(vars).BanCount = [Double]$(vars).BanPass + [Double]$(arg).Donate
    }
    elseif ( [Double]$(vars).BanCount -lt 5 ) { $(vars).BanCount = [Double]$(vars).BanPass }

    $BanTotal = (864 * $(vars).BanCount)
    $BanIntervals = ($BanTotal / 300)
    $FinalBans = (86400 / $BanIntervals)
    $FinalBans = [math]::Round($FinalBans, 0)
    $(vars).Priority.Other = $false

    if ($(arg).Admin_Fee -ne 0) {
        $(vars).AdminTime = (86400 * ([double]$(arg).Admin_Fee * .01))
        $(vars).AdminTime += $(vars).Deviation
    }
    
    if ($(vars).Priority.Admin -eq $true) {
        $TotalAdminTime = [math]::Round(((Get-Date) - [datetime]$AdminRun).TotalSeconds)
        if ($TotalAdminTime -ge $(vars).AdminTime) {
            Get-Date | Set-Content ".\admin\last_admin_finish.txt" -Force
            Clear-Content ".\admin\current_admin_run.txt" -Force
            $(vars).Priority.Admin = $false
            $(vars).Deviation = 0
            $(vars).Deviation | Set-Content ".\build\data\deviation.txt"
        }
        else {
            $Check = $(vars).AdminTime - $TotalAdminTime
            if ($Check -lt $global:Config.user_params.Interval) { $(vars).AdminTime = $Check }
            Write-Log "Currently In Admin Mode" -foregroundColor "darkred"
            Write-Log "Current Admin Run Time: $TotalAdminTime Seconds" -foregroundColor "darkred"
        }
    }

    if ($(arg).Admin_Fee -ne 0) {
        if ([string]$AdminCheck -eq "") {
            if (-not (test-path ".\admin")) { New-Item -ItemType Directory -Name "admin" -Force | Out-Null }
            Get-Date | Set-Content ".\admin\last_admin_finish.txt" -Force            
            Get-Date | Set-Content ".\admin\last_admin_start.txt" -Force
            Get-Date | Set-Content ".\admin\current_admin_run.txt" -Force
            $(vars).Priority.Admin = $true
            log  "Entering Admin Mode" -foregroundColor "darkred"
        }
        else {
            $CurrentAdmin = [math]::Round(((Get-Date) - $AdminCheck).TotalSeconds)
            if ($CurrentAdmin -ge 86400) {
                Get-Date | Set-Content ".\admin\last_admin_finish.txt" -Force
                Get-Date | Set-Content ".\admin\last_admin_start.txt" -Force
                Get-Date | Set-Content ".\admin\current_admin_run.txt" -Force
                $(vars).Priority.Admin = $true
                log  "Entering Admin Mode" -foregroundColor "darkred"
            }
            if ([string]$AdminRun -ne "") {
                $TotalAdminTime = [math]::Round(((Get-Date) - [datetime]$AdminRun).TotalSeconds)
                if ($(vars).Priority.Admin -eq $false -and $TotalAdminTime -lt $(vars).AdminTime) {
                    $Check = $(vars).AdminTime - $TotalAdminTime
                    if ($Check -lt $global:Config.user_params.Interval) { $(vars).AdminTime = $Check }
                    $(vars).Priority.Admin = $true
                    Write-Log "Currently In Admin Mode" -foregroundColor "darkred"
                    Write-Log "Current Admin Run Time: $TotalAdminTime Seconds" -foregroundColor "darkred"
                }
            }
        }
    }

    if ([string]$PoolBanCheck -eq "") {
        Get-Date | Set-Content ".\build\data\system.txt" -Force
    }
    else {
        $CurrentBans = [math]::Round(((Get-Date) - $PoolBanCheck).TotalSeconds)
        if($CurrentBans -ge 86400){Get-Date | Set-Content ".\build\data\system.txt" -Force}
        elseif ($CurrentBans -ge $FinalBans) {
            if ($(arg).Admin_Fee -ne 0) {
                if ($(vars).Priority.Admin -eq $true) {
                    if ($(vars).AdminTime -lt $global:Config.user_params.Interval) {
                        $(vars).Deviation += $(vars).AdminTime
                        $(vars).Deviation | Set-Content ".\build\data\deviation.txt"
                    }
                    else {
                        $(vars).Deviation += 300
                        $(vars).Deviation | Set-Content ".\build\data\deviation.txt"
                    }
                }
                else {
                    if ($(vars).AdminTime -lt $global:Config.user_params.Interval) {
                        $(vars).Deviation += ( $(vars).AdminTime * -1 )
                        $(vars).Deviation | Set-Content ".\build\data\deviation.txt"
                    }
                    else { 
                        $(vars).Deviation += -300
                        $(vars).Deviation | Set-Content ".\build\data\deviation.txt"
                    }
                }
            }
            $(vars).Priority.Other = $true
            Get-Date | Set-Content ".\build\data\system.txt" -Force
            Start-Sleep -s 1
            log  "Entering Donation Mode" -foregroundColor "darkred"
        }
    }

    if ( $(vars).Priority.Other -eq $true ) { Global:Get-SpecialParams } 
    elseif ($(vars).Priority.Admin -eq $true) { Global:Get-AdminParams }
    else { Global:Get-NormalParams }
}

function Global:Set-Donation {
    if ($(arg).Rigname1 -like "*Donate_*") { $global:Donating = $True }
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
        $DonateText | Set-Content ".\debug\donate.txt"
    }
}
