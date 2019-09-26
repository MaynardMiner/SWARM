function Global:Get-PasswordCurrency {
    Write-Host "Doing Password Currency"
    Start-Sleep -S 3
    $(vars).config.Type | % {
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            Write-Host "PasswordCurrency:
    
                Symbol of your wallet address, specifically for Wallet1. Most pools
                only accept BTC for auto-exchange. See pools for options."                
            switch ($_) {
                "AMD1" { $Password = "PasswordCurrency1" }
                "NVIDIA1" { $Password = "PasswordCurrency1" }
                "CPU" { $Password = $null }
                "ASIC" { if ($Type -notlike "*AMD*" -or $Type -notlike "*NVIDIA*") { $Password = "PasswordCurrency1" }else { $Password = $Null } }
                "NVIDIA2" { $Password = "PasswordCurrency2" }
                "NVIDIA3" { $Password = "PasswordCurrency3" }
            }

            if ($Password) {
                $ans = Read-Host -Prompt "
Please enter new symbol for $Password"
                do {
                    if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
                    $Confirm = Read-Host -Prompt "You have entered $ans
Is this correct?

1 Yes
2 No

Answer"
                    $Check = Global:Confirm-Answer $Confirm @("1", "2")
                }while ($Check -eq 1)
                if ($Confirm -ne "1") { Write-Host "Okay, let's try again" }
            }
        }while ($Confirm -ne "1")

        if ($(vars).config.ContainsKey($Password)) { $(vars).config.$Password = $ans }else { $(vars).config.Add($Password, $ans) }
    }
}

function Global:Get-AltWallets {
    Write-Host "Doing AltWallets"
    Start-Sleep -S 3
    $(vars).config.Type | % {
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            Write-Host "AltWallet       
            
[Wallet Address]    

Altcoin wallet adddress. Is used in combinatation of -Wallet1
argument. This will tell SWARM if it switches
to auto-exchange into specified coin.
Used when -Type NVIDIA1/AMD1/CPU/ASIC is specified."

            WRite-Host "AltPassword	 

[Symbol]               

Wallet address symbol of corresponding wallet. Is used
in combination of -PasswordCurrency1 argument. This will tell
SWARM if it switches to pool to use this coin symbol
in password arguments. Used when -Type NVIDIA1/AMD1/CPU/ASIC
is specified."


            switch ($_) {
                "AMD1" { $Password = "AltPassword1"; $Wallet = "AltWallet1" }
                "NVIDIA1" { $Password = "AltPassword1"; $Wallet = "AltWallet1" }
                "CPU" { $Password = $null }
                "ASIC" { if ($Type -notlike "*AMD*" -or $Type -notlike "*NVIDIA*") { $Password = "AltPassword1"; $Wallet = "AltWallet1" }else { $Password = $Null } }
                "NVIDIA2" { $Password = "AltPassword2"; $Wallet = "AltWallet2" }
                "NVIDIA3" { $Password = "AltPassword2"; ; $Wallet = "AltWallet2" }
            }

            if ($Password) {
                $ans1 = Read-Host -Prompt "
Please enter new symbol for $Password"
                $ans2 = Read-Host "
Please enter address for $Wallet"
                do {
                    if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
                    $Confirm = Read-Host -Prompt "You have entered 

$Password`: $ans1
$Wallet`: $ans2

Is this correct?

1 Yes
2 No

Answer"
                    $Check = Global:Confirm-Answer $Confirm @("1", "2")
                }while ($Check -eq 1)
                if ($Confirm -ne "1") { Write-Host "Okay, let's try again" }
            }
        }while ($Confirm -ne "1")

        if($_ -ne "CPU"){
        if ( $(vars).config.Containskey($Password) ) { $(vars).config.$Password = $ans1 }else { $(vars).config.Add($Password, $ans1) }
        if ( $(vars).config.Containskey($Wallet) ) { $(vars).config.$Wallet = $ans2 }else { $(vars).config.Add($Wallet, $ans2) }
        }
    }
}

function Global:Get-Benchmark {
    Write-Host "Doing Benchmark"
    Start-Sleep -S 3
    
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        Write-Host "Benchmark

        [0-100000]           
        
        Expressed in seconds. Default 180. Sets specific interval time for when coin 
        is in benchmark mode. Can be used for faster benchmarking. When coin has
        a set hashrate- Miner will defer to time expressed in -Interval parameter."        
        $ans = Read-Host -Prompt "

Please enter the number of seconds
you wish to set benchmark parameter.

seconds"

        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans seconds
        
Is this correct?

1 Yes
2 No

Answer"
            $check = Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ( $(vars).config.Containskey("benchmark") ) { $(vars).config.benchmark = $ans }else { $(vars).config.Add("benchmark", $ans1) }
}

function Global:Get-Conserve {
    Write-Host "Doing Conserve"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        Write-Host "Conserve        
[Yes or No]        

Default is `"No`". This option will determine if SWARM should continue
mining even though all estimates are negative figures."

        $ans = Read-Host -Prompt "Would you like conseve turned on?

1 Yes
2 No

Answer"
        $check = Confirm-Answer $Confirm @("1", "2")
    }while ($Check -eq 1)

    switch ($ans) {
        "1" { $A = "Yes" }
        "2" { $A = "No" }
    }
    if ( $(vars).config.Containskey("conserve") ) { $(vars).config.conserve = $A }else { $(vars).config.Add("conserve", $A) }
}

function Global:Get-Algorithm {
    Write-Host "Doing Algorithm"
    Start-Sleep -S 3

    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        Write-Host "Algorithm   
    
[algorithm,algorithm,etc.] 

When this is specified, SWARM will not use
Algorithms from pool-algos.json, and defer
to these algorithms instead. Can be used
to select only 1 or 2 algorithms for testing."

        $List = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json

        $Num = 1
        $Algos = [ordered]@{ }
        $List.PSObject.Properties.Name | % { $Algos.Add($Num, $_); $Num++ }
        $Table = @()
        $Algos.keys | % { $Table += "$($_) $($Algos.$_)" }

        $ans = Read-Host -Prompt "What algorithms would you like to use?

Please comma separate your choices, i.e. 1,2,3

$($Table -join "`n")

Algorithms"

        try {
        $get = $ans -split ","
        $Table = @()
        $get | % { $Table += $Algos.[int]$_ }
        }catch {Write-Host "failed to parse your answer"; Start-Sleep -S 3; continue}

        do {
            $Confirm = Read-Host -Prompt "You have selected the following:
       
$($Table -join "`n")

Is This Correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
        if ($Confirm -ne "1") {
            Write-Host "Okay, let's try again."
        }
    }WHile ($Confirm -ne "1")
    if ( $(vars).config.Containskey("Algorithm") ) { $(vars).config.Algorithm = $Table }else { $(vars).config.Add("Algorithm", $Table) }
}

function Global:Get-Coin {
    Write-Host "Doing Coin"
    Start-Sleep -S 3

    Do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        Write-Host "Coin        

[Pool Symbol Of Coin]      

When this is specified, SWARM will convert
c= in pool string to this symbol, allowing
you to mine a single coin. Must be used in
conjuction with Algorithm parameter, only
one coin can be selected. 

EXPIREMENTAL:
Multiple coins can be used, comma seperating items.
-Auto_Coin must be `"Yes`".
If -Auto_Algo is `"Yes`"
will add algorithm switching port on yiimp algo pools.
if -Auto_Algo is `"No`", should mine only coins.
Only Coin pools can be used."

 $ans = Read-Host -Prompt "Please enter the symbols of the coins you wish to mine
 
These must be comma separated
example: RVN,XZC,ZER

Coins"

 $get = $ans -split ","

    do{
        $Confirm = Read-Host -Prompt "You have entered the follwoing coins:
        
$($get -join "`n")

Is this correct?

1 Yes
2 No

Answer"
    $Check = Confirm-Answer $Confirm @("1","2")
    }while($Check -eq 1)

    }while($Confirm -ne "1")
    if ( $(vars).config.Containskey("coin") ) { $(vars).config.coin = $get }else { $(vars).config.Add("coin", $get) }
}

function Global:Get-Strategy { 
    switch ($(vars).input) {
        "1" { Global:Get-PasswordCurrency }
        "2" { Global:Get-AltWallets }
        "3" { Global:Get-Benchmark }
        "4" { Global:Get-Conserve }
        "5" { Global:Get-Algorithm }
        "6" { Global:Get-Coin }
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
