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

function Global:Get-PoolTables {
    $(vars).FeeTable.Add("zpool", @{ })
    $(vars).FeeTable.Add("zergpool", @{ })
    $(vars).FeeTable.Add("fairpool", @{ })

    $(vars).divisortable.Add("zpool", @{ })
    $(vars).divisortable.Add("zergpool", @{ })
    $(vars).divisortable.Add("fairpool", @{ })
    
    if ($(arg).Coin.Count -eq 1 -and $(arg).Coin -ne "" -and $(vars).SWARMAlgorithm.Count -eq 1 -and $(arg).SWARM_Mode -ne "") {
        $(vars).SingleMode = $true
    }
}

function Global:Remove-BanHashrates {
    log "Loading Miner Hashrates" -ForegroundColor Yellow
    if ($(vars).BanHammer -gt 0 -and $(vars).BanHammer -ne "") {
        if (test-path ".\stats") { $A = Get-ChildItem "stats" | Where BaseName -Like "*hashrate*" }
        $(vars).BanHammer | ForEach-Object {
            $Sel = $_.ToLower()
            $Sel = $Sel -replace "`/","`-"
            $Sel = $Sel -replace "`_","`-"        
            $A.BaseName | ForEach-Object {
                $Parse = $_ -split "`_"
                if ($Parse[0] -eq $Sel) {
                    Remove-Item ".\stats\$($_).txt" -Force
                }
                elseif ($Parse[1] -eq $Sel) {
                    Remove-Item ".\stats\$($_).txt" -Force
                }
            }
        }
    }
}