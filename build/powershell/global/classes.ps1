class pool {
   [string]$Symbol
   [string]$Algorithm
   [double]$Price
   [string]$Protocol
   [string]$Pool_Host
   [string]$Port
   [string]$User1
   [string]$User2
   [string]$User3
   [string]$Pass1
   [string]$Pass2
   [string]$Pass3
   [double]$Previous
   [string]$Worker

   pool() { }

   pool([string]$Symbol, [string]$Algorithm, [double]$Price, [string]$Protocol,
      [string]$Pool_Host, [string]$Pool_Port, [string]$User1, [string]$User2,
      [string]$User3, [string]$Pass1, [string]$Pass2, [string]$Pass3,
      [double]$Previous) {
      [string]$this.Symbol = $Symbol
      [string]$this.Algorithm = $Algorithm
      [double]$this.Price = $Price
      [string]$this.Protocol = $Protocol
      [string]$this.Pool_Host = $Pool_Host
      [string]$this.Port = $Pool_Port
      [string]$this.User1 = $User1
      [string]$this.User2 = $User2
      [string]$this.User3 = $User3
      [string]$this.Pass1 = $Pass1
      [string]$this.Pass2 = $Pass2
      [string]$this.Pass3 = $Pass3
      [double]$this.Previous = $Previous        
      [string]$this.worker = $Null
   }

   pool([string]$Symbol, [string]$Algorithm, [double]$Price, [string]$Protocol,
      [string]$Pool_Host, [string]$Pool_Port, [string]$User1, [string]$User2,
      [string]$User3, [string]$worker, [double]$Previous) {
      [string]$this.Symbol = $Symbol
      [string]$this.Algorithm = $Algorithm
      [double]$this.Price = $Price
      [string]$this.Protocol = $Protocol
      [string]$this.Pool_Host = $Pool_Host
      [string]$this.Port = $Pool_Port
      [string]$this.User1 = $User1
      [string]$this.User2 = $User2
      [string]$this.User3 = $User3
      [string]$this.worker = $worker
      [double]$this.Previous = $Previous        
   }
}

class STAT_METHODS {
   ## Get the stat file
   static [PSCustomObject]Get([string]$name) {
      [PSCustomObject]$Get = $null
      if (Test-Path ".\stats\$name.json") {
         try {
            $Get = Get-Content ".\stats\$name.json" -ErrorAction Stop | 
            ConvertFrom-Json -ErrorAction Stop
         }
         catch {
            Write-Host "Warning: Read Error with .\stats\$name.json" -Foreground red
         }
      }
      return $Get
   }

   ## Sets the stat file
   static [void]Set([string]$name, [object]$stat) {
      try {
         $stat | ConvertTo-Json -ErrorAction Stop | Set-Content ".\stats\$name.json"
      }
      catch {
         Write-Host "Warning: Write Error with .\stats\$name.json" -Foreground Red
      }
   }

   ## Calculate Weight
   static [Decimal]Alpha([Decimal]$X) {
      return (2 / ($X + 1) )
   }

   ## Get Sum of values
   static [Microsoft.PowerShell.Commands.GenericMeasureInfo]Theta([Int]$Period, [Decimal[]]$Values) {
      return $Values | Select-Object -Last $Period | Measure-Object -Sum 
   }

   ## Checks if a day has passed, and whether or not
   ## stat should add new daily values.
   static [void]Check_Weekly([object]$old, [object]$new, $Actual) {
      $new.Daily_Values = $old.Daily_values
      $new.Daily_Actual_Values = $old.Daily_Actual_Values
      $new.Daily_Hashrate_Values = $old.Daily_Hashrate_Values
      $new.Start_Of_Day = $old.Start_Of_Day

      $Total_Stat_Time = [math]::Round(((Get-Date).ToUniversalTime() - [DateTime]$Old.Start_Of_Day).TotalSeconds)
      if ($Total_Stat_Time -ge 86400) {
         $new.Daily_Values += $old.Day_MA
         $new.Daily_Actual_Values += $Actual
         $new.Daily_Hashrate_Values += $old.Avg_Hashrate
         if ($new.Daily_Values.Count -gt 7) {
            $new.Daily_Values = $new.Daily_Values | Select -Last 7
            $new.Daily_Actual_Values = $new.Daily_Actual_Values | Select -Last 7
            $new.Daily_Hashrate_Values = $new.Daily_Hashrate_Values | Select -Last 7
         }
         $new.Start_Of_Day = (Get-Date).ToUniversalTime().ToString("o")
      }
   }

   ## Resets particular stats if SWARM was shut off
   static [PSCustomObject]Update_Time([PSCustomObject]$old, [decimal]$Value) {
      ## Determine last time stat was pulled
      $Last_Pull = [math]::Round(((Get-Date).ToUniversalTime() - [DateTime]$Old.Updated).TotalSeconds)
      <# Now we need to see how much of the stats is still valid.
         If user shut off SWARM for 10 minutes for example, then
         technically, the minute_15 stat is still viable. So 
         we remove all values and make the minute_15 the first value
         in value dataset.

         The same if it has been 3 hours, the 4 hour would be
         a viable stat. All values are removed, and 4 hour is used
         as the last stat

         If its greater than 4 hours, we use the day stat to continue.

         If longer than a day- Then we reset entirely.
      #>
      if ($Last_Pull -gt 86400) {
         $old.Live_Values = $old.Live_Values | Select-Object -Last 1
         $old.Minute_10_EMA = $value
         $old.Minute_15_EMA = $value
         $old.Minute_30_EMA = $value
         $old.Hour_EMA = $value
         $old.Hour_4_EMA = $value
         $old.Day_EMA = $value
         $old.Minute_10_MA = $value
         $old.Minute_15_MA = $value
         $old.Minute_30_MA = $value
         $old.Hour_MA = $value
         $old.Hour_4_MA = $value
         $old.Day_MA = $value
         $old.Daily_Values = @()
         $old.Daily_Actual_Values = @()
         $old.Daily_Hashrate_Values = @()
         $old.Start_Of_Day = (Get-Date).ToUniversalTime().ToString("o")
         $old.Pulls = 1
      }
      elseif ($Last_Pull -gt 14440) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Day_MA)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_10_EMA = $old.Day_EMA
         $old.Minute_15_EMA = $old.Day_EMA
         $old.Minute_30_EMA = $old.Day_EMA
         $old.Hour_EMA = $old.Day_EMA
         $old.Hour_4_EMA = $old.Day_EMA
         $old.Minute_10_MA = $old.Day_MA
         $old.Minute_15_MA = $old.Day_MA
         $old.Minute_30_MA = $old.Day_MA
         $old.Hour_MA = $old.Day_MA
         $old.Hour_4_MA = $old.Day_MA
      }
      elseif ($last_Pull -gt 3600) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Hour_4_MA)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_10_EMA = $old.Hour_4_EMA
         $old.Minute_15_EMA = $old.Hour_4_EMA
         $old.Minute_30_EMA = $old.Hour_4_EMA
         $old.Hour_EMA = $old.Hour_4_EMA
         $old.Minute_10_MA = $old.Hour_4_MA
         $old.Minute_15_MA = $old.Hour_4_MA
         $old.Minute_30_MA = $old.Hour_4_MA
         $old.Hour_MA = $old.Hour_4_MA
      }
      elseif ($last_Pull -gt 1800) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Hour_MA)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_10_EMA = $old.Hour_EMA
         $old.Minute_15_EMA = $old.Hour_EMA
         $old.Minute_30_EMA = $old.Hour_EMA
         $old.Minute_10_MA = $old.Hour_MA
         $old.Minute_15_MA = $old.Hour_MA
         $old.Minute_30_MA = $old.Hour_MA
      }
      elseif ($last_Pull -gt 900) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Minute_30_MA)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_10_EMA = $old.Minute_30_EMA
         $old.Minute_15_EMA = $old.Minute_30_EMA
         $old.Minute_10_MA = $old.Minute_30_MA
         $old.Minute_15_MA = $old.Minute_30_MA
      }
      elseif ($last_Pull -gt 600) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Minute_15_MA)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_10_EMA = $old.Minute_15_EMA
         $old.Minute_10_MA = $old.Minute_15_MA
      }
      return $old
   }

   ## Simply Moving Average
   static [void]MA($item, $stat, $old_value, $incoming) {
      $item.$stat = [Convert]::ToDecimal([Math]::Round( ( ($item.$stat * $item.Pulls) + $incoming ) / ($item.Pulls + 1), 0 ))
   }

   ## Weighted Moving Average
   static [void]EMA([Object]$old_stat, [Object]$New_stat, [hashtable]$Calcs) {
      $SmallestValue = 1E-20
      $Calcs.keys | ForEach-Object {
         ## Price
         $Price = $old_stat.Live_Values | Select -Last 1
         ## Select Only Values For Moving Period
         $theta = [STAT_METHODS]::Theta($Calcs.$_, $old_stat.Live_Values)
         ## Smoothing For Period
         $alpha = [Double][STAT_METHODS]::Alpha($theta.Count)
         ## Simple Moving Average For The Select Periods
         $zeta = [Convert]::ToDecimal($Theta.Sum / $Theta.Count)
         ## Add MA
         $New_Stat."$($_)_MA" = $zeta
         ## Create new EMA
         $New_stat."$($_)_EMA" = [convert]::ToDecimal($Price * $alpha + $zeta * (1 - $alpha))
      }
   }

   ## Calculate Historical Earnings.
   static [void]Algo_Bias($item, $Actual) {
      $Actual = [convert]::ToDecimal($Actual)  
      <# If SWARM hasn't been running long enough to gather daily
         stats, we will use the Daily MA.
         If SWARM has recorded daily averages, then will will use
         a weekly simple moving average.
      #>

      ## PPS Pools (Nicehash and Whalesburg) have no actual 24_hour values
      ## Based on how they operate- Live vs. 24 hours or week vs. day
      ## will work fine. It will still build a trend.

      if ($item.Daily_Values.Count -eq 0) {
         $constant = $item.Day_MA
         if ($Actual -eq -1) {
            $Actual = $item.Live
         }
      }
      else {
         $theta = [STAT_METHODS]::Theta(7, $item.Daily_Values)
         $constant = $theta.sum / $theta.count
         $theta = [STAT_METHODS]::Theta(7, $item.Daily_Actual_Values)
         $actual = $theta.sum / $theta.count
         if($Actual -eq -1) {
          $Actual = $item.Day_MA  
         }
      }
      if ($constant -ne 0 -and $Actual -ne 0) {
         $item.Historical_Bias = [math]::Round(($actual - $constant) / $constant , 4)
      }
      else {
         $item.Historical_Bias = -1
      }
      if($item.Historical_Bias -lt -1) {
         $item.Historical_Bias -eq -1
      }
   }

   ## Calculate Historical Earnings For Coin
   static [void]Coin_Bias($item, $Actual) {
      $Actual = [convert]::ToDecimal($Actual)

      <# If SWARM hasn't been running long enough to gather daily
         stats, we will use the Daily MA.
         If SWARM has recorded daily averages, then will will use
         a weekly simple moving average.

         Coin prices we need to to format to actual 24 hours.
      #>

      if ($item.Daily_Values.Count -eq 0) {
         $constant = $item.Day_MA
         if ($actual -ne 0 -and $item.Avg_Hashrate -gt 1) {
            $actual = $actual / $item.Avg_Hashrate
         }
         else {
            $actual = 0
         }
      }
      else {
         $theta = [STAT_METHODS]::Theta(7, $item.Daily_Values)
         $constant = $theta.sum / $theta.count

         $theta = [STAT_METHODS]::Theta(7, $item.Daily_Actual_Values)
         $actual_MA = $theta.sum / $theta.count

         $theta = [STAT_METHODS]::Theta(7, $item.Daily_Hashrate_Values)
         $hashrate_MA = $theta.sum / $theta.count

         if ($actual_MA -ne 0 -and $hashrate_MA -gt 1) {
            $actual = $actual_MA / $hashrate_MA
         }
         else {
            $actual = 0
         }
      }
      if ($constant -ne 0 -and $Actual -ne 0) {
         $item.Historical_Bias = [math]::Round(($actual - $constant) / $constant , 4)
      }
      else {
         $item.Historical_Bias = -1
      }
      if($item.Historical_Bias -lt -1) {
         $item.Historical_Bias -eq -1
      }
   }
}

## Basic Stat Class
class Stat {
   [Decimal]$Live
   [Decimal]$Minute_10_EMA
   [Decimal]$Minute_10_MA
   [Decimal]$Minute_15_EMA
   [Decimal]$Minute_15_MA
   [Decimal]$Minute_30_EMA
   [Decimal]$Minute_30_MA
   [Decimal]$Hour_EMA
   [Decimal]$Hour_MA
   [Decimal]$Actual
   [Decimal[]]$Live_Values
   [Int]$Pulls = 0
   [bool]$Locked ## Lock the stat
   [string]$Updated
}

## A Pool Stat
class Pool_Stat : Stat {
   [Decimal]$Hour_4_EMA
   [Decimal]$Hour_4_MA
   [Decimal]$Day_EMA
   [Decimal]$Day_MA
   [Decimal]$Avg_Hashrate
   [Decimal]$Historical_Bias = 0 ## Total bias % based on daily estimates vs actual
   [Decimal[]]$Daily_Values
   [Decimal[]]$Daily_Actual_Values
   [Decimal[]]$Daily_Hashrate_Values
   [DateTime]$Start_Of_Day

   Pool_Stat([string]$name, [decimal]$Estimate, [Decimal]$Hashrate, [decimal]$Actual, [bool]$coin) {
      $name = $name -replace "`/", "`-"
      $name = "pool_$($name)_pricing"
      $old = [STAT_METHODS]::Get($name)
      ## Minimum decimal value
      ## Convert Value to Decimal
      $Value = [Convert]::ToDecimal($Estimate)         
      ## Calc periods for MA
      [hashtable]$Calcs = @{
         Minute_10 = 2;
         Minute_15 = 3;
         Minute_30 = 6;
         Hour      = 12;
         Hour_4    = 48;
         Day       = 288;
      }

      ## IF there was a previous stat file
      if ($old) {

         ## Add incoming Value.
         $old.Live_Values += $Value

         ## Find Gaps
         $old = [STAT_METHODS]::Update_Time($old, $Value)

         ## Keep only 24hrs worth of values.
         if ($old.Live_Values.Count -gt 288) {
            $old.Live_Values = $old.Live_Values | Select-Object -Last 288
         }

         ## Add live values and make EMA
         $old.Live = $value
         [STAT_METHODS]::EMA($old, $this, $Calcs)

         ## Do MA for stats that need it
         [STAT_METHODS]::MA($this, "Avg_Hashrate", $old.Avg_Hashrate, $Hashrate)
         if ($old.Pulls -lt 288) { $old.Pulls++ }
         $this.Pulls = $old.Pulls

         ## Calculate Bias
         if ($coin) {
            [STAT_METHODS]::Coin_Bias($old, $Actual)
         }
         else {
            [STAT_METHODS]::Algo_Bias($old, $Actual)
         }         

         ## If it is a new day - Add to weekly stat values.
         [STAT_METHODS]::Check_Weekly($old, $this, $Actual)


         $this.Live_Values = $old.Live_Values
         $this.Actual = $Actual
         $this.Live = $Value
         $this.Historical_Bias = $old.Historical_Bias
         $this.Locked = $old.Locked
      }
      else {
         $this.Live_Values += $Value
         $this.Pulls++
         $this.Live = $value
         $this.Minute_10_EMA = $value
         $this.Minute_10_MA = $value
         $this.Minute_15_EMA = $value
         $this.Minute_15_MA = $value
         $this.Minute_30_EMA = $value
         $this.Minute_30_MA = $value
         $this.Hour_EMA = $value
         $This.Hour_MA = $value
         $this.Hour_4_EMA = $Value
         $this.Hour_4_MA = $value
         $this.Day_EMA = $value
         $this.Day_MA = $value
         $this.Daily_Values = @()
         $this.Daily_Actual_Values = @()
         $this.Daily_Hashrate_Values = @()
         $this.Avg_Hashrate = $Hashrate
         $this.Locked = $false
         $this.Actual = $Actual
         $this.Start_Of_Day = (Get-Date).ToUniversalTime().ToString("o")
         if ($coin) {
            [STAT_METHODS]::Coin_Bias($this, $Actual)
         }
         else {
            [STAT_METHODS]::Algo_Bias($this, $Actual)
         }
      }

      [string]$this.Updated = (Get-Date).ToUniversalTime().ToString("o")

      $stat = [ordered]@{
         Live                  = $this.Live
         Actual                = $This.Actual
         Minute_10_EMA         = $this.Minute_10_EMA
         Minute_10_MA          = $this.Minute_10_MA
         Minute_15_EMA         = $this.Minute_15_EMA
         Minute_15_MA          = $This.Minute_15_MA
         Minute_30_EMA         = $This.Minute_30_EMA
         Minute_30_MA          = $this.Minute_30_MA
         Hour_EMA              = $this.Hour_EMA
         Hour_MA               = $This.Hour_MA
         Hour_4_EMA            = $This.Hour_4_EMA
         Hour_4_MA             = $This.Hour_4_MA
         Day_EMA               = $This.Day_EMA
         Day_MA                = $this.Day_MA
         Avg_Hashrate          = $this.Avg_Hashrate
         Pulls                 = $this.Pulls
         Historical_Bias       = $this.Historical_Bias
         Start_Of_Day          = $this.Start_Of_Day
         Locked                = $this.Locked
         Updated               = $this.Updated
         Daily_Values          = $this.Daily_Values
         Daily_Actual_Values   = $this.Daily_Actual_Values
         Daily_Hashrate_Values = $this.Daily_Hashrate_Values
         Live_Values           = $this.Live_Values
      }

      [STAT_METHODS]::Set($name, $stat)
   }
}

class Miner_Stat : Stat {
   [Decimal]$Rejections
}

class Watt_Stat : Stat {

}