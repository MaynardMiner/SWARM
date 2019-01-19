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
$Get = @()
Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))
Write-Host "Moving Default Watt File Content To Current Power.Json file"
$Get += "Moving Default Watt File Content To Current Power.Json file"
if(Test-Path ".\build\data\reset.json"){$Defaults = Get-Content ".\build\data\reset.json"}
if(Test-Path ".\config\power\power.json"){$Defaults | Set-Content ".\config\power\power.json"}
Write-Host "Cleared All Profit Stats" -Foreground Green
$Get += "Cleared All Profit Stats"
$Get | Set-Content ".\build\txt\get.txt"
