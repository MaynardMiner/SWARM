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
function Start-Linux {

    $Miner = Get-Content ".\build\txt\current.txt" | ConvertFrom-Json

    $MinerTimer = New-Object -TypeName System.Diagnostics.Stopwatch
    $Export = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\export")
    
    switch -WildCard ($Miner.Type) {
        "*NVIDIA*" {
            if ($Miner.Devices -ne "none") {
                switch ($Miner.DeviceCall) {
                    "ccminer" {$MinerArguments = "-d $($Miner.Devices) $($Miner.Arguments)"}
                    "ewbf" {$MinerArguments = "--cuda_devices $($Miner.Devices) $($Miner.Arguments)"}
                    "dstm" {$MinerArguments = "--dev $($Miner.Devices) $($Miner.Arguments)"}
                    "claymore" {$MinerArguments = "-di $($Miner.Devices) $($Miner.Arguments)"}
                    "trex" {$MinerArguments = "-d $($Miner.Devices) $($Miner.Arguments)"}
                    "bminer" {$MinerArguments = "-devices $($Miner.Devices) $($Miner.Arguments)"}
                    "lolminer" {$MinerArguments = "-devices=$($Miner.Devices) -profile=miner -usercfg=$($Miner.jsonfile)"}
                    "progminer"{$MinerArguments = "--opencl-devices $($Miner.Devices) $($Miner.Arguments)"}
                }
            }
            else {
                if ($Miner.DeviceCall -eq "lolminer") {$MinerArguments = "-profile=miner -usercfg=$($Miner.jsonfile)"}
                else {$MinerArguments = "$($Miner.Arguments)"}
            }
        }

        "*AMD*" {
            Write-Host "Miner IS AMD"
            if ($Miner.Devices -ne "none") {   
                switch ($Miner.DeviceCall) {
                    "claymore" {$MinerArguments = "-di $($Miner.Devices) $($Miner.Arguments)"}
                    "sgminer-gm" {Write-Host "Miner Has Devices"; $MinerArguments = "-d $($Miner.Devices) $($Miner.Arguments)"}
                    "tdxminer" {$MinerArguments = "-d $($Miner.Devices) $($Miner.Arguments)"}
                    "lolamd" {$MinerArguments = "-devices=$($Miner.Devices) -profile=miner -usercfg=$($Miner.jsonfile)"}           
                    "lyclminer" {
                        $MinerArguments = ""
                        Set-Location (Split-Path $($Miner.Path))
                        $ConfFile = Get-Content ".\lyclMiner.conf" -Force
                        $Connection = $Miner.Connection
                        $Username = $Miner.Username
                        $Password = $Miner.Password
                        $NewLines = $ConfFile | ForEach {
                            if ($_ -like "*<Connection Url =*") {$_ = "<Connection Url = `"stratum+tcp://$Connection`""}
                            if ($_ -like "*Username =*") {$_ = "            Username = `"$Username`"    "}
                            if ($_ -like "*Password =*" ) {$_ = "            Password = `"$Password`">    "}
                            if ($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*") {$_}
                        }
                        Clear-Content ".\lyclMiner.conf" -force
                        $NewLines | Set-Content ".\lyclMiner.conf"
                        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
                    }           
                }
            }
            else {
                if ($Miner.DeviceCall -eq "lolamd") {$MinerArguments = "-profile=miner -usercfg=$($Miner.jsonfile)"}
                elseif ($Miner.DeviceCall -eq "lyclminer") {
                    $MinerArguments = ""
                    Set-Location (Split-Path $($Miner.Path))
                    $ConfFile = Get-Content ".\lyclMiner.conf" -Force
                    $Connection = $Miner.Connection
                    $Username = $Miner.Username
                    $Password = $Miner.Password
                    $NewLines = $ConfFile | ForEach {
                        if ($_ -like "*<Connection Url =*") {$_ = "<Connection Url = `"stratum+tcp://$Connection`""}
                        if ($_ -like "*Username =*") {$_ = "            Username = `"$Username`"    "}
                        if ($_ -like "*Password =*" ) {$_ = "            Password = `"$Password`">    "}
                        if ($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*") {$_}
                    }
                    Clear-Content ".\lyclMiner.conf" -force
                    $NewLines | Set-Content ".\lyclMiner.conf"
                    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
                }
                else {$MinerArguments = "$($Miner.Arguments)"}
            }
        }  
      
        "*CPU*" {
            if ($Miner.Devices -eq '') {$MinerArguments = "$($Miner.Arguments)"}
            elseif ($Miner.DeviceCall -eq "cpuminer-opt") {$MinerArguments = "-t $($Miner.Devices) $($Miner.Arguments)"}
            elseif ($Miner.DeviceCall -eq "cryptozeny") {$MinerArguments = "-t $($Miner.Devices) $($Miner.Arguments)"}
        }
    }
    $Miner.Type
    Write-Host "Miner Arguments are $MinerArguments"
    Set-Location (Split-Path $($Miner.Path))
    Rename-Item "$($Miner.Path)" -NewName "$($Miner.InstanceName)" -Force
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    $MinerConfig = "./$($Miner.InstanceName) $MinerArguments"
    $MinerConfig | Set-Content ".\build\bash\config.sh" -Force
    Write-Host "
        
        
        
Clearing Screen $($Miner.Type) & Tracking



"
    Start-Process ".\build\bash\killall.sh" -ArgumentList "$($Miner.Type)" -Wait
    Start-Sleep -S .25
    Set-Location (Split-Path $($Miner.Path))
    "Current Path is $($Miner.Path)"
    Start-Process "chmod" -ArgumentList "+x $($Miner.InstanceName)" -Wait
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    Start-Sleep -S .25
    Write-Host "Starting $($Miner.Name) Mining $($Miner.Coins) on $($Miner.Type)" -ForegroundColor Cyan
    Start-Sleep -S .25
    $MinerDir = $(Split-Path $($Miner.Path))
    $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
    $Logs = Join-Path $Dir "logs"
    $Export = Join-Path $Dir "build\export"
    if ($Miner.Type -like "*NVIDIA*") {Start-Process ".\build\bash\startupnvidia.sh" -ArgumentList "$MinerDir $($Miner.Type) $Dir/build/bash $Logs $Export" -Wait}
    if ($Miner.Type -like "*AMD*") {Start-Process ".\build\bash\startupamd.sh" -ArgumentList "$MinerDir $($Miner.Type) $Dir/build/bash $Logs $Export" -Wait}
    if ($Miner.Type -like "*CPU*") {Start-Process ".\build\bash\startupcpu.sh" -ArgumentList "$MinerDir $($Miner.Type) $Dir/build/bash $Logs" -Wait}
    Write-Host "$MinerDir $($Miner.Type) $Dir/build/bash $Logs $Export"
    $MinerTimer.Restart()
    $MinerProcessId = $null
    Do {
        Start-Sleep -S 1
        Write-Host "Getting Process ID for $($Miner.MinerName)"           
        $MinerProcessId = Get-Process -Name "$($Miner.InstanceName)" -ErrorAction SilentlyContinue
    }until($MinerProcessId -ne $null -or ($MinerTimer.Elapsed.TotalSeconds) -ge 10)  
    if ($MinerProcessId -ne $null) {
        $MinerProcessId.Id | Set-Content ".\build\pid\$($Miner.Name)_$($Miner.Coins)_$($Miner.InstanceName)_pid.txt" -Force
        Get-Date | Set-Content ".\build\pid\$($Miner.Name)_$($Miner.Coins)_$($Miner.InstanceName)_date.txt" -Force
        Start-Sleep -S 1
    }
    $MinerTimer.Stop()
    Rename-Item "$MinerDir\$($Miner.InstanceName)" -NewName "$($Miner.MinerName)" -Force
    Start-Sleep -S .25
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    $MinerProcess.Id
}