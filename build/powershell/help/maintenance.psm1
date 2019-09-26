function Global:Get-Platform {
    Write-Host "Doing Platform"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        do{
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Platform      
        
[linux,windows]      

Default is "". This lets SWARM
know to build itself for Windows operation. SWARM will attempt to self-detect.
This parameter is optional, only used to force an OS.

Which OS are you using?

1 Windows
2 Linux

Answer"
            $Check = Global:Confirm-Answer $ans @("1","2")
        }While($Check -eq 1)
        do{
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            Switch($ans) {
                "1" {$ans = "windows"}
                "2" {$ans = "linux"}
            }
            $Confirm = Read-Host -Prompt "You have entered $ans
            
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1","2")
        }while($Check -eq 1)
    }while($Confirm -ne "1")
    if ($(vars).config.ContainsKey("Platform")) { $(vars).config.Platform = $ans } else { $(vars).config.Add("Platform", $ans) }
}

function Global:Get-Startup {
    Write-Host "Doing Startup"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Would you like SWARM to start up on Windows?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1","2")
    }While($Check -eq 1)
    Switch($ans){
        "1" {$ans = "Yes"}
        "2" {$ans = "No"}
    }
    if ($(vars).config.ContainsKey("Startup")) { $(vars).config.Startup = $ans } else { $(vars).config.Add("Startup", $ans) }
}

function Global:Get-CLPlatform{
    Write-Host "Doing CLPlatform"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "CLPlatform

[number]             

This will forcefully set the AMD CLPlatform to use for mining.
Set this if SWARM fails to guess correct platform. However,
SWARM ~should~ auto-detect correct platform.

Please enter you opencl platform for AMD"
        do{
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = "You have entered $ans
        
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1","2")
        }While($Check -eq 1)
    }While($Confirm -ne "1")
    if ($(vars).config.ContainsKey("CLPlatform")) { $(vars).config.CLPlatform = $ans } else { $(vars).config.Add("CLPlatform", $ans) }
}

function Global:Get-Update {
    Write-Host "Doing Update"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Update
        
[Yes or No]

Allows HiveOS remote update, which will transfer Default set to `"No`". Old
miner files/settings from previous version, then remove it for you. Pay
attention to releases and notes- Changes/additions to internal miner files
or settings (and previous version bug fixes) may get transferred in if you
attempt to perform remote update! Default changes based on miner version
updates, and whether or not it is safe to transfer files. This does not
work in Windows- Windows users run get update command.

Would you like to turn on Updates in HiveOS?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1","2")
}While($Check -eq 1)
Switch($ans){
    "1" {$ans = "Yes"}
    "2" {$ans = "No"}
}
if ($(vars).config.ContainsKey("Update")) { $(vars).config.Update = $ans } else { $(vars).config.Add("Update", $ans) }
}

function Global:Get-TypeBanCount {
    Write-Host "Doing TypeBanCount"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "TypeBanCount    
        
[0-10]             

Like PoolBanCount, TypeBanCount will take
action if a device type (AMD1,CPU,NVIDIA1,etc.) has x consecutive banned
miners in a row- Where x is -TypeBanCount. When x has been reached, SWARM
will reset all timeouts, then restart computer.

How many miners must be banned before SWARM restart computer?

Answer"
        do{
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans
            
Is this correct?

1 Yes
2 No"
          $Check = Global:Confirm-Answer $ans @("1","2")
        }While($Check -eq 1)
}While($Confirm -ne "1")

if ($(vars).config.ContainsKey("TypeBanCount")) { $(vars).config.TypeBanCount = $ans } else { $(vars).config.Add("TypeBanCount", $ans) }
}

function Global:Get-Maintenance {
    switch ($(vars).input) {
        "41" { Global:Get-Platform }
        "42" { Global:Get-Startup }
        "43" { Global:Get-CLPlatform }
        "44" { Global:Get-Update }
        "45" { Global:Get-TypeBanCount }
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