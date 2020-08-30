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
function Global:Start-Hugepage_Check { 

    ## Run HiveOS hugepages commmand if algo is randomx
    if ($Islinux -and (test-path "/hive/bin")) { ## Is a HiveOS rig
        if (
            "randomx" -in $(vars).BestActiveMiners.Algo -and ## One of the miners is about to mine randomX
            $(vars).HugePages -eq $false ## Not set yet
        ) {
            log "Setting HiveOS hugepages for RandomX" -ForegroundColor Cyan;
            Invoke-Expression "hugepages -rx";
            $(vars).HugePages = $true;
        }

        elseif (
            "randomx" -notin $(vars).BestActiveMiners.Algo -and ## No miner is going to mine randomX
            $(vars).HugePages -eq $true ## Is set
        ) {
            log "Setting hugepages back to default" -ForegroundColor Cyan;
            Invoke-expression "hugepages -r";
            $(vars).HugePages = $false;
        }
    }
    
}