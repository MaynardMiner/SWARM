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
function Global:Get-ZergpoolData {
    $Wallets = @()

    $(arg).Type | ForEach-Object {
        $Sel = $_
        $Pool = "zergpool"
        $(vars).Share_Table.$Sel.Add($Pool, @{ })
        $User_Wallet = $($(vars).Miners | Where-Object Type -eq $Sel | Where-Object MinerPool -eq $Pool | Select-Object -Property Wallet -Unique).Wallet
        if ($Wallets -notcontains $User_Wallet) { try { $HTML = Invoke-WebRequest -Uri "http://www.zergpool.com/site/wallet_miners_results?address=$User_Wallet" -TimeoutSec 10 -ErrorAction Stop }catch { log "Failed to get Shares from $Pool" } }
        $Wallets += $User_Wallet
        $string = $HTML.Content
        $string = $string -split "src=`"/images/"
        $string = $string -split "</table><br><table"
        $string = $string | ForEach-Object { if ($_ -like "*</b><span style=*") { $_ } }
        if ($String) {
            $string | ForEach-Object {
                $Cur = $_
                $Algo = $Cur -split ".8em;`"> \(" | Select-Object -Last 1;
                $Algo = $Algo -split "\)</span><td" | Select-Object -First 1
                $CoinName = $Cur -split ".png" | Select-Object -First 1;
                $Percent = $Cur -split "width=`"60`">" | ForEach-Object { if ($_ -like "*%*") { $_ } }
                $Percent = $Percent -split "%" | Select-Object -First 1
                try { if ([Double]$Percent -gt 0) { $SPercent = $Percent }else { $SPercent = 0 } }catch { log "A Share Value On Site Could Not Be Read on $Pool" }
                $Symbol = "$CoinName`:$Algo".ToUpper()
                $(vars).Share_Table.$Sel.$Pool.Add($Symbol, @{ })
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Name", $CoinName)
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Percent", $SPercent)
                $(vars).Share_Table.$Sel.$Pool.$Symbol.Add("Algo", $Algo)
            }
        }
    }
}