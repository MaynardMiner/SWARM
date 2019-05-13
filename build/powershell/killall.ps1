
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
function start-killscript {

    ##Clear-Screens In Case Of Restart
    $OpenScreens = @()
    $OpenScreens += "NVIDIA1"
    $OpenScreens += "NVIDIA2"
    $OpenScreens += "NVIDIA3"
    $OpenScreens += "AMD1"
    $OpenScreens += "AMD2"
    $OpenScreens += "AMD3"
    $OpenScreens += "CPU"
    $OpenScreens += "ASIC"
    $OpenScreens += "background"
    $OpenScreens += "OC_AMD"
    $OpenScreens += "OC_NVIDIA"
    $OpenScreens += "API"
    $OpenScreens | foreach {
    Start-Process ".\build\bash\killall.sh" -ArgumentList $_ -Wait
    }
}