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

function Get-Nvidia {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Coin
    )

    $Coins = Get-Content ".\config\naming\get-nvidia.json" | ConvertFrom-Json

    $Coin = (Get-Culture).TextInfo.ToTitleCase(($Coin -replace "_", " ")) -replace " "

    if ($Coins.$Coin) {$Coins.$Coin}
    else {$Coin}
}

function Get-CPU {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Coin
    )

    $Coins = Get-Content ".\config\naming\get-cpu.json" | ConvertFrom-Json

    $Coin = (Get-Culture).TextInfo.ToTitleCase(($Coin -replace "_", " ")) -replace " "

    if ($Coins.$Coin) {$Coins.$Coin}
    else {$Coin}
}

function Get-AMD {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Coin
    )

    $Coins = Get-Content ".\config\naming\get-amd.json" | ConvertFrom-Json

    $Coin = (Get-Culture).TextInfo.ToTitleCase(($Coin -replace "_", " ")) -replace " "

    if ($Coins.$Coin) {$Coins.$Coin}
    else {$Coin}
}

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
    $GetAlgorithms = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
    $GetAlgorithms.PSObject.Properties.Name
}

function Get-BadPools {
$Badpools = @()
$GetAlgorithms = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
$GetAlgorithms.PSObject.Properties.Name | %{$Badpools +=  [PSCustomObject]@{"$_" = $GetAlgorithms.$_.pools_to_exclude}}
$Badpools
}

function Get-BadMiners {
    $Badpools = @()
    $GetAlgorithms = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
    $GetAlgorithms.PSObject.Properties.Name | %{$Badpools +=  [PSCustomObject]@{"$_" = $GetAlgorithms.$_.miners_to_exclude}}
    $Badpools
    }