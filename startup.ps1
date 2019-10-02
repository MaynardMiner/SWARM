$Dir = Split-Path $script:MyInvocation.MyCommand.Path
$Dir = $Dir -replace "/var/tmp", "/root"
Set-Location $Dir
if ($IsWindows) { try { if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$Dir`'" -WindowStyle Minimized } }catch { } }


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
    if ( "-help" -in $args ) {
        if ($IsWindows) {
            $host.ui.RawUI.WindowTitle = "SWARM";
            Start-Process "CMD" -ArgumentList "/C `"pwsh -noexit -executionpolicy Bypass -WindowStyle Maximized -command `"Set-Location C:\; Set-Location `'$Dir`'; .\build\powershell\scripts\help.ps1`"`"" -Verb RunAs
        }
        else {
            Invoke-Expression "./help.sh"
        }        
    }
    else {
        $Start = $true
        $args | % {
            $Command = $false
            $ListCheck = $_ -replace "-", ""
            if ($_[0] -eq "-") { $Command = $true; $Com = $_ -replace "-", "" }
            if ($Command -eq $true) {
                if ($ListCheck -in $List) {
                    $parsed.Add($Com, "new")
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
            Start-Process "CMD" -ArgumentList "/C `"pwsh -noexit -executionpolicy Bypass -WindowStyle Maximized -command `"Set-Location C:\; Set-Location `'$Dir`'; .\build\powershell\scripts\help.ps1`"`"" -Verb RunAs
        }
        else {
            Invoke-Expression "./help.sh"
        }        
        Start-Sleep -S 3
        exit    
    }
    elseif (".\config\parameters\newarguments.json") {
        $Start = $true
        $parsed = @{ }
        $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $Parsed.Add("$($_)", $arguments.$_) }    
    }
}
## Check for hiveos saved/help saved config
elseif (Test-Path ".\config\parameters\newarguments.json") {
    $Start = $true
    $parsed = @{ }
    $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
    $arguments.PSObject.Properties.Name | % { $Parsed.Add("$($_)", $arguments.$_) }
}
## Run help if all fails
else {
    if ($IsWindows) {
        $host.ui.RawUI.WindowTitle = "SWARM";
        Start-Process "CMD" -ArgumentList "/C `"pwsh -noexit -executionpolicy Bypass -WindowStyle Maximized -command `"Set-Location C:\; Set-Location `'$Dir`'; .\build\powershell\scripts\help.ps1`"`"" -Verb RunAs
    }
    else {
        Invoke-Expression "./help.sh"
    }        
    Start-Sleep -S 3
    exit
}

if ($Start -eq $true) {
    $Defaults.PSObject.Properties.Name | % { if ($_ -notin $Parsed.keys) { $Parsed.Add("$($_)", $Defaults.$_) } }

    $Parsed | convertto-json | Out-File ".\config\parameters\arguments.json"

    if ($IsWindows) {
        $host.ui.RawUI.WindowTitle = "SWARM";
        Start-Process "pwsh" -ArgumentList "-noexit -executionpolicy Bypass -WindowStyle Maximized -command `"Set-Location C:\; Set-Location `'$Dir`'; .\swarm.ps1`"" -Verb RunAs
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
