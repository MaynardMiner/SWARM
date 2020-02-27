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
    return $X
}

function Global:Get-Theta($Calcs, $Values) { 
    $Values | Select -Last $Calcs | Measure-Object -Sum 
}

function Global:Set-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $false)]
        [Double]$HashRate = $null,
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Date = (Get-Date),
        [Parameter(Mandatory = $false)]
        [switch]$AsHashrate,
        [Parameter(Mandatory = $false)]
        [Double]$Shuffle = $null,
        [Parameter(Mandatory = $false)]
        [Double]$Rejects
    )

    ## Define Set Interval for load average
    if ($name -eq "load-average") { $Interval = 10 }
    else { $Interval = 300 }

    ## Define total # of values for each time frame
    $Calcs = @{
        Minute    = [Math]::Max([Math]::Round(60 / $Interval), 1)
        Minute_5  = [Math]::Max([Math]::Round(300 / $Interval), 1)
        Minute_15 = [Math]::Max([Math]::Round(900 / $Interval), 1)
        Hour      = [Math]::Max([Math]::Round(3600 / $Interval), 1)
    }

    ## If pool stat - Add more time frames
    if (-not $AsHashrate) {
        $Calcs.Add("Hour_4", [Math]::Max([Math]::Round(14400 / $Interval), 1))
        $Calcs.Add("Day", [Math]::Max([Math]::Round(86400 / $Interval), 1))
        $Calcs.Add("Custom", [Math]::Max([Math]::Round(14400 / $Interval), 1))
    }

    ## Adjust for historical_bias argument
    if ($(arg).historical_bias -ne 0 -and $Shuffle) {
        $historical_P = ($(arg).historical_bias / 100)
        $historical_N = $historical_P * -1
        if ( $Shuffle -gt $historical_P) { $Shuffle = $historical_P }
        if ($Shuffle -lt $historical_N ) {
            if ($Shuffle -le -1) { $Shuffle = -1 }
            else { $Shuffle = $historical_N }
        }
    }

    ## Define maximum period calcalations
    if ($AsHashrate) { $Max_Periods = 15 }
    else { $Max_Periods = $(arg).Max_Periods }
    $Hash_Max = 15

    ## Define Stat paths
    $name = $name -replace "`/", "`-"
    if ($name -eq "load-average") { $Max_Periods = 90; $Path = "debug\$Name.txt" }
    else { $Path = "stats\$Name.txt" }
    $Check = Test-Path $Path

    ## Minimum decimal value
    $SmallestValue = 1E-20

    ## Build default stat table
    $Stat = [PSCustomObject]@{
        Live      = [Double]$Value
        Minute    = [Double]$Value
        Minute_5  = [Double]$Value
        Minute_15 = [Double]$Value
        Hour      = [Double]$Value
        Locked    = $false
    }

    ## Change default table if stat already exists
    if ($Check) {
        $GetStat = Get-Content $Path | ConvertFrom-Json
        $Stat.Minute = [Double]$GetStat.Minute
        $Stat.Minute_5 = [Double]$GetStat.Minute_5
        $Stat.Minute_15 = [Double]$GetStat.Minute_15
        $Stat.Hour = [Double]$GetStat.Hour
        
        if ($GetStat.Locked) {
            $Stat.Locked = [bool]$GetStat.Locked
        }

        $Hour_4 = [Double]$GetStat.Hour_4
        $Day = [Double]$GetStat.Day
        $Week = [Double]$GetStat.Week
        $Custom = [Double]$GetStat.Custom
        $End_Of_Day = [Double]$GetStat.End_Of_Day
        $Week_Periods = [Double]$GetStat.Week_Periods
        $S_Hash = [Double]$GetStat.Hashrate
        $S_Hash_Count = $GetStat.Hashrate_Periods
        $Deviation = $GetStat.Deviation
        $Deviation_Periods = $GetStat.Deviation_Periods
        $Rejections = $GetStat.Rejections
        $Rejection_Periods = $GetStat.Rejection_Periods
    }

    ## Add extra time frames if pool stat
    if (-not $AsHashrate) {
        if ($Check) {
            $Stat | Add-Member "Hour_4" $Hour_4
            $Stat | Add-Member "Day" $Day
            $Stat | Add-Member "Week" $Week
            $Stat | Add-Member "Week_Periods" $Week_Periods
            $Stat | Add-Member "End_Of_Day" $End_Of_Day
            $Stat | Add-Member "Custom" $Custom
        }
        else {
            $Stat | Add-Member "Hour_4" $Value
            $Stat | Add-Member "Day" $Value
            $Stat | Add-Member "Week" $Value
            $Stat | Add-Member "End_Of_Day" 0
            $Stat | Add-Member "Week_Periods" 1
            $Stat | Add-Member "Custom" $Value
        }

        ## Add extra values if pool hashrate
        if ([string]$HashRate) {
            if ($Check) {
                $Stat | Add-Member "Hashrate" $S_Hash
                $Stat | Add-Member "Hashrate_Periods" $S_Hash_Count
            }
            else {
                $Stat | Add-Member "Hashrate" $HashRate
                $Stat | Add-Member "Hashrate_Periods" 0
            }
        }

        ## Add extra values if historical bias
        if ([string]$Shuffle) {
            $Stat | Add-member "Deviation" $Shuffle 
        }
    }

    ## Add extra values if rejection bias
    if ($Rejects -gt -1 -and $AsHashrate) {
        if ($Check) {
            $Stat | Add-member "Rejections" $Rejections
            $Stat | Add-Member "Rejection_Periods" $Rejection_Periods
        }
        else {
            $Stat | Add-Member "Rejections" $Rejects
            $Stat | Add-Member "Rejection_Periods" 0
        }
    }    

    ## Set initial values
    $Stat | Add-Member "Values" @()
    if ($Check) { $Stat.Values = @($GetStat.Values) }
    
    ## Add new values, rotate first value if above max periods
    $Stat.Values += [decimal]$Value
    if ($Stat.Values.Count -gt $Max_Periods) { $Stat.Values = $Stat.Values | Select -Skip 1 }    
    
    if ($Stat.Locked -eq $false) {

        ## Same for hashrate, only it is a rolling moving average (no values)
        if ($HashRate) {
            if ($Stat.Hashrate_Periods -lt $Hash_Max) { $Stat.Hashrate_Periods++ }
            else { $Stat.Hashrate_Periods = $Hash_Max }
        }

        ## Same for rejection bias, but is a rolling moving average (no values)
        if ($Rejects -gt -1 -and $AsHashrate) {
            if ( $Stat.Rejection_Periods -lt $Hash_Max) { $Stat.Rejection_Periods++ }
            else { $Stat.Rejection_Periods = $Hash_Max }
        }    

        ## Calculate moving average for each time period
        $Calcs.keys | foreach {
            $T = $Stat.Values
            $Theta = (Global:Get-Theta -Calcs $Calcs.$_ -Values $T)
            $Alpha = [Double](Global:Get-Alpha($Theta.Count))
            $Zeta = [Double]$Theta.Sum / $Theta.Count
            $Stat.$_ = [Math]::Max( ( $Zeta * $Alpha + $($Stat.$_) * (1 - $Alpha) ) , $SmallestValue )
            $Stat.$_ = $Stat.$_
        }
        
        if(-not $AsHashrate) {
            $Stat.End_Of_Day++
            if($Stat.End_Of_Day -gt (86400 / $Interval)) {
                $Stat.End_Of_Day = 1
                $Stat.Week = [Math]::Round( ( ($Stat.Week * $Stat.Week_Periods) + $Stat.Day ) / ($Stat.Week_Periods + 1), 0 )
                $stat.Week_Periods++
                if($stat.Week_Periods -gt 7) {$stat.Week_Periods = 7}
            }
        }

        ## Calculate simple rolling moving average for each pool hashrate / deviation / Rejects
        if ($HashRate) { $Stat.Hashrate = [Math]::Round( ( ($Stat.Hashrate * $Stat.Hashrate_Periods) + $HashRate ) / ($Stat.Hashrate_Periods + 1), 0 ) }
        if ($Rejects -gt -1 -and $AsHashrate) { $Stat.Rejections = [Math]::Round( ( ($Stat.Rejections * $Stat.Rejection_Periods) + $Rejects ) / ($Stat.Rejection_Periods + 1), 4 ) }
    }
    else {
        log "Warning: Cannot change stat - `'Locked`' in stat file is set to true" -Foreground yellow
    }

    ## In case it doesn't exist.
    if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" }

    ## Convert final values to decimal values, and set new file.
    $Stat.Values = @( $Stat.Values | % { [Decimal]$_ } )
    $Stat.Live = [Decimal]$Value
    $Stat.Minute = [Decimal]$Stat.Minute
    $Stat.Minute_5 = [Decimal]$Stat.Minute_5
    $Stat.Minute_15 = [Decimal]$Stat.Minute_15
    $Stat.Hour = [Decimal]$Stat.Hour
    if ($Stat.Hour_4) { $Stat.Hour_4 = [Decimal]$Stat.Hour_4 }
    if ($Stat.Day) { $Stat.Day = [Decimal]$Stat.Day }
    if ($Stat.Week) { $Stat.Week = [Decimal]$Stat.Week }
    if ($Stat.Custom) { $Stat.Custom = [Decimal]$Stat.Custom }
    if ($Stat.Hashrate) { $Stat.Hashrate = [Decimal]$Stat.Hashrate }
    if ($Stat.Rejections -and $AsHashrate) { $Stat.Rejections = [Decimal]$Stat.Rejections }

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
    if ($name -eq "load-average") { Get-ChildItem "debug" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json }
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