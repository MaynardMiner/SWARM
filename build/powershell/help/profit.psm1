function Global:Get-Admin_Fee {
    Write-Host "Doing Admin_Fee"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}

        $ans = Read-Host -Prompt "-Admin_Fee    [0-50]                
        
        
Expressed as Percentage. 
        Admin_Fee allows users to set a seperate wallet, and specify
        a certain percentage of time mined on that wallet a day. Admin
        Mode is done first, and then normal mode begins. Every 24 hours-
        Admin_Mode starts again, mining % of day specified by this parameter.
        If SWARM enters donation mode, time is either added to Admin_Fee, or
        removed, to encompass an even distribution between admin mode and user mode.
        Simple timestamp of when last Admin ran occurred will be
        placed in `".\admin`" folder for reference. They will be transferred on update.
        -Admin must be specified if using -Admin_Fee.


Please enter the percent you wish to mine for yourself

Answer"
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered a % figure of $ans
    
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
        if ($Confirm -ne "1") {
            Write-Host "Okay, lets try again"
            Start-Sleep -S 3
        }
    }while ($Confirm -ne "1")
    if ( $(vars).config.Containskey("Admin_Fee") ) { $(vars).config.Admin_Fee = $ans }else { $(vars).config.Add("Admin_Fee", $ans) }
}


function Global:Get-Admin {
    Write-Host "Doing Admin"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}

        $ans = Read-Host -Prompt "-Admin        
        
[address]             

Admin Wallet for -Admin_Fee Parameter. Only needed if you are using
Admin. It is also advised to set -Admin_Pass


Please enter your wallet address:

Answer"
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered a wallet address of $ans
    
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
        if ($Confirm -ne "1") {
            Write-Host "Okay, lets try again"
            Start-Sleep -S 3
        }
    }while ($Confirm -ne "1")
    if ( $(vars).config.Containskey("Admin") ) { $(vars).config.Admin = $ans }else { $(vars).config.Add("Admin", $ans) }
}

function Global:Get-Admin_Pass {
    Write-Host "Doing Admin_Pass"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}

        $ans = Read-Host -Prompt "-Admin_Pass        
        
[address]             

Admin Password for -Admin_Fee Parameter. Only needed if you are using
Admin. It is also advised to set -Admin_Wallet


Please enter Coin symbol of your wallet address:

Answer"
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered the symbol of $ans
    
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
        if ($Confirm -ne "1") {
            Write-Host "Okay, lets try again"
            Start-Sleep -S 3
        }
    }while ($Confirm -ne "1")
    if ( $(vars).config.Containskey("Admin_Pass") ) { $(vars).config.Admin_Pass = $ans }else { $(vars).config.Add("Admin_Pass", $ans) }
}

function Global:Get-Profit { 
    switch ($(vars).input) {
        "19" { Global:Get-Admin_Fee }
        "20" { Global:Get-Admin }
        "20" { Global:Get-Admin_Pass }
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