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


function Get-Algorithm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Algorithm
    )

    $Algorithms = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json

    $Algorithm = (Get-Culture).TextInfo.ToTitleCase(($Algorithm -replace "_", " ")) -replace " "

    if ($Algorithms.$Algorithm) {$Algorithms.$Algorithm}
    else {$Algorithm}
}

function Convert-DateString ([string]$Date, [string[]]$Format) {
    $result = New-Object DateTime

    $Convertible = [DateTime]::TryParseExact(
        $Date,
        $Format,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$result)

    if ($Convertible) { $result }
}

function Get-AlgoList {
    $Pool_Json.PSObject.Properties.Name
}

function Get-BadPools {
$Badpools = @()
$Pool_Json.PSObject.Properties.Name | %{$Badpools +=  [PSCustomObject]@{"$_" = $Pool_Json.$_.pools_to_exclude}}
$Badpools
}

function Get-BadMiners {
    $Badpools = @()
    $Pool_Json.PSObject.Properties.Name | %{$Badpools +=  [PSCustomObject]@{"$_" = $Pool_Json.$_.miners_to_exclude}}
    $Badpools
}

function Add-ASIC_ALGO {
        ##Add ASIC_ALGO to pool-algos.txt for bans, etc
        $Algolist = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
        $Algolist = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json

        if($global:Config.Params.ASIC_ALGO -and $global:Config.Params.ASIC_ALGO -ne "") {
            $global:Config.Params.ASIC_ALGO | ForEach-Object {
                if($_ -notin $Algolist.PSObject.Properties.Name) {
                $Algolist | Add-Member $_ @{"hiveos_name" = $_; exclusions = @("add pool or miner here","comma seperated")}
                }
        } 
    }
}