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
function Global:Get-CoinShares {

    . .\build\api\pools\zergpool.ps1;
    . .\build\api\pools\nlpool.ps1;    
    . .\build\api\pools\ahashpool.ps1;
    . .\build\api\pools\blockmasters.ps1;
    . .\build\api\pools\hashrefinery.ps1;
    . .\build\api\pools\phiphipool.ps1;
    . .\build\api\pools\fairpool.ps1;
    . .\build\api\pools\blazepool.ps1;

    $(arg).Type | ForEach-Object { $(vars).Share_Table.Add("$($_)", @{ }) }

    ##For 
    $(arg).Poolname | ForEach-Object {
        switch ($_) {
            "zergpool" { Global:Get-ZergpoolData }
            "nlpool" { Global:Get-NlPoolData }        
            "ahashpool" { Global:Get-AhashpoolData }
            "blockmasters" { Global:Get-BlockMastersData }
            "hashrefinery" { Global:Get-HashRefineryData }
            "phiphipool" { Global:Get-PhiphipoolData }
            "fairpool" { Global:Get-FairpoolData }
            "blazepool" { Global:Get-BlazepoolData }
        }
    }
}