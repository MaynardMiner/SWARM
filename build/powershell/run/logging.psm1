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

function Global:Update-Log {
    $Global:log_params.lognum++
    ## When we have looped 288 times, we have reached a full day of logs.
    if($Global:log_params.lognum -gt 288) {
        $LogName = Get-Date -Format "HH_mm__dd__MM__yyyy"
        $Global:log_params.logname = Join-Path $($(vars).dir) "logs\swarm_$LogName.log"
        $Global:log_params.lognum = 1
    }
}
