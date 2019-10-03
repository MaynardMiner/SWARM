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

function Global:Remove-BadMiners {
    $BadMiners = @()
    if ($(arg).Threshold -ne 0) { $(vars).Miners | ForEach-Object { 
        if ($_.Profit -gt $(arg).Threshold) { 
            $BadMiners += $_ 
            $(vars).Thresholds += "$($_.Name) mining $($_.Algo) was removed this run: Profit/Day above $($(arg).Threshold) BTC"
            }
        } 
    }
    $BadMiners | ForEach-Object { $(vars).Miners.Remove($_) }
    $BadMiners = $Null
}

function Global:Get-BestMiners {

    $BestMiners = @()

    $(arg).Type | foreach {
        $SelType = $_
        $BestTypeMiners = @()
        $OldMiners = @()
        $OldTypeMiners = @()
        $MinerCombo = @()

        $TypeMiners = $(vars).Miners | Where Type -EQ $SelType
        $(vars).BestActiveMiners | ForEach { $(vars).Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | Where Type -EQ $SelType | ForEach { $OldMiners += $_ } }
        if ($OldMiners) {
            $OldTypeMiners += $OldMiners | Where Profit -gt 0 | Sort-Object @{Expression = "Profit"; Descending = $true } | Select -First 1
            $OldTypeMiners += $OldMiners | Where Profit -lt 0 | Sort-Object @{Expression = "Profit"; Descending = $false } | Select -First 1
            $OldTypeMiners = $OldTypeMiners | Select -First 1
            $OldTypeMiners | foreach { $_ | Add-Member "Old" "Yes" }
        }
        if ($OldTypeMiners) { $MinerCombo += $OldTypeMiners }
        $MinerCombo += $TypeMiners | Where Profit -NE $NULL
        $BestTypeMiners += $TypeMiners | Where Profit -EQ $NULL | Select -First 1
        $BestTypeMiners += $MinerCombo | Where Profit -NE $Null | Where Profit -gt 0 | Sort-Object { ($_ | Measure Profit -Sum).Sum } -Descending | Select -First 1
        $BestTypeMiners += $MinerCombo | Where Profit -NE $Null | Where Profit -lt 0 | Sort-Object { ($_ | Measure Profit -Sum).Sum } -Descending | Select -First 1
        $BestMiners += $BestTypeMiners | Select -first 1
    }

    $BestMiners
}

function Global:Get-Conservative {
    if ($(arg).Conserve -eq "Yes") {
        $bestminers_combo = @()
        $(arg).Type | ForEach-Object {
            $SelType = $_
            $ConserveArray = @()
            $ConserveArray += $(vars).Miners_Combo | Where-Object Type -EQ $SelType | Where-Object Profit -EQ $NULL
            $ConserveArray += $(vars).Miners_Combo | Where-Object Type -EQ $SelType | Where-Object Profit -GT 0
        }
        $bestminers_combo += $ConserveArray
    }
    else { $bestminers_combo = $(vars).Miners_Combo }
    $bestminers_combo
}