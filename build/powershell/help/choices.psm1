function Global:Get-Choices {
    Write-Host "Well, the basic settings are done. This is what we have so far:
"
    
    $(vars).config | Out-Host
    
    Start-Sleep -S 1
    
    Write-Host "
These settings along with default advanced settings will be saved to `".\config\parameter\newarguments.json`""
    Write-Host "If you run -help again in future, it will prompt if you wish to load your basic configs."
    Write-Host "
                
If using HiveOS- You can copy and paste this into your flight sheet:
    
    "
    $Arg = $null
    
    $(vars).config.keys | % {
        if ($(vars).config.$_ -and (vars).config.$_ -ne "") {
            if ( $(vars).config.$_ -is [Array]) { $Sec = "$($(vars).config.$_)" -replace " ", "," }
            else { $Sec = $(vars).config.$_ }
            $Arg += "-$($_) $Sec "
        }
    }
    $Arg.Substring(0, $Arg.Length - 1) | Out-Host
    
    do {
        $Confirm = Read-Host -Prompt "
                
You can now start SWARM. Would you like to save these settings, and start SWARM?
    
or
    
Would you like to start advanced configs?
    
1 MY BODY IS READY! LETS START SWARM!
2 No. I have plenty of time. I would like to go through all settings, knowing that it will take awhile.
    
Answer"
        $Check = Global:Confirm-Answer $Confirm @("1", "2")
    }While ($Check -eq 1)
    $Confirm
    }
    