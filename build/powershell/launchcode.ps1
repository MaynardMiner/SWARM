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

function Tee-ObjectNoColor {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [string]$InputObject,
        [Parameter(Position=1, Mandatory=$true)]
        [string]$FilePath
    )

  process{
        $Logs = $InputObject -replace '\\[\d+(;\d+)?m'
        $Logs | Out-File $FilePath -Append
        $InputObject | Out-Host
         }
}

function Open-Colored([String] $Filename)
  {Write-Colored($Filename)}

function Write-Colored([String] $text)
  { # split text at ESC-char
    $split = $text.Split([char] 27)
    foreach ($line in $split)
      { if ($line[0] -ne '[')
          { Write-Host $line -NoNewline }
        else
          { if(($line[1] -eq '0') -and ($line[2] -eq 'm')) { Write-Host $line.Substring(3) -NoNewline }
            elseif(($line[1] -eq '0') -and ($line[2] -eq '1')) { Write-Host $line.Substring(3) -NoNewline -ForegroundColor White }           
            elseif (($line[1] -eq '3') -and ($line[3] -eq 'm'))
              { # normal color codes
                if     ($line[2] -eq '0') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor Black       }
                elseif ($line[2] -eq '1') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkRed     }
                elseif ($line[2] -eq '2') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkGreen   }
                elseif ($line[2] -eq '3') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkYellow  }
                elseif ($line[2] -eq '4') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkBlue    }
                elseif ($line[2] -eq '5') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkMagenta }
                elseif ($line[2] -eq '6') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkCyan    }
                elseif ($line[2] -eq '7') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor Gray        }
              }
            elseif (($line[1] -eq '3') -and ($line[3] -eq ';') -and ($line[5] -eq 'm'))
              { # bright color codes
                if     ($line[2] -eq '0') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor DarkGray    }
                elseif ($line[2] -eq '1') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Red         }
                elseif ($line[2] -eq '2') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Gree        }
                elseif ($line[2] -eq '3') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Yellow      }
                elseif ($line[2] -eq '4') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Blue        }
                elseif ($line[2] -eq '5') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Magenta     }
                elseif ($line[2] -eq '6') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Cyan        }
                elseif ($line[2] -eq '7') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor White       }
              }
          }
      }
  }

function Start-LaunchCode {

    param(
    [Parameter(Mandatory=$true)]
    [String]$Platforms
    ) 

  $Miner = Get-Content ".\build\txt\current.txt" | ConvertFrom-Json
  $MinerTimer = New-Object -TypeName System.Diagnostics.Stopwatch
  $Export = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\export")  
  ##Remove Old PID FIle
  $PIDMiners = "$($_.Type)"
  if(Test-Path ".\build\pid\*$PIDMiners*"){Remove-Item ".\build\pid\*$PIDMiners*" -Force}

switch -WildCard ($Miner.Type)
 {
  "*NVIDIA*"
    {
     if($Miner.Devices -ne $null)
      {
       switch($Miner.DeviceCall)
       {
        "ccminer"{$MinerArguments = "-d $($Miner.Devices) $($Miner.Arguments)"}
        "ewbf"{$MinerArguments = "--cuda_devices $($Miner.Devices) $($Miner.Arguments)"}
        "dstm"{$MinerArguments = "--dev $($Miner.Devices) $($Miner.Arguments)"}
        "claymore"{$MinerArguments = "-di $($Miner.Devices) $($Miner.Arguments)"}
        "trex"{$MinerArguments = "-d $($Miner.Devices) $($Miner.Arguments)"}
        "bminer"{$MinerArguments = "-devices $($Miner.Devices) $($Miner.Arguments)"}
        "lolminer"{$MinerArguments = "-devices=$($Miner.Devices) -profile=miner -usercfg=$($Miner.jsonfile)"}
       }
      }
     else
      {
       if($Miner.DeviceCall -eq "lolminer"){$MinerArguments = "-profile=miner -usercfg=$($Miner.jsonfile)"}
       else{$MinerArguments = "$($Miner.Arguments)"}
      }
    }

  "*AMD*"
   {
    if($Miner.Devices -ne $null)
     {   
      switch($Miner.DeviceCall)
       {
        "claymore"{$MinerArguments = "-di $($Miner.Devices) $($Miner.Arguments)"}
        "xmrstak"{$MinerArguments = "$($Miner.Arguments)"}
        "sgminer-gm"{Write-Host "Miner Has Devices"; $MinerArguments = "-d $($Miner.Devices) $($Miner.Arguments)"}
        "tdxminer"{$MinerArguments = "-d $($Miner.Devices) $($Miner.Arguments)"}
        "lolamd"{$MinerArguments = "-devices=$($Miner.Devices) -profile=miner -usercfg=$($Miner.jsonfile)"}
        "wildrig"{$MinerArguments = "$($Miner.Arguments)"}        
        "lyclminer"{
        $MinerArguments = ""
        Set-Location (Split-Path $($Miner.Path))
        $ConfFile = Get-Content ".\lyclMiner.conf" -Force
        $Connection = $Miner.Connection
        $Username = $Miner.Username
        $Password = $Miner.Password
        $NewLines = $ConfFile | ForEach {
        if($_ -like "*<Connection Url =*"){$_ = "<Connection Url = `"stratum+tcp://$Connection`""}
        if($_ -like "*Username =*"){$_ = "            Username = `"$Username`"    "}
        if($_ -like "*Password =*" ){$_ = "            Password = `"$Password`">    "}
        if($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*"){$_}
        }
        Clear-Content ".\lyclMiner.conf" -force
        $NewLines | Set-Content ".\lyclMiner.conf"
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
        }           
       }
      }
    else
     {
      if($Miner.DeviceCall -eq "lolamd"){$MinerArguments = "-profile=miner -usercfg=$($Miner.jsonfile)"}
      elseif($Miner.DeviceCall -eq "lyclminer"){
      $MinerArguments = ""
      Set-Location (Split-Path $($Miner.Path))
      $ConfFile = Get-Content ".\lyclMiner.conf" -Force
      $Connection = $Miner.Connection
      $Username = $Miner.Username
      $Password = $Miner.Password
      $NewLines = $ConfFile | ForEach {
      if($_ -like "*<Connection Url =*"){$_ = "<Connection Url = `"stratum+tcp://$Connection`""}
      if($_ -like "*Username =*"){$_ = "            Username = `"$Username`"    "}
      if($_ -like "*Password =*" ){$_ = "            Password = `"$Password`">    "}
      if($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*"){$_}
      }
      Clear-Content ".\lyclMiner.conf" -force
      $NewLines | Set-Content ".\lyclMiner.conf"
      Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
      }
      else{$MinerArguments = "$($Miner.Arguments)"}
     }
    }  
      
  "*CPU*"
    {
     if($Miner.Devices -eq ''){$MinerArguments = "$($Miner.Arguments)"}
     elseif($Miner.DeviceCall -eq "cpuminer-opt"){$MinerArguments = "-t $($Miner.Devices) $($Miner.Arguments)"}
     elseif($Miner.DeviceCall -eq "cryptozeny"){$MinerArguments = "-t $($Miner.Devices) $($Miner.Arguments)"}
    }
   }

if($Platforms -eq "windows")
{
  if($MinerProcess -eq $null -or $MinerProcess.HasExited -eq $true)
  {
    $Logs = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "logs\$($Miner.Type).log" 
    $WorkingDirectory = Split-Path $($Miner.Path)
    if(Test-Path $Logs){Clear-Content $Logs}
    $script = @()
    if($Miner.SetX -ne $null){$Miner.SetX | foreach {$script += $_}}
    $script += ". C:\Users\Mayna\Desktop\MM.Test\build\powershell\launchcode.ps1;"
    $script += "`$host.ui.RawUI.WindowTitle = ""$($Miner.Name)"";"
    if($Miner.DeviceCall -eq "ewbf"){$script += "Invoke-Expression `'.\$($Miner.MinerName) $($MinerArguments) --log 3 --logfile $Logs`'"}
    $script += "Invoke-Expression `'.\$($Miner.MinerName) $($MinerArguments) | Tee-ObjectNoColor -FilePath ""$Logs"" -erroraction SilentlyContinue`'"
    $script | out-file "$WorkingDirectory\swarm-start.ps1"
    Start-Sleep -S .5
  
    $Job = Start-Job -ArgumentList $PID, $WorkingDirectory {
     param($ControllerProcessID, $WorkingDirectory)
     Set-Location $WorkingDirectory
     $ControllerProcess = Get-Process -Id $ControllerProcessID
     if($ControllerProcess -eq $null){return}
     $Process = Start-Process "CMD" -ArgumentList "/c powershell.exe -windowstyle minimized -executionpolicy bypass -command "".\swarm-start.ps1""" -PassThru
     if($Process -eq $null){[PSCustomObject]@{ProcessId = $null}; return};
     [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle};
     $ControllerProcess.Handle | Out-Null; $Process.Handle | Out-Null; 
     do{if($ControllerProcess.WaitForExit(1000)){$Process.CloseMainWindow() | Out-Null}}while($Process.HasExited -eq $false)
    }
      
        do{sleep 1; $JobOutput = Receive-Job $Job}
        while($JobOutput -eq $null)
      
        $Process = Get-Process | Where Id -EQ $JobOutput.ProcessId
        $Process.Handle | Out-Null
        $Process
    }
  else{$MinerProcess}
} 

elseif($Platforms -eq "linux")
{
  $Logs = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "logs\$($Miner.Type).log" 
  if(Test-Path $Logs){Clear-Content $Logs}
  Set-Location (Split-Path $($Miner.Path))
  Rename-Item "$($Miner.Path)" -NewName "$($Miner.InstanceName)" -Force
  Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
  $MinerConfig = "./$($Miner.InstanceName) $MinerArguments"
  $MinerConfig | Set-Content ".\build\bash\config.sh" -Force  
  Write-Host "
         ______________
       /.----------..-'
-.     ||           \\
.----'-||-.          \\
|o _   || |           \\
| [_]  || |_...-----.._\\
| [_]  ||.'            ``-._ _
| [_]  '.O)_...-----....._ ``.\
/ [_]o .' _ _'''''''''_ _ `. ``.       __
|______/.'  _  ``.---.'  _  ``.\  ``._./  \Cl
|'''''/, .' _ '. . , .' _ '. .``. .o'|   \ear
``---..|; : (_) : ;-; : (_) : ;-'``--.|    \ing Screen $($Miner.Type) & Tracking
       ' '. _ .' ' ' '. _ .' '      /     \
        ``._ _ _,'   ``._ _ _,'       ``._____\        
"
Start-Process ".\build\bash\killall.sh" -ArgumentList "$($Miner.Type)" -Wait
Start-Sleep -S .25
Set-Location (Split-Path $($Miner.Path))
Start-Process "chmod" -ArgumentList "+x $($Miner.InstanceName)" -Wait
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
Start-Sleep -S .25
Write-Host "Starting $($Miner.Name) Mining $($Miner.Coins) on $($Miner.Type)" -ForegroundColor Cyan
Start-Sleep -S .25
$MinerDir = $(Split-Path $($Miner.Path))
$Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$Export = Join-Path $Dir "build\export"
if($Miner.Type -like "*NVIDIA*"){Start-Process ".\build\bash\startupnvidia.sh" -ArgumentList "$MinerDir $($Miner.Type) $Dir/build/bash $Logs $Export" -Wait}
if($Miner.Type -like "*AMD*"){Start-Process ".\build\bash\startupamd.sh" -ArgumentList "$MinerDir $($Miner.Type) $Dir/build/bash $Logs $Export" -Wait}
if($Miner.Type -like "*CPU*"){Start-Process ".\build\bash\startupcpu.sh" -ArgumentList "$MinerDir $($Miner.Type) $Dir/build/bash $Logs" -Wait}
$MinerTimer.Restart()
Do{
  Start-Sleep -S 1
  Write-Host "Getting Process ID for $($Miner.MinerName)"           
  $MinerProcess = Get-Process -Name "$($Miner.InstanceName)" -ErrorAction SilentlyContinue
 }until($MinerProcess -ne $null -or ($MinerTimer.Elapsed.TotalSeconds) -ge 10)  
if($MinerProcess -ne $null)
{
   $MinerProcess.Id | Set-Content ".\build\pid\$($Miner.Name)_$($Miner.Coins)_$($Miner.InstanceName)_pid.txt" -Force
   Get-Date | Set-Content ".\build\pid\$($Miner.Name)_$($Miner.Coins)_$($Miner.InstanceName)_date.txt" -Force
   Start-Sleep -S 1
}
$MinerTimer.Stop()
Rename-Item "$MinerDir\$($Miner.InstanceName)" -NewName "$($Miner.MinerName)" -Force
Start-Sleep -S .25
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
$MinerProcess
 }
}













