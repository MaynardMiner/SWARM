function Global:Get-Auto_Coin {
    Write-Host "Doing Auto_Coin"
    Start-Sleep -S 3

    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Auto_Coin      

[Yes,No]            

Turns on Auto_Coin switching for pools that are capable of it.
Default is `"No`". Auto_Coin will price out individual coins,
and will select the most profitable coin, rather than relying on
the auto-switching ports

Do you wish to enable Auto_Coin?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1", "2")
    }While ($Check -eq 1)
     switch($ans) {
         "1"{$ans = "Yes"}
         "2"{$ans = "No"}
     }
    if ( $(vars).config.Containskey("Auto_Coin") ) { $(vars).config.Auto_Coin = $ans }else { $(vars).config.Add("Auto_Coin", $ans) }
}

function Global:Get-Auto_Algo {
    Write-Host "Doing Auto_Algo"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "-Auto_Algo     
       
[Yes,No]		    

Default is `"Yes`". Should always be set to `"Yes`", except when using the -Coin
Parameter with multiple coins. See -Coin for more information.

Do you wish to enable Auto_Algo?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1", "2")
    }While ($Check -eq 1)
    switch($ans) {
        "1"{$ans = "Yes"}
        "2"{$ans = "No"}
    }
   if ( $(vars).config.Containskey("Auto_Algo") ) { $(vars).config.Auto_Algo = $ans }else { $(vars).config.Add("Auto_Algo", $ans) }
}

Function Global:Get-Interval {
    Write-Host "Doing Interval"
    Start-Sleep -S 3
    Do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Interval         
        
[1-1000]          

Expression is in seconds. Time before miner begins checking pools for 
pricing. Ideal target goal should be miner windows close/open every 
5 minutes. Slower cpus may need to fine tune due to the length of time
needed to search pools and find most profitable coin/algo. Defaut is 300

Please specify the interval you wish to use

seconds"
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans seconds
         
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
        if ($Confirm -ne "1") {
            Write-Host "Okay, let's try again"
            Start-Sleep -S 3
        }
    }While ($Confirm -ne "1")
    if ( $(vars).config.Containskey("Interval") ) { $(vars).config.Interval = $ans }else { $(vars).config.Add("Interval", $ans) }
}

function  Global:Get-SWARM_MODE {
    Write-Host "Doing SWARM_MODE"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host "SWARM_Mode      
    
[Yes or No]          

SWARM_Mode Allows sycronization of all SWARM Users. SWARM will
collectively pull database at the same time for all users with
SWARM_Mode set to `"Yes`". Intervals are based on 5 minute periods.
This disables -Interval argument. Default is No. Your rig will
still mine what is best for your cards. This simply syncronizes
your rig to pull pricing data at the same time as other using
this argument, increasing the chance you will mine the same thing.
This is useful to sycronize all your rigs to switch together.

Do you wish to enable SWARM_Mode

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1", "2")
    }while ($Check -eq 1)
    switch($ans) {
        "1"{$ans = "Yes"}
        "2"{$ans = "No"}
    }
    if ( $(vars).config.Containskey("SWARM_MODE") ) { $(vars).config.SWARM_MODE = $ans }else { $(vars).config.Add("SWARM_MODE", $ans) }
}

function Global:Get-StatsInterval {
    Write-Host "Doing StatsInterval"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "StatsInterval   
        
[1-10000]            

Expression is in seconds. This is time required for miner apps to run
before miner write/re-writes benchmarking. This is not be confused 
with -Interval argument, which is used for when miner begins swithing 
process. leave 1 if you want dynamic benchmarking, and for initial 
benchmarking. 1000 for more smoother benchmarking. 10000 to disable 
benchmarking altogether.

Please enter the StatInterval you wish to use.

Seconds"
        Do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans seconds.
            
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)
        if ($Confirm -ne "1") {
            Write-Host "Okay let's try again"
            Start-Sleep -S 3
        }
    }While ($Confirm -ne "1")
    if ( $(vars).config.Containskey("StatsInterval") ) { $(vars).config.StatsInterval = $ans }else { $(vars).config.Add("StatsInterval", $ans) }
}

function Global:Get-Switch_Threshold {
    Write-Host "Doing Switch_Threshold"
    Start-Sleep -S 3
    Do{
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Switch_Threshold   
        
[0-1000]          

Expression is in percentage. This will add a percentage based
increase in profit of current miner, in order to decrease
switching unless profit breaks over x%, where x is the number
specified. Default is 1%.

Please enter a new switch_threshold

Percent"

      do{
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $Confirm = Read-Host -Prompt "You have entered $ans percent.

Is this correct?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $Confirm @("1","2")
      }While($Check -eq 1)
      if($Confirm -ne "1"){
          Write-Host "Okay, let's try again."
          Start-Sleep -S 3
      }
    }While($Confirm -ne "1")
    if ( $(vars).config.Containskey("switch_threshold") ) { $(vars).config.switch_threshold = $ans }else { $(vars).config.Add("switch_threshold", $ans) }
}

function Global:Get-Switching { 
    switch ($(vars).input) {
        "7" { Global:Get-Auto_Coin }
        "8" { Global:Get-Auto_Algo }
        "9" { Global:Get-Interval }
        "10" { Global:Get-SWARM_MODE }
        "11" { Global:Get-StatsInterval }
        "12" { Global:Get-Switch_Threshold }
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
