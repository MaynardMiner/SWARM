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

param (
    [Parameter(Position = 0, Mandatory = $true)]
    [int]$Port
)

$GETPID = Get-Content ".\build\pid\miner_pid.txt"
$SWARM = Get-Process -ID $GETPID

While ($true) {
    if ($SWARM.HasExited) {
        try {Invoke-RestMethod "http://localhost:$Port/end" -UseBasicParsing -TimeoutSec 5}catch {}
        exit
    }
    Start-Sleep -S 1
}