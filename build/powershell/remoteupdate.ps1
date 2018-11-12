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
$PreviousVersions += "SWARM.1.7.0"
$PreviousVersions += "SWARM.1.7.1"
$PreviousVersions += "SWARM.1.7.2"

$PreviousVersions | foreach {
  $PreviousPath = Join-Path "/hive/custom" "$_"
   if(Test-Path $PreviousPath)
    {
     Write-Host "Detected Previous Version"
     Write-Host "Previous Version is $($PreviousPath)"
     Write-Host "Gathering Old Version Config And HashRates- Then Deleting"
     Start-Sleep -S 5
     $OldBackup = Join-Path $PreviousPath "backup"
     $OldTime = Join-Path $PreviousPath "build\data"
     $OldConfig = Join-Path $PreviousPath "config"
     $OldTimeout = Join-Path $PreviousPath "timeout"
      if(-not (Test-Path "backup")){New-Item "backup" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "stats")){New-Item "stats" -ItemType "directory"  | Out-Null }
      if(Test-Path $OldBackup)
       {
        Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\stats"
        Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\backup"
       }
      if(Test-Path $OldTime){Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\build\data"}
       if(Test-Path $OldTimeout)
       {
        if(-not (Test-Path ".\timeout")){New-Item "timeout" -ItemType "directory" | Out-Null }
        if(-not (Test-Path ".\timeout\algo_block")){New-Item ".\timeout\algo_block" -ItemType "directory" | Out-Null }
        if(-not (Test-Path ".\timeout\pool_block")){New-Item ".\timeout\pool_block" -ItemType "directory" | Out-Null }
        if(Test-Path "$OldTimeout\algo_block"){Get-ChildItem -Path "$($OldTimeout)\algo_block" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\timeout\algo_block"}
        if(Test-Path "$OldTimeout\algo_block"){Get-ChildItem -Path "$($OldTimeout)\pool_block" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\timeout\pool_block"}
        Get-ChildItem -Path "$($OldTimeout)\*" -Include *.txt | Copy-Item -Destination ".\timeout"
       }
      $Jsons = @("miners","naming","oc","power")
      $UpdateType = @("CPU","AMD1","NVIDIA1","NVIDIA2","NVIDIA3")
      $Jsons | foreach {
        $OldJson_Path = Join-Path $OldConfig "$($_)";
        $NewJson_Path = Join-Path ".\config" "$($_)";
        $GetOld_Json =  Get-ChildItem $OldJson_Path;
        $GetOld_Json = $GetOld_Json.Name
        $GetOld_Json | foreach {
         $ChangeFile = $_
         $OldJson = Join-Path $OldJson_Path "$ChangeFile";
         $NewJson = Join-Path $NewJson_Path "$ChangeFile";
         if($ChangeFile -notlike "sample.json*")
         {
         $JsonData = Get-Content $OldJson;
         Write-Host "Pulled $OldJson"
         $Data = $JsonData | ConvertFrom-Json;
         if($ChangeFile -eq "cryptodredge.json")
          {
          $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
          $Data.$_.commands| Add-Member "hmq1725" ""
          $Data.$_.difficulty | Add-Member "hmq1725" ""
          $Data.$_.naming | Add-Member "hmq1725" "hmq1725"
          $Data.$_.oc | Add-Member "hmq1725" @{Power=""; Core=""; Memory=""}
           }
         }
         if($ChangeFile -eq "wildrig.json")
          {
          $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
          $Data.$_.commands| Add-Member "polytimos" ""
          $Data.$_.difficulty | Add-Member "polytimos" ""
          $Data.$_.naming | Add-Member "polytimos" "polytimos"
          $Data.$_.oc | Add-Member "polytimos" @{Power=""; Core=""; Memory=""}
           }
         }
         if($ChangeFile -eq "sgminer-kl.json")
          {
          $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
          $Data.$_.commands| Add-Member "skunk" ""
          $Data.$_.difficulty | Add-Member "skunk" ""
          $Data.$_.naming | Add-Member "skunk" "skunk"
          $Data.$_.oc | Add-Member "skunk" @{Power=""; Core=""; Memory=""}
           }
         }
         if($Data.AMD1.oc)
         {
          $Data.AMD1.oc | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Foreach{
           $Data.AMD1.oc.$_ | Add-Member "fans" ""
          }
         }
         if($Data.default_AMD1)
         {
           $Data.default_AMD1 | Add-Member "fans" ""
         }
         $UpdateType | foreach {
          if($Data.$_)
          {
           $Data.$_ | Add-Member "delay" "1"
          }
         }
         $Data | ConvertTo-Json -Depth 3 | Set-Content $NewJson;
         Write-Host "Wrote To $NewJson"
          }
         }
        }
       Remove-Item $PreviousPath -recurse -force
     }
    }
   }
  }