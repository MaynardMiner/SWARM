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

function Global:Get-Alpha($X) { (2 / ($X + 1) ) }

function Global:Get-Theta { 
    param (
        [Parameter(Mandatory = $true)]
        [Int]$Calcs,
        [Parameter(Mandatory = $true)]
        [Array]$Values
    )
    $Values | Select -Last $Calcs | Measure-Object -Sum 
}

function Global:Set-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $false)]
        [Double]$HashRate,
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Date = (Get-Date),
        [Parameter(Mandatory = $false)]
        [switch]$AsHashrate
    )

    $Calcs = @{
        Minute    = [Math]::Max([Math]::Round(60 / $(arg).Interval), 1)
        Minute_5  = [Math]::Max([Math]::Round(300 / $(arg).Interval), 1)
        Minute_15 = [Math]::Max([Math]::Round(900 / $(arg).Interval), 1)
        Hour      = [Math]::Max([Math]::Round(3600 / $(arg).Interval), 1)
    }

    if (-not $AsHashrate) {
        $Calcs.Add("Hour_4", [Math]::Max([Math]::Round(14400 / $(arg).Interval), 1))
        $Calcs.Add("Day", [Math]::Max([Math]::Round(14400 / $(arg).Interval), 1))
        $Calcs.Add("Custom", [Math]::Max([Math]::Round(14400 / $(arg).Interval), 1))
    }

    if ($HashRate) {
        $Calcs.Add("Hashrate", [Math]::Max([Math]::Round(3600 / $(arg).Interval), 1))
    }

    if ($AsHashrate) { $Max_Periods = 15 }
    else { $Max_Periods = $(arg).Max_Periods }
    $Hash_Max = 15
    $name = $name -replace "`/","`-"
    if ($name -eq "load-average") { $Max_Periods = 90; $Path = "build\txt\$Name.txt" }
    else { $Path = "stats\$Name.txt" }
    $SmallestValue = 1E-20

    if (-not $AsHashrate) {
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
    }
    elseif (Test-Path $Path) {
        $Stat = Get-Content $Path | ConvertFrom-Json 
        $Stat = [PSCustomObject]@{
            Live      = [Double]$Value
            Minute    = [Double]$Stat.Minute
            Minute_5  = [Double]$Stat.Minute_5
            Minute_15 = [Double]$Stat.Minute_15
            Hour      = [Double]$Stat.Hour
            Values    = $Stat.Values
        }
    }
    else {
        $Stat = [PSCustomObject]@{
            Live      = [Double]$Value
            Minute    = [Double]$Value
            Minute_5  = [Double]$Value
            Minute_15 = [Double]$Value
            Hour      = [Double]$Value
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
        $Theta = (Global:Get-Theta -Calcs $Calcs.$_ -Values $T)
        $Alpha = [Double](Global:Get-Alpha($Theta.Count))
        $Zeta = [Double]$Theta.Sum / $Theta.Count
        $Stat.$_ = [Math]::Max( ( $Zeta * $Alpha + $($Stat.$_) * (1 - $Alpha) ) , $SmallestValue )
    }

    if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" }

    $Stat.Values = @( $Stat.Values | % { [Decimal]$_ } )
    if ($Stat.Hash_Val) { $Stat.Hash_Val = @( $Stat.Hash_Val | % { [Decimal]$_ } ) }

    if (-not $AsHashrate) {
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
    }
    else {
        $Stat = [PSCustomObject]@{
            Live      = [Double]$Value
            Minute    = [Double]$Stat.Minute
            Minute_5  = [Double]$Stat.Minute_5
            Minute_15 = [Double]$Stat.Minute_15
            Hour      = [Double]$Stat.Hour
            Values    = $Stat.Values
        } | ConvertTo-Json | Set-Content $Path
    }

    $Stat

}

function Global:Get-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $name = $name -replace "`/","`-"
    if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" }
    if ($name -eq "load-average") { Get-ChildItem "build\txt" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json }
    else { Get-ChildItem "stats" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json }
}

function Global:Set-WStat {
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

function Global:get-wstats {
    $GetWStats = [PSCustomObject]@{ }
    if (Test-Path ".\wallet\values") { Global:Get-ChildItemContent ".\wallet\values" | ForEach { $GetWStats | Add-Member $_.Name $_.Content } }
    $GetWStats
}

function Global:ConvertFrom-Fees {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Double]$Fees,
        [Parameter(Position = 1, Mandatory = $true)]
        [Double]$Workers,
        [Parameter(Position = 2, Mandatory = $true)]
        [Double]$Estimate,
        [Parameter(Position = 3, Mandatory = $true)]
        [Double]$Divisor
    )

    [Double]$FeeStat = $fees / 100
    [Double]$WorkerPercent = $Workers * $FeeStat
    [Double]$PoolCut = $WorkerPercent + $Fees
    [Double]$WorkerFee = $Estimate / $Divisor * (1 - ($PoolCut / 100))
    return $WorkerFee
}