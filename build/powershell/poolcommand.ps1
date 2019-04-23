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

function Get-Pools {
    param (
        [Parameter(Mandatory = $true)]
        [String]$PoolType
    )

    Switch($PoolType)
    {
     "Algo"{$GetPools = if (Test-Path "algopools") {Get-ChildItemContent "algopools" | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
     "Coin"{$GetPools = if (Test-Path "coinpools") {Get-ChildItemContent "coinpools" | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
     "Custom"{$GetPools = if (Test-Path "custompools") {Get-ChildItemContent "custompools" | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
    }

    $GetPools
  
}

function Sort-Pools {
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Pools
    )

    $PoolPriority1 = @()
    $PoolPriority2 = @()
    $PoolPriority3 = @()
}

function Get-Volume {
    $global:Pool_Hashrates.keys | ForEach-Object {
        $SortAlgo = $_
        $Sorted = @()
        $global:Pool_HashRates.$SortAlgo.keys | ForEach-Object {$Sorted += [PSCustomObject]@{Name = "$($_)"; HashRate = [Double]$global:Pool_HashRates.$SortAlgo.$_.HashRate}}
        $BestHash = $($Sorted | Sort-Object HashRate -Descending | Select -First 1).HashRate
        $global:Pool_HashRates.$SortAlgo.keys | ForEach-Object {$global:Pool_HashRates.$SortAlgo.$_.Percent = ([Double]$global:Pool_HashRates.$SortAlgo.$_.HashRate / [Double]$BestHash)}
    }
}