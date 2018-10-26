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
$PreviousVersions += "SWARM.1.6.3"
$PreviousVersions += "SWARM.1.6.4"

$Exclude = @("TRex-1.ps1","TRex-2.ps1","TRex-3.ps1","WildRig-1.ps1")

$PreviousVersions | foreach {
  $PreviousPath = Join-Path "/hive/custom" "$_"
   if(Test-Path $PreviousPath)
    {
     Write-Host "Detected Previous Version"
     Write-Host "Previous Version is $($PreviousPath)"
     Write-Host "Gathering Old Version Config And HashRates- Then Deleting"
     Start-Sleep -S 5
     $OldBackup = Join-Path $PreviousPath "backup"
     $OldMiners = Join-Path $PreviousPath "miners\linux"
     $OldTime = Join-Path $PreviousPath "build\data"
     $OldConfig = Join-Path $PreviousPath "config"
     $OldTimeout = Join-Path $PreviousPath "timeout"
      if(-not (Test-Path "backup")){New-Item "backup" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "stats")){New-Item "stats" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "miners")){New-Item "miners" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "miners\linux")){New-Item "miners\linux" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "config")){New-Item "config" -ItemType "directory"  | Out-Null }
      if(Test-Path $OldMiners){Get-ChildItem -Path "$($OldMiners)\*" -Include *.ps1 -Exclude $Exclude -Recurse | Copy-Item -Destination ".\miners\linux" -Force}
      if(Test-Path $OldBackup)
       {
        Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\stats"
        Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\backup"
       }
      if(Test-Path $OldTime){Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\build\data"}
      if(Test-Path $OldConfig)
       {
        Get-ChildItem -Path "$($OldConfig)\oc" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\config\oc" -Force
        Get-ChildItem -Path "$($OldConfig)\power" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\config\power" -Force
       }
       if(Test-Path $OldTimeout)
       {
        if(-not (Test-Path ".\timeout")){New-Item "timeout" -ItemType "directory" | Out-Null }
        if(-not (Test-Path ".\timeout\algo_block")){New-Item ".\timeout\algo_block" -ItemType "directory" | Out-Null }
        if(-not (Test-Path ".\timeout\pool_block")){New-Item ".\timeout\pool_block" -ItemType "directory" | Out-Null }
        if(Test-Path "$OldTimeout\algo_block"){Get-ChildItem -Path "$($OldTimeout)\algo_block" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\timeout\algo_block"}
        if(Test-Path "$OldTimeout\algo_block"){Get-ChildItem -Path "$($OldTimeout)\pool_block" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\timeout\pool_block"}
        Get-ChildItem -Path "$($OldTimeout)\*" -Include *.txt | Copy-Item -Destination ".\timeout"
       }
       Remove-Item $PreviousPath -recurse -force
     }
   }
  }
}