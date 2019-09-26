function Global:Get-Track_Shares {
    Write-Host "Doing Track_Shares"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "NOTE: Interface is limited to the amount of information it can track.
    
Track_Shares   

[Yes,No]            

Default is Yes. SWARM will gather your current share percentage
from pools, if it is possible to do so. Zergpool will only gather
shares if -Auto_Coin Yes is on. Some pools share gathering is
possible yet.

Woule to you like SWARM to track shares?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1", "2")
    }While ($Check -eq 1)
    Switch ($ans) {
        "1" { $ans = "Yes" }
        "2" { $ans = "No" }
    }
    if ($(vars).config.ContainsKey("Track_Shares")) { $(vars).config.Track_Shares = $ans } else { $(vars).config.Add("Track_Shares", $ans) }
}

function Global:Get-CoinExchange {
    Write-Host "Doing CoinExchange"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "NOTE: Interface is limited to the amount of information it can track.
       
CoinExchange      
       
[Any]            

Coin Symbol Of An Optional AltWallet (Will only work for coins on 
cryptocompare). This will calculate the coin of your choice profit/day
and display on stats screens. Good if you are exchanging into a coin 
other than BTC. This figure does not include modifiers.

Please enter an additional coin you wish to track"
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans
            
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("CoinExchange")) { $(vars).config.CoinExchange = $ans } else { $(vars).config.Add("CoinExchange", $ans) }
}

function Global:Get-Currency {
    Write-Host "Doing Currency"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}    
        $ans = Read-Host -Prompt "Currency          
    
[Any]            

Fiat Currency Of Your Choice. This is used to calculated your 
profit/day. Only currencies on cryptocompare will work. Default
is USD

Please Enter Symbol of Currency You wish SWARM to track"
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have enetered $ans
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("Currency")) { $(vars).config.Currency = $ans } else { $(vars).config.Add("Currency", $ans) }
}

function Global:Get-Hive_Hash {
    Write-Host "Doing Hive_Hash"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Hive_Hash     
        
[address]            

This is required for Windows. Specify Hive_Hash in order to use HiveOS
website. Farm Hash is attained by making a user account in HiveOS.

Steps to attaining a HiveOS farm hash
1.) Go to HiveOS website.
2.) Make an account.
3.) Start a new farm.
4.) Go to farm - settings.
5.) Farm_Hash will be there.

Note: You must make a Custom miner flight sheet with SWARM afterwards.

Please enter your farm_hash"

        Do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans.
            
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
    }while ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("Hive_Hash")) { $(vars).config.Hive_Hash = $ans } else { $(vars).config.Add("Hive_Hash", $ans) }
}

function Global:Get-CPUOnly {
    Write-Host "Doing CPUOnly"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "CPUOnly	   
        
[Yes or No]		

For CPU only miners- This lets HiveOS know whether or not to
stat CPU. Note: Some CPU miners will only send stats on
accepted shares, so this means that it can take a while for
HiveOS to recieve hashrate. SWARM internally pulls hashrates
from logs to benchmark fast.

Do you wish to activate CpuOnly?

1 Yes
2 No

Answer"

        $Check = Global:Confirm-Answer $ans @("1","2")
    }while($Check -eq 1)
    Switch ($ans) {
        "1" { $ans = "Yes" }
        "2" { $ans = "No" }
    }
    if ($(vars).config.ContainsKey("CPUOnly")) { $(vars).config.CPUOnly = $ans } else { $(vars).config.Add("CPUOnly", $ans) }
}
    function Global:Get-Interface { 
        switch ($(vars).input) {
            "29" { Global:Get-Track_Shares }
            "30" { Global:Get-CoinExchange }
            "31" { Global:Get-Currency }
            "32" { Global:Get-Hive_Hash }
            "33" { Global:Get-CPUOnly }
        }

        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "Do You Wish To Continue?
    
1 Yes
2 No

Answer"
            $check = Global:Confirm-Answer $Confirm @("1", "2")
            Switch ($Confirm) {
                "1" { $(vars).continue = $true }
                "2" { $(vars).continue = $false }
            }
        }while ($check -eq 1)
    }