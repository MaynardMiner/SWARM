function Global:Get-Stat_Algo {
    Write-Host "Doing Stat_Algo"
    Start-Sleep -S 3
    $Table = [ordered]@{}
    $Table.Add("1","Live")
    $Table.Add("2","Minute_5")
    $Table.Add("3","Minute_15")
    $Table.Add("4","Hour")
    $Table.Add("5","Hour_4")
    $Table.Add("6","Custom")
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Stat_Algo         
        
[Live,		 
 Minute_5,		
 Minute_15,
 Hour
 Hour_4,
 Day,
 Custom]

This will allow you to factor period average smoothing.
By default everything is day pricing. This will allow you to
smooth out stat fluctuations if you so desired into the period
specified. Essentially it will allow you choose whether or not
you want to base switching on price averages, or live...And if
you choose price averages, what average to base it on. Default
is day. If using -Custom_Periods, this must be set to Custom.

Please select the time period wou with to use

1 Live
2 5 Minute Moving Average
3 15 Minute Moving Average
4 1 Hour Moving Average
5 4 Hour Moving Average
6 Daily Moving Average
7 Custom Moving Average (must set Custom_Periods)

Time Period"
    do{
       $ans = $Table.$ans
       if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
       $Confirm = Read-Host -Prompt "You have selected $ans.
       
Is this correct?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $Confirm @("1","2")
    }while($Check -eq 1)
    if($Confirm -ne "1") {
        Write-Host "Okay, lets try again"
        Start-Sleep -S 3
    }
    }while($Confirm -ne "1")
    if ( $(vars).config.Containskey("Stat_Algo") ) { $(vars).config.Stat_Algo = $ans }else { $(vars).config.Add("Stat_Algo", $ans) }
}

function Global:Get-Stat_Coin {
    Write-Host "Doing Stat_Coin"
    Start-Sleep -S 3
    $Table = [ordered]@{}
    $Table.Add("1","Live")
    $Table.Add("2","Minute_5")
    $Table.Add("3","Minute_15")
    $Table.Add("4","Hour")
    $Table.Add("5","Hour_4")
    $Table.Add("6","Custom")
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Stat_Coin       
        
[Live,		 
 Minute_5,		
 Minute_15,
 Hour
 Hour_4,
 Day,
 Custom]

This will allow you to factor period average smoothing.
By default everything is day pricing. This will allow you to
smooth out stat fluctuations if you so desired into the period
specified. Essentially it will allow you choose whether or not
you want to base switching on price averages, or live...And if
you choose price averages, what average to base it on. Default
is day. If using -Custom_Periods, this must be set to Custom.

Please select the time period wou with to use

1 Live
2 5 Minute Moving Average
3 15 Minute Moving Average
4 1 Hour Moving Average
5 4 Hour Moving Average
6 Daily Moving Average
7 Custom Moving Average (must set Custom_Periods)

Time Period"
    do{
        $ans = $Table.$ans
       if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
       $Confirm = Read-Host -Prompt "You have selected $ans.
       
Is this correct?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $Confirm @("1","2")
    }while($Check -eq 1)
    if($Confirm -ne "1") {
        Write-Host "Okay, lets try again"
        Start-Sleep -S 3
    }
    }while($Confirm -ne "1")
    if ( $(vars).config.Containskey("Stat_Coin") ) { $(vars).config.Stat_Coin = $ans }else { $(vars).config.Add("Stat_Coin", $ans) }
}

function Global:Get-Volume {
    Write-Host "Doing Volume"
    Start-Sleep -S 3
    do{
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Volume         
        
[Yes,No]            

Default is No. Volume calculates pool hashrate % in comparision
to other pools, and will penalize pools based on percent difference
from pool with highest hashrate. This means SWARM favors pools with
the highest hashrates for each algorithm. The % values are displayed
on get stats screen, under Vol.

Would you like to active the Volume modifier?

1 Yes
2 No

Answer"
     $Check = Global:Confirm-Answer $ans @("1","2")
    }while($Check -eq 1)
    switch($ans) {
        "1"{$ans = "Yes"}
        "2"{$ans = "No"}
    }
    if ( $(vars).config.Containskey("Volume") ) { $(vars).config.Volume = $ans }else { $(vars).config.Add("Volume", $ans) }
}

function Global:Get-WattOMeter {
    Write-Host "Doing WattOMeter"
    Start-Sleep -S 3
    do{
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "WattOMeter   
        
[Yes or No]           

This turns on the on the self-generated watt settings for SWARM.
This will allow watts recorded for each algorithm
as a stat, and continues to be recorded with every switch.
This may not be stable in larger rigs. Default is Yes.

Would you SWARM to save Watt Values for each GPU?

1 Yes
2 No

Answer"
     $Check = Global:Confirm-Answer $ans @("1","2")
    }while($Check -eq 1)
    switch($ans) {
        "1"{$ans = "Yes"}
        "2"{$ans = "No"}
    }
    if ( $(vars).config.Containskey("WattOMeter") ) { $(vars).config.WattOMeter = $ans }else { $(vars).config.Add("WattOMeter", $ans) }
}

function Global:Get-WattOMeter {
    Write-Host "Doing WattOMeter"
    Start-Sleep -S 3
    do{
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "WattOMeter   
        
[Yes or No]           

This turns on the on the self-generated watt settings for SWARM.
This will allow watts recorded for each algorithm
as a stat, and continues to be recorded with every switch.
This may not be stable in larger rigs. Default is Yes.

Would you SWARM to save Watt Values for each GPU?

1 Yes
2 No

Answer"
     $Check = Global:Confirm-Answer $ans @("1","2")
    }while($Check -eq 1)
    switch($ans) {
        "1"{$ans = "Yes"}
        "2"{$ans = "No"}
    }
    if ( $(vars).config.Containskey("WattOMeter") ) { $(vars).config.WattOMeter = $ans }else { $(vars).config.Add("WattOMeter", $ans) }
}

function Global:Get-KWH {
    Write-Host "Doing KWH"
    Start-Sleep -S 3
    Do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "kwh          
        
[decimal number]      

Default is `"`" (`$null). This is the kw/h pricing of your electricty costs.
-kwh 0.10 would mean your electricty cost it 0.10 kwh. If argument is ommited,
or left as `"`" in config.json- kw/h figures will based on values in power.json.
This parameter overrides kwh values in power.json

Would you like to specify your electricity kilowatt/hour cost for rig?

If so, please enter kw/h here, in decimal, i.e.  0.11

kilowatt/hour"
        do{
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered a kwh of $ans

Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1","2")
        }while($Check -eq 1)
        if($Confirm -ne "1"){
            Write-Host "Okay, let's try again"
            Start-Sleep -S 3
        }
    }While($Confirm -ne "1")
    if ( $(vars).config.Containskey("kwh") ) { $(vars).config.kwh = $ans }else { $(vars).config.Add("kwh", $ans) }
}

Function Global:Get-Max_Periods {
    Write-Host "Doing Max_Periods"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Max_Periods    
        
[integer]        

Default is 288. SWARM calculates profit via a rolling expontenial
moving average, with each new period happening at the end of your
interval. With a default interval of 300 seconds (5 minutes),
and 288 periods: That means you will have factored 86400 seconds
of pricing data, or an entire day of pricing pulls from pools.
It is not advised to set this number higher than 288. This is
only available to help reduce SWARM's memory footprint. If you
are using -Stat_Algo and -Stat_Coin live, there is no reason to
record 288 periods of data, since you are using live pricing.
You can set this number to 1. If you were using Minute_15
with an -interval of 300 (5 minutes), there is no real reason
to store nore than 3 periods of data (15 minutes total).

Please specify the maximum periods you wish SWARM to record.

Maximum Periods"
        do{
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered a maximum period of $ans
            
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1","2")
        }While($Check -eq 1)
        if($Confirm -ne "1"){
            Write-Host "Okay, lets try again"
            Start-Sleep -S 3
        }
    }While($Confirm -ne "1")
    if ( $(vars).config.Containskey("Max_Periods") ) { $(vars).config.Max_Periods = $ans }else { $(vars).config.Add("Max_Periods", $ans) }
}

function  Global:Get-Stat_All {
    Write-Host "Doing Stat_All"
    Start-Sleep -S 3

    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Stat_All        
    
[Yes,No]           

Default is No. When enabled to Yes, it will pull / save ALL coin stats. 
However, this is a huge expenditure of CPU and system resources to do.
Not reccommended to run if Using -Type CPU with all threads used for mining.

Would you like to record all coin stats when -Auto_Coin is on

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1","2")
    }While($Check -eq 1)
    switch($ans) {
        "1"{$ans = "Yes"}
        "2"{$ans = "No"}
    }
    if ( $(vars).config.Containskey("Stat_All") ) { $(vars).config.Stat_All = $ans }else { $(vars).config.Add("Stat_All", $ans) }
}

Function Global:Get-Custom_Periods{
    Write-Host "Doing Custom_Periods"
    Start-Sleep -S 3
     do{
         if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
         $ans = Read-Host "Custom_Periods    
         
[integer]         

Default is 1. This will allow the user to specify the number of periods
that SWARM should gather its data from, with `"periods`" defined as each 
pull from pool. Default is 1 (to reduce use). If used, -Stat_Algo and /or
-Stat_Coin should be set to `"custom`"

Note: -Stat_Algo Custom and -Stat_Coin Custom should be specified.

Please enter a custom moving average value"
        do{
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered custom moving average of $ans periods
            
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1","2")
        }while($Check -eq 1)
        if($Confirm -ne "1"){
            Write-Host "Okay, lets try again"
            Start-Sleep -S 3
        }
     }while($Confirm -ne "1")
     if ( $(vars).config.Containskey("Custom_Periods") ) { $(vars).config.Custom_Periods = $ans }else { $(vars).config.Add("Custom_Periods", $ans) }
}

function Global:Get-Historical_Bias {
    Write-Host "Doing Historical_Bias"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}

        $ans = Read-Host -Prompt "-Historical_Bias [0-100]          
        
Expressed as Percentage. 
Will only affect Auto_Algo.
Will not affect niechash.
Historical_Bias bias does two things:
 -Reduces algorithms that have no 24h returns to 100%
 -Compares the deviation between 24hr estimates and 24hr
  returns into a %, which then creates a EMA with each
  value. (for smoothing). SWARM then applies a bonus/penality
  to the algorithm based on how well it has performed
  over time historically. SWARM will only apply a % penality
  or bonus of x%, where x is -Historical_Bias figure.
  Deviations will be listed in stat files.
  If you use, reccommended starting values are somewhere
  around 25-35% historical bias.

Please enter a number 0-100 on the maximum % bias penalty you wish to
place on algorithms that do not return well over 24 hours.

Answer"
do{
    if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
    $Confirm = Read-Host -Prompt "You have entered a % bias of $ans
    
Is this correct?

1 Yes
2 No

Answer"
    $Check = Global:Confirm-Answer $Confirm @("1","2")
}while($Check -eq 1)
if($Confirm -ne "1"){
    Write-Host "Okay, lets try again"
    Start-Sleep -S 3
}
}while($Confirm -ne "1")
if ( $(vars).config.Containskey("Historical_Bias") ) { $(vars).config.Historical_Bias = $ans }else { $(vars).config.Add("Historical_Bias", $ans) }
}

function Global:Get-Statistics { 
    switch ($(vars).input) {
        "13" { Global:Get-Stat_Algo }
        "14" { Global:Get-Stat_Coin }
        "15" { Global:Get-Volume }
        "16" { Global:Get-WattOMeter }
        "17" { Global:Get-KWH }
        "18" { Global:Get-Max_Periods }
        "19" { Global:Get-Stat_All }
        "20" { Global:Get-Custom_Periods }
        "20" { Global:Get-Historical_Bias }
    }

    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $Confirm = Read-Host -Prompt "Do You Wish To Continue?
    
1 Yes
2 No

Answer"
        $check = Global:Confirm-Answer $Confirm @("1", "2")
        Switch($Confirm){
            "1" {$(vars).continue = $true}
            "2" {$(vars).continue = $false}
        }
    }while ($check -eq 1)
}