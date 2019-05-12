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

function get-NIST {
    $progressPreference = 'silentlyContinue'
    try {
        $WebRequest = Invoke-WebRequest -Uri 'http://nist.time.gov/actualtime.cgi' -UseBasicParsing -TimeoutSec 10
        $GetNIST = (Get-Date -Date '1970-01-01 00:00:00Z').AddMilliseconds(([XML]$WebRequest.Content | Select -expandproperty timestamp | Select -ExpandProperty time) / 1000)
    }
    Catch {
        Write-Warning "Failed To Get NIST time. Using Local Time."
        $GetNIST = Get-Date
    }
    $progressPreference = 'Continue'
    $GetNIST
}

function Get-NewDate {
    $myDate = (Get-Date).toString("MM/dd/yyyy HH:mm:ss", $global:cultureENUS)
    $myDate
}


function get-stats {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Timeouts
    )

    if ($Timeouts -eq "No") { 
        $GetStats = [PSCustomObject]@{ }
        if (Test-Path "stats") { Get-ChildItemContent "stats" | ForEach { $GetStats | Add-Member $_.Name $_.Content } }
        $GetStats
    }

    if ($Timeouts -eq "Yes") {
        $GetStats = [PSCustomObject]@{ }
        if (Test-Path ".\timeout") { Remove-Item ".\timeout" -Force -Recurse }
        Write-Host "Cleared all bans" -ForegroundColor Green
        Start-Sleep -S 3
        if (Test-Path "stats") { Get-ChildItemContent "stats" | ForEach { $GetStats | Add-Member $_.Name $_.Content } }
        $GetStats
    }

}

function Get-Alpha($X) { (2 / ($X + 1) ) }

function Get-Theta { 
    param (
        [Parameter(Mandatory = $true)]
        [Int]$Calcs,
        [Parameter(Mandatory = $true)]
        [Array]$Values
    )
    $Values | Select -Last $Calcs | Measure-Object -Sum 
}

function Set-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $false)]
        [Double]$HashRate,
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Date = (Get-Date)
    )

    $Calcs = @{
        Minute    = [Math]::Max([Math]::Round(60 / $global:Config.Params.Interval), 1)
        Minute_5  = [Math]::Max([Math]::Round(300 / $global:Config.Params.Interval), 1)
        Minute_15 = [Math]::Max([Math]::Round(900 / $global:Config.Params.Interval), 1)
        Hour      = [Math]::Max([Math]::Round(3600 / $global:Config.Params.Interval), 1)
        Hour_4    = [Math]::Max([Math]::Round(14400 / $global:Config.Params.Interval), 1)
        Day       = [Math]::Max([Math]::Round(86400 / $global:Config.Params.Interval), 1)
        Custom    = [Math]::Max([Math]::Round($global:Config.Params.Custom_Periods), 1)
    }

    if ($HashRate) {
        $Calcs.Add("Hashrate", [Math]::Max([Math]::Round(3600 / $global:Config.Params.Interval), 1))
    }

    if($global:Config.Params.Max_Periods -and $global:Config.Params.Max_Periods -ne ""){$Max_Periods = $global:Config.Params.Max_Periods}
    else {$Max_Periods = 288}
    $Hash_Max = 15
    if ($name -eq "load-average") { $Max_Periods = 90; $Path = "build\txt\$Name.txt" }
    else { $Path = "stats\$Name.txt" }
    $SmallestValue = 1E-20

    if ((Test-Path $Path) -and $HashRate) {
        $Stat = Get-Content $Path | ConvertFrom-Json 
        $Stat = [PSCustomObject]@{
            Live      = [Double]$Value
            Minute    = [Double]$Stat.Minute
            Minute_5  = [Double]$Stat.Minute_5
            Minute_15 = [Double]$Stat.Minute_15
            Hour      = [Double]$Stat.Hour
            Hour_4    = [Double]$Stat.Hour_4
            Day       = [Double]$Stat.Day
            Custom    = [Double]$Stat.Custom
            Hashrate  = [Double]$Stat.Hashrate
            Hash_Val  = $Stat.Hash_Val
            Values    = $Stat.Values
        }
    } 
    elseif (Test-Path $Path) {
        $Stat = Get-Content $Path | ConvertFrom-Json 
        $Stat = [PSCustomObject]@{
            Live      = [Double]$Value
            Minute    = [Double]$Stat.Minute
            Minute_5  = [Double]$Stat.Minute_5
            Minute_15 = [Double]$Stat.Minute_15
            Hour      = [Double]$Stat.Hour
            Hour_4    = [Double]$Stat.Hour_4
            Day       = [Double]$Stat.Day
            Custom    = [Double]$Stat.Custom
            Values    = $Stat.Values
        }
    }
    elseif ($HashRate) {
        $Stat = [PSCustomObject]@{
            Live      = $Value
            Minute    = $Value
            Minute_5  = $Value
            Minute_15 = $Value
            Hour      = $Value
            Hour_4    = $Value
            Day       = $Value
            Custom    = $Value
            Hashrate  = $HashRate
            Hash_Val  = @()
            Values    = @()
        }
    }
    else {
        $Stat = [PSCustomObject]@{
            Live      = $Value
            Minute    = $Value
            Minute_5  = $Value
            Minute_15 = $Value
            Hour      = $Value
            Hour_4    = $Value
            Day       = $Value
            Custom    = $Value
            Values    = @()
        }
    }

    $Stat.Values += [decimal]$Value
    if ($Stat.Values.Count -gt $Max_Periods) { $Stat.Values = $Stat.Values | Select -Skip 1 }

    if ($HashRate) {
        $Stat.Hash_Val += [decimal]$Hashrate
        if ($Stat.Hash_Val.Count -gt $Hash_Max) { $Stat.Hash_Val = $Stat.Hash_Val | Select -Skip 1 }
    }

    $Calcs.keys | foreach {
        if ($_ -eq "Hashrate") { $T = $Stat.Hash_Val }
        else { $T = $Stat.Values }
        $Theta = (Get-Theta -Calcs $Calcs.$_ -Values $T)
        $Alpha = [Double](Get-Alpha($Theta.Count))
        $Zeta = [Double]$Theta.Sum / $Theta.Count
        $Stat.$_ = [Math]::Max( ( $Zeta * $Alpha + $($Stat.$_) * (1 - $Alpha) ) , $SmallestValue )
    }

    if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" }

    $Stat.Values = @( $Stat.Values | % { [Decimal]$_ } )
    if ($Stat.Hash_Val) { $Stat.Hash_Val = @( $Stat.Hash_Val | % { [Decimal]$_ } ) }

    if ($HashRate) {
        [PSCustomObject]@{
            Live      = [Decimal]$Value
            Minute    = [Decimal]$Stat.Minute
            Minute_5  = [Decimal]$Stat.Minute_5
            Minute_15 = [Decimal]$Stat.Minute_15
            Hour      = [Decimal]$Stat.Hour
            Hour_4    = [Decimal]$Stat.Hour_4
            Day       = [Decimal]$Stat.Day
            Custom    = [Decimal]$Stat.Custom
            Hashrate  = [Decimal]$Stat.Hashrate
            Values    = $Stat.Values
            Hash_Val  = $Stat.Hash_Val
        } | ConvertTo-Json | Set-Content $Path
    }
    else {
        [PSCustomObject]@{
            Live      = [Decimal]$Value
            Minute    = [Decimal]$Stat.Minute
            Minute_5  = [Decimal]$Stat.Minute_5
            Minute_15 = [Decimal]$Stat.Minute_15
            Hour      = [Decimal]$Stat.Hour
            Hour_4    = [Decimal]$Stat.Hour_4
            Day       = [Decimal]$Stat.Day
            Custom    = [Decimal]$Stat.Custom
            Values    = $Stat.Values
        } | ConvertTo-Json | Set-Content $Path
    }

    $Stat

}

function Get-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" }
    if ($name -eq "load-average") { Get-ChildItem "build\txt" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json }
    else { Get-ChildItem "stats" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json }
}

function Remove-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $Remove = Join-Path ".\stats" "$Name"
    if (Test-Path $Remove) {
        Remove-Item -path $Remove
    }
}

function Set-WStat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name,
        [Parameter(Mandatory = $true)]
        [String]$Symbol,
        [Parameter(Mandatory = $true)]
        [String]$address,
        [Parameter(Mandatory = $true)]
        [Double]$balance,
        [Parameter(Mandatory = $true)]
        [Double]$unpaid,
        [Parameter(Mandatory = $false)]
        [DateTime]$Date = (Get-Date)
    )

    $Path = ".\wallet\values\$Name.txt"
    $Date = $Date.ToUniversalTime()
    $Pool = $Name -split "_" | Select -First 1

    if (Test-Path $Path) { $WStat = Get-Content $Path | ConvertFrom-Json }
    if ($WStat) {
        $WStat.address = $address;
        $WStat.symbol = $symbol;
        $WStat.Pool = $Pool;
        $WStat.balance = $balance;
        $WStat.unpaid = $unpaid;
        $WStat.Date = $Date
    }
    else {
        $WStat = [PSCustomObject]@{
            Address = $address;
            Symbol  = $symbol;
            Pool    = $Pool;
            Balance = $balance; 
            Unpaid  = $unpaid; 
            Date    = $Date
        }
    }
    if (-not (Test-Path ".\wallet\values")) { New-Item -Name "values" -Path ".\wallet" -ItemType "directory" | Out-Null }

    $WStat | ConvertTo-Json | Set-Content $Path 

}

function get-wstats {
    $GetWStats = [PSCustomObject]@{ }
    if (Test-Path ".\wallet\values") { Get-ChildItemContent ".\wallet\values" | ForEach { $GetWStats | Add-Member $_.Name $_.Content } }
    $GetWStats
}

function Invoke-SwarmMode {

    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [datetime]$SwarmMode_Start,
        [Parameter(Position = 1, Mandatory = $false)]
        [int]$ModeDeviation = 5
    )




    $DateMinute = [Int]$SwarmMode_Start.Minute + $ModeDeviation
    $DateMinute = ([math]::Floor(($DateMinute / $ModeDeviation)) * $ModeDeviation)
    if ($DateMinute -gt 59) { $DateMinute = 0; $DateHour = [Int]$SwarmMode_Start.Hour; $DateHour = [int]$DateHour + 1 }else { $DateHour = [Int]$SwarmMode_Start.Hour; $DateHour = [int]$DateHour }
    if ($DateHour -gt 23) { $DateHour = 0; $DateDay = [Int]$SwarmMode_Start.Day; $DateDay = [int]$DateDay + 1 }else { $DateDay = [Int]$SwarmMode_Start.Day; $DateDay = [int]$DateDay }
    if ($DateDay -gt 31) { $DateDay = 1; $DateMonth = [Int]$SwarmMode_Start.Month; $DateMonth = [int]$DateMonth + 1 }else { $DateMonth = [Int]$SwarmMode_Start.Month; $DateMonth = [int]$DateMonth }
    if ($DateMonth -gt 12) { $DateMonth = 1; $DateYear = [Int]$SwarmMode_Start.Year; $DateYear = [int]$DateYear + 1 }else { $DateYear = [Int]$SwarmMode_Start.Year; $DateYear = [int]$DateYear }
    $ReadyValue = (Get-Date -Year $DateYear -Month $DateMonth -Day $DateDay -Hour $DateHour -Minute $DateMinute -Second 0 -Millisecond 0)
    $StartValue = [math]::Round((([DateTime](Get-Date)) - $ReadyValue).TotalSeconds)
    $StartValue
}

function ConvertFrom-Fees {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Double]$Fees,
        [Parameter(Position = 1, Mandatory = $true)]
        [Double]$Workers,
        [Parameter(Position = 2, Mandatory = $true)]
        [Double]$Estimate
    )

    [Double]$FeeStat = $fees / 100
    [Double]$WorkerPercent = $Workers * $FeeStat
    [Double]$PoolCut = $WorkerPercent + $Fees
    $WorkerFee = $Estimate * (1 - ($PoolCut / 100))
    return $WorkerFee
} 


function ConvertFrom-PoolHash {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Double]$HashRates,
        [Parameter(Position = 1, Mandatory = $true)]
        [Double]$Shares,
        [Parameter(Position = 2, Mandatory = $true)]
        [Double]$Estimate
    )

    $TotalShares = $Shares / $HashRates
    $TotalShares = [Math]::Round($TotalShares, 3)
    [Double]$Calc = $Estimate * $TotalShares
    $Calc
}

function Remove-BanHashrates {
    if ($global:BanHammer -gt 0 -and $global:BanHammer -ne "") {
        if (test-path ".\stats") { $A = Get-ChildItem "stats" | Where BaseName -Like "*hashrate*" }
        $global:BanHammer | ForEach-Object {
            $Sel = $_.ToLower()
            $A.BaseName | ForEach-Object {
                $Parse = $_ -split "`_"
                if($Parse[0] -eq $Sel){
                    Remove-Item ".\stats\$($_).txt" -Force
                }
                elseif($Parse[1] -eq $Sel) {
                    Remove-Item ".\stats\$($_).txt" -Force
                }
            }
        }
    }
}