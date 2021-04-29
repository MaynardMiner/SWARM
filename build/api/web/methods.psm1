
Function GLobal:Get-StringHash([String] $String, $HashName = "SHA1") { 
    $StringBuilder = New-Object System.Text.StringBuilder ; 
    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String)) | Foreach-Object  { 
        [Void]$StringBuilder.Append($_.ToString("x2")) 
    }; 
    $StringBuilder.ToString() 
}

function Global:Get-RigData {


    Switch ($IsWindows) {
        $True {
            $RigData = @{ }
            $getuid = (Get-CimInstance win32_networkadapterconfiguration | Where-Object  { $null -ne $_.IPAddress } | Select-Object  MACAddress).MacAddress[0] -replace ("`:", "")
            $uuid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
            $RigData.Add("cpu", @{ })
            $cpud = Get-CimInstance -Class Win32_processor | Select-Object  Name, ProcessorId, NumberOfCores
            $cpuname = $cpud.name.Trim()
            $RigData.cpu.Add("model", $cpuname)
            $cpucores = $cpud.NumberOfCores
            $RigData.cpu.Add("cores", $cpucores)
            $cpuid = $cpud.ProcessorId
            $RigData.cpu.Add("cpu_id", $cpuid)
            $string1 = $getuid + "-" + $uuid + "-" + $cpuid
            $string1 = "$string1".ToLower()
            $uid = Global:Get-StringHash $string1
            $RigData.Add("uid", $uid)
            $BootTime = $((Get-CimInstance -ClassName win32_operatingsystem | Select-Object  lastbootuptime).lastbootuptime)
            $Uptime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End ($BootTime.ToUniversalTime())).TotalSeconds
            $UpTime = [Math]::Round($Uptime)
            $RigData.Add("boot_time", $Uptime)
            $Ip = $(Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object  { $_.Ipaddress.length -gt 1 }).ipaddress[0]
            $RigData.Add("ip", "$Ip")
            $RigData.Add("gpu", $(vars).BusData)
            $AMDCount = ($(vars).BusData | Where-Object  brand -eq "amd").Count
            $NVIDIACount = ($(vars).BusData | Where-Object  brand -eq "nvidia").Count
            $RigData.Add("gpu_count_amd", "$AMDCount")
            $RigData.Add("gpu_count_nvidia", "$NVIDIACount")
            $manu = $(Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer).Manufacturer
            $RigData.Add("mb", @{ })
            $RigData.mb.Add("manufacturer", $manu)
            $prod = $(Get-CimInstance Win32_BaseBoard | Select-Object Product).Product
            $RigData.mb.Add("product", $prod)
            $RigData.mb.Add("system_uuid",$uuid)
            $AES = $(Invoke-Expression ".\build\apps\features-win\features-win.exe" | Select-Object  -Skip 1 | ConvertFrom-StringData)."AES-NI"
            if ($AES -eq "Yes") { $HasAES = 1 }else { $HasAES = 0 }
            $RigData.cpu.Add("aes", $HasAES)
            $disk = $(Get-CimInstance win32_diskdrive).model
            $diskSpace = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size
            $diskSpace = $diskSpace.Size / [math]::pow( 1024, 3 )
            $diskSpace = [math]::Round($diskSpace)
            $diskSpace = "$($diskSpace)GB"
            $RigData.Add("disk_model", "$disk $diskSpace")
            $swarmversion = Get-Content ".\h-manifest.conf" | ConvertFrom-StringData
            $swarmversion = $swarmversion.CUSTOM_VERSION
            $RigData.Add("kernel", $swarmversion)
            invoke-expression ".\build\cmd\nvidia-smi.bat --query-gpu=driver_version --format=csv" | Tee-Object -Variable nversion | Out-Null
            $nvidiaversion = $nversion | ConvertFrom-Csv
            $nvidiaversion = $nvidiaversion.driver_version | Select-Object  -First 1
            $RigData.Add("nvidia_version", $nvidiaversion)
            Set-Location "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
            $Reg = $(Get-Item * -ErrorAction SilentlyContinue).Name
            $Reg = $Reg | Foreach-Object  { $_ -split "\\" | Select-Object  -Last 1 } | Foreach-Object  { if ($_ -like "*00*") { $_ } }
            $Reg | Foreach-Object  {
                if ($null -eq $DriverDesc) {
                    $DriverDesc = $(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($_)" -Name "RadeonSoftwareVersion" -ErrorAction SilentlyContinue).RadeonSoftwareVersion;
                }
            }
            if ($DriverDesc) { $AMDDriver = "$DriverDesc" }else { $AMDDriver = "0.0.0" }
            $RigData.Add("amd_version", $AMDDriver)
            Set-Location $($(vars).dir)
        }
        $false {
            ##dmidecode 3.1
            $RigData = @{ }
            $cpuid = "$(Invoke-Expression "./build/apps/dmidecode/dmidecode -t 4" | Select-String "ID: " | Foreach-Object {$_ -split "ID: " | Select-Object  -Last 1})" -replace " ", ""
            $uuid = Invoke-Expression "./build/apps/dmidecode/dmidecode -s system-uuid"
            $net = Invoke-Expression "ip -o link | grep -vE `'LOOPBACK|POINTOPOINT|sit0|can0`'"
            $net_interfaces = @()
            $net | Foreach-Object  { $eth = $_.Split(" ") | Select-Object  -Skip 1 -First 1; $mac = $_.Split(" ") | Select-Object  -Last 3 | Select-Object  -First 1; $net_interfaces += [PSCustomObject]@{ iface = $eth; mac = $mac } }
            $eth0 = "$($($net_interfaces | Select-Object  -First 1 ).mac)" -replace ":", ""
            $String1 = "$uuid-$cpuid-$eth0".ToLower()
            $uid = Global:Get-StringHash $string1
            $RigData.Add("uid",$uid)
            $Date = Invoke-Expression "date `+`%s"
            $Boot = $(Invoke-Expression "cat /proc/uptime") -split " " | Select-Object  -First 1
            $Boot_Time = [Math]::Round($Date - $Boot)     
            $RigData.Add("boot_time",$Boot_Time)
            $swarmversion = Get-Content ".\h-manifest.conf" | ConvertFrom-StringData
            $swarmversion = $swarmversion.CUSTOM_VERSION
            $RigData.Add("kernel",$swarmversion)
            $IP = @()
            $IPs = $(Invoke-Expression "hostname -I | sed `'s`/ `/`\n`/g`'") | Foreach-Object  {if($_ -ne ""){$IP += $_}}
            $RigData.Add("ip",$IP)
            $lan_address = Invoke-Expression "ip -o -f inet addr show | grep eth0 | awk `'/scope global/ {print `$4}`'"
            $lan_gateway = Invoke-Expression "ip route | awk `'/default/ && /eth0/ { print `$3 }`' | head -1"
            $lan_dns = Invoke-Expression "cat /run/systemd/resolve/resolv.conf | grep -m1 `^nameserver | awk '`{print `$2}`'"
            $get_dhcp = Invoke-Expression "cat /etc/systemd/network/20-ethernet.network" | Select-String "DHCP=yes"
            if($get_dhcp){$lan_dhcp = 1} else {$lan_dhcp = 0}
            $lan_config = [PSCustomObject]@{ dhcp = $lan_dhcp; address = $lan_address; gateway = $lan_gateway; dns = $lan_dns }
            $RigData.Add("net_interfaces",$net_interfaces)
            $RigData.Add("lan_config",$lan_config)
            $nv_ver = [Expression]::Invoke("nvidia-smi", "--help").Split("`n")[0]
            $nv_ver = invoke-expression "`"$nv_ver`" | awk `'{print `$NF}`' | sed `'s/v//`'"
            $amd_ver = [Expression]::Invoke("dpkg","-s amdgpu-pro");
            $amd_ver = Invoke-Expression "`"$amd_ver`" | grep `'`^Version`: `' | sed `'s/Version: `/`/`' | awk -F`'-`' `'{print `$1}`'"
            if(-not $amd_ver) {
                $amd_ver = [Expression]::Invoke("dpkg","-s amdgpu");
                $amd_ver = Invoke-Expression "`"$amd_ver`" | grep `'`^Version`: `' | sed `'s/Version: `/`/' | awk -F`'-`' `'{print `$1}`'"
            }
            if(-not $amd_ver){
                $amd_ver = [Expression]::Invoke("dpkg","-s opencl-amdgpu-pro-icd");
                $amd_ver = Invoke-Expression "`"$amd_ver`" | grep `'`^Version`: `' | sed `'s/Version: `/`/' | awk -F`'-`' `'{print `$1}`'"            
            }
            if(-not $amd_ver){
                $amd_ver = "none";
            }
            $RigData.Add("nvidia_version",$nv_ver)
            $RigData.Add("amd_version",$amd_ver)
            $mb_manufacturer = Invoke-Expression "./build/apps/dmidecode/dmidecode | grep -A4 `'`^Base Board Information`' | grep `"Manufacturer:`" | sed -E `'s`/`\sManufacturer:`\`s`+(`.`*)`/`\1`/`'"
            $mb_product = Invoke-Expression "./build/apps/dmidecode/dmidecode | grep -A4 `'`^Base Board Information' | grep `"Product Name:`" | sed -E `'s`/`\sProduct Name:`\`s`+(`.`*)`/`\1`/'"
            $RigData.Add("mb",@{
                manufacturer = $mb_manufacturer
                product = $mb_product
                system_uuid = $uuid
            })
            $cpu_model = Invoke-Expression "lscpu | grep `"Model name:`" | sed `'`s`/Model name:[ `\t]`*`/`/g`'"
            $cpu_cores = Invoke-Expression "lscpu | grep `"`^CPU(s):`" | sed `'s`/CPU(s):[ `\t]`*`/`/`g`'"
            $aes = Invoke-Expression "lscpu | grep `"`^Flags:`.`*aes`" | wc -l"
            $RigData.Add("cpu",@{
                model = $cpu_model
                cores = $cpu_cores
                aes = $AES
                cpu_id = $cpuid
            })
            $bootpart = "$(Invoke-Expression "readlink -f /dev/block/`$(mountpoint -d `/)")"
            $bootpart = $bootpart.Substring(0, $bootpart.Length - 1)
            $disk = Invoke-Expression "parted -ml | grep -m1 `"$bootpart`:`""
            $disk_model = $disk -split ":"
            $disk_model = "$($disk_model | Select-Object  -Last 2 | Select-Object  -First 1) $($disk_model | Select-Object  -Skip 1 -First 1)"
            $RigData.Add("disk_model",$disk_model)
            $RigData.Add("gpu_count_nvidia",$($(vars).BusData | Where-Object  Brand -eq "nvidia").Count)
            $RigData.Add("gpu_count_amd",$($(vars).BusData | Where-Object  Brand -eq "amd").Count)
            $GPUS = @()
            $GPUS += $(vars).BusData
            $RigData.Add("gpu",$GPUS)
        }
    }
    $RigData

}

function Global:Invoke-WebCommand {
    Param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        [Parameter(Mandatory = $true)]
        [String]$Site,
        [Parameter(Mandatory = $true)]
        [String]$Action,
        [Parameter(Mandatory = $false)]
        [String]$method,
        [Parameter(Mandatory = $false)]
        [String]$Type,
        [Parameter(Mandatory = $false)]
        [string]$data,
        [Parameter(Mandatory = $false)]
        [String]$payload,
        [Parameter(Mandatory = $false)]
        [string]$Id
    )
    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

    ##First load Correct Modules
    Switch ($Site) {
        "HiveOS" { $URL = $global:config.hive_params.Mirror; }
        "SWARM" { $URL = $global:Config.SWARM_Params.Mirror; }
    }

    ##Run Command Based on action
    Switch ($Action) {
        "Hello" { 
            $Return = Global:Start-Hello $InputObject 
        }
        "Message" {
            if ($InputObject) { $Get = $InputObject | ConvertTo-Json -Depth 3 }
            else {
                $GetParams = @{ }
                if ($method) { $GetParams.Add("method", $method) }
                if ($Type) { $GetParams.Add("Type", $Type) }
                if ($data) { $GetParams.Add("data", $data) }
                if ($payload) { $GetParams.Add("payload", $payload) }
                if ($Id) { $GetParams.Add("Id", $Id) }
                $Get = Global:Set-Response @$GetParams;
                $Get = $Get | ConvertTo-JSon -Depth 1
            }
            try { $Return = Invoke-RestMethod "$URL/worker/api" -TimeoutSec 10 -Method Post -Body $Get -ContentType 'application/json' }
            catch { Write-Host "Failed To Contact $Site" -ForegroundColor Red; $Return = $null }
        }
        "oc" { }
    }

    $Return
}

function Global:Get-WebModules {
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Site
    )
    
    Switch ($Site) {
        "HiveOS" { $Web_Mods = Get-ChildItem ".\build\api\hiveos"; }
        "SWARM" { $Web_Mods = Get-ChildItem ".\build\api\swarm"; }
    }
    $Web_Mods | Foreach-Object  { Global:Add-Module $_.FullName }
}

function Global:Remove-WebModules {
    Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Site
    )
    
    Switch ($Site) {
        "HiveOS" { $Web_Mods = Get-ChildItem ".\build\api\hiveos"; }
        "SWARM" { $Web_Mods = Get-ChildItem ".\build\api\swarm"; }
    }
    $Web_Mods | Foreach-Object  { Remove-Module -Name "$($_.BaseName)" }
}
