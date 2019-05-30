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
    [Parameter(Mandatory = $false)]
    [String]$Type,
    [Parameter(Mandatory = $false)]
    [String]$Platform
)
[cultureinfo]::CurrentCulture = 'en-US'
Set-Location (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
if (Test-Path ".\logs\$($Type).log") {$Log = Get-Content ".\logs\$($Type).log"}
if ($Type -eq "miner") {if (Test-Path ".\logs\*active*") {$Log = Get-Content ".\logs\*active.log*"}}
$Log | Select -Last 300
if ($global:Config.Params.Platform -eq "windows") {$Log | Out-File ".\build\txt\logcom.txt"}
     