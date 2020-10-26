
<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Action,
    [Parameter(Mandatory = $false, Position = 1)]
    [array]$Bans,
    [Parameter(Mandatory = $false, Position = 2)]
    [string]$Launch  
)

[cultureinfo]::CurrentCulture = 'en-US'

$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp", "/root"
Set-Location $dir

if (-not $Launch) { $Launch = "command" }
$PoolDir = ".\config\pools\pool-algos.json"; $BanDir = ".\config\pools\bans.json"    
if (Test-Path $PoolDir) { $PoolJson = Get-Content $PoolDir | ConvertFrom-Json }
if (Test-Path $BanDir) { $BanJson = Get-Content $BanDir | ConvertFrom-Json }

$Screen = @()
$JsonBanHammer = @()
if ($Launch -eq "Process") {
    $BanJson | Foreach-Object { $(vars).BanHammer += $_ }
}
$BanJson | Foreach-Object { $JsonBanHammer += $_ }

$BanChange = $false
$PoolChange = $false

switch ($Action) {
    "add" {
        if ($Bans) {
            $Bans | Foreach-Object {

                $Arg = $_ -split "`:"
    
                if ($Arg.Count -eq 1) {
                    switch ($Launch) {
                        "Process" {
                            if ($Arg -notin $(vars).BanHammer) { $(vars).BanHammer += $Arg }
                        }
                        "Command" {
                            $Arg = $Arg.replace("cnight", "cryptonight");
                            if ($Arg -notin $JsonBanHammer) { $JsonBanHammer += $Arg }
                            $BanChange = $true
                            $Screen += "Adding $Arg to bans.json"
                        }
                    }
                }
                else {
                    $Item = ($_.split("`:") | Select-Object -First 1).replace("cnight", "cryptonight");
                    $Value = ($_.split("`:") | Select-Object -Last 1).replace("cnight", "cryptonight");
                    switch ($Launch) {
                        "command" {
                            if ($Item -in $PoolJson.keys) {
                                if ($Value -notin $PoolJson.$Item.exclusions) {
                                    $PoolJson.$Item.exclusions += $Value
                                    $PoolChange = $true
                                    $Screen += "Adding $Value in $Item exclusions in pool-algos.json"
                                }
                            }
                            else {
                                $PoolJson | Add-Member $Item @{exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                                if ($Value -notin $PoolJson.$Item.exclusions) {
                                    $PoolJson.$Item.exclusions += $Value
                                    $PoolChange = $true
                                    $Screen += "Adding $Value in $Item exclusions in pool-algos.json"
                                }
                            }
                        }
                        "process" {
                            if ($global:Config.Pool_Algos.$Item) {
                                if ($Value -notin $global:Config.Pool_Algos.$Item.exclusions) {
                                    $global:Config.Pool_Algos.$Item.exclusions += $Value
                                }
                            }
                            else { log "WARNING: Cannot add $Value to $Item Bans" -ForeGroundColor Yellow }
                        }
                    }
                }
            }
        }
    }
    "remove" {
        if ($Bans) {
            $Bans | Foreach-Object {
                $Arg = $_ -split "`:"
                if ($Arg.Count -eq 1) {
                    switch ($Launch) {
                        "Command" {
                            $Arg = $Arg.Replace("cnight","cryptonight")
                            if ($Arg -in $JsonBanHammer) { $JsonBanHammer = $JsonBanHammer | ForEach-Object { if ($_ -ne $Arg) { $_ } } }
                            $BanChange = $true
                            $Screen += "Removed $Arg in bans.json"
                        }
                    }
                }
                else {
                    $Item = ($_.split("`:") | Select-Object -First 1).replace("cnight","cryptonight");
                    $Value = ($_.split("`:") | Select-Object -Last 1).replace("cnight","cryptonight");
                    switch ($Launch) {
                        "Command" {
                            if ($Value -in $PoolJson.$Item.exclusions) {
                                $PoolJson.$Item.exclusions = $PoolJson.$Item.exclusions | Where-Object { $_ -ne $Value }
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

