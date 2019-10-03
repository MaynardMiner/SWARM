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

function Global:start-log {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Number
    )
    #Start the log
    if (-not (Test-Path "logs")) {New-Item "logs" -ItemType "directory" | Out-Null; Start-Sleep -S 1}
    if (Test-Path ".\logs\*active*") {
        $OldActiveFile = Get-ChildItem ".\logs" -Force | Where BaseName -like "*active*"
        $OldActiveFile | ForEach-Object {
            $RenameActive = ".\logs\$($_.Name)" -replace ("-active", "")
            if (Test-Path $RenameActive) {Remove-Item $RenameActive -Force}
            Move-Item ".\logs\$($_.Name)" $RenameActive -force
        }
    }
    $Global:log_params.logname = Join-Path $($(vars).dir) "logs\miner$($Number)-active.log"
}
