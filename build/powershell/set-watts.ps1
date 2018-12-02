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
        [Parameter(Position=0,Mandatory=$true)]
        [String]$Miner,
        [Parameter(Position=1,Mandatory=$true)]
        [String]$Algorithm,
        [Parameter(Position=2,Mandatory=$true)]
        [String]$Watts
        )

Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))
. .\build\powershell\statcommand.ps1

$Message = "Searching For $Algorithm files"
Write-Host "Message"
$Message | Set-Content ".\build\txt\WattCom.txt"

$WattStats = Get-ChildItem Content