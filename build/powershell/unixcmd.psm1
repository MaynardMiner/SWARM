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

 function Start-Launch {
        param(
            [parameter(Mandatory=$true)]
            [String]$OCType,
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
        $PIDMiners = "$($OCType)"
        if(Test-Path ".\PID\*$PIDMiners*"){Remove-Item ".\PID\*$PIDMiners*" -Force}
        if($OCType -eq "NVIDIA1" -or $OCType -eq "AMD1"){$Algo | Set-Content ".\Unix\Hive\algo.sh"}
        if($OCType -like '*NVIDIA*')
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
        if($OCType -like '*AMD*')
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
        if($OCType -like '*CPU*')
        {
        if($Devices -eq ''){$MinerArguments = "$($Arguments)"}
        else{
          if($DeviceCall -eq "cpuminer-opt"){$MinerArguments = "-t $($Devices) $($Arguments)"}
          if($DeviceCall -eq "cryptozeny"){$MinerArguments = "-t $($Devices) $($Arguments)"}
         }
        }
        if($OCType -like '*ASIC*'){$MinerArguments = $Arguments}
   	    $MinerConfig = "./$MinerInstance $MinerArguments"
        $MinerConfig | Set-Content ".\Unix\Hive\config.sh" -Force
        if($OCType -eq "NVIDIA1" -or $Type -eq "AMD1")
         {
         Start-Process ".\Unix\Hive\killall.sh" -ArgumentList "LogData" -Wait
         Start-Sleep -S .25
         $DeviceCall | Set-Content ".\Unix\Hive\mineref.sh" -Force
         $Ports | Set-Content ".\Unix\Hive\port.sh" -Force
         $Name | Set-Content ".\Unix\Hive\minername.sh" -Force
         Start-Process "screen" -ArgumentList "-S LogData -d -m" -Wait
         Start-Process ".\Unix\Hive\LogData.sh" -ArgumentList "LogData $DeviceCall $OCType $GPUGroups $MDir $Algos $APIs $Ports" -Wait
         }
         if($OCType -eq "CPU")
          {
          if($CPUOnly -eq "Yes")
           {
            $DeviceCall | Set-Content ".\Unix\Hive\mineref.sh" -Force
            $Ports | Set-Content ".\Unix\Hive\port.sh" -Force
            Start-Process ".\Unix\Hive\killall.sh" -ArgumentList "LogData" -Wait
            Start-Sleep -S .25
            Start-Process "screen" -ArgumentList "-S LogData -d -m" -Wait  
            Start-Process ".\Unix\Hive\LogData.sh" -ArgumentList "LogData $DeviceCall $OCType $GPUGroups $MDir $Algos $APIs $Ports" -Wait
           }
          }
       Write-Host "
       ______________
       /.----------..-'
    -. ||           \\
.----'-||-.          \\
|o _   || |           \\
| [_]  || |_...-----.._\\
| [_]  ||.'            ``-._ _
| [_]  '.O)_...-----....._ ``.\
/ [_]o .' _ _'''''''''_ _ `. ``.       __
|______/.'  _  ``.---.'  _  ``.\  ``._./  \Cl
|'''''/, .' _ '. . , .' _ '. .``. .o'|   \ear
``---..|; : (_) : ;-; : (_) : ;-'``--.|    \ing Screen $($OCType) & Tracking
       ' '. _ .' ' ' '. _ .' '      /     \
        ``._ _ _,'   ``._ _ _,'       ``._____\        
"
        Start-Process ".\Unix\Hive\killall.sh" -ArgumentList "$($OCType)" -Wait
        Start-Sleep $Delay #Wait to prevent BSOD
        Start-Sleep -S .25
        Set-Location $MinerDIr
        Start-Process "chmod" -ArgumentList "+x $MinerInstance" -Wait
        Set-Location $CmdDir
	    Start-Sleep -S .25
        Write-Host "Starting $($Name) Mining $($Coins) on $($OCType)" -ForegroundColor Cyan
        if($OCType -like "*NVIDIA*"){Start-Process ".\Unix\Hive\startupnvidia.sh" -ArgumentList "$MinerDir $($OCType) $CmdDir/Unix/Hive $Logs $Export" -Wait}
        if($OCType -like "*AMD*"){Start-Process ".\Unix\Hive\startupamd.sh" -ArgumentList "$MinerDir $($OCType) $CmdDir/Unix/Hive $Logs $Export" -Wait}
        if($OCType -like "*CPU*"){Start-Process ".\Unix\Hive\startupcpu.sh" -ArgumentList "$MinerDir $($OCType) $CmdDir/Unix/Hive $Logs" -Wait}
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