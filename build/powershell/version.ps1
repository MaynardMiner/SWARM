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
    [parameter(Position=0,Mandatory=$false)]
    [String]$Command,
    [parameter(Position=1,Mandatory=$false)]
    [String]$Name,
    [parameter(Position=2,Mandatory=$false)]
    [String]$EXE,
    [parameter(Position=3,Mandatory=$false)]
    [String]$Version,
    [parameter(Position=4,Mandatory=$false)]
    [String]$Uri,
    [parameter(Mandatory=$false)]
    [String]$Platform
)

## Set to SWARM dir
Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))
$Message = @()

if($Command -eq "!"){$Message += "No Command Given. Try version query"; Write-Host $($Message | Select -last 1)}
else{$CommandQuery = $Command -replace("!","")}
$Name = $Name -replace "!",""
$EXE = $EXE -replace "!",""
$Version = $Version -replace "!",""
$Uri = $Uri -replace "!",""

$Message += "Selected Miner Is $Name"
Write-Host $($Message | Select -last 1)
$Message += "Selected Executable Is $EXE"
Write-Host $($Message | Select -last 1)
$Message += "Selected Version Is $Version"
Write-Host $($Message | Select -last 1)
$Uri += "Selected Uri is $URI"
Write-Host $($Message | Select -last 1)

if($CommandQuery)
 {
  $Message += "Command is $CommandQuery"
  Write-Host $($Message | Select -last 1)
  $GetCuda = ".\build\txt\cuda.txt"
  if(test-path $GetCuda){$CudaVersion = Get-Content $GetCuda}
  else{$Message += "Warning: Unable to detect cuda version."; Write-Host $($Message | Select -last 1)}
  Switch($Platform)
  {
   "windows"
    {
     $miner_update_nvidia = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json
     $miner_update_amd = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json
     $miner_update_cpu = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json
    } 
   default
   {
    Switch($CudaVersion)
    {
    "9.2"
     {
      $updatecheck = ".\config\update\nvidia9.2-linux.json"
      if(Test-Path $updatecheck){$miner_update_nvidia = Get-Content $updatecheck | ConvertFrom-Json}
      else{$Message += "Warning: Cuda 9.2 update file not found"; Write-Host $($Message | Select -last 1)}
     }
    "10"
     {
      $updatecheck = ".\config\update\nvidia10-linux.json"
      if(Test-Path $updatecheck){$miner_update_nvidia = Get-Content $updatecheck | ConvertFrom-Json}
      else{$Message += "Warning: Cuda 10 update file not found"; Write-Host $($Message | Select -last 1)}
     }
    }
    $miner_update_amd = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json
    $miner_update_cpu = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json  
   }
  }

$MinerSearch = @()
$MinerSearch += $miner_update_nvidia
$MinerSearch += $miner_update_amd
$MinerSearch += $miner_update_cpu

 switch($CommandQuery)
  {
   "Update"
    {
     $Message += "Executing Command: $CommandQuery"
     Write-Host $($Message | Select -last 1)
     $Failed = $false
     $Found = $false

     $MinerSearch | %{
     $MinerType = $_
     $MinerType.PSObject.Properties.Name | %{
     if($MinerType.$_.name -eq $Name)
      {
       $Found = $true
       $UpdateFile = $MinerType.Name
       if($EXE){$MinerType.$_.minername = $EXE}
       else{$Message += "No exe supplied. Please run again."; Write-Host $($Message | Select -last 1); $Failed = $true}
       if($Version){$MinerType.$_.version = $Version}
       else{$Message += "No version supplied. Please run again."; Write-Host $($Message | Select -last 1); $Failed = $true}
       if($Uri){$MinerType.$_.uri = $Uri}
       else{$Message += "No Uri Supplied. Please run again."; Write-Host $($Message | Select -last 1); $Failed = $true}
      }
     }
    } 
    
    if($Found -eq $true -and $Failed -eq $false)
    {
     $Message += "Stopping Miner & Waiting 5 Seconds"
     Write-Host $($Message | Select -last 1)
     switch ($Platform)
      {
       "windows"
        {
         $ID = Get-Content ".\build\pid\miner_pid.txt"
         Stop-Process -Id $ID
         Start-Sleep -S 5
        }
        default
        {
         screen -S miner -X quit
         Start-Sleep -S 5
        }
      }
     $Updated = $MinerSearch | Where Name -eq $UpdateFile
     if(Test-Path $Updated.$Name.path1){Remove-Item (Split-Path $Updated.$Name.path1) -Recurse -Force}
     if(Test-Path $Updated.$Name.path2){Remove-Item (Split-Path $Updated.$Name.path2) -Recurse -Force}
     if(Test-Path $Updated.$Name.path3){Remove-Item (Split-Path $Updated.$Name.path3) -Recurse -Force}
     $Updated | ConvertTo-Json -Depth 3 | Set-Content ".\config\update\$UpdateFile.json"
     $message += "Miner New executable is $EXE"
     Write-Host $($Message | Select -last 1)
     $message += "Miner New version is $Version"
     Write-Host $($Message | Select -last 1)
     $message += "Miner New uri is $URI"
     Write-Host $($Message | Select -last 1)
     $message += "Miner Was Updated"
     Write-Host $($Message | Select -last 1)
     if($Platform -ne "windows")
     {
     if(-not (test-path "/hive/miners/custom"))
      {
       $Message += "SWARM can be restarted"
       Write-Host $($Message | Select -last 1)
      }
     else
      {
       $Message += "Restarting Swarm"
       Write-Host $($Message | Select -last 1)
       miner start
      }
     }
    }
   else{$message += "Miner update process failed. Exiting"; Write-Host $($Message | Select -last 1)}
  }

  "query"
    {
     $MinerTables = @()
     $MinerSearch | %{
     $MinerTable = $_
     $MinerTable = $MinerTable.PSObject.Properties.Name | %{if($_ -ne "name"){$MinerTable.$_}}
     $MinerTables += $MinerTable |  Sort-Object -Property Type,Name | Format-Table (@{Label = "Name"; Expression={$($_.Name)}},@{Label = "Type"; Expression={$($_.Type)}},@{Label = "Executable"; Expression={$($_.MinerName)}},@{Label = "Version"; Expression={$($_.Version)}})
    }
   }
  }
 }
 
 if($CudaVersion){$Message += "Cuda Version is $CudaVersion"; Write-Host $($Message | Select -last 1)}
 $Message | Set-Content ".\build\txt\version.txt"
 if($MinerTables){$MinerTables | Out-Host; $MinerTables | Out-File ".\build\txt\version.txt" -Append}

