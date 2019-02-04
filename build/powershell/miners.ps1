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

function Get-minerfiles {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Types,
        [Parameter(Mandatory = $false)]
        [string]$Platforms,
        [Parameter(Mandatory = $false)]
        [string]$Cudas
    )
 
    $miner_update = [PSCustomObject]@{}

    switch ($Types) {
        "CPU" {
            if ($Platforms -eq "linux") {$update = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json}
            elseif ($Platforms -eq "windows") {$update = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json}
        }

        "NVIDIA" {
            if ($Platforms -eq "linux") {
                if ($Cudas -eq "10") {$update = Get-Content ".\config\update\nvidia10-linux.json" | ConvertFrom-Json}
                if ($Cudas -eq "9.2") {$update = Get-Content ".\config\update\nvidia9.2-linux.json" | ConvertFrom-Json}
            }
            elseif ($Platforms -eq "windows") {$update = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json}
        }

        "AMD" {
            if ($Platforms -eq "linux") {$update = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json}
            elseif ($Platforms -eq "windows") {$update = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json}
        }
    }

    $update | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {if ($_ -ne "name") {$miner_update | Add-Member $update.$_.Name $update.$_}}

    $miner_update

}