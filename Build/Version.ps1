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
    [parameter(Mandatory=$false)]
    [String]$Name,
    [parameter(Mandatory=$false)]
    [String]$Uri,
    [parameter(Mandatory=$false)]
    [String]$EXE,
    [parameter(Mandatory=$false)]
    [String]$Version,
    [parameter(Mandatory=$false)]
    [String]$Command
)

if($Command -eq "!"){Write-Host "No Command Given. Try version query"}
$CommandQuery = $Command -replace("!","")
Write-Host "Executing Command: $CommandQuery"
Write-Host "                   "
$CmdDir = (Split-Path $script:MyInvocation.MyCommand.Path)
$Dir = Split-Path $CmdDir
Set-Location $Dir
$CudaVersion = Get-Content ".\Build\Cuda.txt"
if($CudaVersion -eq "9.1"){$miner_update_nvidia = Get-Content ".\Config\Update\nvidia9.1-linux.conf" | ConvertFrom-Json}
if($CudaVersion -eq "9.2"){$miner_update_nvidia = Get-Content ".\Config\Update\nvidia9.2-linux.conf" | ConvertFrom-Json}
$miner_update_amd = Get-Content ".\Config\Update\amd-linux.conf" | ConvertFrom-Json
$miner_update_cpu = Get-Content ".\Config\Update\cpu-linux.conf" | ConvertFrom-Json
$Allupdates = @()
$Allupdates += $miner_update_nvidia
$Allupdates += $miner_update_amd
$Allupdates += $miner_update_cpu

$nvidia = [PSCustomObject]@{}
$amd = [PSCustomObject]@{}
$cpu = [PSCustomObject]@{}

$miner_update_nvidia | foreach {
$nvidia | Add-Member $_.Name $_
}
$miner_update_amd | foreach {
$amd | Add-Member $_.Name $_
}
$miner_update_cpu | foreach {
$cpu | Add-Member $_.Name $_
}

if($Command -eq "!query")
 {
    $Allupdates | Sort-Object -Property Type,Name  | Format-Table (
        @{Label = "Name"; Expression={$($_.Name)}},
        @{Label = "Type"; Expression={$($_.Type)}},
        @{Label = "Executable"; Expression={$($_.MinerName)}},
        @{Label = "Version"; Expression={$($_.Version)}}
    ) | Out-Host
}

if($Command -eq "!update")
 {
    $Name = $Name -replace ("!","")
    Write-Host "Stopping Miner & Waiting Three Seconds"
    miner stop
    Start-Sleep -S 3
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
       if(Test-Path ".\Bin\*$Name*"){Remove-Item ".\Bin\*$Name*" -Recurse -Force}
       $nvidiaupdate = $true
      }
     }

     if($nvidiaupdate -eq $true)
     { 
        $newupdate = @()
        $nvidia | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$nvidia.$_ | foreach {$newupdate += $_}}
        $newupdate | ConvertTo-Json | Out-File ".\Config\Update\nvidia-linux.conf"
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
       if(Test-Path ".\Bin\*$Name*"){Remove-Item ".\Bin\*$Name*" -Recurse -Force}
       $amdupdate = $true
      }
    }

    if($amdupdate -eq $true)
    { 
       $newupdate = @()
       $amd | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$amd.$_ | foreach {$newupdate += $_}}
       $newupdate | ConvertTo-Json | Out-File ".\Config\Update\amd-linux.conf"
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
       if(Test-Path ".\Bin\*$Name*"){Remove-Item ".\Bin\*$cpu*" -Recurse -Force}
       $cpuupdate = $true
      }
    }

    if($cpuupdate -eq $true)
    { 
       $newupdate = @()
       $cpu | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$cpu.$_ | foreach {$newupdate += $_}}
       $newupdate | ConvertTo-Json | Out-File ".\Config\Update\cpu-linux.conf"
    }

    Write-Host "Miner Was Updated" -ForegroundColor Green
    Write-Host "Restarting Miner With New Settings"
    miner start
}