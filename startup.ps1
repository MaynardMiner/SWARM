Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
try { if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$Dir`'" -WindowStyle Minimized } }catch { }


if (Test-Path ".\config\parameters\default.json") {
    $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
} else {
    Write-Host "Default.json is missing. Exiting" -ForegroundColor DarkRed
    Start-Sleep -S 3
    exit
}

$List = $Defaults.PSObject.Properties.Name
$parsed = @{ }

if ($args) {
    $args | % {
        $Command = $false
        $ListCheck = $_ -replace "-",""
        if ($_[0] -eq "-") { $Command = $true; $Com = $_ -replace "-", "" }
        if ($Command -eq $true) {
            if($ListCheck -in $List) {
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
} elseif (test-path ".\config.json") {
    $parsed = @{ }
    $arguments = Get-Content ".\config.json" | ConvertFrom-Json
    $arguments.PSObject.Properties.Name | % { $Parsed.Add("$($_)", $arguments.$_) }
} elseif (Test-Path ".\config\parameters\arguments.json") {
    $parsed = @{ }
    $arguments = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
    $arguments.PSObject.Properties.Name | % { $Parsed.Add("$($_)", $arguments.$_) }
} else {
    Write-Host "No Arguments or arguments.json file found. Exiting."
    Start-Sleep -S 3
    exit
}

$Defaults.PSObject.Properties.Name | % { if (-not [string]$Parsed.$_) { $Parsed.Add("$($_)", $Defaults.$_) } }

$Parsed | convertto-json | Out-File ".\config\parameters\arguments.json"

if(Test-path "C:\") {
    Start-Process "CMD" -ArgumentList "/C powershell -noexit -executionpolicy Bypass -windowstyle maximized -command `"pwsh -command `"Set-Location C:\; Set-Location `'$Dir`'; .\swarm.ps1`"`"" -Verb RunAs
}
else {
    Invoke-Expression ".\swarm.ps1"
}
