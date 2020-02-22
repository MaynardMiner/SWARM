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

class Stat {
   [Decimal]$Live
   [Decimal]$Minute_5
   [Decimal]$Minute_15
   [Decimal]$Minute_30
   [Decimal]$Hour
   [Decimal[]]$Live_Values  
   [bool]$Locked ## Lock the stat
   [string]$Updated

   ## Get Old Stat File
   [PSCustomObject]Get([string]$name) {
      [PSCustomObject]$Get = $null
      if ([IO.File]::Exists(".\stats\$name.json")) {
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

   # Sets Old Stat File
   [void]Set([string]$name,[object]$stat) {
      try {
         $stat | ConvertTo-Json -ErrorAction Stop | Set-Content ".\stats\$name.json"
      }
      catch {
         Write-Host "Warning: Write Error with .\stats\$name.json" -Foreground Red
      }
   }

   # Calculate Alpha Value in EMA
   [Decimal]Alpha([Decimal]$X) {
      return (2 / ($X + 1) )
   }

   # Calulate Thete Value in EMA
   [Microsoft.PowerShell.Commands.GenericMeasureInfo]Theta([Int]$Period, [Decimal[]]$Values) {
      return $Values | Select-Object -Last $Period | Measure-Object -Sum 
   }

   ## Update Values Over Time
   [PSCustomObject]Update_Time([PSCustomObject]$old, [decimal]$Value) {
      ## Determine last time stat was pulled
      $Last_Pull = [math]::Round(([Datetime]::Now.ToUniversalTime() - [DateTime]$Old.Updated).TotalSeconds)
      <# Now we need to see how much of the stats is still valid.
         If user shut off SWARM for 10 minutes for example, then
         technically, the minute_15 stat is still viable. So 
         we remove all values and make the minute_15 the first value
         in value dataset.

         The same if it has been 3 hours, the 4 hour would be
         a viable stat. All values are removed, and 4 hour is used
         as the last stat

         If its greater than 4 hours, we use the day stat to continue.

         If longer than a day- Then we reset entirely
      #>
      if ($Last_Pull -gt 86400) {
         $old.Live_Values = $old.Live_Values | Select-Object -Last 1
         $old.Minute_5 = $value
         $old.Minute_15 = $value
         $old.Minute_30 = $value
         $old.Hour = $value
         $old.Hour_4 = $value
         $old.Day = $value
      }
      elseif ($Last_Pull -gt 14440) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Day)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_5 = $old.Day
         $old.Minute_15 = $old.Day
         $old.Minute_30 = $old.Day
         $old.Hour = $old.Day
         $old.Hour_4 = $old.Day
      }
      elseif ($last_Pull -gt 3600) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Hour_4)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_5 = $old.Hour_4
         $old.Minute_15 = $old.Hour_4
         $old.Minute_30 = $old.Hour_4
         $old.Hour = $old.Hour_4
      }
      elseif ($last_Pull -gt 1800) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Hour)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_5 = $old.Hour
         $old.Minute_15 = $old.Hour
         $old.Minute_30 = $old.Hour
      }
      elseif ($last_Pull -gt 900) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Minute_30)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_5 = $old.Minute_30
         $old.Minute_15 = $old.Minute_30
      }
      elseif ($last_Pull -gt 600) {
         $old.Live_Values = @(([Convert]::ToDecimal($old.Minute_15)), ($old.Live_Values | Select-Object -Last 1))
         $old.Minute_5 = $old.Minute_15
      }
      return $old
   }

   ## Generate EMA for each Time Value
   [void]EMA([Object]$stat, [hashtable]$Calcs) {
      $SmallestValue = 1E-20
      $Calcs.keys | ForEach-Object {
         $theta = $this.Theta($Calcs.$_, $stat.Live_Values)
         $alpha = [Double]$this.Alpha($theta.Count)
         $zeta = [Double]$Theta.Sum / $Theta.Count
         $this.$_ = [convert]::ToDecimal([Math]::Round([Math]::Max( ( $zeta * $alpha + $($stat.$_) * (1 - $alpha) ) , $SmallestValue ), 15))
      }
   }
}

class Pool_Stat : Stat {
   [Decimal]$Hour_4
   [Decimal]$Day
   [Decimal]$Week
   [Decimal]$Avg_Hashrate
   [Int]$Hashrate_Periods ## Total Periods For rolling moving average, max is 288
   [Decimal]$Historical_Bias ## Total bias % based on daily estimates vs actual
   [Decimal[]]$Daily_Values
   [Decimal]$Actual_24h
   [bool]$Pre_Stat  ## Denotes whether or not this is an initial downloaded stat.
   [DateTime]$Start_Of_Day

   Pool_Stat([string]$name, [string]$Estimate, [string]$Hashrate, [string]$Actual, [bool]$Coin) {
      $name = $name -replace "`/", "`-"
      $name = "Pool_$($name)_pricing"
      $old = $this.Get($name)
      ## Minimum decimal value
      ## Convert Value to Decimal
      $Value = $this.Live = [Convert]::ToDecimal($Estimate)         
      ## Calc periods for MA
      [hashtable]$Calcs = @{
         Minute_5  = 2;
         Minute_15 = 3;
         Minute_30 = 6;
         Hour      = 12;
         Hour_4    = 48;
         Day       = 288;
      }
      if ($old) {
         ## Add incoming Value.
         $old.Live_Values += $Value
         ## Find Gaps
         $old = $this.Update_Time($old, $Value)
         ## Keep only 24hrs worth of values.
         if ($old.Live_Values.Count -gt 288) {
            $old.Live_Values = $old.Live_Values | Select-Object -Last 288
         }
         $old.Live = $value
         $this.EMA($old,$Calcs)
         $this.Live_Values = $old.Live_Values
         $this.Avg_Hashrate = $old.Avg_Hashrate
         $this.Hashrate_Periods = $old.Hashrate_Periods
         $this.Historical_Bias = $old.Historical_Bias
         $this.Locked = $old.Locked
         $this.Start_Of_Day = $old.Start_Of_Day
      }
      else {
         $this.Live_Values += $Value
         $this.Live = $value
         $this.Minute_5 = $value
         $this.Minute_15 = $value
         $this.Minute_30 = $value
         $this.Hour = $value
         $this.Hour_4 = $value
         $this.Day = $value
         $this.EMA($this,$Calcs)
         $this.Start_Of_Day = [datetime]::Now.ToUniversalTime().ToString("o")
      }
      [string]$this.Updated = [datetime]::Now.ToUniversalTime().ToString("o")

      $stat = [ordered]@{
         Live = $this.Live
         Minute_5 = $this.Minute_5
         Minute_15 = $this.Minute_15
         Minute_30 = $This.Minute_30
         Hour = $this.Hour
         Hour_4 = $this.Hour_4
         Day = $this.Day
         Week = $this.Week
         Avg_Hashrate = $this.Avg_Hashrate
         Hashrate_Periods = $this.Hashrate_Periods
         Historical_Bias = $this.Historical_Bias
         Actual_24h = $this.Actual_24h
         Pre_stat = $this.Pre_Stat
         Start_Of_Day = $this.Start_Of_Day
         Locked = $this.Locked
         Updated = $this.Updated
         Daily_values = $this.Daily_Values
         Live_Values = $this.Live_Values
      }

      $this.Set($name,$stat)
   }
}

class Miner_Stat : Stat {
   [Decimal]$Rejections
   [Decimal]$Rej_Periods ## Total Periods for rejection average, max is 288
}

class Watt_Stat : Stat {

}

$A = [Pool_Stat]::New("test_x16r","0.00352","121234343","0.000312425",$false)