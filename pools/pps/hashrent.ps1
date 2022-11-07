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

. .\build\powershell\global\modules.ps1
. .\build\powershell\global\classes.ps1

if ($Name -in $(arg).PoolName) {

    $Request = [PSCustomObject]@{ } 

    try { $request = Invoke-Webrequest "https://hashrent.pro/" -TimeoutSec 30 -ErrorAction Stop } 
    catch { return "WARNING: SWARM contacted ($Name) but there was no response." }
 
    if (!$request.content) {
        return "WARNING: SWARM contacted ($Name) but ($Name) the response was empty."        
    } 
    
    if ($(vars).Algorithm -contains "ethash") {
        $Hashrent_Port = "7007"
        $Hashrent_Host = $Region + "ru.hashrent.pro";
        $Fee = 0.5;
        $GH = [convert]::ToDecimal([regex]::match($request.content, '<span class="GH_Revenue">([^/)]+?)</span>').Value.Replace('<span class="GH_Revenue">', '').Replace('</span>', ''));
        $Estimate = [Convert]::ToDecimal(($GH / 1000000000));    
        $Value = [convert]::ToDecimal($Estimate * (1 - ($Fee / 100)));
        $Stat = [Pool_Stat]::New("$($Name)_ethash", $Value, 0, -1, $false)
        $Level = $Stat.$($(arg).Stat_Algo)
        $previous = $Stat.Day_MA

        $User1 = $(arg).SuperWallet + "/$($(arg).HashrentInstance)"
        ## User2
        $User2 = $(arg).SuperWallet + "/$($(arg).HashrentInstance)"
        ## User3
        $User3 = $(arg).SuperWallet + "/$($(arg).HashrentInstance)"

        [Pool]::New(
            ## Symbol
            "ethash-Algo",
            ## Algorithm
            "ethash",
            ## Level
            $Level,
            ## Stratum
            "stratum+tcp",
            ## Pool_Host
            $Hashrent_Host,
            ## Pool_Port
            $Hashrent_Port,
            ## User1
            $User1,
            ## User2
            $User2,
            ## User3
            $User3,
            ## Pass1
            "x",
            ## Pass2
            "x",
            ## Pass3
            "x",
            ## Previous
            $previous
        )
    }
}