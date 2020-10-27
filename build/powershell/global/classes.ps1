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

   ## Get the stat file
   hidden static [PSCustomObject]Get([string]$name) {
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
   hidden static [void]Set([string]$name, [object]$stat) {
      try {
         $stat | ConvertTo-Json -ErrorAction Stop | Set-Content ".\stats\$name.json"
      }
      catch {
         Write-Host "Warning: Write Error with .\stats\$name.json" -Foreground Red
      }
   }
   
   ## Calculate Weight
   hidden static [Decimal]Alpha([Decimal]$X) {
      return (2 / ($X + 1) )
   }
   
   ## Get Sum of values
   hidden static [Microsoft.PowerShell.Commands.GenericMeasureInfo]Theta([Int]$Period, [Decimal[]]$Values) {
      return $Values | Select-Object -Last $Period | Measure-Object -Sum 
   }
   
   ## Checks if a day has passed, and whether or not
   ## stat should add new daily values.
   hidden static [void]Check_Weekly([object]$old, [object]$new, $Actual) {
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
            $new.Daily_Values = $new.Daily_Values | Select-Object -Last 7
            $new.Daily_Actual_Values = $new.Daily_Actual_Values | Select-Object -Last 7
            $new.Daily_Hashrate_Values = $new.Daily_Hashrate_Values | Select-Object -Last 7
         }
         $new.Start_Of_Day = (Get-Date).ToUniversalTime().ToString("o")
      }
   }
   
   ## Resets particular stats if SWARM was shut off
   ## TODO Actually grab good values rather than use EMA.
   hidden static [PSCustomObject]Update_Time([PSCustomObject]$old, [decimal]$Value) {
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
         $old.Pulls = 288
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
         $old.Pulls = 48
      }
      elseif ($last_Pull -gt 1800) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Hour_MA)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_10_EMA = $old.Hour_EMA
         $old.Minute_15_EMA = $old.Hour_EMA
         $old.Minute_30_EMA = $old.Hour_EMA
         $old.Minute_10_MA = $old.Hour_MA
         $old.Minute_15_MA = $old.Hour_MA
         $old.Minute_30_MA = $old.Hour_MA
         $old.Pulls = 12
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
         $old.Pulls = 3
      }
      return $old
   }
   
   ## Simply Moving Average
   hidden static [void]MA($item, $stat, $old_value, $incoming) {
      $item.$stat = [Convert]::ToDecimal([Math]::Round( ( ($item.$stat * $item.Pulls) + $incoming ) / ($item.Pulls + 1), 0 ))
   }
   
   ## Weighted Moving Average
   hidden static [void]EMA([Object]$old_stat, [Object]$New_stat, [hashtable]$Calcs) {
      $Calcs.keys | ForEach-Object {
         ## Price
         $Price = $old_stat.Live_Values | Select-Object -Last 1
         ## Select-Object Only Values For Moving Period
         $theta = [Pool_Stat]::Theta($Calcs.$_, $old_stat.Live_Values)
         ## Smoothing For Period
         $alpha = [Double][Pool_Stat]::Alpha($theta.Count)
         ## Simple Moving Average For The Select-Object Periods
         $zeta = [Convert]::ToDecimal($Theta.Sum / $Theta.Count)
         ## Add MA
         $New_Stat."$($_)_MA" = $zeta
         ## Create new EMA
         $New_stat."$($_)_EMA" = [convert]::ToDecimal($Price * $alpha + $zeta * (1 - $alpha))
      }
   }
   
   ## Calculate Historical Earnings.
   hidden static [void]Bias($item) {
      ## Some pools have no actual 24_hour values
      ## We have four scenarios:
      ## 1.) actual / day_ma - 1 = % bias (positive means it did better predicted, done if no daily values)
      ## 2.) daily_actual_avg / daily_ma_average - 1 = % bias (positive means it did better than predicted)
      ## 3.) live / daily_ma - 1 = % bias (positive means it has generally been higher, done if no daily values)
      ## 4.) daily / daily_ma - 1 = % bias (positive means it has generally been higher)
   
      $HasDailyValues = $item.Daily_Values.Count -gt 0;
      $NoActual = $item.Actual -eq -1;
      $item.Historical_Bias = -1;

      if ($NoActual) {
         ## Scenario 3
         $x = $item.Live;
         $y = $item.Day_MA;
         ## Check for Scenario 4
         if ($HasDailyValues) {
            $x = $item.Day_MA;
            $theta = [Pool_Stat]::Theta(7, $item.Daily_Values)
            $y = $theta.sum / $theta.count
         }
      }
      else {
         ## Scenario 1
         $x = $item.Actual;
         $y = $item.Day_MA;
         ## Scenario 2
         if ($HasDailyValues) {
            $theta = [Pool_Stat]::Theta(7, $item.Daily_Actual_Values)
            $x = $theta.sum / $theta.count
            $theta = [Pool_Stat]::Theta(7, $item.Daily_Values)
            $y = $theta.sum / $theta.count
         }
      }
      if ($y -ne 0) {
         $item.Historical_Bias = [math]::Round($x / $y - 1, 4)
      }
   }   
   
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
      $old = [Pool_Stat]::Get($name)
      if (-not $old.locked) {
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
            $old = [Pool_Stat]::Update_Time($old, $Value)

            ## Keep only 24hrs worth of values.
            if ($old.Live_Values.Count -gt 288) {
               $old.Live_Values = $old.Live_Values | Select-Object -Last 288
            }

            ## Add live values and make EMA
            $old.Live = $value
            [Pool_Stat]::EMA($old, $this, $Calcs)

            ## Do MA for stats that need it
            [Pool_Stat]::MA($this, "Avg_Hashrate", $old.Avg_Hashrate, $Hashrate)
            if ($old.Pulls -lt 288) { $old.Pulls++ }
            $this.Pulls = $old.Pulls

            ## Calculate Bias
            [Pool_Stat]::Bias($old)

            ## If it is a new day - Add to weekly stat values.
            [Pool_Stat]::Check_Weekly($old, $this, $Actual)


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
            [Pool_Stat]::Bias($this)
            [Pool_Stat]::Bias($this)
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

         [Pool_Stat]::Set($name, $stat)
      }
   }
}

class Miner_Stat : Stat {
   [Decimal]$Rejections
}

class Watt_Stat : Stat {

}