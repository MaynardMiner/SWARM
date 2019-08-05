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

function Global:Start-Shuffle($X, $Y) {
    $X = [Double]$X * 1000
    $Z = [Double]$Y - $X
    $X = [math]::Round( ($Z / $X) , 4)
    $historical_P = ($(arg).historical_bias / 100)
    $historical_N = ($(arg).historical_bias / 100) * -1
    if( $X -gt $historical_P ){ $X = $historical_P }
    if($X -lt $historical_N ){
        if($X -le -1){ $X = -1 }
        else{ $X = $historical_N }
    }
    return $X
}

function Global:Get-Theta($Calcs, $Values) { 
    $Values | Select -Last $Calcs | Measure-Object -Sum 
}

function Global:Get-Zinterval($X) {
    $C = @{
        
    }
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
        [switch]$AsHashrate,
        [Parameter(Mandatory = $false)]
        [Double]$Shuffle
    )

    if ($name -eq "load-average") { $Interval = 10 }
    else { $Interval = $(arg).Interval }

    $Calcs = @{
        Minute    = [Math]::Max([Math]::Round(60 / $Interval), 1)
        Minute_5  = [Math]::Max([Math]::Round(300 / $Interval), 1)
        Minute_15 = [Math]::Max([Math]::Round(900 / $Interval), 1)
        Hour      = [Math]::Max([Math]::Round(3600 / $Interval), 1)
    }

    if (-not $AsHashrate) {
        $Calcs.Add("Hour_4", [Math]::Max([Math]::Round(14400 / $Interval), 1))
        $Calcs.Add("Day", [Math]::Max([Math]::Round(14400 / $Interval), 1))
        $Calcs.Add("Custom", [Math]::Max([Math]::Round(14400 / $Interval), 1))
    }

    if ($HashRate) {
        $Calcs.Add("Hashrate", [Math]::Max([Math]::Round(3600 / $Interval), 1))
    }

    if ($AsHashrate) { $Max_Periods = 15 }
    else { $Max_Periods = $(arg).Max_Periods }
    $Hash_Max = 15
    $name = $name -replace "`/", "`-"
    if ($name -eq "load-average") { $Max_Periods = 90; $Path = "build\txt\$Name.txt" }
    else { $Path = "stats\$Name.txt" }
    $SmallestValue = 1E-20
    $Check = Test-Path $Path

    $Stat = [PSCustomObject]@{
        Live      = [Double]$Value
        Minute    = [Double]$Value
        Minute_5  = [Double]$Value
        Minute_15 = [Double]$Value
        Hour      = [Double]$Value
        Values    = @()
    }

    if ($Check) {
        $GetStat = Get-Content $Path | ConvertFrom-Json
        $Stat.Minute = [Double]$GetStat.Minute
        $Stat.Minute_5 = [Double]$GetStat.Minute_5
        $Stat.Minute_15 = [Double]$GetStat.Minute_15
        $Stat.Hour = [Double]$GetStat.Hour
        $Stat.Values = @($GetStat.Values)

        $Hour_4 = [Double]$GetStat.Hour_4
        $Day = [Double]$GetStat.Day
        $Custom = [Double]$GetStat.Custom
        $S_Hash = [Double]$GetStat.Hashrate
        $S_Hash_Vals = @($GetStat.Hash_Vals)
        $Deviation = $GetStat.Deviation
        $Deviations = @($GetStat.Deviations)
    }

    if (-not $AsHashrate) {
        if ($Check) {
            $Stat | Add-Member "Hour_4" $Hour_4
            $Stat | Add-Member "Day" $Day
            $Stat | Add-Member "Custom" $Custom
        } else {
            $Stat | Add-Member "Hour_4" $Value
            $Stat | Add-Member "Day" $Value
            $Stat | Add-Member "Custom" $Value
        }
        if($HashRate) {
            if ($Check) {
            $Stat | Add-Member "Hashrate" $S_Hash
            $Stat | Add-Member "Hash_Vals" $S_Hash_Vals
            } else {
                $Stat | Add-Member "Hashrate" $HashRate
                $Stat | Add-Member "Hash_Vals" @()    
            }
        }
        if($Shuffle) {
            if($Check) {
                $Stat | Add-member "Deviation" $Deviation 
                $Stat | Add-member "Deviations" $Deviations
            }
            else{
                $Stat | Add-Member "Deviation" $Shuffle
                $Stat | Add-Member "Deviations" @() 
            }
        }
    }
    
    $Stat.Values += [decimal]$Value
    if ($Stat.Values.Count -gt $Max_Periods) { $Stat.Values = $Stat.Values | Select -Skip 1 }

    if ($HashRate) {
        $Stat.Hash_Vals += [decimal]$Hashrate
        if ($Stat.Hash_Vals.Count -gt $Hash_Max) { $Stat.Hash_Vals = $Stat.Hash_Vals | Select -Skip 1 }
    }

    if($Shuffle) {
        $Stat.Deviations += $Shuffle
        if ($Stat.Deviations.Count -gt $Max_Periods) { $Stat.Deviations = $Stat.Deviations | Select -Skip 1 }
    }

    $Calcs.keys | foreach {
        if ($_ -eq "Hashrate") { $T = $Stat.Hash_Vals }
        else { $T = $Stat.Values }
        $Theta = (Global:Get-Theta -Calcs $Calcs.$_ -Values $T)
        $Alpha = [Double](Global:Get-Alpha($Theta.Count))
        $Zeta = [Double]$Theta.Sum / $Theta.Count
        $Stat.$_ = [Math]::Max( ( $Zeta * $Alpha + $($Stat.$_) * (1 - $Alpha) ) , $SmallestValue )
    }

    if($Shuffle) {
        $T = $Stat.Deviations
        $Theta = (Global:Get-Theta -Calcs $Calcs.Day -Values $T)
        $Alpha = [Double](Global:Get-Alpha($Theta.Count))
        $Zeta = [Double]$Theta.Sum / $Theta.Count
        $Stat.Deviation = [Math]::Round($Zeta * $Alpha + $($Stat.Deviation) * (1 - $Alpha), 4 )
    }

    if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" }

    $Stat.Values = @( $Stat.Values | % { [Decimal]$_ } )

    if ($Stat.Hash_Vals) { $Stat.Hash_Vals = @( $Stat.Hash_Vals | % { [Decimal]$_ } ) }
    if ($Stat.Deviations) { $Stat.Deviations = @( $Stat.Deviations | % { [double]$_ } ) }
    $Stat.Live = [Decimal]$Value
    $Stat.Minute = [Decimal]$Stat.Minute
    $Stat.Minute_5 = [Decimal]$Stat.Minute_5
    $Stat.Minute_15 = [Decimal]$Stat.Minute_15
    $Stat.Hour = [Decimal]$Stat.Hour
    if($Stat.Hour_4){$Stat.Hour_4 = [Decimal]$Stat.Hour_4}
    if($Stat.Day){$Stat.Day = [Decimal]$Stat.Day}
    if($Stat.Custom){$Stat.Custom = [Decimal]$Stat.Custom}
    if($Stat.Hashrate){$Stat.Hashrate = [Decimal]$Stat.Hashrate}

    $Stat | ConvertTo-Json | Set-Content $Path

    $Stat

}

function Global:Get-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $name = $name -replace "`/", "`-"
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

Set-Alias -Name shuffle -Value Global:Start-Shuffle -Scope Global