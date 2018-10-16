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

param(
    [parameter(Position=0,Mandatory=$true)]
    [String]$Name
    [parameter(Position=1,Mandatory=$false)]
    [String]$Platform
)
Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))
Write-Host "Checking For $Name Bechmarks"
if($Platform -eq "windows"){"Removed Hashrate files" | Out-File ".\build\txt\benchcom.txt"}
if(Test-Path ".\stats\*$($Name)_hashrate.txt*"){Remove-Item ".\stats\*$($Name)_hashrate.txt*" -Force}
if(Test-Path ".\stats\*$($Name)_power.txt*"){Remove-Item ".\stats\*$($Name)_power.txt*" -Force}
Write-Host "Removed Hashrate files"
if($Platform -eq "windows"){"Removed Hashrate files" | Out-File ".\build\txt\benchcom.txt"}
