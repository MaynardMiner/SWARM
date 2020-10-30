
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
    [string]$Launch = "Command"
)

[cultureinfo]::CurrentCulture = 'en-US';

$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))));
$dir = $dir -replace "/var/tmp", "/root";
Set-Location $dir;

if (-not $Launch) { $Launch = "command" };
$PoolDir = ".\config\pools\pool-algos.json"; 
$BanDir = ".\config\pools\bans.json"; 
$CoinDir = ".\config\pools\pool-coins.json";
$CoinJson = [PSCustomObject]@{}
if (Test-Path $CoinDir) { $CoinJson = Get-Content $CoinDir | ConvertFrom-Json; }
if (Test-Path $PoolDir) { $PoolJson = Get-Content $PoolDir | ConvertFrom-Json; }
if (Test-Path $BanDir) { $BanJson = Get-Content $BanDir | ConvertFrom-Json; }

$Screen = @();
$JsonBanHammer = @();
if ($Launch -eq "Process") {
    $BanJson | Foreach-Object { $(vars).BanHammer += $_ };
}
$BanJson | Foreach-Object { $JsonBanHammer += $_ };

$BanChange = $false;
$PoolChange = $false;
$CoinChange = $false;

switch ($Action) {
    "add" {
        if ($Bans) {
            $Bans | Foreach-Object {
                $Arg = $_ -split "`:"
                if ($Arg.Count -eq 1) {
                    switch ($Launch) {
                        ## Add the singular item to the banhammer list
                        "Process" {
                            if ($Arg -notin $(vars).BanHammer) { $(vars).BanHammer += $Arg }
                        }
                        ## Update the bans.json file
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
                        "Command" {
                            ### If item in is pool-algos.json, it is a algorithm.
                            ### We add the specific exclusion (NVIDIA1,Pool,Miner) etc. to it.
                            if ($Item -in $PoolJson.PSObject.Properties.Name) {
                                if ($Value -notin $PoolJson.$Item.exclusions) {
                                    $PoolJson.$Item.exclusions += $Value
                                    $PoolChange = $true
                                    $Screen += "Adding $Value in $Item exclusions in pool-algos.json"
                                }
                            }
                            ### If the item isn't in pool-algos.json, we have 1 of 2 possibilities.
                            ### 1.) User misspelled the algorithm.
                            ### 2.) The item they are trying to ban is a coin.
                            else {
                                $Screen += "WARNING: Item $Item Is Not Detected To Be An Algorithm. Assuming it is a Coin instead.";
                                ## Create or get the current list of bans for coin:
                                if ($Item -notin $CoinJson) {
                                    $Screen += "Adding $Item to list in pool-coins.json"
                                    $CoinJson | Add-Member @{ $Item = @{ alt_names = @($Item); exclusions = @("add pool or miner here", "comma seperated") } };
                                    $CoinChange = $true;
                                }
                                if ($Value -notin $CoinJson.$Item.exclusions) {
                                    $Screen += "Adding $Value in $Item exclusions in pool-coins.json";
                                    $CoinJson.$Item.exclusions += $Value;
                                    $CoinChange = $true;
                                }
                            }
                        }
                        "process" {
                            ### If item in is pool-algos.json, it is a algorithm.
                            ### We add the specific exclusion (NVIDIA1,Pool,Miner) etc. to it.
                            if ($global:Config.Pool_Algos.$Item) {
                                if ($Value -notin $global:Config.Pool_Algos.$Item.exclusions) {
                                    $global:Config.Pool_Algos.$Item.exclusions += $Value
                                }
                            }
                            else { 
                                ### If the item isn't in pool-algos.json, we have 1 of 2 possibilities.
                                ### 1.) User misspelled the algorithm.
                                ### 2.) The item they are trying to ban is a coin.
                                log "WARNING: Item $Item Is Not Detected To Be An Algorithm. Assuming it is a Coin instead." -ForeGroundColor Yellow 
                                if ($Item -notin $Global:Config.Pool_Coins.PSobject.Properties.Name) {
                                    $Global:Config.Pool_Coins | Add-Member @{ $item = @{alt_names = @($Item); exclusions = @() } };
                                }
                                if ($Value -notin $Global:Config.Pool_Coins.$Item.exclusions) {
                                    $global:Config.Pool_Coins.$Item.exclusions += $Value
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    ## Can only be ran from commandline
    "remove" {
        if ($Bans) {
            $Bans | Foreach-Object {
                $Arg = $_ -split "`:"
                if ($Arg.Count -eq 1) {
                    $Arg = $Arg.Replace("cnight", "cryptonight")
                    if ($Arg -in $JsonBanHammer) { $JsonBanHammer = $JsonBanHammer | ForEach-Object { if ($_ -ne $Arg) { $_ } } }
                    $BanChange = $true
                    $Screen += "Removed $Arg in bans.json"

                }
                else {
                    $Item = ($_.split("`:") | Select-Object -First 1).replace("cnight", "cryptonight");
                    $Value = ($_.split("`:") | Select-Object -Last 1).replace("cnight", "cryptonight");
                    if ($Value -in $PoolJson.$Item.exclusions) {
                        $array = @();
                        $PoolJson.$Item.exclusions | Where-Object { $_ -ne $Value } | ForEach-Object {
                            $array += $_;
                        }
                        $PoolJson.$Item.exclusions = $array
                        $PoolChange = $true
                        $Screen += "Removed $Value in $Item exclusions in pool-algos.json"
                    }
                    else {
                        $Screen += "WARNING: Item $Item Is Not Detected To Be An Algorithm. Assuming it is a Coin instead.";
                        ## Create or get the current list of bans for coin:
                        if ($Item -notin $CoinJson.PSobject.Properties.Name) {
                            $Screen += "Adding $Item to list in pool-coins.json"
                            $CoinJson | Add-Member @{ $item = @{alt_names = @($Item); exclusions = @() } };
                            $CoinChange = $true;
                        }
                        if ($Value -in $CoinJson.$Item.exclusions) {
                            $Screen += "Adding $Value in $Item exclusions in pool-coins.json";
                            $array = @()
                            $CoinJson.$Item.exclusions | Where-Object { $_ -ne $Value } | ForEach-Object {
                                $array += $_;
                            }
                            $CoinJson.$Item.exclusions = $array
                            $CoinChange = $true;
                        }
                        $Screen += "Removed $Value in $Item exclusions in pool-coins.json"
                    }
                }
            }
        }
    }
}


if ($CoinChange) { $CoinJson | ConvertTo-Json | Set-Content $CoinDir }
if ($PoolChange) { $PoolJson | ConvertTo-Json | Set-Content $PoolDir }
if ($BanChange) { if (-not $JSonBanHammer) { Clear-Content $Bandir }else { $JsonBanHammer | ConvertTo-Json | Set-Content $BanDir } }
if ($screen.count -gt 0) { $Screen }

