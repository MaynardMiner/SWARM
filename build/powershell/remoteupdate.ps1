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
    [String]$Update,
    [Parameter(Mandatory=$true)]
    [String]$Dir,
    [Parameter(Mandatory=$true)]
    [String]$Platforms
)

$Location = split-Path $Dir
$StartUpdate = $True
if($Platforms -eq "linux" -and $Update -eq "No"){$StartUpdate = $false}

if($StartUpdate -eq $true)
{
$PreviousVersions = @()
$PreviousVersions += "SWARM.1.7.6"
$PreviousVersions += "SWARM.1.7.7"
$PreviousVersions += "SWARM.1.7.8"
$PreviousVersions += "SWARM.1.7.9"
$PreviousVersions += "SWARM.1.8.0"
$PreviousVersions += "SWARM.1.8.1"
$PreviousVersions += "SWARM.1.8.2"
$PreviousVersions += "SWARM.1.8.3"
$PreviousVersions += "SWARM.1.8.4"
$PreviousVersions += "SWARM.1.8.5"
$PreviousVersions += "SWARM.1.8.6"
$PreviousVersions += "SWARM.1.8.7"
$PreviousVersions += "SWARM.1.8.8"
$PreviousVersions += "SWARM.1.8.9"
$PreviousVersions += "SWARM.1.9.0"
$PreviousVersions += "SWARM.1.9.1"
$PreviousVersions += "SWARM.1.9.2"

Write-Host "User Specfied Updates: Searching For Previous Version" -ForegroundColor Yellow
Write-Host "Check $Location For any Previous Versions"

$PreviousVersions | foreach {
  $PreviousPath = Join-Path "$Location" "$_"
   if(Test-Path $PreviousPath)
    {
     Write-Host "Detected Previous Version"
     Write-Host "Previous Version is $($PreviousPath)"
     Write-Host "Gathering Old Version Config And HashRates- Then Deleting"
     Start-Sleep -S 10
     $ID = ".\build\pid\background_pid.txt"
     if($Platforms -eq "windows"){Start-Sleep -S 10}
     if($Platforms -eq "windows")
     {
     Write-Host "Stopping Previous Agent"
     if(Test-Path $ID){$Agent = Get-Content $ID}
     if($Agent){$BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue}
     if($BackGroundID.name -eq "powershell"){Stop-Process $BackGroundID | Out-Null}
     }
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
      #if(Test-Path $OldTime){Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\build\data"}
       if(Test-Path $OldTimeout)
       {
        if(-not (Test-Path ".\timeout")){New-Item "timeout" -ItemType "directory" | Out-Null }
        if(-not (Test-Path ".\timeout\algo_block")){New-Item ".\timeout\algo_block" -ItemType "directory" | Out-Null }
        if(-not (Test-Path ".\timeout\pool_block")){New-Item ".\timeout\pool_block" -ItemType "directory" | Out-Null }
        if(Test-Path "$OldTimeout\algo_block"){Get-ChildItem -Path "$($OldTimeout)\algo_block" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\timeout\algo_block"}
        if(Test-Path "$OldTimeout\algo_block"){Get-ChildItem -Path "$($OldTimeout)\pool_block" -Include *.txt,*.conf -Recurse | Copy-Item -Destination ".\timeout\pool_block"}
        Get-ChildItem -Path "$($OldTimeout)\*" -Include *.txt | Copy-Item -Destination ".\timeout"
       }
      $Jsons = @("miners","oc","power")
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
         if($ChangeFile -ne "new_sample.json" -and $ChangeFile -ne "sgminer-kl.json" -and $ChangeFile -ne "vega-oc.json")
         {
         $JsonData = Get-Content $OldJson;
         Write-Host "Pulled $OldJson"
         $Data = $JsonData | ConvertFrom-Json;
         if($ChangeFile -eq "cryptodredge.json")
          {
          $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
          if($_ -ne "name")
          {
          $Data.$_.commands = $Data.$_.commands | Select -ExcludeProperty "blake2s","exosis","lbk3","Lyra2REv2","lyra2v2","polytimos","skein","lyra2vc0banhash"
          $Data.$_.difficulty = $Data.$_.difficulty | Select -ExcludeProperty "blake2s","exosis","lbk3","Lyra2REv2","lyra2v2","polytimos","skein","lyra2vc0banhash"
          $Data.$_.naming = $Data.$_.naming | Select -ExcludeProperty "blake2s","exosis","lbk3","Lyra2REv2","lyra2v2","polytimos","skein","lyra2vc0banhash"
          $Data.$_.oc = $Data.$_.oc | Select -ExcludeProperty "blake2s","exosis","lbk3","Lyra2REv2","lyra2v2","polytimos","skein","lyra2vc0banhash"
        
          $Data.$_.commands| Add-Member "hmq1725" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "hmq1725" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "hmq1725" "hmq1725" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "hmq1725" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "x21s" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "x21s" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "x21s" "x21s" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "x21s" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "lyra2vc0ban" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "lyra2vc0ban" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "lyra2vc0ban" "lyra2vc0ban" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "lyra2vc0ban" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "lyra2v3" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "lyra2v3" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "lyra2v3" "Lyra2REv3" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "lyra2v3" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "lyra2v3" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "lyra2v3" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "lyra2v3" "lyra2rev3" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "lyra2v3" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         

          $Data.$_.commands| Add-Member "mtp" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "mtp" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "mtp" "mtp" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "mtp" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "x16rt" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "x16rt" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "x16rt" "x16rt" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "x16rt" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "lyra2zz" "" -ErrorAction SilentlyContinue -Force
          $Data.$_.difficulty | Add-Member "lyra2zz" "" -ErrorAction SilentlyContinue -Force
          $Data.$_.naming | Add-Member "lyra2zz" "lyra2zz" -ErrorAction SilentlyContinue -Force
          $Data.$_.oc | Add-Member "lyra2zz" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue -Force

          $Data.$_.commands| Add-Member "cnfastv2" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "cnfastv2" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "cnfastv2" "cnfastv2" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "cnfastv2" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "cnsuperfast" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "cnsuperfast" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "cnsuperfast" "cnsuperfast" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "cnsuperfast" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue
            }  
           }
         }
         if($ChangeFile -eq "lolminer.json")
         {
          $Data.$_.commands| Add-Member "equihash192" "--coin AUTO192_7" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "equihash192" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "equihash192" "equihash192" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "equihash192" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         
         }
         if($ChangeFile -eq "t-rex.json")
          {
          $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {
          $Data.$_.commands| Add-Member "dedal" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "dedal" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "dedal" "dedal" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "dedal" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "x21s" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "x21s" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "x21s" "x21s" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "x21s" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "x16rt" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "x16rt" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "x16rt" "x16rt" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "x16rt" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "sha256q" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "sha256q" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "sha256q" "sha256q" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "sha256q" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue
          
          $Data.$_.commands| Add-Member "astralhash" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "astralhash" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "astralhash" "astralhash" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "astralhash" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "padihash" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "padihash" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "padihash" "padihash" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "padihash" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "jeonghash" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "jeonghash" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "jeonghash" "jeonghash" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "jeonghash" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "pawelhash" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "pawelhash" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "pawelhash" "pawelhash" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "pawelhash" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue
           }
          }
         }
         if($ChangeFile -eq "wildrig.json")
          {
          $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {
          $Data.$_.commands| Add-Member "polytimos" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "polytimos" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "polytimos" "polytimos" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "polytimos" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         

          $Data.$_.commands| Add-Member "dedal" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "dedal" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "dedal" "dedal" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "dedal" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "x18" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "x18" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "x18" "x18" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "x18" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "x21s" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "x21s" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "x21s" "x21s" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "x21s" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "exosis" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "exosis" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "exosis" "exosis" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "exosis" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "lyra2v3" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "lyra2v3" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "lyra2v3" "lyra2v3" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "lyra2v3" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue          

          $Data.$_.commands| Add-Member "sha256q" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "sha256q" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "sha256q" "sha256q" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "sha256q" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue                    

          $Data.$_.commands| Add-Member "x16rt" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "x16rt" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "x16rt" "x16rt" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "x16rt" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue                    

          $Data.$_.commands| Add-Member "mtp" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "mtp" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "mtp" "mtp" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "mtp" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue
          
          $Data.$_.commands| Add-Member "astralhash" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "astralhash" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "astralhash" "glt-astralhash" -ErrorAction SilentlyContinue -Force
          $Data.$_.oc | Add-Member "astralhash" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "padihash" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "padihash" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "padihash" "glt-padihash" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "padihash" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "jeonghash" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "jeonghash" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "jeonghash" "glt-jeonghash" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "jeonghash" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

          $Data.$_.commands| Add-Member "pawelhash" "" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "pawelhash" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "pawelhash" "glt-pawelhash" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "pawelhash" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

          ## Temp remove these algos
          $Data.$_.commands = $Data.$_.commands | Select -ExcludeProperty "mtp"
          $Data.$_.difficulty = $Data.$_.difficulty | Select -ExcludeProperty "mtp"
          $Data.$_.naming = $Data.$_.naming | Select -ExcludeProperty "mtp"
          $Data.$_.oc = $Data.$_.oc | Select -ExcludeProperty "mtp"
            }
           }
          }
          if($ChangeFile -eq "bminer.json")
          {
            $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {      
            $Data.$_.commands| Add-Member "equihash144" "-pers auto" -ErrorAction SilentlyContinue
            $Data.$_.difficulty | Add-Member "equihash144" "" -ErrorAction SilentlyContinue
            $Data.$_.naming | Add-Member "equihash144" "equihash1445" -ErrorAction SilentlyContinue
            $Data.$_.oc | Add-Member "equihash144" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue  

            $Data.$_.commands| Add-Member "beam" "" -ErrorAction SilentlyContinue
            $Data.$_.difficulty | Add-Member "beam" "" -ErrorAction SilentlyContinue
            $Data.$_.naming | Add-Member "beam" "beam" -ErrorAction SilentlyContinue
            $Data.$_.oc | Add-Member "beam" @{Power=""; Core=""; Memory=""} -ErrorAction SilentlyContinue  
            }
           }
          }
          if($ChangeFile -eq "ewbf.json")
          {
            $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {    
            $Data.$_.commands."equihash-btg" = "--algo 144_5 --pers BgoldPoW"
            $Data.$_.commands."equihash192" = "--algo 192_7 --pers auto"
            $Data.$_.commands."equihash144" = "--algo 144_5 --pers auto"
            $Data.$_.commands."equihash96" = "--algo 96_5 --pers auto"
            $Data.$_.commands."equihash210" = "--algo 210_9 --pers auto"
            $Data.$_.commands."equihash200" = "--algo 200_9 --pers auto"
            $Data.$_.commands."zhash" = "--algo 144_5 --pers auto"
            }
           }
          }
          if($ChangeFile -eq "zjazz.json")
          {
            $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {    
            $Data.$_.naming."cuckoo" = "bitcash"
            }
           }
          }
          if($ChangeFile -eq "claymore.json")
          {
            $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {    
            $Data.$_.commands."ethash" = ""
            }
           }
          }
          if($ChangeFile -eq "claymore_amd.json")
          {
            $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {    
            $Data.$_.commands."ethash" = ""
            $Data.$_.prestart = @("export GPU_MAX_HEAP_SIZE=100", "export GPU_USE_SYNC_OBJECTS=1", "export GPU_SINGLE_ALLOC_PERCENT=100", "export GPU_MAX_ALLOC_PERCENT=100")
            }
           }
          }
          if($ChangeFile -eq "phoenix.json")
          {
            $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {    
            $Data.$_.commands."ethash" = ""
            }
           }
          }
          if($ChangeFile -eq "phoenix_amd.json")
          {
            $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {    
            $Data.$_.commands."ethash" = ""
            $Data.$_.prestart = @("export GPU_MAX_HEAP_SIZE=100", "export GPU_USE_SYNC_OBJECTS=1", "export GPU_SINGLE_ALLOC_PERCENT=100", "export GPU_MAX_ALLOC_PERCENT=100")
            }
           }
          }
          if($ChangeFile -eq "gminer.json")
          {
            $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
            if($_ -ne "name")
            {    
            $Data.$_.commands."equihash-btg" = "--algo 144_5 --pers BgoldPoW"
            $Data.$_.commands."equihash192" = "--algo 192_7 --pers auto"
            $Data.$_.commands."equihash144" = "--algo 144_5 --pers auto"
            $Data.$_.commands."equihash96" = "--algo 96_5 --pers auto"
            $Data.$_.commands."equihash210" = "--algo 210_9 --pers auto"
            $Data.$_.commands."equihash200" = "--algo 200_9 --pers auto"
            $Data.$_.commands."zhash" = "--algo 144_5 --pers auto"
            }
           }
          }
          if($ChangeFile -eq "miniz.json")
          {
           $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
           if($_ -ne "name")
           {
            $Data.$_.commands = $Data.$_.commands | Select -ExcludeProperty "equihash192","equihash196"
            $Data.$_.difficulty = $Data.$_.difficulty | Select -ExcludeProperty "equihash192","equihash196"
            $Data.$_.naming = $Data.$_.naming | Select -ExcludeProperty "equihash192","equihash196"
            $Data.$_.oc = $Data.$_.oc | Select -ExcludeProperty "equihash192","equihash196"
            $Data.$_.commands."equihash-btg" = "--par=144,5 --pers BgoldPoW"
            $Data.$_.commands."equihash144" = "--par=144,5 --pers auto"
            $Data.$_.commands."equihash210" = "--par=210,9 --pers auto"
            $Data.$_.commands."equihash200" = "--par=200,9 --pers auto"
            $Data.$_.commands."zhash" = "--par=144,5 --pers auto"       
            }
           }
          }
          if($ChangeFile -eq "fancyix.json")
          {
          $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
          if($_ -ne "name")
           {
            $Data.$_.commands| Add-Member "x22i" "-w 256 -I 22" -ErrorAction SilentlyContinue -Force
            $Data.$_.difficulty | Add-Member "x22i" "" -ErrorAction SilentlyContinue -Force
            $Data.$_.naming | Add-Member "x22i" "x22i" -ErrorAction SilentlyContinue -Force
            $Data.$_.oc | Add-Member "x22i" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue

            $Data.$_.commands| Add-Member "lyra2z" "-w 256 -I 22" -ErrorAction SilentlyContinue -Force
            $Data.$_.difficulty | Add-Member "lyra2z" "" -ErrorAction SilentlyContinue
            $Data.$_.naming | Add-Member "lyra2z" "lyra2z" -ErrorAction SilentlyContinue
            $Data.$_.oc | Add-Member "lyra2z" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         

            $Data.$_.commands| Add-Member "phi2" "-w 256 -I 22" -ErrorAction SilentlyContinue -Force
            $Data.$_.difficulty | Add-Member "phi2" "" -ErrorAction SilentlyContinue
            $Data.$_.naming | Add-Member "phi2" "phi2" -ErrorAction SilentlyContinue
            $Data.$_.oc | Add-Member "phi2" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         

            $Data.$_.commands| Add-Member "allium" "-w 256 -I 22" -ErrorAction SilentlyContinue -Force
            $Data.$_.difficulty | Add-Member "allium" "" -ErrorAction SilentlyContinue
            $Data.$_.naming | Add-Member "allium" "allium" -ErrorAction SilentlyContinue
            $Data.$_.oc | Add-Member "allium" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         
        
          $Data.$_.commands| Add-Member "lyra2rev3" "-w 256 -I 24" -ErrorAction SilentlyContinue -Force
          $Data.$_.difficulty | Add-Member "lyra2rev3" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "lyra2rev3" "lyra2rev3" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "lyra2rev3" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         

          $Data.$_.commands| Add-Member "lyra2v3" "-I 24 -w 256" -ErrorAction SilentlyContinue -Force
          $Data.$_.difficulty | Add-Member "lyra2v3" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "lyra2v3" "lyra2rev3" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "lyra2v3" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         

          $Data.$_.commands| Add-Member "argon2d" "-w 64 -g 2" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "argon2d" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "argon2d" "argon2d" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "argon2d" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         

          $Data.$_.commands| Add-Member "mtp" "-w 256 -I 20" -ErrorAction SilentlyContinue
          $Data.$_.difficulty | Add-Member "mtp" "" -ErrorAction SilentlyContinue
          $Data.$_.naming | Add-Member "mtp" "mtp" -ErrorAction SilentlyContinue
          $Data.$_.oc | Add-Member "mtp" @{dpm=""; v=""; core=""; mem=""; mdpm=""; fans=""} -ErrorAction SilentlyContinue         
            }
           }
          }
         if($Data.AMD1.oc)
         {
          $Data.AMD1.oc | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Foreach{
           $Data.AMD1.oc.$_ | Add-Member "fans" "" -ErrorAction SilentlyContinue
          }
         }
         if($Data.default_AMD1)
         {
           $Data.default_AMD1 | Add-Member "fans" "" -ErrorAction SilentlyContinue
         }
         $UpdateType | foreach {
          if($Data.$_)
          {
           $Data.$_ | Add-Member "delay" "1" -ErrorAction SilentlyContinue
          }
         }
         $Data | ConvertTo-Json -Depth 3 | Set-Content $NewJson;
         Write-Host "Wrote To $NewJson"
          }
         }
        }
          $NameJson_Path = Join-Path ".\config" "miners";
          $GetOld_Json =  Get-ChildItem $NameJson_Path;
          $GetOld_Json = $GetOld_Json.Name
          $GetOld_Json | foreach {
          $ChangeFile = $_
          $NewName = $ChangeFile -Replace ".json","";
          $NameJson = Join-Path ".\config\miners" "$ChangeFile";
          $JsonData = Get-Content $NameJson;
          Write-Host "Pulled $NameJson"
          $Data = $JsonData | ConvertFrom-Json;
          $Data | Add-Member "name" "$NewName" -ErrorAction SilentlyContinue
          $Data | ConvertTo-Json -Depth 3 | Set-Content $NameJson;
          Write-Host "Wrote To $NameJson"
          }
       Remove-Item $PreviousPath -recurse -force
     }
    }
   }
  }
