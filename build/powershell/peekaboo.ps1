function Start-Peekaboo {
    param (
    [Parameter(Mandatory=$false)]
    [String]$HiveId,
    [Parameter(Mandatory=$false)]
    [String]$HivePassword,
    [Parameter(Mandatory=$false)]
    [String]$HiveMirror
    )

 . .\build\powershell\commandweb.ps1

$getversion = (Split-Path $script:MyInvocation.MyCommand.Path -Leaf)
$version = $getversion -replace ("SWARM.","")
$getuid =  $(Get-NetAdapter | Select MacAddress).MacAddress -replace ("-","")
$enc = [system.Text.Encoding]::UTF8
$string1 = "$getuid".ToLower()
$data1 = $enc.GetBytes($string1) 
$sha = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider 
$result1 = $sha.ComputeHash($data1)
$uid = [System.Convert]::ToBase64String($result1)
$Date = [int][double]::Parse((Get-Date -UFormat %s))
$BootTime = (Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime).lastbootuptime
$Getboot = [math]::Round(((Get-Date)-[DateTime]$BootTime).TotalSeconds)
$GetbootTime = $Date - $Getboot
Write-Host "Last Boot Time Is $GetbootTime"
$Ip = $(get-WmiObject Win32_NetworkAdapterConfiguration| Where {$_.Ipaddress.length -gt 1}).ipaddress[0]
Invoke-Expression ".\build\apps\nvidia-smi.exe --query-gpu=gpu_bus_id,vbios_version,gpu_name,memory.total,power.min_limit,power.default_limit,power.max_limit --format=csv > "".\build\txt\getgpu.txt"""
$GetGPU = Get-Content ".\build\txt\getgpu.txt" | ConvertFrom-Csv
$GPUS = @()
for($i=0; $i -lt $GetGPU.count; $i++){$GPUS += @{busid = ($GetGPU."pci.bus_id"[$i] -split ":",2 | Select -Last 1).ToLower(); name =  $GetGPU.name[$i]; brand = "nvidia"; subvendor = "nvidia"; mem = $GetGPU."memory.total [MiB]"[$i]; vbios = ($GetGPU.vbios_version[$i]).ToLower(); plim_min = $GetGPU."power.min_limit [W]"[$i]; plim_def = $GetGPU."power.default_limit [W]"[$i]; plim_max = $GetGPU."power.max_limit [W]"[$i];}}
$manu = $(Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer).Manufacturer
$prod = $(Get-WmiObject Win32_BaseBoard | Select-Object Product).Product
$cpud = Get-WmiObject -Class Win32_processor | ft Name,DeviceID,NumberOfCores
$cpuname = $cpud.name
$cpucores = $cpud.NumberOfCores
$cpuid = $cpud.DeviceID
$disk = $(Get-WMIObject win32_diskdrive).model
$url = $HiveMirror

$Hello = @{
    method = "hello"
    jsonrpc = "2.0"
    id = "0"
    params = @{
        uid = "$uid"
        rig_id = "$HiveId"
        passwd = "$HivePassword"
        boot_time = "$GetbootTime"
        boot_event = "0"
        ip = "$Ip"
        net_interfaces = ""
        openvpn = ""
        gpu = $GPUS
        gpu_count_amd = "0"
        gpu_cound_nvidia = "$($GetGPU.Count)"
        version = '0.5-82'
        nvidia_version = "410.76"
        amd_version = "18.10"
        manufacturer = "$manu"
        product = "$prod" 
        model = "$cpuname"
        cores = "$cpucores"
        aes = ""
        cpu_id = "$cpuid"
        disk_model = "$disk"
        kernel = '4.13.16-hiveos'
        server_url = "$url"
       }
      }

      
   Write-Host "Saying Hello To Hive"
   $Hello | ConvertTo-Json -Depth 3 -Compress | Set-Content ".\build\txt\hello.txt"

try{
    $response = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($Hello | ConvertTo-Json -Depth 3 -Compress) -ContentType 'application/json'
    if($response.result.exec){
    Write-Host "Sending Command $($response.result.exec) To Hive"
    $message = Start-webcommand $response
    if($message){$hiveresponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($message | ConvertTo-Json -Depth 1) -ContentType 'application/json'}
    $message = $hiveresponse
    }
    else{$message = $response.result.config}
   }
   catch{$message = "Failed To Contact HiveOS.Farm"}

   return $message
}