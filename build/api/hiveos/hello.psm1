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
    
    $message = @()

    $Hello = @{
        method  = "hello"
        jsonrpc = "2.0"
        id      = "0"
        params  = @{
            farm_hash        = "$($(arg).Hive_Hash)"
            server_url       = "$($global:Config.hive_params.Mirror)"
            uid              = $RigData.uid
            boot_time        = "$($RigData.boot_time)"
            boot_event       = "0"
            ip               = "$($RigData.ip)"
            net_interfaces   = ""
            openvpn          = "0"
            lan_config       = ""
            gpu              = @($RigData.gpu)
            gpu_count_amd    = "$($RigData.gpu_count_amd)"
            gpu_count_nvidia = "$($RigData.gpu_count_nvidia)"
            worker_name      = "$($global:Config.hive_params.Worker)" 
            version          = ""
            kernel           = "$($RigData.kernel)"
            amd_version      = "$($RigData.amd_version)"
            nvidia_version   = "$($RigData.nvidia_version)"
            mb               = @{
                manufacturer = "$($RigData.mb.manufacturer)"
                product      = "$($RigData.mb.product)" 
                system_uuid  = "$($RigData.mb.system_uuid)" 
            }
            cpu              = @{
                model  = "$($RigData.cpu.model)"
                cores  = "$($RigData.cpu.cores)"
                aes    = "$($RigData.cpu.aes)"
                cpu_id = "$($RigData.cpu.cpu_id)"
            }
            disk_model       = "$($RigData.disk_model)"
        }
    }
      
    log "Saying Hello To Hive"
    $GetHello = $Hello | ConvertTo-Json -Depth 3 -Compress
    $GetHello | Set-Content ".\build\txt\hive_hello.txt"
    log "$GetHello" -ForegroundColor Green

    try {
        $response = Invoke-RestMethod "$($Global:Config.hive_params.Mirror)/worker/api" -TimeoutSec 15 -Method POST -Body ($Hello | ConvertTo-Json -Depth 3 -Compress) -ContentType 'application/json'
        $response | ConvertTo-Json | Out-File ".\build\txt\get-hive-hello.txt"
        $message = $response
    }
    catch [Exception] {
        log "Exception: $($_.Exception.Message)" -ForegroundColor Red;
    }
        
    return $message
}

function Global:Start-WebStartup($response, $Site) {
    
    switch ($Site) {
        "HiveOS" { $Params = "hive_params" }
        "SWARM" { $Params = "SWARM_Params" }
    }

    if ($response.result) { $RigConf = $response }
    elseif (Test-Path ".\build\txt\get-hive-hello.txt") {
        log "WARNGING: Failed To Contact HiveOS. Using Last Known Configuration"
        Start-Sleep -S 2
        $RigConf = Get-Content ".\build\txt\get-hive-hello.txt" | ConvertFrom-Json
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
                    $global:Config.$Params.WD_CHECK_GPU = $Rig.WD_CHECK_GPU -replace "`"", ""
                    $global:Config.$Params.PUSH_INTERVAL = $Rig.PUSH_INTERVAL -replace "`"", ""
                    $global:Config.$Params.MINER_DELAY = $Rig.MINER_DELAY -replace "`"", ""

                    if (Test-Path ".\config\parameters\$($Params)_keys.json") { $OldHiveKeys = Get-Content ".\config\parameters\$($Params)_keys.json" | ConvertFrom-Json }

                    ## If password was changed- Let Hive know message was recieved

                    if ($OldHiveKeys) {
                        if ("$($global:Config.$Params.Password)" -ne "$($OldHiveKeys.Password)") {
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
                    $global:Config.$Params | ConvertTo-Json | Set-Content ".\config\parameters\$($Params)_keys.json"
                }
                "wallet" {
                    $arguments = [string]$RigConf.result.wallet
                    if ($arguments -like "*-wallet1*" -or $arguments -like "*`"wallet1`"*") {
                        $argjson = @{ }
                        $start = $arguments.Lastindexof("CUSTOM_USER_CONFIG=") + 20
                        $end = $arguments.LastIndexOf("META") - 3
                        $arguments = $arguments.substring($start, ($end - $start))
                        $arguments = $arguments -replace "\'\\\'", ""
                        $arguments = $arguments -replace "\u0027", "`'"
                        try { $test = "$arguments" | ConvertFrom-Json; if ($test) { $isjson = $true } } catch { $isjson = $false }
                        if ($isjson) {
                            $Params = @{ }
                            $test.PSObject.Properties.Name | % { $Params.Add("$($_)", $test.$_) }
                            $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
                            $Defaults.PSObject.Properties.Name | % { if ($_ -notin $Params.keys) { $Params.Add("$($_)", $Defaults.$_) } }
    
                        }
                        else {
                            $arguments = $arguments -split " -"
                            $arguments = $arguments | foreach { $_.trim(" ") }
                            $arguments = $arguments | % { $_.trimstart("-") }
                            $arguments | foreach { $argument = $_ -split " " | Select -first 1; $argparam = $_ -split " " | Select -last 1; $argjson.Add($argument, $argparam); }
                            $argjson = $argjson | ConvertTo-Json | ConvertFrom-Json
      
                            $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json   
                            $Params = @{ }
      
                            $Defaults | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % { $Params.Add("$($_)", $Defaults.$_) }
      
                            $argjson | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                if ($argjson.$_ -ne $Params.$_) {
                                    switch ($_) {
                                        default { $Params.$_ = $argjson.$_ }
                                        "Bans" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "Coin" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "Algorithm" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "GPUDevices3" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "Config.params.GPUDevices2" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "GPUDevices1" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "Asic_Algo" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "Type" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "Poolname" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "Currency" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "PasswordCurrency1" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "PasswordCurrency2" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                        "PasswordCurrency3" { $NewParamArray = @(); $argjson.$_ -split "," | Foreach { $NewParamArray += $_ }; $Params.$_ = $NewParamArray }
                                    }
                                }
                            }
                        }
                        $Params | convertto-Json | Out-File ".\config\parameters\newarguments.json"

                        ## Change parameters after getting them.
                        ## First change -Type and -Cputhreads if empty
                        if([string]$Params.Type -eq "") { $params.type = $(vars).types }
                        if([string]$Params.CpuThreads -eq "") { $params.CpuThreads = $(vars).threads }
                        $global:Config.params = @{ }
                        $global:Config.user_params = @{ }
                        $params.keys | % {
                            $Global:Config.params.Add($_ , $Params.$_ ) 
                            $Global:Config.user_params.Add( $_ , $Params.$_ )
                        }
                        $Global:Config.params.Platform = "windows"
                        $global:Config.user_params.Platform = "windows"
                }
                else { Write-Log "WARNING: User Flight Sheet Arguments Did Not Contain -Wallet1 argument. They were ignored!" -ForegroundColor Yellow; Start-Sleep -S 3 }
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
    log "No HiveOS Rig.conf- Do you have an account? Did you use your farm hash?"
    log "Try running Hive_Windows_Reset.bat then try again."
    Start-Sleep -S 2
}
}