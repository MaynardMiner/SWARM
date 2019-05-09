Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
$dir = Split-Path $script:MyInvocation.MyCommand.Path
$json = $true
if ($args) {
    $global:parsed = @{ }
    $args | % {
        $Command = $false
        if ($_[0] -eq "-") { $Command = $true; $Com = $_ -replace "-", "" }
        if ($Command -eq $true) { $parsed.Add($Com, "new") }
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
elseif(Test-Path ".\config\parameters\arguments.json") {
    $global:parsed = @{ }
    $arguments = Get-Content ".\config\parameters\arguments.json" ConvertFrom-Json
    $arguments.PSObject.Properties.Name | % { $Parsed.Add("$($_)", $arguments.$_) }
}
else{
    Write-Host "No Arguments or arguments.json file found. Exiting."
    Start-Sleep -S 3
    exit
}

$Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
$Defaults.PSObject.Properties.Name | % { if (-not [String]$Parsed.$_) { $Parsed.Add("$($_)", $Defaults.$_) } }

$Parsed | convertto-json | Out-File ".\config\parameters\arguments.json"

Start-Process "CMD" -ArgumentList "/C powershell -Version 5.0 -noexit -executionpolicy Bypass -windowstyle maximized -command `"pwsh -command `"Set-Location C:\; Set-Location `'$dir`'; .\swarm.ps1`"`"" -Verb RunAs
