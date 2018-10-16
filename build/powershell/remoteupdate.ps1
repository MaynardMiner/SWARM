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

function start-update {
param (
    [Parameter(Mandatory=$true)]
    [String]$Update
)

if($Update -eq "Yes")
 {
$PreviousVersions = @()
$PreviousVersions += "MM.Hash.1.4.6b"
$PreviousVersions += "SWARM.1.4.7b"
$PreviousVersions += "SWARM.1.4.9b"
$PreviousVersions += "SWARM.1.5.0b"
$PreviousVersions += "SWARM.1.5.1b"

$PreviousVersions | foreach {
  $PreviousPath = Join-Path "/hive/custom" "$_"
   if(Test-Path $PreviousPath)
    {
     Write-Host "Previous Version is $($PreviousPath)"
     Write-Host "Deleting Old Version"
     Start-Sleep -S 5
     $OldBackup = Join-Path $PreviousPath "backup"
     $OldMiners = Join-Path $PreviousPath "miners\unix"
     $OldTime = Join-Path $PreviousPath "build\data"
     $OldConfig = Join-Path $PreviousPath "config"
      if(-not (Test-Path "backup")){New-Item "backup" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "stats")){New-Item "stats" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "miners")){New-Item "miners" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "miners\unix")){New-Item "miners\unix" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "config")){New-Item "config" -ItemType "directory"  | Out-Null }
      if(Test-Path $OldMiners){Get-ChildItem -Path "$($OldMiners)\*" -Include *.ps1 -Recurse | Copy-Item -Destination ".\miners\unix" -force}
      if(Test-Path $OldBackup)
       {
        Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\stats" -force
        Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\backup" -force
       }
      if(Test-Path $OldTime){Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\build\data" -force}
      if(Test-Path $OldConfig)
       {
        Get-ChildItem -Path "$($OldConfig)\naming" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\config\naming" -force
        Get-ChildItem -Path "$($OldConfig)\oc" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\config\oc" -force
        Get-ChildItem -Path "$($OldConfig)\power" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\config\power" -force
       }
       Remove-Item $PreviousPath -recurse -force
     }
   }
  }
}