param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action,
    [Parameter(Mandatory = $false, Position = 1)]
    [array]$Bans,
    [Parameter(Mandatory = $false, Position = 2)]
    [string]$Launch  
)


Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))
$dir = Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))

if (-not $Launch) { $Launch = "command" }
$PoolDir = ".\config\pools\pool-algos.json"; $BanDir = ".\config\pools\bans.json"    
if (Test-Path $PoolDir) { $PoolJson = Get-Content $PoolDir | ConvertFrom-Json }
if (Test-Path $BanDir) { $BanJson = Get-Content $BanDir | ConvertFrom-Json }

$Screen = @()
$JsonBanHammer = @()
$BanJson | % { $global:banhammer += $_ }
$BanJson | % { $JsonBanHammer += $_ }

$Global:Exclusions = $PoolJson
$BanChange = $false
$PoolChange = $false

switch ($Action) {
    "add" {
        if ($Bans) {
            $Bans | % {

                $Arg = $_ -split "`:"
    
                if ($Arg.Count -eq 1) {
                    switch ($Launch) {
                        "Process" {
                            if ($Arg -notin $global:banhammer) { $global:banhammer += $Arg }
                        }
                        "Command" {
                            if ($Arg -notin $JsonBanHammer) { $JsonBanHammer += $Arg }
                            $BanChange = $true
                            $Screen += "Adding $Arg to bans.json"
                        }
                    }
                }
                else {
                    $Item = $_ -split "`:" | Select -First 1
                    $Value = $_ -split "`:" | Select -Last 1
                    switch ($Launch) {
                        "command" {
                            if ($Value -notin $PoolJson.$Item.exclusions) {
                                $PoolJson.$Item.exclusions += $Value
                                $PoolChange = $true
                                $Screen += "Adding $Value in $Item exclusions in pool-algos.json"
                            }
                        }
                        "process" {
                            if ($Value -notin $PoolJson.$Item.exclusions) {
                                $Global:Exclusions.$Item.exclusions += $Value
                            }
                        }
                    }
                }
            }
        }
    }
    "remove" {
        if ($Bans) {
            $Bans | % {
                $Arg = $_ -split "`:"
                if ($Arg.Count -eq 1) {
                    switch ($Launch) {
                        "Command" {
                            if ($Arg -in $JsonBanHammer) { $JsonBanHammer = $JsonBanHammer | ForEach-Object { if ($_ -ne $Arg) { $_ } } }
                            $BanChange = $true
                            $Screen += "Removed $Arg in bans.json"
                        }
                    }
                }
                else {
                    $Item = $_ -split "`:" | Select -First 1
                    $Value = $_ -split "`:" | Select -Last 1
                    switch ($Launch) {
                        "Command" {
                            if ($Value -in $PoolJson.$Item.exclusions) {
                                $PoolJson.$Item.exclusions = $PoolJson.$Item.exclusions | ForEach-Object { if ($_ -ne $Value) { $_ } }
                                $PoolChange = $true
                                $Screen += "Removed $Value in $Item exclusions in pool-algos.json"
                            }
                        }
                    }
                }
            }
        }
    }
}

if ($PoolChange = $true) { $PoolJson | ConvertTo-Json | Set-Content $PoolDir }
if ($BanChange = $true) { if (-not $JSonBanHammer) { Clear-Content $Bandir }else { $JsonBanHammer | ConvertTo-Json | Set-Content $BanDir } }
if ($Screen) { $Screen }