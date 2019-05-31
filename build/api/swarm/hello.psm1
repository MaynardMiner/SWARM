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

    $Hello = @{
        method  = "hello"
        jsonrpc = "2.0"
        id      = "0"
        params  = @{
            farm_hash        = "$($global:Config.Params.Farm_Hash)"
            server_url       = "$($global:Config.hive_params.HiveMirror)"
            uid              = $RigData.uid
            boot_time        = "$($RigData.boot_time)"
            boot_event       = "0"
            ip               = "$($RigData.ip)"
            net_interfaces   = ""
            openvpn          = "0"
            lan_config       = ""
            gpu              = $RigData.gpu
            gpu_count_amd    = "$($RigData.gpu_count_amd)"
            gpu_count_nvidia = "$($RigData.gpu_count_nvidia)"
            worker_name      = "$($global:Config.hive_params.HiveWorker)" 
            version          = ""
            kernel           = "$($RigData.kernel)"
            amd_version      = "$($RigData.amd_version)"
            nvidia_version   = "$($RigData.nvidia_version)"
            mb               = @{
                manufacturer = "$($RigData.mb.manufacturer)"
                product      = "$($RigData.mb.product)" 
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
      
    Global:Write-Log "Saying Hello To SWARM"
    $GetHello = $Hello | ConvertTo-Json -Depth 3 -Compress
    $GetHello | Set-Content ".\build\txt\hello.txt"
    Global:Write-Log "$GetHello" -ForegroundColor Green

    try {
        $response = Invoke-RestMethod "$($Global:Config.hive_params.HiveMirror)/worker/api" -TimeoutSec 15 -Method POST -Body ($Hello | ConvertTo-Json -Depth 3 -Compress) -ContentType 'application/json'
        $response | ConvertTo-Json | Out-File ".\build\txt\get-swarm-hello.txt"
        $message = $response
    }
    catch { $message = "Failed To Contact SWARM webstie" }

    return $message
}