$Dir = Split-Path $script:MyInvocation.MyCommand.Path
$Dir = $Dir -replace "/var/tmp", "/root"
Set-Location $Dir

## Check to make sure that Windows was start with correct pwsh
if ($IsWindows) {
    $Bat_File = Get-Content ".\SWARM.bat"
    $Preview = $Bat_File | Select-String "pwsh -executionpolicy Bypass"
    if($Preview) {
        $Bat_File = $Bat_File.Replace("pwsh-preview -executionpolicy Bypass","pwsh -executionpolicy Bypass")
        $Bat_File | Set-Content ".\SWARM.bat"
        Write-Host "Edited Bat File to use pwsh then restarted."
        Write-Host "This will only happen once."
        Start-Sleep -S 5
        Start-Process "SWARM.bat"
        exit    
    }
}

## EUID denotes if root or not.
if ($IsLinux) { $Global:EUID = (Invoke-Expression "bash -c set" | ConvertFrom-StringData).EUID }
if ($IsWindows) { try { if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$Dir`'" -WindowStyle Minimized } }catch { } }

## Confirm user did not delect default.json
if (Test-Path ".\config\parameters\default.json") {
    $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
}
else {
    Write-Host "Default.json is missing. Exiting" -ForegroundColor DarkRed
    Start-Sleep -S 3
    exit
}

$List = $Defaults.PSObject.Properties.Name
$parsed = @{ }
$start = $false
$noconfig = $false

## Arguments take highest priority
if ($args) {
    ## First run -help
    if ( "-help" -in $args ) {
        if ($IsWindows) {
            $host.ui.RawUI.WindowTitle = "SWARM";
            $file = "$Dir\build\powershell\scripts\help.ps1"
            $exec = "$PSHOME\pwsh.exe"
            Start-Process $exec -ArgumentList "-noexit -executionpolicy Bypass -WindowStyle Maximized -file `"$file`"" -Verb RunAs
        }
        else {
            Invoke-Expression "./help_linux"
        }        
    }
    ## Parse each argument. Convoluted way to scan arguments for issues.
    ## This will add it to a hashtable, which will later add in any
    ## defaults not specified.
    else {
        $Start = $true
        $args | % {
            if ($_ -is [string]) {
                $_ = $_.replace("cnight", "cryptonight")
            }
            $Command = $false
            $ListCheck = $_ -replace "-", ""
            if ($_[0] -eq "-") { $Command = $true; $Com = $_ -replace "-", "" }
            if ($Command -eq $true) {
                if ($ListCheck -in $List) {
                    if ($ListCheck -notin $parsed.keys) {
                        $parsed.Add($Com, "new")
                    }
                    else {
                        Write-Host "Found $Listcheck twice in arguments" -ForegroundColor Red
                        Write-Host "Contiuning startup, but this may cause major issues." -ForegroundColor red
                        Start-Sleep -S 3
                    }
                }
                else {
                    Write-Host "Parameter `"$($ListCheck)`" Not Found. Exiting" -ForegroundColor Red
                    Start-Sleep -S 3
                    exit
                }            
            }
            else {
                if ($parsed.$Com -eq "new") { $parsed.$Com = $_ }
                else {
                    $NewArray = @()
                    $Parsed.$Com | % { $NewArray += $_ }
                    $NewArray += $_
                    $Parsed.$Com = $NewArray
                }
            }
        }
    }
}
## Check if h-run.sh ran config.json
## If user threw a .json file in their wallet.config-
## We simply pull the arguments and add in any defaults
## They may have missed.
elseif (test-path ".\config.json") {
    $parsed = @{ }
    $arguments = Get-Content ".\config.json" | ConvertFrom-Json
    if ([string]$arguments -ne "") {
        $Start = $true
        $arguments.PSObject.Properties.Name | % { $Parsed.Add("$($_)", $arguments.$_) }
    }
    ## run help if no newarguments
    elseif (-not (test-path ".\config\parameters\newarguments.json")) {
        if ($IsWindows) {
            $host.ui.RawUI.WindowTitle = "SWARM";
            $file = "$Dir\build\powershell\scripts\help.ps1"
            $exec = "$PSHOME\pwsh.exe"
            Start-Process $exec -ArgumentList "-noexit -executionpolicy Bypass -WindowStyle Maximized -file `"$file`"" -Verb RunAs
        }
        else {
            Invoke-Expression "./help_linux"
        }        
        Start-Sleep -S 3
        exit    
    }
    else {
        $Start = $true
        $parsed = @{ }
        $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
        $defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $Parsed.Add("$($_)", $arguments.$_) }    
        $defaults.PSObject.Properties.Name | % {
            if ($_ -notin $Parsed.keys) {
                $Parsed.Add("$($_)", $defaults.$_)
            }
        }
        $Parsed | ConvertTo-Json -Depth 5 | Set-Content ".\config\parameters\newarguments.json"
    }
}
## Check for hiveos saved/help saved config
elseif (Test-Path ".\config\parameters\newarguments.json") {
    $Start = $true
    $parsed = @{ }
    $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
    $defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
    $arguments.PSObject.Properties.Name | % { $Parsed.Add("$($_)", $arguments.$_) }
    $defaults.PSObject.Properties.Name | % {
        if ($_ -notin $Parsed.keys) {
            $Parsed.Add("$($_)", $defaults.$_)
        }
    }
    $Parsed | ConvertTo-Json -Depth 5 | Set-Content ".\config\parameters\newarguments.json"
}
## Run help if all fails
else {
    if ($IsWindows) {
        $host.ui.RawUI.WindowTitle = "SWARM";
        $file = "$Dir\build\powershell\scripts\help.ps1"
        $exec = "$PSHOME\pwsh.exe"
        Start-Process $exec -ArgumentList "-noexit -executionpolicy Bypass -WindowStyle Maximized -file `"$file`"" -Verb RunAs
    }
    else {
        Invoke-Expression "./help_linux"
    }        
    Start-Sleep -S 3
    exit
}

if ($Start -eq $true) {
    $Defaults.PSObject.Properties.Name | % { if ($_ -notin $Parsed.keys) { $Parsed.Add("$($_)", $Defaults.$_) } }

    $Parsed | convertto-json | Out-File ".\config\parameters\arguments.json"

    if ($IsWindows) {
        $host.ui.RawUI.WindowTitle = "SWARM";
        $Windowstyle = "Maximized"
        if ($Parsed.Hidden -eq "Yes") {
            $Windowstyle = "Hidden"
        }
        $file = "$Dir\swarm.ps1"
        $exec = "$PSHOME\pwsh.exe"
        Start-Process $exec -ArgumentList "-noexit -executionpolicy bypass -windowstyle $windowstyle -File `"$file`"" -Verb Runas
    }
    else {
        ## Add Arguments to newarguments.json
        if (test-path "/hive-config") {
            Write-Host "Saving Arguments To .\config\parameters\newarguments.json" -ForegroundColor Yellow
            $Parsed | ConvertTo-Json | Out-File ".\config\parameters\newarguments.json"
        }
        Invoke-Expression ".\swarm.ps1"
    }
}
