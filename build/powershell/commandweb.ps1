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

function Start-Webcommand {
    Param(
        [Parameter(Mandatory = $false)]
        [Object]$Command,
        [Parameter(Mandatory = $false)]
        [string]$swarm_message,
        [Parameter( Mandatory = $false)]
        [string]$HiveID,  
        [Parameter(Mandatory = $false)]
        [string]$HivePassword,
        [Parameter(Mandatory = $false)]
        [string]$HiveMirror
    )
 
    Switch ($Command.result.command) { 
        "timeout" {
            $method = "message"
            $messagetype = "warning"
            $data = $swarm_message
            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
            $trigger = "exec"
        }
  
  
        "OK" {$trigger = "stats"}
  
        "reboot" {
            $method = "message"
            $messagetype = "success"
            $data = "Rebooting"
            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
            Write-Host $method $messagetype $data
            $trigger = "reboot"
            $MinerFile = ".\build\pid\miner_pid.txt"
            if (Test-Path $MinerFile) {$MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue}
            if ($MinerId) {
                Stop-Process $MinerId
                Start-Sleep -S 3
            }
            Start-Process "powershell" -ArgumentList "-executionpolicy bypass -windowstyle maximized -command `".\build\powershell\reboot.ps1`""
            exit
        }
  
        ##upgrade
  
        "exec" {
            $firstword = $command.result.exec -split " " | Select -First 1
            $secondword = $command.result.exec -split " " | Select -Skip 1 -First 1
            Switch ($firstword) {
                "nvidia-smi" {
                    $method = "message"
                    $messagetype = "info"
                    $data = "nvidia-smi"
                    invoke-expression ".\build\apps\nvidia-smi.exe" | Tee-Object ".\build\txt\getcommand.txt" | Out-Null
                    $getpayload = Get-Content ".\build\txt\getcommand.txt"
                    $line = @()
                    $getpayload | foreach {$line += "$_`n"}
                    $payload = $line
                    $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                    $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                    $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    Write-Host $method $messagetype $data
                    $trigger = "exec"
                    if (Test-Path ".\build\txt\getcommand.txt") {Clear-Content ".\build\txt\getcommand.txt"}  
                }
                "ps" {
                    $method = "message"
                    $messagetype = "info"
                    $data = "ps"
                    $pscommand = $command.result.exec -split "ps ", ""
                    Start-Process "powershell" -ArgumentList "-executionpolicy bypass -command `"$pscommand | Tee-Object `"$WorkingDir\build\txt\getcommand.txt`"`"" -Verb RunAs -Wait
                    $getpayload = Get-Content ".\build\txt\getcommand.txt"
                    $line = @()
                    $getpayload | foreach {$line += "$_`n"}
                    $payload = $line
                    $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                    $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                    $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    Write-Host $method $messagetype $data
                    $trigger = "exec"
                    if (Test-Path ".\build\txt\getcommand.txt") {Clear-Content ".\build\txt\getcommand.txt"}
                }
                "stats" {
                    $method = "message"
                    $messagetype = "info"
                    $data = "stats"
                    $getpayload = Get-Content ".\build\txt\minerstats.txt"
                    $line = @()
                    $getpayload | foreach {$line += "$_`n"}
                    $payload = $line
                    $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                    $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                    $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    Write-Host $method $messagetype $data
                    $trigger = "exec"
                }
                "active" {
                    $method = "message"
                    $messagetype = "info"
                    $data = "active"
                    $getpayload = Get-Content ".\build\txt\mineractive.txt"
                    $line = @()
                    $getpayload | foreach {$line += "$_`n"}
                    $payload = $line
                    $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                    $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                    $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    Write-Host $method $messagetype $data
                    $trigger = "exec"
                }
                "version" {
                    Switch ($secondword) {
                        "query" {
                            $method = "message"
                            $messagetype = "info"
                            $data = "$($command.result.exec)"
                            start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\version.ps1 -platform windows -command query""" -Wait -WindowStyle Minimized -Verb RunAs
                            $getpayload = Get-Content ".\build\txt\version.txt"
                            $line = @()
                            $getpayload | foreach {$line += "$_`n"}
                            $payload = $line
                            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                            Write-Host $method $messagetype $data
                            $trigger = "exec"
                        }
                        "update" {
                            $method = "message"
                            $messagetype = "info"
                            $data = "$($command.result.exec)"
                            $arguments = $data -replace ("version ", "")
                            start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\version.ps1 -platform windows -command $arguments""" -WindowStyle Minimized -Verb Runas -Wait
                            $getpayload = Get-Content ".\build\txt\version.txt"
                            $line = @()
                            $getpayload | foreach {$line += "$_`n"}
                            $payload = $line
                            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                            Write-Host $method $messagetype $data
                            Start-Process ".\SWARM.bat"
                            Start-Sleep -S 2
                            $ID = ".\build\pid\background_pid.txt"
                            $BackGroundID = Get-Process -id (Get-Content "$ID" -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue
                            Stop-Process $BackGroundID | Out-Null
                        }
                    }
                }
                "clear_profits" {
                    $method = "message"
                    $messagetype = "info"
                    $data = "clear_profits"
                    start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\clear_profits.ps1""" -WindowStyle Minimized -Verb Runas -Wait
                    $getpayload = Get-Content ".\build\txt\get.txt"
                    $line = @()
                    $getpayload | foreach {$line += "$_`n"}
                    $payload = $line 
                    $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                    $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                    $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    Write-Host $method $messagetype $data
                    $trigger = "exec"
                }
                "clear_watts" {
                    $method = "message"
                    $messagetype = "info"
                    $data = "clear_watts"
                    start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\clear_watts.ps1""" -WindowStyle Minimized -Verb Runas -Wait
                    $getpayload = Get-Content ".\build\txt\get.txt"
                    $line = @()
                    $getpayload | foreach {$line += "$_`n"}
                    $payload = $line 
                    $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                    $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                    $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    Write-Host $method $messagetype $data
                    $trigger = "exec"
                }
                "get" {
                    $method = "message"
                    $messagetype = "info"
                    $data = "$($command.result.exec)"
                    $arguments = $data -replace ("get ", "")
                    $line = @()
                    if ($data -eq "get update") {    
                        $version = Get-Content ".\build\txt\version.txt"
                        $versionnumber = $version -replace "SWARM.", ""
                        $version1 = $versionnumber[4]
                        $version1 = $version1 | % {iex $_}
                        $version1 = $version1 + 1
                        $version2 = $versionnumber[2]
                        $version3 = $versionnumber[0]
                        if ($version1 -eq 10) {
                            $version1 = 0; 
                            $version2 = $version2 | % {iex $_}
                            $version2 = $version2 + 1
                        }
                        if ($version2 -eq 10) {
                            $version2 = 0; 
                            $version3 = $version3 | % {iex $_}
                            $version3 = $version3 + 1
                        }
                        $versionnumber = "$version3.$version2.$version1"    
                        $Failed = $false
                        $line += "Operating System Is Windows: Updating via 'get' is possible`n"
                        $versionlink = "https://github.com/MaynardMiner/SWARM/releases/download/v$VersionNumber/SWARM.$VersionNumber.zip"
                        $line += "Detected New Version Should Be $VersionNumber`n"
                        Write-Host "Detected New Version Should Be $VersionNumber"
                        $line += "Attempting To Download New Version at $Versionlink`n"
                        Write-Host "Attempting To Download New Version at $Versionlink"
                        $Location = Split-Path $WorkingDir
                        $line += "Main Directory is $Location`n"
                        Write-Host "Main Directory is $Location"
                        $NewLocation = Join-Path (Split-Path $WorkingDir) "SWARM.$VersionNumber"
                        $FileName = join-path ".\x64" "SWARM.$VersionNumber.zip"
                        $DLFileName = Join-Path "$WorkingDir" "x64\SWARM.$VersionNumber.zip"
                        $URI = "https://github.com/MaynardMiner/SWARM/releases/download/v$versionNumber/SWARM.$VersionNumber.zip"
                        try {Invoke-WebRequest $URI -OutFile $FileName -UseBasicParsing -ErrorAction Stop}catch {$Failed = $true; $line += "Failed To Contact Github For Download! Must Do So Manually"}
                        Start-Sleep -S 5
                        if ($Failed -eq $false) {
                            Start-Process "7z" "x `"$($DLFileName)`" -o`"$($Location)`" -y" -Wait -WindowStyle Minimized
                            Start-Sleep -S 3
                            $line += "Config Command Initiated- Restarting SWARM`n"
                            Write-Host "Config Command Initiated- Restarting SWARM"
                            $MinerFile = ".\build\pid\miner_pid.txt"
                            if (Test-Path $MinerFile) {$MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue}
                            if ($MinerId) {
                                Stop-Process $MinerId -Force
                                $line += "Stopping Old Miner`n"
                                Write-Host "Stopping Old Miner"
                                Start-Sleep -S 5
                                Write-Host "Attempting to start new SWARM verison at $NewLocation\SWARM.bat"
                                $line += "Downloaded and extracted SWARM successfully`n"
                                Copy-Item ".\SWARM.bat" -Destination $NewLocation -Force
                                Copy-Item ".\config\parameters\newarguments.json" -Destination "$NewLocation\config\parameters" -Force
                                New-Item -Name "pid" -Path "$NewLocation\build" -ItemType "Directory"
                                Copy-Item ".\build\pid\background_pid.txt" -Destination "$NewLocation\build\pid" -Force
                                Set-Location $NewLocation
                                Start-Process "SWARM.bat"
                                Set-Location $WorkingDir
                                $payload = $line
                                $Trigger = "update"
                            }
                        }     
                    }
                    else {
                        start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\get.ps1 $arguments""" -Wait -WindowStyle Minimized -Verb Runas; $Trigger = "exec"
                        $getpayload = Get-Content ".\build\txt\get.txt"
                        $getpayload | foreach {$line += "$_`n"}
                        $payload = $line
                    }
                    $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                    $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                    $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    Write-Host $method $messagetype $data
                }
                "miner" {
                    switch ($secondword) {
                        "restart" {
                            $method = "message"
                            $messagetype = "success"
                            $data = "Miner Restarted"
                            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
                            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                            Write-Host $method $messagetype $data
                            $trigger = "config"
                        }
                        "stop" {
                            $method = "message"
                            $messagetype = "success"
                            $data = "Miner stopped"
                            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
                            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                            Write-Host $method $messagetype $data
                            $GetMiner = Get-Content ".\build\pid\miner_pid.txt"
                            if($GetMiner){$MinerProcess = Get-PRocess -ID $GetMiner -ErrorAction SilentlyContinue; if($MinerProcess){Stop-Process $MinerProcess}}
                            $trigger = "exec"
                        }
                        "start" {
                            $method = "message"
                            $messagetype = "success"
                            $data = "Miner started"
                            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
                            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                            Write-Host $method $messagetype $data
                            $trigger = "config"
                        }
                    }
                } 
                "benchmark" {
                    $method = "message"
                    $messagetype = "info"
                    $data = "$($command.result.exec)"
                    $arguments = $data -replace ("benchmark ", "")
                    start-process "powershell" -Workingdirectory ".\build\powershell" -ArgumentList "-executionpolicy bypass -command "".\benchmark.ps1 $arguments""" -Wait -WindowStyle Minimized -Verb Runas
                    $getpayload = Get-Content ".\build\txt\get.txt"
                    $line = @()
                    $getpayload | foreach {$line += "$_`n"}
                    $payload = $line 
                    $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
                    $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                    $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    Write-Host $method $messagetype $data
                    $trigger = "exec"
                }
            }
        }
  
        "nvidia_oc" {
            $method = "message"
            $messagetype = "success"
            $data = "Nvidia settings applied"
            $NewOC = $Command.result.nvidia_oc | Convertto-Json -Compress
            $NewOC | Start-NVIDIAOC
            $getpayload = Get-Content ".\build\txt\ocnvidia.txt"
            $line = @()
            $getpayload | foreach {$line += "$_`n"}
            $payload = $line
            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
            Write-Host $method $messagetype $data
            $trigger = "exec"
        }
  
        "amd_oc" {
            $method = "message"
            $messagetype = "success"
            $data = "AMD settings applied"
            $NewOC = $Command.result.amd_oc | Convertto-Json -Compress
            $NewOC | Start-AMDOC
            $getpayload = Get-Content ".\build\txt\ocamd.txt"
            $line = @()
            $getpayload | foreach {$line += "$_`n"}
            $payload = $line
            $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id -Payload $payload
            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
            $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
            Write-Host $method $messagetype $data
            $trigger = "exec"
        }
  
        "config" {
            $Command.result | ConvertTo-Json | Set-Content ".\build\txt\hiveconfig.txt"
            if ($command.result.config) {
                $config = [string]$command.result.config | ConvertFrom-StringData
                $hiveworker = $config.WORKER_NAME -replace "`"", ""
                $Pass = $config.RIG_PASSWD -replace "`"", ""
                $mirror = $config.HIVE_HOST_URL -replace "`"", ""
                $hiveWorkerID = $config.RIG_ID
                $NewHiveKeys = @{}
                $NewHiveKeys.Add("HiveWorker", "$hiveworker")
                $NewHiveKeys.Add("HivePassword", "$Pass")
                $NewHiveKeys.Add("HiveID", "$hiveWorkerID")
                $NewHiveKeys.Add("HiveMirror", "$mirror")
                if (Test-Path ".\build\txt\hivekeys.txt") {$OldHiveKeys = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json}
                if ($OldHiveKeys) {
                    if ($NewHiveKeys.HivePassword -ne $OldHiveKeys.HivePassword) {
                        Write-Warning "Detected New Password"
                        $method = "message"
                        $messagetype = "warning"
                        $data = "Password change received, wait for next message..."
                        $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
                        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                        $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                        $SendResponse
                        $DoResponse = @{method = "password_change_received"; params = @{rig_id = $HiveID; passwd = $HivePassword}; jsonrpc = "2.0"; id = "0"}
                        $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                        $Send2Response = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                    }
                }
                $NewHiveKeys | ConvertTo-Json | Set-Content ".\build\txt\hivekeys.txt"        
            }
  
            if ($Command.result.wallet) {
                $method = "message"
                $messagetype = "success"
                $data = "Rig config changed"
                $arguments = $command.result.wallet
                $argjson = @{}
                $start = $arguments.Lastindexof("CUSTOM_USER_CONFIG=") + 20
                $end = $arguments.LastIndexOf("META") - 3
                $arguments = $arguments.substring($start, ($end - $start))
                $arguments = $arguments -replace "\'\\\'", ""
                $arguments = $arguments -replace "\u0027", "`'"
                $arguments = $arguments -split " -"
                $arguments = $arguments | foreach {$_.trim(" ")}
                $arguments = $arguments | % {$_.trimstart("-")}
                $arguments | foreach {$argument = $_ -split " " | Select -first 1; $argparam = $_ -split " " | Select -last 1; $argjson.Add($argument, $argparam); }
                $argjson = $argjson | ConvertTo-Json | ConvertFrom-Json
  
                $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json   
                $Params = @{}
  
                $Defaults |Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {$Params.Add("$($_)", "$($Defaults.$_)")}
  
                $argjson | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name |  foreach {
                    if ($Params.$_ -ne $argjson.$_) {
                        switch ($_) {
                            default {$Params.$_ = $argjson.$_}
                            "Type" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "Poolname" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "Currency" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "PasswordCurrency1" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "PasswordCurrency2" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "PasswordCurrency3" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "No_Algo1" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "No_Algo2" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "No_Algo3" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                            "No_Miner" {$NewParamArray = @(); $argjson.$_ -split "," | Foreach {$NewParamArray += $_}; $Params.$_ = $NewParamArray}
                        }
                    }
                }
  
                $DoResponse = Add-HiveResponse -Method $method -messagetype $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
                $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1
                $SendResponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                $SendResponse
                $Params | convertto-Json | Out-File ".\config\parameters\newarguments.json"
            }
            $trigger = "config"
        }
  
    }
    if (Test-Path ".\build\txt\get.txt") {Clear-Content ".\build\txt\get.txt"}
    $trigger
}