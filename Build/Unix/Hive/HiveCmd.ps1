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
function Get-GPUCount {
    param (
        [Parameter(Mandatory=$true)]
        [Array]$DeviceType,
        [Parameter(Mandatory=$true)]
        [String]$CmdDir
    )

    Set-Location (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "Build")

    $DeviceType | foreach{
     if($_ -like "*NVIDIA*")
      {
       Write-Host "Getting NVIDIA GPU Count" -foregroundcolor cyan
       lspci | Tee-Object ".\GPUCount.txt" | Out-Null
       $GCount = Get-Content ".\GPUCount.txt" -Force
       $AttachedGPU = $GCount | Select-String "VGA","3d" | Select-String "NVIDIA"   
       [int]$GPU_Count = $AttachedGPU.Count
       }
      if($_ -like "*AMD*")
       {
         Write-Host "Getting AMD GPU Count" -foregroundcolor cyan
         lspci | Tee-Object ".\GPUCount.txt" | Out-Null
         $GCount = Get-Content ".\GPUCount.txt" -Force
         $AttachedGPU = $GCount | Select-String "VGA" | Select-String "AMD"   
         [int]$GPU_Count = $AttachedGPU.Count
       }
    }
             
    $GPU_Count  
}

function Get-Data {
    param (
    [Parameter(Mandatory=$true)]
    [String]$CmdDir
    )

    Set-Location (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "Build")

    if(Test-Path ".\stats")
    {
         Copy-Item ".\stats" -Destination "/usr/bin" -force | Out-Null
         Set-Location "/usr/bin"
         Start-Process "chmod" -ArgumentList "+x stats"
         Set-Location "/"
         Set-Location $CmdDir     
    }

    if(Test-Path ".\get-oc")
    {
         Copy-Item ".\get-oc" -Destination "/usr/bin" -force | Out-Null
         Set-Location "/usr/bin"
         Start-Process "chmod" -ArgumentList "+x get-oc"
         Set-Location "/"
         Set-Location $CmdDir     
    }
   
   if(Test-Path ".\active")
    {
       Copy-Item ".\active" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x active"
       Set-Location "/"
       Set-Location $CmdDir
       }

    if(Test-Path ".\version")
     {
      Copy-Item ".\version" -Destination "/usr/bin" -force | Out-Null
      Set-Location "/usr/bin"
      Start-Process "chmod" -ArgumentList "+x version"
      Set-Location "/"
      Set-Location $CmdDir
    }
    
       if(Test-Path ".\get-screen")
    {
       Copy-Item ".\get-screen" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x get-screen"
       Set-Location "/"
       Set-Location $CmdDir
       }
   
   if(Test-Path ".\mine")
    {
       Copy-Item ".\mine" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x mine"
       Set-Location "/"
       Set-Location $CmdDir
       }
   
   if(Test-Path ".\logdata")
    {
       Copy-Item ".\logdata" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x logdata"
       Set-Location "/"
       Set-Location $CmdDir
       }
   
   if(Test-Path ".\pidinfo")
    {
       Copy-Item ".\pidinfo" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x pidinfo"
       Set-Location "/"
       Set-Location $CmdDir
       }

   if(Test-Path ".\dir.sh")
    {
       Copy-Item ".\dir.sh" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x dir.sh"
       Set-Location "/"
       Set-Location $CmdDir
       }

       if(Test-Path ".\benchmark")
       {
          Copy-Item ".\benchmark" -Destination "/usr/bin" -force | Out-Null
          Set-Location "/usr/bin"
          Start-Process "chmod" -ArgumentList "+x benchmark"
          Set-Location "/"
          Set-Location $CmdDir
          }

          if(Test-Path ".\clear_profits")
          {
             Copy-Item ".\clear_profits" -Destination "/usr/bin" -force | Out-Null
             Set-Location "/usr/bin"
             Start-Process "chmod" -ArgumentList "+x clear_profits"
             Set-Location "/"
             Set-Location $CmdDir
             }   
   
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    
    }
    
    function Get-DateFiles {
        param (
        [Parameter(Mandatory=$true)]
        [String]$CmdDir
        )
    
    Set-Location (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "Build")

    if((Get-Item ".\Data\Info.txt" -Force -ErrorAction SilentlyContinue) -eq $null)
    {New-Item -Path ".\Data" -Name "Info.txt" -Force | Out-Null}
   if((Get-Item ".\Data\System.txt" -Force -ErrorAction SilentlyContinue) -eq $null)
    {New-Item -Path ".\Data" -Name "System.txt" -Force | Out-Null}
   if((Get-Item ".\Data\TimeTable.txt" -Force -ErrorAction SilentlyContinue) -eq $null)
    {New-Item -Path ".\Data" -Name "TimeTable.txt" -Force | Out-Null}
    if((Get-Item ".\Data\Error.txt" -Force -ErrorAction SilentlyContinue) -eq $null)
    {New-Item -Path ".\Data" -Name "Error.txt" -Force | Out-Null}
    $TimeoutClear = Get-Content ".\Data\Error.txt" -Force | Out-Null
    if(Test-Path ".\PID"){Remove-Item ".\PID\*" -Force | Out-Null}
    else{New-Item -Path "." -Name "PID" -ItemType "Directory" -Force | Out-Null}   
    if($TimeoutClear -ne "")
     {
      Clear-Content ".\Data\System.txt" -Force
      Get-Date | Out-File ".\Data\Error.txt" -Force | Out-Null
     } 

    $DonationClear = Get-Content ".\Data\Info.txt" -Force | Out-String
    if($DonationClear -ne "")
    {Clear-Content ".\Data\Info.txt" -Force} 
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
}

function Get-AlgorithmList {
    param (
        [Parameter(Mandatory=$true)]
        [Array]$DeviceType,
        [Parameter(Mandatory=$true)]
        [String]$CmdDir,
        [Parameter(Mandatory=$false)]
        [Array]$No_Algo
    )

    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

    $AlgorithmList = @()
    $GetAlgorithms = Get-Content ".\Config\get-pool.txt" -Force | ConvertFrom-Json
    $PoolAlgorithms = @()
    $GetAlgorithms | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
     $PoolAlgorithms += $_
    }
    
    if($No_Algo -ne $null)
     {
     $GetNoAlgo = Compare-Object $No_Algo $PoolAlgorithms
     $GetNoAlgo.InputObject | foreach{$AlgorithmList += $_}
     }
     else{$PoolAlgorithms | foreach { $AlgorithmList += $($_)} }
         
    $AlgorithmList
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    }

 function Start-LaunchCode {
        param(
            [parameter(Mandatory=$true)]
            [String]$Type,
            [parameter(Mandatory=$true)]
            [String]$Name,
            [parameter(Mandatory=$false)]
            [String]$DeviceCall,
            [parameter(Mandatory=$false)]
            [String]$Devices='',
            [parameter(Mandatory=$false)]
            [String]$Arguments,
            [parameter(Mandatory=$true)]
            [String]$MinerName,
            [parameter(Mandatory=$true)]
            [String]$Path,
            [parameter(Mandatory=$true)]
            [String]$Coins,
            [parameter(Mandatory=$true)]
            [String]$CmdDir,
            [parameter(Mandatory=$true)]
            [String]$MinerDir,
	        [parameter(Mandatory=$true)]
            [String]$Logs,
            [parameter(Mandatory=$true)]
            [String]$Delay,
            [parameter(Mandatory=$true)]
            [string]$MinerInstance,
            [parameter(Mandatory=$true)]
            [string]$Algos,
            [parameter(Mandatory=$true)]
            [string]$GPUGroups,
            [parameter(Mandatory=$true)]
            [string]$APIs,
            [parameter(Mandatory=$true)]
            [string]$Ports,
            [parameter(Mandatory=$true)]
            [string]$MDir,
            [parameter(Mandatory=$false)]
            [string]$Username,                      
            [parameter(Mandatory=$false)]
            [string]$Connection,
            [parameter(Mandatory=$false)]
            [string]$Password,
            [parameter(Mandatory=$false)]
            [string]$jsonfile                                         
        )
    
        $MinerTimer = New-Object -TypeName System.Diagnostics.Stopwatch
        $Export = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "Build/Export")
        Set-Location (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "Build")
        $PIDMiners = "$($Type)"
        if(Test-Path ".\PID\*$PIDMiners*"){Remove-Item ".\PID\*$PIDMiners*" -Force}
        if($Type -eq "NVIDIA1" -or $Type -eq "AMD1"){$Algo | Set-Content ".\Unix\Hive\algo.sh"}
        if($Type -like '*NVIDIA*')
        {
        if($Devices -eq '')
         {
        $MinerArguments = "$($Arguments)"
        if($DeviceCall -eq "lolminer"){$MinerArguments = "-profile=miner -usercfg=$($jsonfile)"}
         }
        else{
        if($DeviceCall -eq "ccminer"){$MinerArguments = "-d $($Devices) $($Arguments)"}
        if($DeviceCall -eq "ewbf"){$MinerArguments = "--cuda_devices $($Devices) $($Arguments)"}
        if($DeviceCall -eq "dstm"){$MinerArguments = "--dev $($Devices) $($Arguments)"}
        if($DeviceCall -eq "claymore"){$MinerArguments = "-di $($Devices) $($Arguments)"}
        if($DeviceCall -eq "trex"){$MinerArguments = "-d $($Devices) $($Arguments)"}
        if($DeviceCall -eq "bminer"){$MinerArguments = "-devices $($Devices) $($Arguments)"}
        if($DeviceCall -eq "lolminer"){$MinerArguments = "-devices=$($Devices) -profile=miner -usercfg=$($jsonfile)"}
         }
        }
        if($Type -like '*AMD*')
        {
        if($Devices -eq ''){
        $MinerArguments = "$($Arguments)"
	    if($DeviceCall -eq "lolamd"){$MinerArguments = "-profile=miner -usercfg=$($jsonfile)"}
        if($DeviceCall -eq "lyclminer"){
        $MinerArguments = ""
            Set-Location $MinerDir
            $ConfFile = Get-Content ".\lyclMiner.conf" -Force
            $NewLines = $ConfFile | ForEach {
            if($_ -like "*<Connection Url =*"){$_ = "<Connection Url = `"stratum+tcp://$Connection`""}
            if($_ -like "*Username =*"){$_ = "            Username = `"$Username`"    "}
            if($_ -like "*Password =*" ){$_ = "            Password = `"$Password`">    "}
            if($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*"){$_}
            }
            Clear-Content ".\lyclMiner.conf" -force
            $NewLines | Set-Content ".\lyclMiner.conf"
            Set-Location $CmdDir
            }
           }
        else{
          if($DeviceCall -eq "claymore"){$MinerArguments = "-di $($Devices) $($Arguments)"}
          if($DeviceCall -eq "sgminer"){$MinerArguments = "-d $($Devices) $($Arguments)"}
          if($DeviceCall -eq "tdxminer"){$MinerArguments = "-d $($Devices) $($Arguments)"}
          if($DeviceCall -eq "lolamd"){$MinerArguments = "-devices=$($Devices) -profile=miner -usercfg=$($jsonfile)"}
          if($DeviceCall -eq "lyclminer"){
            $MinerArguments = ""
            Set-Location $MinerDir
            $ConfFile = Get-Content ".\lyclMiner.conf" -Force
            $NewLines = $ConfFile | ForEach {
            if($_ -like "*<Connection Url =*"){$_ = "<Connection Url = `"stratum+tcp://$Connection`""}
            if($_ -like "*Username =*"){$_ = "            Username = `"$Username`"    "}
            if($_ -like "*Password =*" ){$_ = "            Password = `"$Password`">    "}
            if($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*"){$_}
            }
            Clear-Content ".\lyclMiner.conf" -force
            $NewLines | Set-Content ".\lyclMiner.conf"
            Set-Location $CmdDir
            }
         }
        }
        if($Type -like '*CPU*')
        {
        if($Devices -eq ''){$MinerArguments = "$($Arguments)"}
        else{
          if($DeviceCall -eq "cpuminer-opt"){$MinerArguments = "-t $($Devices) $($Arguments)"}
          if($DeviceCall -eq "cryptozeny"){$MinerArguments = "-t $($Devices) $($Arguments)"}
         }
        }
        if($Type -like '*ASIC*'){$MinerArguments = $Arguments}
   	    $MinerConfig = "./$MinerInstance $MinerArguments"
        $MinerConfig | Set-Content ".\Unix\Hive\config.sh" -Force
        if($Type -eq "NVIDIA1" -or $Type -eq "AMD1")
         {
         Start-Process ".\Unix\Hive\killall.sh" -ArgumentList "LogData" -Wait
         Start-Sleep -S .25
         $DeviceCall | Set-Content ".\Unix\Hive\mineref.sh" -Force
         $Ports | Set-Content ".\Unix\Hive\port.sh" -Force
         $Name | Set-Content ".\Unix\Hive\minername.sh" -Force
         Start-Process "screen" -ArgumentList "-S LogData -d -m" -Wait
         Start-Process ".\Unix\Hive\LogData.sh" -ArgumentList "LogData $DeviceCall $Type $GPUGroups $MDir $Algos $APIs $Ports" -Wait
         }
         if($Type -eq "CPU")
          {
          if($CPUOnly -eq "Yes")
           {
            $DeviceCall | Set-Content ".\Unix\Hive\mineref.sh" -Force
            $Ports | Set-Content ".\Unix\Hive\port.sh" -Force
            Start-Process ".\Unix\Hive\killall.sh" -ArgumentList "LogData" -Wait
            Start-Sleep -S .25
            Start-Process "screen" -ArgumentList "-S LogData -d -m" -Wait  
            Start-Process ".\Unix\Hive\LogData.sh" -ArgumentList "LogData $DeviceCall $Type $GPUGroups $MDir $Algos $APIs $Ports" -Wait
           }
          }
       Write-Host "
        
        
        
        Clearing Screen $($Type) & Tracking



        "
        Start-Process ".\Unix\Hive\killall.sh" -ArgumentList "$($Type)" -Wait
        Start-Sleep $Delay #Wait to prevent BSOD
        Start-Sleep -S .25
        Set-Location $MinerDIr
        Start-Process "chmod" -ArgumentList "+x $MinerInstance" -Wait
        Set-Location $CmdDir
	    Start-Sleep -S .25
        Write-Host "Starting $($Name) Mining $($Coins) on $($Type)" -ForegroundColor Cyan
        if($Type -like "*NVIDIA*"){Start-Process ".\Unix\Hive\startupnvidia.sh" -ArgumentList "$MinerDir $($Type) $CmdDir/Unix/Hive $Logs $Export" -Wait}
        if($Type -like "*AMD*"){Start-Process ".\Unix\Hive\startupamd.sh" -ArgumentList "$MinerDir $($Type) $CmdDir/Unix/Hive $Logs $Export" -Wait}
        if($Type -like "*CPU*"){Start-Process ".\Unix\Hive\startupcpu.sh" -ArgumentList "$MinerDir $($Type) $CmdDir/Unix/Hive $Logs" -Wait}
        $MinerTimer.Restart()
        $MinerProcessId = $null
        Do{
           Start-Sleep -S 1
           Write-Host "Getting Process ID for $MinerName"           
           $MinerProcessId = Get-Process -Name "$($MinerInstance)" -ErrorAction SilentlyContinue
          }until($MinerProcessId -ne $null -or ($MinerTimer.Elapsed.TotalSeconds) -ge 10)  
        if($MinerProcessId -ne $null)
         {
            $MinerProcessId.Id | Set-Content ".\PID\$($Name)_$($Coins)_$($MinerInstance)_PID.txt" -Force
            Get-Date | Set-Content ".\PID\$($Name)_$($Coins)_$($MinerInstance)_Date.txt" -Force
            Start-Sleep -S 1
        }
        $MinerTimer.Stop()
        Rename-Item "$MinerDir\$($MinerInstance)" -NewName "$MinerName" -Force
        Start-Sleep -S .25
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    }

    function Get-PID {
        param(
            [parameter(Mandatory=$false)]
            [String]$Instance,          
	    [parameter(Mandatory=$false)]
            [String]$Type,
	    [parameter(Mandatory=$false)]
            [String]$InstanceNum
            )
    
        $GetPID = "$($Instance)_PID.txt"
        
        if(Test-Path $GetPID)
         {
	  $PIDName = "$($Instance)-$($InstanceNum)"
          $PIDNumber = Get-Content $GetPID -Force
          $MinerPID = Get-Process -Id $PIDNumber -erroraction SilentlyContinue
 	  if($MinerPID -eq $Null){$MinerPID = Get-Process -Name $PIDName -erroraction SilentlyContinue}
         }
        else{$MinerPID = $null}

        $MinerPID

    }
