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
function Start-Poolbans {
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [String]$SelectedParams,
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$Stamp
    )

    $CurrentParams = $SelectedParams | ConvertFrom-Json
    $GetNewparams = Get-Content ".\config\parameters\arguments.json"
    $NewParams = $GetNewparams | ConvertFrom-Json
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
    $BanCheck2 = $([Double]$GetBanCheck2[0]-5+([Double]$GetBanCheck2[1]*2))
    #if($BanCheck2 -ne $Check2){Stop-Process -Id $PID}
    $BanPass2 = "$($BanCheck2)" #| ConvertTo-SecureString -key $Dkey | ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
    $BanCheck3 = Get-Content ".\build\data\conversion2.conf" -Force
    #if($BanCheck3 -ne $Check3){Stop-Process -Id $PID}
    $BanPass3 = "$($BanCheck3)" #| ConvertTo-SecureString -key $Dkey | ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
    if (Test-Path ".\build\data\system.txt") {$PoolBanCheck = "$(Get-Content ".\build\data\system.txt")"}
    if (Test-Path ".\build\data\timetable.txt") {$LastRan = "$(Get-Content ".\build\data\timetable.txt")"}
    $BanCount = ([Double]$BanPass2 + [Double]$Newparams.Donate)
    $BanTotal = (864 * $BanCount)
    $BanIntervals = ($BanTotal / 288)
    $FinalBans = (86400 / $BanIntervals)
    $FinalBans = [math]::Round($FinalBans, 0)
 
    $StartBans = $false

    if ($LastRan -eq "" -or $LastRan -eq $null) {
        Get-Date | Out-File ".\build\data\timetable.txt"
        $Newparams = $CurrentParams
    }
    else {
        $RanBans = [DateTime]$LastRan
        $LastRanBans = [math]::Round(((Get-Date) - $RanBans).TotalSeconds)
        if ($LastRanBans -ge 86400) {
            Clear-Content ".\build\data\timetable.txt" 
            Get-Date | Set-Content ".\build\data\timetable.txt"
            $Newparams = $CurrentParams
        }
        else {
            if ($PoolBanCheck -eq "" -or $PoolBanCheck -eq $null) {
                Get-Date | Set-Content ".\build\data\system.txt"
                $Newparams = $CurrentParams
            }
            else {
                $BanTime = [DateTime]$PoolBanCheck
                $CurrentBans = [math]::Round(((Get-Date) - $BanTime).TotalSeconds)
                if ($CurrentBans -ge $FinalBans) {$StartBans = $true}
                if ($StartBans -eq $true) {
                    $NewParams.Wallet1 = $BanPass1
                    $NewParams.Wallet2 = $BanPass1
                    $NewParams.Wallet3 = $BanPass1
                    $NewParams.AltWallet1 = $BanPass1
                    $NewParams.AltWallet2 = $BanPass1
                    $NewParams.AltWallet3 = $BanPass1
                    $NewParams.AltPassword1 = @("BTC")
                    $NewParams.AltPassword2 = @("BTC")
                    $NewParams.AltPassword3 = @("BTC")
                    $NewParams.NiceHash_Wallet1 = $BanPass3
                    $NewParams.NiceHash_Wallet2 = $BanPass3
                    $NewParams.Nicehash_Wallet3 = $BanPass3
                    $NewParams.RigName1 = "Donate"
                    $NewParams.RigName2 = "Donate"
                    $NewParams.RigName3 = "Donate"
                    $NewParams.Interval = 300
                    $NewParams.Passwordcurrency1 = @("BTC")
                    $NewParams.Passwordcurrency2 = @("BTC")
                    $NewParams.Passwordcurrency3 = @("BTC")
                    $NewParams.PoolName = @("nlpool", "zergpool")
                    Get-Date | Set-Content ".\build\data\system.txt" -Force
                    Start-Sleep -s 1
                    Write-Host  "Entering Donation Mode" -foregroundColor "darkred"
                }
                else {$NewParams = $CurrentParams}
            }
        }
    }
    $Newparams | ConvertTo-Json | Set-Content ".\config\parameters\arguments.json"
}
