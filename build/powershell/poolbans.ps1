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

Function Get-NormalParams {
    $Global:config.params.Wallet1 = $global:startingconfig.params.Wallet1
    $Global:config.params.Wallet2 = $global:startingconfig.params.Wallet2
    $Global:config.params.Wallet3 = $global:startingconfig.params.Wallet3
    $Global:config.params.AltWallet1 = $global:startingconfig.params.AltWallet1
    $Global:config.params.AltWallet2 = $global:startingconfig.params.AltWallet2
    $Global:config.params.AltWallet3 = $global:startingconfig.params.AltWallet3
    $Global:config.params.AltPassword1 = $global:startingconfig.params.AltPassword1
    $Global:config.params.AltPassword2 = $global:startingconfig.params.AltPassword2
    $Global:config.params.AltPassword3 = $global:startingconfig.params.AltPassword3
    $Global:config.params.NiceHash_Wallet1 = $global:startingconfig.params.NiceHash_Wallet1
    $Global:config.params.NiceHash_Wallet2 = $global:startingconfig.params.NiceHash_Wallet2
    $Global:config.params.Nicehash_Wallet3 = $global:startingconfig.params.Nicehash_Wallet3
    $Global:config.params.RigName1 = $global:startingconfig.params.RigName1
    $Global:config.params.RigName2 = $global:startingconfig.params.RigName2
    $Global:config.params.RigName3 = $global:startingconfig.params.RigName3
    $Global:config.params.Interval = $global:startingconfig.params.Interval
    $Global:config.params.Passwordcurrency1 = $global:startingconfig.params.Passwordcurrency1
    $Global:config.params.Passwordcurrency2 = $global:startingconfig.params.Passwordcurrency2
    $Global:config.params.Passwordcurrency3 = $global:startingconfig.params.Passwordcurrency3
    $Global:config.params.PoolName = $global:startingconfig.params.PoolName
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
}

function Start-Poolbans {
    #$string = $Stamp
    #$length = $string.length
    #$pad = 32-$length
    #if (($length -lt 16) -or ($length -gt 32)) {Throw "String must be between 16 and 32 characters"}
    #$encoding = New-Object System.Text.ASCIIEncoding
    #$bytes = $encoding.GetBytes($string + "0" * $pad)
    #$Dkey = $bytes
    #$Check1 = "76492d1116743f0423413b16050a5345MgB8AC8AbgBBACsAOABRAFEAUABRAHQAcwBWADIARQBwADUAagBNAHoAZQBuAHcAPQA9AHwANAAyADYANQA2ADEAOQBhADkAMwA4AGMAOAA0ADMAMgA1ADEAZAA5ADYAYQBiAGYAZgA2ADkAMQAzAGYAYwAxAGYAMABkAGYAYwAwAGUAYQBjAGUAOQAwADAANwA3ADYANQA1ADgAOQA2ADgAYgBjAGUAZgA1ADIAZAAxADAAYwAwAGYANQA1ADgAZQBiADQANgA5ADAAMQBjAGMAZQBhADQANABlADMAMQBmADMAMABlADYAMwA3ADEAYgBkADMAMQBlADUAMQAzADkANgA2ADQAMwA0AGIAMgA3AGQAMAA5AGIAZAAzAGYAMQA0AGYAZQBkAGEANwA2ADEANgBiADYAOQA1AGQAZAA1ADYAYQA4ADQAMgBkAGYAMwAxADQANABkAGEAOABlADIAOQA3AGUAMgAwAGUANgBmADgAMQA5AGIANwAwAGMAMQAzADIAZgBjAGIAOQA2ADUAMQA0AGUAYwBkAGIAMgBmADEAOAA3ADYAMgBmAGQANgA5AGEAMQBiADQAZgBhADUAOABiADcAZgBmAGQAOQBmADcAMwAzADcANQA0ADYAMwBlADQAZQBlADIAMQBlADQANgAwADcAZQAyADMAMwAzADEAOQA4ADIAZgBmADEAZQA2AGEANQAxADIAZQBiAGQAMAA5ADcANABjADAAYQA1AGQAOQAzADQAMgAzAGIAMAA3ADEAOQBlAGEANgAwADYAYQBkAGYAYQA4ADUAMAA5ADcAMgBhAGMAZQA4ADkAYQAyADQAZgA0ADIAYwA2ADAAYQAwADgANABjADEANQA5ADIAZABjADUAMwBlADkAOQBhADgAYQBjADEANQA0AGQAOAAxADYANgA5AGYANgBhADkANwA3AGEAMAAxADcANAA2ADIANAA2ADAAOQA5AGEANwAxADAANwAzAGYAMgA3ADIAYgA0ADUAYQBkAGIAMQA1AGMAZgA2ADgAMAA4ADYAOQBiADgAYgA2AGQAYQA2ADIAOQBlADkAZgA0ADUANgBkAGUA"
    #$Check2 = "76492d1116743f0423413b16050a5345MgB8AE0AYgB0AFoAWgA0AE4AVwByAEQAdQA1ADcALwBWAGcAagBtAGsANQBmAGcAPQA9AHwAYgAwAGEAZgAzADUAMABiADAANwBkAGIANQAxAGIAZQBkADcAOABjADkAYgBhADUANABlAGYANQBjAGQAMwA5AA=="
    #$Check3 = "76492d1116743f0423413b16050a5345MgB8AGEAbgBsAHkAQwBKADUAcQAwAGUATQBxAEoAMAA0AEkANwA5AHgAUgBUAEEAPQA9AHwAYwAzADUAYgBlADIAZAA4ADcAMAA2ADIAYgA5ADAANwAzADAAMQA2ADUAOQAyAGUANQA0AGYANwAyADgAYgBlAGIAMgA2ADYAYwA1ADQAYwBiAGMAMQBkAGEANwA0ADQAYgBhADkAOQBhADMANQBmAGIAZQAzADgAMAA4ADgAYwBiAGQAZAAyADQAZgAyADMAMAAxAGQANwA3ADUAYgA0ADAAYQBmADQAYQA5ADIAMgA4ADYAYgBhAGQAZgA4ADMAMQA2ADIANAA5AGUAOAA0AGUAMwA5ADIAMQAyADIANQA0AGQANwAzADYAYwBiADMAZABiADgAMQAzADgAYQA2AGQAMwAxADMANwA5ADYANQAyADEAMwA4AGEANwBjADIAZABmAGEANABkAGQANABkADAANwA3ADEAYgAyADUAMwAxADIANQA0AGUAMQA3ADYAYQBlADAAYQAyADAAZQA3ADIAOABkADIAYwBmADcAMgBhADcAZQBmADIAOQA2ADgAYwA1ADIANwA2ADYAYwA4AGIANgA2ADUAMgA2ADIAYgAzADMANwAzADkAOQAxAGYAYgBiADAAMwA4ADUAMwA2AGMAOQBmADcAMABmADMANgA3AGMAZABiAGMAYwAyAGQAMwA1AGMANQBiAGMAZAAxADkAZgAxAGIANgA2AGQAOQBhAGUAMwA1AGEAYQAxAGQAOQBjADAAMwA4ADcAYgA4AGIAMAAxADkANwBiADEAYgBiADcAMAAxADAAMQBlADIAMQA2ADkANwA0AGYAZQAzAGYANwBiADUANAA4ADIAZQA1AGQANQAxADgANwAwADIANQA0AGYAYwAxADQAYgA0ADYAOQAxAGIAYgAxADcAZAA4ADkANwBlADgANQA1ADcAMgA0AGEANQA2ADIAYQA4ADUAYgAwAGMANAA5ADMANQA="
    $BanCheck1 = Get-Content ".\build\data\conversion.conf" -Force
    #if($BanCheck1 -ne $Check1){Stop-Process -Id $PID}
    $BanPass1 = "$($BanCheck1)" #| ConvertTo-SecureString -key $Dkey | ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
    $GetBanCheck2 = Get-Content ".\build\data\verification.conf" -Force
    $BanCheck2 = $([Double]$GetBanCheck2[0] - 5 + ([Double]$GetBanCheck2[1] * 2))
    #if($BanCheck2 -ne $Check2){Stop-Process -Id $PID}
    $BanPass2 = "$($BanCheck2)" #| ConvertTo-SecureString -key $Dkey | ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
    $BanCheck3 = Get-Content ".\build\data\conversion2.conf" -Force
    #if($BanCheck3 -ne $Check3){Stop-Process -Id $PID}
    $BanPass3 = "$($BanCheck3)" #| ConvertTo-SecureString -key $Dkey | ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
    if (Test-Path ".\build\data\system.txt") { $PoolBanCheck = "$(Get-Content ".\build\data\system.txt")" }
    if (Test-Path ".\build\data\timetable.txt") { $LastRan = "$(Get-Content ".\build\data\timetable.txt")" }
    $BanCount = ([Double]$BanPass2 + [Double]$Newparams.Donate)
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
