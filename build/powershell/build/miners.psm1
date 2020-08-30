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
function Global:Get-minerfiles {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Types
    )
 
    $miner_update = [PSCustomObject]@{ }

    switch ($Types) {
        "CPU" {
            if ($(arg).Platform -eq "linux") { $(arg).Update = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json }
            elseif ($(arg).Platform -eq "windows") { $(arg).Update = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json }
        }

        "NVIDIA" {
            if ($(arg).Platform -eq "linux") {
                $(arg).Update = Get-Content ".\config\update\nvidia-linux.json" | ConvertFrom-Json
            }
            elseif ($(arg).Platform -eq "windows") { $(arg).Update = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json }
        }

        "AMD" {
            if ($(arg).Platform -eq "linux") { $(arg).Update = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json }
            elseif ($(arg).Platform -eq "windows") { $(arg).Update = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json }
        }
    }

    $(arg).Update | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { if ($_ -ne "name") { $miner_update | Add-Member $(arg).Update.$_.Name $(arg).Update.$_ } }

    $miner_update

}
