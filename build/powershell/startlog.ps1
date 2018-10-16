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

function start-log {
#Start the log
$Log = 1
if(-not (Test-Path "logs")){New-Item "logs" -ItemType "directory" | Out-Null; Start-Sleep -S 1}
if(Test-Path ".\logs\*active*")
{
 Set-Location ".\logs"
 $OldActiveFile = Get-ChildItem "*active*" -Force
 $OldActiveFile | Foreach {
  $RenameActive = $_ -replace ("-active","")
  if(Test-Path $RenameActive){Remove-Item $RenameActive -Force}
  Rename-Item $_ -NewName $RenameActive -force
  } 
 Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
}
Set-Location ".\logs"
Start-Transcript "miner$($Log)-active.log"
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
}