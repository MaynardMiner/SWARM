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
    if ($(arg).Threshold -ne 0) {
        $(vars).Miners | Foreach-Object { 
            if ($_.Profit -gt $(arg).Threshold) { 
                $BadMiners += $_ 
                $(vars).Thresholds += "$($_.Name) mining $($_.Algo) was removed this run: Profit/Day above $($(arg).Threshold) BTC"
            }
        } 
    }
    $BadMiners | Foreach-Object { $(vars).Miners.Remove($_) }
}

function Global:Get-BestMiners {
    $BestMiners = @()
    $trigger = $False;
    $(arg).Type | Foreach-Object {
        $SelType = $_
        $BestTypeMiners = @()
        $OldMiners = @()
        $OldTypeMiners = @()
        $MinerCombo = @()

        $TypeMiners = $(vars).Miners | Where-Object Type -EQ $SelType
        $(vars).BestActiveMiners | Foreach-Object { $(vars).Miners | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments | Where-Object Type -EQ $SelType | Foreach-Object { $OldMiners += $_ } }
        if ($OldMiners) {
            $OldTypeMiners += $OldMiners | Where-Object Profit -gt 0 | Sort-Object @{Expression = "Profit"; Descending = $true } | Select-Object -First 1
            $OldTypeMiners += $OldMiners | Where-Object Profit -lt 0 | Sort-Object @{Expression = "Profit"; Descending = $false } | Select-Object -First 1
            $OldTypeMiners = $OldTypeMiners | Select-Object -First 1
            $OldTypeMiners | Foreach-Object { $_ | Add-Member "Old" "Yes" }
        }
        if ($OldTypeMiners) { $MinerCombo += $OldTypeMiners }
        if ($(vars).switch -eq $true) {
            $MinerCombo += $TypeMiners | Where-Object Profit -NE $NULL
            $BestTypeMiners += $TypeMiners | Where-Object Profit -EQ $NULL | Select-Object -First 1
            $BestTypeMiners += $MinerCombo | Where-Object Profit -NE $Null | Where-Object Profit -gt 0 | Sort-Object { ($_ | Measure-Object Profit -Sum).Sum } -Descending | Select-Object -First 1
            $BestTypeMiners += $MinerCombo | Where-Object Profit -NE $Null | Where-Object Profit -lt 0 | Sort-Object { ($_ | Measure-Object Profit -Sum).Sum } -Descending | Select-Object -First 1
            $BestMiners += $BestTypeMiners | Select-Object -first 1
            $trigger = $true
        }
        else {
            log "Interval has not elapsed since last sort- Using Same Miner for $_ If Pool Had Data" -Foreground Cyan
            if($OldTypeMiners) {
                $BestMiners += $OldTypeMiners
            } else {
                $MinerCombo += $TypeMiners | Where-Object Profit -NE $NULL
                $BestTypeMiners += $TypeMiners | Where-Object Profit -EQ $NULL | Select-Object -First 1
                $BestTypeMiners += $MinerCombo | Where-Object Profit -NE $Null | Where-Object Profit -gt 0 | Sort-Object { ($_ | Measure-Object Profit -Sum).Sum } -Descending | Select-Object -First 1
                $BestTypeMiners += $MinerCombo | Where-Object Profit -NE $Null | Where-Object Profit -lt 0 | Sort-Object { ($_ | Measure-Object Profit -Sum).Sum } -Descending | Select-Object -First 1
                $BestMiners += $BestTypeMiners | Select-Object -first 1    
            }
        }
    }
    if($trigger){$(vars).switch = $False}
    $BestMiners
}

function Global:Get-Conservative {
    if ($(arg).Conserve -eq "Yes") {
        $bestminers_combo = @()
        $(arg).Type | Foreach-Object {
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