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
Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))

if($Platform -ne "windows")
{
if($Command -eq "!"){Write-Host "No Command Given. Try version query"}
else{$CommandQuery = $Command -replace("!","")
Write-Host "Executing Command: $CommandQuery"
Write-Host "                   " }
$CudaVersion = Get-Content ".\build\txt\cuda.txt"
if($CudaVersion -eq "9.1"){$updatecheck = ".\config\update\nvidia9.1-linux.json"; $miner_update_nvidia = Get-Content ".\config\update\nvidia9.1-linux.json" | ConvertFrom-Json}
if($CudaVersion -eq "9.2"){$updatecheck = ".\config\update\nvidia9.2-linux.json"; $miner_update_nvidia = Get-Content ".\config\update\nvidia9.2-linux.json" | ConvertFrom-Json}
if($CudaVersion -eq "10"){$updatecheck = ".\config\update\nvidia10-linux.json"; $miner_update_nvidia = Get-Content ".\config\update\nvidia10-linux.json" | ConvertFrom-Json}
$miner_update_amd = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json
$miner_update_cpu = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json

$nvidia = [PSCustomObject]@{}
$amd = [PSCustomObject]@{}
$cpu = [PSCustomObject]@{}

$miner_update_nvidia | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$nvidia | Add-Member $miner_update_nvidia.$_.Name $miner_update_nvidia.$_}
$miner_update_amd | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$amd | Add-Member $miner_update_amd.$_.Name $miner_update_amd.$_}
$miner_update_cpu | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$cpu | Add-Member $miner_update_cpu.$_.Name $miner_update_cpu.$_}

$nvidiatable = @()
$amdtable = @()
$cputable = @()

$nvidia | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
    $nvidiatable += [PSCustomObject]@{
     Name = $nvidia.$_.Name
     Type = $nvidia.$_.Type
     MinerName = $nvidia.$_.MinerName
     Version = $nvidia.$_.version
    }
}

$amd | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
    $amdtable += [PSCustomObject]@{
     Name = $amd.$_.Name
     Type = $amd.$_.Type
     MinerName = $amd.$_.MinerName
     Version = $amd.$_.version
    }
}

$cpu | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
    $cputable += [PSCustomObject]@{
     Name = $cpu.$_.Name
     Type = $cpu.$_.Type
     MinerName = $cpu.$_.MinerName
     Version = $cpu.$_.version
    }
}



if($Command -eq "!query")
 {
    $nvidiatable | Sort-Object -Property Type,Name | Format-Table (
        @{Label = "Name"; Expression={$($_.Name)}},
        @{Label = "Type"; Expression={$($_.Type)}},
        @{Label = "Executable"; Expression={$($_.MinerName)}},
        @{Label = "Version"; Expression={$($_.Version)}}
    ) | Out-Host
    $amdtable | Sort-Object -Property Type,Name | Format-Table (
        @{Label = "Name"; Expression={$($_.Name)}},
        @{Label = "Type"; Expression={$($_.Type)}},
        @{Label = "Executable"; Expression={$($_.MinerName)}},
        @{Label = "Version"; Expression={$($_.Version)}}
    ) | Out-Host
    $cputable | Sort-Object -Property Type,Name | Format-Table (
        @{Label = "Name"; Expression={$($_.Name)}},
        @{Label = "Type"; Expression={$($_.Type)}},
        @{Label = "Executable"; Expression={$($_.MinerName)}},
        @{Label = "Version"; Expression={$($_.Version)}}
    ) | Out-Host
}

if($Command -eq "!update")
 {
    $Name = $Name -replace ("!","")
    Write-Host "Stopping Miner & Waiting 5 Seconds"
    miner stop
    Start-Sleep -S 5
    $newEXE = $EXE -replace("!","")
    $newVersion = $Version -replace("!","")
    $newURI = $uri -replace("!","")
    $nvidiaupdate = $false
    $amdupdate = $false
    $cpuupdate = $false

    $nvidia | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
     if($Name -eq $nvidia.$_.name)
      {
       $nvidia.$_.minername = $newEXE 
       $nvidia.$_.version = $newversion
       $nvidia.$_.uri = $newuri 
       Write-Host "$Name new executable is $newEXE"
       Write-Host "$Name new uri is $newuri"
       Write-Host "$Name new version is $newversion"
       if(Test-Path ".\bin\*$Name*"){Remove-Item ".\bin\*$Name*" -Recurse -Force}
       $nvidiaupdate = $true
       if(Test-Path ".\bin\*$Name*"){Remove-Item ".\bin\*$Name*" -Recurse -Force};
       $nvidia | ConvertTo-Json | Out-File $updatecheck
      }
    }

    $amd | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
     if($Name -eq $amd.$_.name)
      {
       $amd.$_.minername = $newEXE
       $amd.$_.version = $newVersion
       $amd.$_.uri = $newuri
       Write-Host "$Name new executable is $newexe"
       Write-Host "$Name new uri is $newuri"
       Write-Host "$Name new version is $newversion"
       if(Test-Path ".\bin\*$Name*"){Remove-Item ".\bin\*$Name*" -Recurse -Force}
       $amd | ConvertTo-Json | Out-File ".\config\update\amd-linux.json"
      }
    }

    $cpu | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
     if($Name -eq $cpu.$_.name)
      {
       $cpu.$_.minername = $newEXE
       $cpu.$_.version = $newVersion
       $cpu.$_.uri = $newuri
       Write-Host "$Name new executable is $newexe"
       Write-Host "$Name new uri is $newuri"
       Write-Host "$Name new version is $newversion"
       if(Test-Path ".\bin\*$Name*"){Remove-Item ".\bin\*$cpu*" -Recurse -Force}
       $cpu | ConvertTo-Json | Out-File ".\config\update\cpu-linux.json"
      }
    }

    Write-Host "Miner Was Updated" -ForegroundColor Green
    Write-Host "Restarting Miner With New Settings"
    miner start
}
}
else {
    if($Command -eq $null){"No Command Given. Try version query" | Out-File ".\build\txt\version.txt"}
    "Executing Command: $Command" | Out-File ".\build\txt\version.txt"
    "                   " | Out-File ".\build\txt\version.txt" -Append
    $miner_update_nvidia = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json
    $miner_update_cpu = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json
    $cpu = [PSCustomObject]@{}
    $nvidia = [PSCustomObject]@{}
    $miner_update_nvidia | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$nvidia | Add-Member $miner_update_nvidia.$_.Name $miner_update_nvidia.$_}
    $miner_update_cpu | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$cpu | Add-Member $miner_update_cpu.$_.Name $miner_update_cpu.$_}
    $nvidiatable = @()
    $cputable = @()

    $nvidia | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$nvidiatable += [PSCustomObject]@{ Name = $nvidia.$_.Name; Type = $nvidia.$_.Type; MinerName = $nvidia.$_.MinerName; Version = $nvidia.$_.version;}}
 
    $cpu | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
        $cputable += [PSCustomObject]@{
         Name = $cpu.$_.Name
         Type = $cpu.$_.Type
         MinerName = $cpu.$_.MinerName
         Version = $cpu.$_.version
        }
    }
    
    if($Command -eq "query")
    {
       $nvidiatable | Sort-Object -Property Type,Name | Format-Table (
           @{Label = "Name"; Expression={$($_.Name)}},
           @{Label = "Type"; Expression={$($_.Type)}},
           @{Label = "Executable"; Expression={$($_.MinerName)}},
           @{Label = "Version"; Expression={$($_.Version)}}
       ) | Out-File ".\build\txt\version.txt" -Append
       $cputable | Sort-Object -Property Type,Name | Format-Table (
           @{Label = "Name"; Expression={$($_.Name)}},
           @{Label = "Type"; Expression={$($_.Type)}},
           @{Label = "Executable"; Expression={$($_.MinerName)}},
           @{Label = "Version"; Expression={$($_.Version)}}
       ) | Out-File ".\build\txt\version.txt" -Append
   }

   if($Command -eq "update")
   {
      "Stopping Miner & Waiting 5 Seconds" | Out-File ".\build\txt\version.txt" -Append
      $ID = Get-Content ".\build\pid\miner_pid.txt"
      Stop-Process -Id $ID
      Start-Sleep -S 5
      $newEXE = $EXE 
      $newVersion = $Version 
      $newURI = $uri 
      $nvidiaupdate = $false
      $amdupdate = $false
      $cpuupdate = $false
  
      $nvidia | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
         if($Name -eq $nvidia.$_.name){
         $nvidia.$_.minername = $newEXE; 
         $nvidia.$_.version = $newversion;
         $nvidia.$_.uri = $newuri ;
         "$Name new executable is $newEXE" | Out-File ".\build\txt\version.txt" -Append;
         "$Name new uri is $newuri" | Out-File ".\build\txt\version.txt" -Append;
         "$Name new version is $newversion" | Out-File ".\build\txt\version.txt" -Append;
         if(Test-Path ".\bin\*$Name*"){Remove-Item ".\bin\*$Name*" -Recurse -Force};
         $nvidia | ConvertTo-Json | Out-File ".\config\update\nvidia-win.json"
        }
      }
    
      $cpu | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
       if($Name -eq $cpu.$_.name)
        {
         $cpu.$_.minername = $newEXE
         $cpu.$_.version = $newVersion
         $cpu.$_.uri = $newuri
         "$Name new executable is $newexe" | Out-File ".\build\txt\version.txt" -Append
         "$Name new uri is $newuri" | Out-File ".\build\txt\version.txt" -Append
         "$Name new version is $newversion" | Out-File ".\build\txt\version.txt" -Append
         if(Test-Path ".\bin\*$Name*"){Remove-Item ".\bin\*$cpu*" -Recurse -Force}
         $cpu | ConvertTo-Json | Out-File ".\config\update\cpu-win.json"
        }
      }
  
     "Miner Was Updated" | Out-File ".\build\txt\version.txt" -Append
      "Restarting Miner With New Settings" | Out-File ".\build\txt\version.txt" -Append
      Start-Process .\SWARM.bat
    }
  
 }