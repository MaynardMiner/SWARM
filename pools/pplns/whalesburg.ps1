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

if ($(arg).PoolName -eq $Name) {
    $Whalesburg_Request = [PSCustomObject]@{ } 
 
    try { $Whalesburg_Request = Invoke-RestMethod "https://payouts.whalesburg.com/profitabilities/share_price" -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop } 
    catch { 
        return "WARNING: SWARM contact $($Name) but there was no response"
    }
    try { $Whalesburg_Stats = Invoke-RestMethod "https://stats.whalesburg.com/current_stats" -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop } 
    catch { 
        return "WARNING: SWARM contacted ($Name) but there was no response." 
    }

    if (!$Whalesburg_Request.mh_per_second_price -or !$Whalesburg_Stats.eth) { 
        return "WARNING: SWARM contacted ($Name) but ($Name) the response was empty.";
    }
    try { $(vars).ETH_exchange = Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=ETH&tsyms=BTC" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch { return "WARNING: SWARM failed to get ETH Pricing for $Name"; }

    $(vars).ETH_exchange = $(vars).ETH_exchange.ETH.BTC

    $Whalesburg_Algorithm = "ethash"
  
    if ($(vars).Algorithm -contains $Whalesburg_Algorithm) {
        $Whalesburg_Port = "8082"
        $Whalesburg_Host = "eu1.whalesburg.com"
        ## add fee based on reward system. (they say its bonus, but actually fee)
        $Prorate = 2;
        ## btc/mhs/day
        $Estimate = ((([Double]$Whalesburg_Request.mh_per_second_price * 86400))) * $(vars).ETH_exchange;
        $Value = [convert]::ToDecimal($Estimate * (1 - ($Prorate / 100)));
        $Hashrate = [convert]::ToDecimal($Whalesburg_Stats.eth.current_hashrate);
        if (-not $Global:Config.vars.Pool_HashRates.$Name) {
            $Global:Config.vars.Pool_HashRates.Add("$Name", @{})
        }
        elseif (-not $Global:Config.vars.Pool_HashRates.$Name.$Whalesburg_Algorithm) {
            $Global:Config.vars.Pool_HashRates.$NameAdd("$Whalesburg_Algorithm", @{
                    Hashrate = "$Hashrate"
                    Percent  = ""
                })
        }

        $Stat = [Pool_Stat]::New("$($Name)_$($Whalesburg_Algorithm)", $Value, $hashrate, -1, $false)

        $Level = $Stat.$($(arg).Stat_Algo)
        $previous = $Stat.Day_MA

        [Pool]::New(
            ## Symbol
            "$Whalesburg_Algorithm-Algo",
            ## Algorithm
            "$Whalesburg_Algorithm",
            ## Level
            $Level,
            ## Stratum
            "stratum+tcp",
            ## Pool_Host
            $Whalesburg_Host,
            ## Pool_Port
            $Whalesburg_Port,
            ## User1
            $(arg).ETH,
            ## User2
            $(arg).ETH,
            ## User3
            $(arg).ETH,
            ## Worker
            "$($(arg).Worker)",
            ## Previous
            $previous
        )
    }
}
