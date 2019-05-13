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

function Get-Pools {
    param (
        [Parameter(Mandatory = $true)]
        [String]$PoolType
    )

    Switch($PoolType)
    {
     "Algo"{$GetPools = if (Test-Path "algopools") {Get-ChildItemContent "algopools" | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
     "Coin"{$GetPools = if (Test-Path "coinpools") {Get-ChildItemContent "coinpools" | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
     "Custom"{$GetPools = if (Test-Path "custompools") {Get-ChildItemContent "custompools" | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
    }

    $GetPools
  
}

function Sort-Pools {
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Pools
    )

    $PoolPriority1 = @()
    $PoolPriority2 = @()
    $PoolPriority3 = @()
}

function Get-Volume {
    $global:Pool_Hashrates.keys | ForEach-Object {
        $SortAlgo = $_
        $Sorted = @()
        $global:Pool_HashRates.$SortAlgo.keys | ForEach-Object {$Sorted += [PSCustomObject]@{Name = "$($_)"; HashRate = [Decimal]$global:Pool_HashRates.$SortAlgo.$_.HashRate}}
        $BestHash = [Decimal]$($Sorted | Sort-Object HashRate -Descending | Select -First 1).HashRate
        $global:Pool_HashRates.$SortAlgo.keys | ForEach-Object {$global:Pool_HashRates.$SortAlgo.$_.Percent = (([Decimal]$BestHash - [Decimal]$global:Pool_HashRates.$SortAlgo.$_.HashRate) / [decimal]$BestHash)}
    }
}

function Remove-Pools {
    param (
        [Parameter(Mandatory = $true)]
        [String]$IPAddress,
        [Parameter(Mandatory = $true)]
        [Int]$PoolPort,
        [Parameter(Mandatory = $true)]
        [Int]$PoolTimeout
    )
    $getpool = "pools|0"
    $getpools = Get-TCP -Server $IPAddress -Port $Port -Message $getpool -Timeout 10
    if ($getpools) {
        $ClearPools = @()
        $getpools = $getpools -split "\|" | Select -skip 1 | Where {$_ -ne ""}
        $AllPools = [PSCustomObject]@{}
        $Getpools | foreach {$Single = $($_ -split "," | ConvertFrom-StringData); $AllPools | Add-Member "Pool$($Single.Pool)" $Single}
        $AllPools | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {if ($AllPools.$_.Priority -ne 0) {$Clear = $($_ -replace "Pool", ""); $ClearPools += "removepool|$Clear"}}
        if ($ClearPools) {$ClearPools | foreach {Get-TCP -Server $Master -Port $Port -Message "$($_)" -Timeout 10}; Start-Sleep -S .5}
    }
   
    $Found = "1"
    $Found
}

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
    if([Double]$global:Config.Params.Donate -gt 0) {
        $BanCount = [Double]$BanPass2 + [Double]$global:Config.Params.Donate
    }
    else{$BanCount = [Double]$BanPass2}
    $BanTotal = (864 * $BanCount)
    $BanIntervals = ($BanTotal / 288)
    $FinalBans = (86400 / $BanIntervals)
    $FinalBans = [math]::Round($FinalBans, 0)
 
    $StartBans = $false

    if ($LastRan -eq "" -or $LastRan -eq $null) {
        Get-NewDate | Out-File ".\build\data\timetable.txt"
        Get-NormalParams
    }
    else {
        $RanBans = [DateTime]$LastRan
        $LastRanBans = [math]::Round(((Get-Date) - $RanBans).TotalSeconds)
        if ($LastRanBans -ge 86400) {
            Clear-Content ".\build\data\timetable.txt" 
            Get-NewDate | Set-Content ".\build\data\timetable.txt"
            Get-NormalParams
        }
        else {
            if ($PoolBanCheck -eq "" -or $PoolBanCheck -eq $null) {
                Get-NewDate | Set-Content ".\build\data\system.txt"
                Get-NormalParams
            }
            else {
                $BanTime = [DateTime]$PoolBanCheck
                $CurrentBans = [math]::Round(((Get-Date) - $BanTime).TotalSeconds)
                if ($CurrentBans -ge $FinalBans) { $StartBans = $true }
                if ($StartBans -eq $true) {
                    Get-SpecialParams
                    Get-NewDate | Set-Content ".\build\data\system.txt" -Force
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
