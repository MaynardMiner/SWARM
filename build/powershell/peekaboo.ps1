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
function Start-Peekaboo {
    param (
        [Parameter(Mandatory = $false)]
        [String]$HiveId,
        [Parameter(Mandatory = $false)]
        [String]$HivePassword,
        [Parameter(Mandatory = $false)]
        [String]$HiveWorker,
        [Parameter(Mandatory = $false)]
        [String]$HiveMirror,
        [Parameter(Mandatory = $false)]
        [String]$GPUData,
        [Parameter(Mandatory = $false)]
        [String]$version
    )

    ##"{0:f0}" -f $($Test.AdapterRam/1000000)
    $AMDData = $GPUData | ConvertFrom-Json
    $NVIDIAData = $GPUData | ConvertFrom-Json
    $AMDData = $AMDData | Where PnPID -match "PCI\\VEN_1002*"
    $NVIDIAData = $NVIDIAData | Where PnPID -match "PCI\\VEN_10DE*"
    Invoke-Expression ".\build\apps\nvidia-smi.exe --query-gpu=gpu_bus_id,vbios_version,gpu_name,memory.total,power.min_limit,power.default_limit,power.max_limit --format=csv > "".\build\txt\getgpu.txt"""
    $GetGPU = Get-Content ".\build\txt\getgpu.txt" | ConvertFrom-Csv
    $getversion = (Split-Path $script:MyInvocation.MyCommand.Path -Leaf)
    $version = $getversion -replace ("SWARM.", "")
    $getuid = $(Get-NetAdapter | Select MacAddress).MacAddress -replace ("-", "")
    $enc = [system.Text.Encoding]::UTF8
    $string1 = "$getuid".ToLower()
    $data1 = $enc.GetBytes($string1) 
    $sha = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider 
    $result1 = $sha.ComputeHash($data1)
    $uid = [System.Convert]::ToBase64String($result1)
    $BootTime = $((Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime).lastbootuptime)
    $Uptime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End ($BootTime.ToUniversalTime())).TotalSeconds
    $UpTime = [Math]::Round($Uptime)
    $Ip = $(get-WmiObject Win32_NetworkAdapterConfiguration| Where {$_.Ipaddress.length -gt 1}).ipaddress[0]
    $GPUS = @()
    if ($AMDData) {for ($i = 0; $i -lt $AMDData.name.Count; $i++) {$GPUS += @{busid = ($AMDData[$i].PCIBusID).ToLower(); name = $AMDData[$i].Name; brand = $AMDData[$i].brand; subvendor = $AMDData[$i].subvendor ; mem = $AMDData[$i].ram; mem_type = "unknown"; vbios = "unknown"}}
    }
    if ($GetGPU) {for ($i = 0; $i -lt $GetGPU.name.count; $i++) {$GPUS += @{busid = "$($GetGPU[$i]."pci.bus_id" -split ":",2 | Select -Last 1)".ToLower(); name = $GetGPU[$i].name; brand = "nvidia"; subvendor = $NVIDIAData[$i].subvendor ; mem = $GetGPU[$i]."memory.total [MiB]"; vbios = "$($GetGPU[$i].vbios_version)".ToLower(); plim_min = $GetGPU[$i]."power.min_limit [W]"; plim_def = $GetGPU[$i]."power.default_limit [W]"; plim_max = $GetGPU[$i]."power.max_limit [W]"; }}
    }
    $manu = $(Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer).Manufacturer
    $prod = $(Get-WmiObject Win32_BaseBoard | Select-Object Product).Product
    $cpud = Get-WmiObject -Class Win32_processor | Select Name, DeviceID, NumberOfCores
    $cpuname = $cpud.name
    $cpucores = $cpud.NumberOfCores
    $cpuid = $cpud.DeviceID
    $disk = $(Get-WMIObject win32_diskdrive).model
    $url = $HiveMirror
    $swarmversion = Get-Content ".\h-manifest.conf" | ConvertFrom-StringData
    $swarmversion = $swarmversion.CUSTOM_VERSION
    Invoke-Expression ".\build\apps\nvidia-smi.exe --query-gpu=driver_version --format=csv" | Tee-Object -Variable nversion | Out-Null
    $nvidiaversion = $nversion | ConvertFrom-Csv
    $nvidiaversion = $nvidiaversion.driver_version | Select -First 1

    $Hello = @{
        method  = "hello"
        jsonrpc = "2.0"
        id      = "0"
        params  = @{
            farm_hash        = "$FARM_HASH"
            server_url       = "$url"
            uid              = $uid
            boot_time        = "$UpTime"
            boot_event       = "0"
            ip               = "$Ip"
            net_interfaces   = ""
            openvpn          = "0"
            lan_config       = ""
            gpu              = $GPUS
            gpu_count_amd    = "$($AMDData.name.Count)"
            gpu_count_nvidia = "$($GetGPU.name.count)"
            worker_name      = "$HiveWorker" 
            version          = ""
            kernel           = "$swarmversion"
            amd_version      = "18.10"
            nvidia_version   = "$nvidiaversion"
            mb               = @{
                manufacturer = "$manu"
                product      = "$prod" 
            }
            cpu              = @{
                model  = "$cpuname"
                cores  = "$cpucores"
                aes    = "2"
                cpu_id = "$cpuid"
            }
            disk_model       = "$disk"
        }
    }
      
    Write-Host "Saying Hello To Hive"
    $GetHello = $Hello | ConvertTo-Json -Depth 3 -Compress
    $GetHello | Set-Content ".\build\txt\hello.txt"
    Write-Host "$GetHello" -ForegroundColor Green

    try {
        $response = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($Hello | ConvertTo-Json -Depth 3 -Compress) -ContentType 'application/json'
        $response | ConvertTo-Json | Out-File ".\build\txt\get-hello.txt"
        $message = $response
    }
    catch {$message = "Failed To Contact HiveOS.Farm"}

    return $message
}