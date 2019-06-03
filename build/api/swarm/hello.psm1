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
function Global:Start-Hello($RigData) {

    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

    ## Get Device Groups
    $Count = 0
    $ad = $false
    $Check = $Global:Busdata | Where brand -eq "amd"
    if ($Check) { $ad = $true }
    $Global:BusData | % {
        if ($ad) {
            if ($_.brand -eq "amd") { $_ | Add-Member "devices_group" "AMD1" }
            else {
                if ($global:Config.Params.GPUDevices3 -and $Count -in $global:Config.Params.GPUDevices3) {
                    $_ | Add-Member "devices_group" "NVIDIA3" 
                }
                else { $_ | Add-Member "devices_group" "NVIDIA2" }
            }
        }
        else {
            if ($global:Config.Params.GPUDevices1 -and $Count -in $global:Config.Params.GPUDevices1) {
                $_ | Add-Member "devices_group" "NVIDIA1" 
            }
            elseif ($global:Config.Params.GPUDevices2 -and $Count -in $global:Config.Params.GPUDevices2) {
                $_ | Add-Member "devices_group" "NVIDIA2" 
            }
            elseif ($global:Config.Params.GPUDevices3 -and $Count -in $global:Config.Params.GPUDevices3) {
                $_ | Add-Member "devices_group" "NVIDIA3" 
            }
            else { $_ | Add-Member "devices_group" "NVIDIA1" }
        }
        $Count++
    }

    $Hello = @{
        farm_hash = "$($global:Config.Params.SWARM_Hash)"
        worker    = @{
            name                   = "$($global:Config.SWARM_params.Worker)"
            uid                    = $RigData.uid
            nvidia_version         = "$($RigData.nvidia_version)"
            boot_time              = "$($RigData.boot_time)"
            kernel                 = "$($RigData.kernel)"
            amd_version            = "$($RigData.amd_version)"
            disk_model             = "$($RigData.disk_model)"
            ip                     = "$($RigData.ip)"
            gpu_count_amd          = "$($RigData.gpu_count_amd)"
            gpu_count_nvidia       = "$($RigData.gpu_count_nvidia)"
            gpus_attributes        = $RigData.gpu
            cpus_attributes        = @{
                model  = "$($RigData.cpu.model)"
                cores  = "$($RigData.cpu.cores)"
                aes    = "$($RigData.cpu.aes)"
                cpu_id = "$($RigData.cpu.cpu_id)"
            }
            motherboard_attributes = @{
                manufacturer = "$($RigData.mb.manufacturer)"
                product      = "$($RigData.mb.product)"
            }
        }
    }
      
    Global:Write-Log "Saying Hello To SWARM"
    $GetHello = $Hello | ConvertTo-Json -Depth 3 -Compress
    $GetHello | Set-Content ".\build\txt\swarm_hello.txt"
    Global:Write-Log "$GetHello" -ForegroundColor Green

    try {
        $response = Invoke-RestMethod "$($Global:Config.swarm_params.Mirror)/api/v1/workers/connect" -TimeoutSec 15 -Method POST -Body $GetHello -ContentType 'application/json'
        $response | ConvertTo-Json | Out-File ".\build\txt\get-swarm-hello.txt"
        $message = $response
    }
    catch { $message = "Failed To Contact SWARM monitoring site" }

    return $message
}

function Global:Start-WebStartup($response, $Site) {
    
    switch ($Site) {
        "HiveOS" { $Params = "hive_params" }
        "SWARM" { $Params = "SWARM_Params" }
    }

    if ($response.result) { $RigConf = $response }
    elseif (Test-Path ".\build\txt\get-swarm-hello.txt") {
        Global:Write-Log "WARNGING: Failed To Contact SWARM. Using Last Known Configuration"
        Start-Sleep -S 2
        $RigConf = Get-Content ".\build\txt\get-swarm-hello.txt" | ConvertFrom-Json
    }
    if ($RigConf) {
        $RigConf.result | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
            $Action = $_
            Switch ($Action) {
                "config" {
                    $Rig = [string]$RigConf.result.config | ConvertFrom-StringData                
                    $global:Config.$Params.Worker = $Rig.WORKER_NAME -replace "`"", ""
                    $global:Config.$Params.Password = $Rig.RIG_PASSWD -replace "`"", ""
                    $global:Config.$Params.Mirror = $Rig.HIVE_HOST_URL -replace "`"", ""
                    $global:Config.$Params.FarmID = $Rig.FARM_ID -replace "`"", ""
                    $global:Config.$Params.Id = $Rig.RIG_ID -replace "`"", ""
                    $global:Config.$Params.Wd_enabled = $Rig.WD_ENABLED -replace "`"", ""
                    $global:Config.$Params.Wd_Miner = $Rig.WD_MINER -replace "`"", ""
                    $global:Config.$Params.Wd_reboot = $Rig.WD_REBOOT -replace "`"", ""
                    $global:Config.$Params.Wd_minhashes = $Rig.WD_MINHASHES -replace "`"", ""
                    $global:Config.$Params.Miner = $Rig.MINER -replace "`"", ""
                    $global:Config.$Params.Miner2 = $Rig.MINER2 -replace "`"", ""
                    $global:Config.$Params.Timezone = $Rig.TIMEZONE -replace "`"", ""

                    if (Test-Path ".\build\txt\$($Params)_keys.txt") { $OldKeys = Get-Content ".\build\txt\$($Params)_keys.txt" | ConvertFrom-Json }

                    ## If password was changed- Let Hive know message was recieved

                    if ($OldKeys) {
                        if ("$($global:Config.$Params.Password)" -ne "$($OldKeys.Password)") {
                            $method = "message"
                            $messagetype = "warning"
                            $data = "Password change received, wait for next message..."
                            $DoResponse = Global:Set-Response -Method $method -MessageType $messagetype -Data $data -CommandID $command.result.id -Site $Site
                            $sendResponse = $DoResponse | Global:Invoke-WebCommand -Site $Site -Action "Message"
                            $SendResponse
                            $DoResponse = @{method = "password_change_received"; params = @{rig_id = $global:Config.$Params.Id; passwd = $global:Config.$Params.Password }; jsonrpc = "2.0"; id = "0" }
                            $send2Response = $DoResponse | Global:Invoke-WebCommand -Site $Site -Action "Message"
                        }
                    }

                    ## Set Arguments/New Parameters
                    $global:Config.$Params | ConvertTo-Json | Set-Content ".\build\txt\$($Params)_keys.txt"
                }

                ##If Hive Sent OC Start SWARM OC
                "nvidia_oc" {
                    Global:Start-NVIDIAOC $RigConf.result.nvidia_oc 
                }
                "amd_oc" {
                    Global:Start-AMDOC $RigConf.result.amd_oc
                }
            }
        }
        ## Print Data to output, so it can be recorded in transcript
        $RigConf.result.config
    }
    else {
        Global:Write-Log "No SWARM Config- Do you have an account? Did you use your farm hash?"
        Global:Write-Log "Try running Hive_Windows_Reset.bat then try again."
        Start-Sleep -S 2
    }
}