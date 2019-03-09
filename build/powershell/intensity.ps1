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
function Get-Intensity {
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [String]$LogMiner,
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$LogAlgo,
        [Parameter(Position = 2, Mandatory = $false)]
        [String]$LogPath
    )

    $ParseLog = ".\logs\$($LogMiner).log"
    if (Test-Path $ParseLog) {
        $GetInfo = Get-Content $ParseLog
        $GetIntensity = $GetInfo | Select-String "intensity"
        $GetDifficulty = $GetInfo | Select-String "difficulty"
        $NotePath = Split-Path $LogPath
        if ($GetIntensity) {$GetIntensity | Set-Content "$NotePath\$($LogAlgo)_intensity.txt"}
        if ($GetDifficulty) {$GetDifficulty | Set-Content "$NotePath\$($LogAlgo)_difficulty.txt"}
    }
}