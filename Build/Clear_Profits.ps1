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

$CmdDir = (Split-Path $script:MyInvocation.MyCommand.Path)
$Dir = Split-Path $CmdDir
Set-Location $Dir
Write-Host "Gathering All Profit Stats"
if(Test-Path ".\Stats\*Profit.txt*"){Remove-Item ".\Stats\*Profit.txt*" -Force}
Write-Host "Cleared All Profit Stats" -Foreground Green
