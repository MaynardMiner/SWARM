function Global:Start-API {
    Write-Host "Doing API"
    Start-Sleep -S 3
    do {
        Clear-Host
        $ans = Read-Host -Prompt "API
        
[Yes or No]

This Option Enables or Disables SWARM html API. Default is No.

Would you like to enable html API?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1", "2")
    }While ($Check -eq 1)
    Switch ($ans) {
        "1" { $ans = "Yes" }
        "2" { $ans = "No" }
    }
    if ($(vars).config.ContainsKey("API")) { $(vars).config.API = $ans } else { $(vars).config.Add("API", $ans) }
}

function Global:Get-Remote {
    Write-Host "Doing Remote"
    Start-Sleep -S 3
    do {
        Clear-Host
        $ans = Read-Host -Prompt "Remote         
        
[Yes or No]         

This Option Enables Remote html API. Default is No.

Would you like to be able to access the HTML API remotely?

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1", "2")
    }While ($Check -eq 1)
    Switch ($ans) {
        "1" { $ans = "Yes" }
        "2" { $ans = "No" }
    }
    if ($(vars).config.ContainsKey("Remote")) { $(vars).config.Remote = $ans } else { $(vars).config.Add("Remote", $ans) }
}

function Global:Get-APIPassword {
    Write-Host "Doing APIPassword"
    Start-Sleep -S 3
    do {
        Clear-Host
        $ans = Read-Host -Prompt "APIPassword    
        
[chacters]          

This sets password for Remote API. If your set this parameter,
new endpoint for api is http://ipaddress:port/APIPassword/,
instead of usual http://ipaddress:port/

Please enter a new HTML API password

Password"
        do {
            clear-host
            $Confirm = Read-Host -Prompt "You have entered $ans
            
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }WHile ($Check -eq 1)
    }WHile ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("APIPassword")) { $(vars).config.APIPassword = $ans } else { $(vars).config.Add("APIPassword", $ans) }
}

function Global:Get-TCP {
    Write-Host "Doing TCP"
    Start-Sleep -S 3
    do {
        Clear-Host
        $ans = Read-Host -Prompt "TCP            
        
[Yes or No]         

Default is No. Activates TCP port for API on -API_Port. Note:
If SWARM is in HiveOS, it will turn on automatically.

Would you like to turn on TCP

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans ("1", "2")
    }While ($Check -eq 1)
    Switch ($ans) {
        "1" { $ans = "Yes" }
        "2" { $ans = "No" }
    }
    if ($(vars).config.ContainsKey("TCP")) { $(vars).config.TCP = $ans } else { $(vars).config.Add("TCP", $ans) }
}

function Get-TCP_Port {
    Write-Host "Doing TCP_Port"
    Start-Sleep -S 3
    do {
        Clear-Host
        $ans = Read-Host -Prompt "TCP_Port       

[Integer]               

Default is 6099. Activates TCP Port for API. 
    
Port"
        do {
            Clear-Host
            $Confirm = Read-Host -Prompt "You have entered $ans
         
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("TCP_Port")) { $(vars).config.TCP_Port = $ans } else { $(vars).config.Add("TCP_Port", $ans) }
}

function Global:Get-TCP_IP {
    Write-Host "Doing TCP_IP"
    Start-Sleep -S 3
    do {
        Clear-Host
        $ans = Read-Host -Prompt "TCP_IP       
    
[IP Address]          

Default is 127.0.0.1
Remote is 0.0.0.0

Ip Address for TCP API"
        do {
            clear-host
            $Confirm = Read-Host -Prompt "You have entered $ans

Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }while ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("TCP_IP")) { $(vars).config.TCP_IP = $ans } else { $(vars).config.Add("TCP_IP", $ans) }
}

function Global:Get-API_Key {
    Write-Host "Doing API_Key"
    Start-Sleep -S 3
    do {
        Clear-Host
        $ans = Read-Host -Prompt "API_Key        
        
[HiveOS API key]    

Default is `"`" (none). By supplying SWARM with your HiveOS
API key (you must generate one in account > settings), SWARM
is able to use OC profiles from HiveOS. If you set an algorithm
profile, and SWARM switched to that algorithm- It will notify
HiveOS, triggering an OC command. SWARM will confirm OC was changed.
If 30 seconds has passed, and HiveOS has not set OC, SWARM will
contiue forward. Note: This takes precedence over SWARM's OC
settings.

HiveOS API Key For This IP Address"
        do {
            Clear-Host
            $Confirm = Read-Host -Prompt "You have entered $ans
            
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("API_Key")) { $(vars).config.API_Key = $ans } else { $(vars).config.Add("API_Key", $ans) }
}

function Global:Get-API {
    switch ($(vars).input) {
        "34" { Global:Start-API }
        "35" { Global:Get-Remote }
        "36" { Global:Get-APIPassword }
        "37" { Global:Get-TCP }
        "38" { Global:Get-TCP_Port }
        "39" { Global:Get-TCP_IP }
        "40" { Global:Get-API_Key }
    }

    do {
        clear-host
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