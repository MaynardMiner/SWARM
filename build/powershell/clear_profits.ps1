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
Write-Host "Gathering All Profit Stats"
$Get += "Gathering All Profit Stats"
if (Test-Path ".\stats\*profit.txt*") {Remove-Item ".\stats\*profit.txt*" -Force}
Write-Host "Cleared All Profit Stats" -Foreground Green
$Get += "Cleared All Profit Stats"
$Get | Set-Content ".\build\txt\get.txt"
