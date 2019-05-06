Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
$dir = Split-Path $script:MyInvocation.MyCommand.Path
$json = $true
try { $Parsed = $args | ConvertFrom-Json -ErrorAction Stop }catch { Write-Host "Could not convert from json, Trying different method"; $json = $false }
if ($json -eq $false) {
    $global:parsed = @{ }
    $args | % {
        $Command = $false
        if ($_ -like "*-*") { $Command = $true; $Com = $_ -replace "-", "" }
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

$global:Params = @{ }
$Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
$Defaults | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % { $Params.Add("$($_)", $Defaults.$_) }
$Parsed.keys| % {
    if ($Params.$_ -ne $Parsed.$_) {
        $Params.$_ = $Parsed.$_
    }
}

$Params | convertto-Json | Out-File ".\config\parameters\arguments.json"

Invoke-Expression ".\swarm.ps1"