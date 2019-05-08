Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
$dir = Split-Path $script:MyInvocation.MyCommand.Path
$json = $true
try { $Parsed = $args | ConvertFrom-Json -ErrorAction Stop }catch { Write-Host "Could not convert from json, Trying different method"; $json = $false }
if ($json -eq $false) {
    $global:parsed = @{ }
    $args | % {
        $Command = $false
        if ($_.Substring(0,1) -eq "-") { $Command = $true; $Com = $_ -replace "-", "" }
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

$Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
$Defaults.PSObject.Properties.Name | % { if (-not $Parsed.$_) { $Parsed.Add("$($_)",$Defaults.$_) } }

$Parsed | convertto-json | Out-File ".\config\parameters\arguments.json"

Start-Process "CMD" -ArgumentList "/C powershell -Version 5.0 -noexit -executionpolicy Bypass -windowstyle maximized -command `"pwsh -command `"Set-Location C:\; Set-Location `'$dir`'; .\swarm.ps1`"`"" -Verb RunAs
