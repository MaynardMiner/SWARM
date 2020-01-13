Using namespace System;
Using namespace System.Text;
Using module ".\helper.psm1";

if(-not $Global:DIR) { $Global:Dir = (Convert-Path ".")}

## Placeholder
class MINER {

}

## Base Class For RIG.
## After Constructed, Used To Send 'hello' to HiveOS
class RIG {
    [CPU]$cpu = [CPU]::New();
    [MOTHERBOARD]$mb = [MOTHERBOARD]::New();
    [DISK]$disk = [DISK]::New();
    [RAM]$ram = [RAM]::New();
    [DEVICE_GROUP[]]$Groups;
    [Array]$gpu = @(); ##Mix of nvidia and amd cards
    [Hashtable]$net_interfaces = @{ };
    [hashtable]$lan_config = @{ };
    [String]$version;
    [String]$nvidia_version;
    [String]$amd_version;
    [String]$gpu_count_nvidia;
    [String]$gpu_count_amd;
    [String]$uid;
    [String]$openvpn;
    [String]$kernel;
    [string[]]$ip
    [String]$boot_time;

    RIG() {
        ## Kernel
        $this.kernel = [RIG_RUN]::get_kernel();

        ## Net Interfaces & uid
        [hashtable]$data = [RIG_RUN]::uid();
        $this.net_interfaces = $data.net_interfaces;
        $this.uid = $data.uid;

        ## AMD Driver
        $this.amd_version = [AMD]::get_driver();

        ## NVIDIA Driver
        $this.nvidia_version = [NVIDIA]::get_driver();

        ## Boot Time
        $this.boot_time = [RIG_RUN]::get_uptime();

        ## IPs
        $this.ip = [RIG_RUN]::get_ip();

        ## LAN config
        $this.lan_config = [RIG_RUN]::get_lan();

        ## Version
        [string]$Path = Join-Path $Global:Dir "h-manifest.conf"
        $this.version = ([filedata]::stringdata("$($Path)")).CUSTOM_VERSION

        ## Get GPU Information
        $GPU_Data = [RIG_RUN]::get_gpus();
    }

    ## Returns JSON for hello method.
    [string] hello ($worker_name = $null, $farm_hash = $null, $worker_id = $null, $server_url = $null) {
        [hashtable]$Hello = @{ };
        $Hello.Add('method', "hello");
        $Hello.Add('jsonrpc', '2.0');
        $Hello.Add('id', "0");
        $Hello.Add('params', @{ });
        $Hello.params.Add("cpu", $this.cpu);
        $Hello.params.Add("version", $this.version);
        $Hello.params.Add("nvidia_version", $this.nvidia_version);
        $Hello.params.Add("amd_version", $this.amd_version);
        $Hello.params.Add("gpu_count_nvidia", $this.gpu_count_nvidia);
        $Hello.params.Add("gpu_count_amd", $this.gpu_count_amd);
        $Hello.params.Add("gpu", $this.gpu);
        $Hello.params.Add("uid", $this.uid);
        $Hello.params.Add("disk_model", $this.disk.disk_model);
        $Hello.params.Add("mb", $this.mb);
        $Hello.params.Add("net_interfaces", $this.net_interfaces);
        $Hello.params.Add("kernel", $this.kernel);
        $Hello.params.Add("ip", $this.ip);
        $Hello.params.Add("boot_time", $this.boot_time);

        if ($worker_name) {
            $Hello.params.Add("worker_name", $worker_name)
        }
        if ($farm_hash) {
            $Hello.params.Add("farm_hash", $farm_hash)
        }
        else {
            $Hello.params.Add("worker_id", $worker_id)
        }

        return $Hello | ConvertTo-Json -Depth 5 -Compress;
    }
}

## Device Groups Used To Execute Miner.
class DEVICE_GROUP {
    [String]$Name #User denoted name of group
    [String]$Device #Device this is (NVIDIA,AMD,CPU,ASIC)
    [String]$Hashrate #Current Hashrate
    [Miner]$Miner #Current Miner
    [Int]$Accepted ## Miner Current Accepted Shares
    [Int]$Rejected ## Miner Current Rejected Shares
    [Int]$Rej_Percent ## Rejection Percent
    [Array]$Devices = @() ## Can be AMD cards, NVIDIA cards, ASIC, CPU

    Add_GPU([GPU]$GPU) {
        $this.Devices += $GPU
        $this.Device = $GPU.Brand
    }

    Add_Thread([Thread]$Thread) {
        $this.Devices += $Thread
        $this.Device = $Thread.Brand
    }
}

## GPU class constructor for SWARM. These are cards used for mining.
class GPU {
    [String]$Brand;
    [Int]$PCI_SLOT; #Denoted Order It Is On The Bus
    [Int]$Device; #Denoted Order It Is Among Same Model Cards
    [Decimal]$Speed; #Current Hashrate
    [Int]$Temp = 0; #Current Temperature
    [Int]$Fan = 0; #Current Fan Speed
    [Int]$Wattage = 0; #Current Wattage

    GPU([AMD_GPU]$gpu) {

    }

    GPU([NVIDIA]$gpu) {

    }
}

## Base class for video card
class VIDEO_CARD {
    [String]$busid; 
    [String]$name;
    [String]$brand;

    VIDEO_CARD($Busid, $Name, $Brand) {
        $this.busid = $Busid;
        $this.name = $Name;
        $this.brand = $Brand;
    }
}

## A NVIDIA gpu
class NVIDIA_GPU : VIDEO_CARD {
    [String]$subvendor;
    [String]$mem;
    [String]$vbios;
    [string]$plim_min;
    [string]$plim_def;
    [string]$plim_max;

    NVIDIA_GPU($Busid, $Name, $Brand, $Subvendor, $Mem, $Vbios, $Plim_min, $Plim_def, $Plim_max) {
        $this.busid = $Busid;
        $this.name = $Name;
        $this.brand = $Brand;
        $this.subvendor = $Subvendor
        $this.mem = $Mem;
        $this.vbios = $Vbios;
        $this.plim_min = $Plim_min;
        $this.plim_def = $Plim_def;
        $this.plim_max = $Plim_max;
    }
}

## A AMD gpu
class AMD_GPU : VIDEO_CARD {
    [String]$subvendor
    [String]$mem
    [String]$vbios
    [String]$mem_type

    AMD_GPU($Busid, $Name, $Brand, $Subvendor, $Mem, $Vbios, $Mem_Type) {
        $this.busid = $Busid;
        $this.name = $Name;
        $this.brand = $Brand;
        $this.subvendor = $Subvendor
        $this.mem = $Mem;
        $this.vbios = $Vbios;
        $this.mem_type = $Mem_Type;
    }
}

## BASE CPU class constructor
class CPU {
    [string]$aes;
    [string]$model;
    [string]$cpu_id;
    [string]$cores;

    CPU() {
        $this.Model = $(
            if ($global:IsLinux) {
                Invoke-Expression "lscpu | grep `"Model name:`" | sed `'`s`/Model name:[ `\t]`*`/`/g`'"
            }
            if ($global:IsWindows) {
                (Get-CimInstance -Class Win32_processor).Name.Trim()
            }
        )
        $this.Cores = $(
            if ($global:IsLinux) {
                Invoke-Expression "lscpu | grep `"`^CPU(s):`" | sed `'s`/CPU(s):[ `\t]`*`/`/`g`'"
            }
            if ($global:IsWindows) {
                (Get-CimInstance -Class Win32_processor).NumberOfCores
            }
        )
        $this.Aes = $(
            if ($global:IsLinux) {
                Invoke-Expression "lscpu | grep `"`^Flags:`.`*aes`" | wc -l"
            }
            if ($global:IsWindows) {
                $Get = $(Invoke-Expression ".\build\apps\features-win\features-win.exe" | Select-Object -Skip 1 | ConvertFrom-StringData)."AES-NI"
                if ($Get -eq "Yes") { $HasAES = 1 }else { $HasAES = 0 }
                $HasAES
            }
        )
        $this.cpu_id = $(
            if ($global:IsLinux) {
                "$(Invoke-Expression "dmidecode -t 4" | Select-String "ID: " | ForEach-Object{$_ -split "ID: " | Select-Object -Last 1})" -replace " ", ""
            }
            if ($global:IsWindows) {
                (Get-CimInstance -Class Win32_processor).ProcessorId
            }
        )
    }
}

## Mining Threads for CPU
class THREAD : CPU {
    [String]$Brand = "CPU"
    [Decimal]$Speed; #Current Hashrate
    [Int]$Temp = 0; #Current Temperature Not Used Yet
    [Int]$Fan = 0; #Current Fan Speed Not Used Yet
    [Int]$Wattage = 0; #Current Wattage Not Used Yet
}

## Motherboard constructor
class MOTHERBOARD {
    [String]$system_uuid;
    [String]$product;
    [String]$manufacturer;

    MOTHERBOARD() {
        $this.manufacturer = $(
            if ($global:ISLinux) {
                $data = [RIG_RUN]::dmidecode($null);
                [string]((($data | Select-String "Base Board Information" -Context 0,4).Context.PostContext | Select-String "Manufacturer:").Line).Split("Manufacturer: ")[1]
            }
            if ($global:IsWindows) {
                (Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer).Manufacturer
            }
        )
        $this.product = $(
            if ($global:IsLinux) {
                $data = [RIG_RUN]::dmidecode($null);
                [string]((($data | Select-String "Base Board Information" -Context 0,4).Context.PostContext | Select-String "Product Name:").Line).Split("Product Name: ")[1]
            }
            if ($global:IsWindows) {
                (Get-CimInstance Win32_BaseBoard | Select-Object Product).Product
            }
        )
        $this.system_uuid = $(
            if ($global:ISLinux) {
                [string]([RIG_RUN]::dmidecode("-s system-uuid"));
            }
            if ($global:IsWindows) {
                (Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID
            }
        )
    }
}

## Root Disk Constructor
class DISK {
    [string]$disk_model

    DISK() {
        if ($global:ISLinux) {
            $bootpart = "$(Invoke-Expression "readlink -f /dev/block/`$(mountpoint -d `/)")"
            $bootpart = $bootpart.Substring(0, $bootpart.Length - 1)
            $disk = Invoke-Expression "parted -ml | grep -m1 `"$bootpart`:`""
            $disk = $disk -split ":"
            $disk = "$($disk | Select-Object -Last 2 | Select-Object -First 1) $($disk | Select-Object -Skip 1 -First 1)"
            $this.disk_model = $disk
        }
        if ($global:IsWindows) {
            $model = (Get-CimInstance win32_diskdrive).model | Select -First 1
            $size = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size
            $size = $size.Size / [math]::pow( 1024, 3 )
            $size = [math]::Round($size)
            $this.disk_model = "$model $($size)GB"
        }
    }

    static [string] Get_FreeSpace() {
        $freespace = "0"
        if ($global:IsLinux) {
            $freespace = invoke-expression "df -h / | awk '{ print `$4 }' | tail -n 1 | sed 's/%//'"
        }
        if ($global:IsWindows) {
            $freespace = "$([math]::Round((Get-CIMInstance -ClassName Win32_LogicalDisk | Where-Object DeviceID -eq "C:").FreeSpace/1GB,0))G"
        }
        return $freespace;
    }
}

## Onboard RAM constructor
class RAM {
    [string]$total_space
    [string]$used_space

    RAM() {
        $this.total_space = $(
            if ($global:ISLinux) {
                Get-Content '/proc/meminfo' | Select-String "MemTotal:" | ForEach-Object { $($_ -split 'MemTotal:\s+' | Select-Object -Last 1).replace(" kB", "") }
            }
            if ($global:IsWindows) {
                [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB, 0)
            }
        )
        $this.used_space = $(
            if ($global:IsLinux) {
                [math]::Round((Get-Content '/proc/meminfo' | Select-String "MemFree:" | ForEach-Object { $($_ -split 'MemFree:\s+' | Select-Object -Last 1).replace(" kB", "") }) / 1KB, 0)
            }
            if ($global:IsWindows) {
                [math]::Round((Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1KB, 0)
            }
        )
    }

    [string] Get_Total() {
        $this.total_space = $(
            if ($global:ISLinux) {
                Get-Content '/proc/meminfo' | Select-String "MemTotal:" | ForEach-Object { $($_ -split 'MemTotal:\s+' | Select-Object -Last 1).replace(" kB", "") }
            }
            if ($global:IsWindows) {
                [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB, 0)
            }
        )
        return $this.total_space
    }

    [string] Get_Used() {
        $this.used_space = $(
            if ($global:IsLinux) {
                [math]::Round((Get-Content '/proc/meminfo' | Select-String "MemFree:" | ForEach-Object { $($_ -split 'MemFree:\s+' | Select-Object -Last 1).replace(" kB", "") }) / 1KB, 0)
            }
            if ($global:IsWindows) {
                [math]::Round((Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1KB, 0)
            }
        )
        return $this.used_space
    }
}

<# 

    Below are various methods to query information on RIG. 
    These are the methods that will do things such as
    gather detailed rig information, and query drivers
    for information.

    For windows, there is a method to initiate GPU-Z
    as well to gather detailed GPU information.
#>

<# 
    Methods for RIG Device Query 
#>
class RIG_RUN {

    ## Get GPU information
    static [Array] get_gpus() {
        $gpus = @()
        
        ## Insert Code Here

        return $gpus;
    }

    ## Get lan information
    static [hashtable] get_lan() {
        $lan = @{ }
        if ($Global:ISLinux) {
            $dhcp = [IO.File]::ReadAllLines("/etc/systemd/network/20-ethernet.network") | Select-String "DHCP=No"
            if ($dhcp) { $lan_dhcp = 1 }else { $lan_dhcp = 0 }
            $lan_address = invoke-expression "ip -o -f inet addr show | grep eth0 | awk `'/scope global/ {print `$4}`'"
            $lan_gateway = invoke-expression "ip route | awk `'/default/ && /eth0/ { print `$3 }`' | head -1"
            $lan_dns = invoke-expression "cat /run/systemd/resolve/resolv.conf | grep -m1 ^nameserver | awk `'{print `$2}`'"
            $lan.Add("dhcp", $lan_dhcp)
            $lan.Add("address", $lan_address)
            $lan.Add("gateway", $lan_gateway)
            $lan.Add("dns", $lan_dns)
        }
        elseif ($Global:IsWindows) {
            $ipconfig = invoke-expression "ipconfig /all"
            [string]$dhcp = $($ipconfig | Select-String "DHCP Enabled")
            $get_dhcp = 1
            switch ($dhcp.split(": ") | Select -Last 1) { "Yes" { $get_dhcp = 1 }; "No" { $get_dhcp = 0 } }
            [string]$lan_address = $($ipconfig | Select-String "IPv4 Address")
            $address = ($lan_address.split(": ") | Select -Last 1).Replace("`(Preferred`)", "")
            [string]$lan_gateway = $ipconfig | Select-String "Default Gateway"
            $gateway = ($lan_gateway.split(": ") | Select -Last 1)
            [string]$lan_dns = $ipconfig | Select-String "DNS Servers"
            $dns = ($lan_dns.split(": ") | Select -Last 1)
            $lan.Add("dhcp", $get_dhcp)
            $lan.Add("address", $address)
            $lan.Add("gateway", $gateway)
            $lan.Add("dns", $dns)
        }
        return $lan;
    }

    ## Get IP information
    static [string[]] get_ip() {
        [string[]]$ip = @()
        if ($Global:IsWindows) {
            $ip_host = [System.Net.DNS]::GetHostName()
            $ip_addresses = ([System.Net.DNS]::GetHostEntry($ip_host)).AddressList
            $get_ip = $($ip_addresses | Where AddressFamily -eq "InterNetwork").IPAddressToString
            $get_ip | foreach { $ip += "$($_)" }
        }
        elseif ($GLobal:IsLinux) {
            $get_ip = invoke-expression "hostname -I | sed `'s`/ `/`\n`/g`'"
            $get_ip | foreach { if ([string]$_ -ne "") { $ip += "$($_)" } }
        }
        return $ip;
    }

    ## Gets uptime
    static [string] get_uptime() {
        [string]$boot_time = "";
        if ($global:IsWindows) {
            $BootTime = $((Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime).lastbootuptime);
            $Get_Uptime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End ($BootTime.ToUniversalTime())).TotalSeconds;
            $boot_time = ([Math]::Round($Get_Uptime)).ToString();
        }
        elseif ($Global:IsLinux) {
            $date = invoke-expression 'date +%s';
            $time = ([IO.File]::ReadAllText("/proc/uptime")).split(" ") | Select -First 1;
            $boot_time = ([math]::Round($date - $time, 0)).ToString();
        }        
        return $boot_time
    }

    ## Get OS kernel version
    static [string] get_kernel() {
        $kernel = "unknown"
        if ($Global:IsLinux) {
            $get_kernel = invoke-expression "uname --kernel-release";
            if ($get_kernel) { 
                $kernel = $get_kernel 
            }
        }
        elseif ($Global:ISWindows) {
            $get_version = [System.Environment]::OSVersion.Version
            $kernel = "$($get_version.Major).$($get_version.Minor).$($get_version.Build)"
        }        
        return $kernel;
    }

    ## Gets uid (and net interfaces needed for uid)
    static [hashtable] uid() {
        $data = @{ }
        $data.Add("net_interfaces", @{ })
        $data.Add("uid", "")

        if ($Global:IsWindows) {
            $mac = (Get-CimInstance win32_networkadapterconfiguration | where { $_.IPAddress -ne $null } | select MACAddress).MacAddress
            $Data.net_interfaces.Add("mac", $mac)
            $get_uid = (Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID
            $Get = (Get-NetAdapter -Physical | Where Status -eq "Up").Name
            $iface = "eth0"
            switch ($Get) {
                "Ethernet" { $iface = "eth0" }
                "Wi-Fi" { $iface = "wlan0" }
            }
            $data.net_interfaces.Add("iface", $iface)
            $get_mac = ($mac.replace(":", "").ToLower())
            $cpu_id = (Get-CimInstance -Class Win32_processor).ProcessorId.ToLower()
            $get_uid = "$get_uid-$cpu_id-$get_mac"
            $StringBuilder = [StringBuilder]::New()
            [System.Security.Cryptography.HashAlgorithm]::Create('SHA1').ComputeHash([Encoding]::UTF8.GetBytes($get_uid)) | % { [Void]$StringBuilder.Append($_.ToString("x2")) }; 
            $data.uid = $StringBuilder.ToString()     
        }
        elseif ($Global:ISLinux) {
            $net = invoke-expression "ip -o link | grep -vE 'LOOPBACK|POINTOPOINT|sit0|can0|docker|sonm|ifb'" 
            $iface = $($net.split(":") | Select -Skip 1 -First 1) -replace " ", ""
            $data.net_interfaces.Add("iface", $iface)
            $mac = $($net.split(" "))
            $mac = $mac | Select -Skip ($mac.count - 3) -First 1
            $data.net_interfaces.Add("mac", $mac)
            $get_uid = invoke-expression 'dmidecode -s system-uuid'
            $cpu_id = invoke-expression "dmidecode -t 4 | grep ID | sed `'s`/.`*ID:`/`/`;s`/ `/`/g`'"
            $get_mac = $data.net_interfaces.mac.replace(":", "").ToLower()
            $get_uid = "$get_uid-$cpu_id-$get_mac"
            $StringBuilder = [StringBuilder]::New()
            [System.Security.Cryptography.HashAlgorithm]::Create('SHA1').ComputeHash([Encoding]::UTF8.GetBytes($get_uid)) | % { [Void]$StringBuilder.Append($_.ToString("x2")) }; 
            $data.uid = $StringBuilder.ToString()     
        }
        return $data
    }

    ## Runs dmidecode. Is used for data
    static [string[]] dmidecode($arguments = $null) {
        [string[]] $dmidecode = @()
        $info = [System.Diagnostics.ProcessStartInfo]::new()
        $info.FileName = 'dmidecode'
        $info.UseShellExecute = $false
        $info.RedirectStandardOutput = $true
        $info.Verb = "runas"
        if($arguments) {$info.Arguments = $arguments}
        $Proc = [System.Diagnostics.Process]::New()
        $proc.StartInfo = $Info
        $proc.Start() | Out-Null
        $proc.WaitForExit(15000) | Out-Null
        if ($proc.HasExited) {
            while(-not $Proc.StandardOutput.EndOfStream){
                $dmidecode += $Proc.StandardOutput.ReadLine()
            }    
        }
        else { Stop-Process -Id $Proc.Id -ErrorAction Ignore }
        return $dmidecode
    }
}

<# 

    Methods For GPU Specific Device Query 

#>

## NVIDIA specific
class NVIDIA {
    static [string] get_driver() {
        $driver = "0.0"
        $smi = (invoke-expression "nvidia-smi -h" | Select -First 1).split("-- v") | Select -Last 1
        if ($smi) { $driver = $smi }
        return $driver;
    }

    static [void] get_nvml() {
        ## Check for NVIDIA-SMI and nvml.dll in system32. If it is there- copy to NVSMI
        $x86_driver = [IO.Path]::Join(${env:ProgramFiles(x86)}, "NVIDIA Corporation")
        $x64_driver = [IO.Path]::Join($env:ProgramFiles, "NVIDIA Corporation")
        $x86_NVSMI = [IO.Path]::Join($x86_driver, "NVSMI")
        $x64_NVSMI = [IO.Path]::Join($x64_driver, "NVSMI")
        $smi = [IO.Path]::Join($env:windir, "system32\nvidia-smi.exe")
        $nvml = [IO.Path]::Join($env:windir, "system32\nvml.dll")

        ## Set the device order to match the PCI bus if NVIDIA is installed
        if ([IO.Directory]::Exists($x86_driver) -or [IO.Directory]::Exists($x64_driver)) {
            $Target1 = [System.EnvironmentVariableTarget]::Machine
            $Target2 = [System.EnvironmentVariableTarget]::Process
            [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", $Target1)
            [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", $Target2)
        }

        if ( [IO.Directory]::Exists($x86_driver) ) {
            if (-not [IO.Directory]::Exists($x86_NVSMI)) { [IO.Directory]::CreateDirectory($x86_NVSMI) | Out-Null }
            $dest = [IO.Path]::Join($x86_NVSMI, "nvidia-smi.exe")
            try { [IO.File]::Copy($smi, $dest, $true) | Out-Null } catch { }
            $dest = [IO.Path]::Join($x86_NVSMI, "nvml.dll")
            try { [IO.File]::Copy($nvml, $dest, $true) | Out-Null } catch { }
        }

        if ( [IO.Directory]::Exists($x64_driver) ) {
            if (-not [IO.Directory]::Exists($x64_NVSMI)) { [IO.Directory]::CreateDirectory($x64_NVSMI) | Out-Null }
            $dest = [IO.Path]::Join($x64_NVSMI, "nvidia-smi.exe")
            try { [IO.File]::Copy($smi, $dest, $true) | Out-Null } catch { }
            $dest = [IO.Path]::Join($x64_NVSMI, "nvml.dll")
            try { [IO.File]::Copy($nvml, $dest, $true) | Out-Null } catch { }
        }
    }
}

## AMD Specific
class AMD {
    static [string] get_driver() {
        $driver = "0.0"
        if ($global:IsWindows) {
            [string]$aMDPnPId = 'pci\\ven_1002.*';
            [string]$DriverName = 'RadeonSoftwareVersion';
            $DriverDesc = $null;
            $AMDDriver = "";
            [string]$regKeyName = 'SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}';
            $reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Default);
            $key = $reg.OpenSubKey($regKeyName, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree);
            ForEach ($subKey in $key.GetSubKeyNames()) {
                if ($subKey -match '\d{4}') {
                    $driver_gpu = $key.OpenSubKey($subKey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree);
                    if ($driver_gpu) {
                        $pnPId = $driver_gpu.GetValue("MatchingDeviceId");
                        if ($pnPId -match $aMDPnPId ) {
                            $gpukey = $key.OpenSubKey($subKey, $true);
                            $driver = $gpukey.GetValue($DriverName);                         
                        }
                    }
                }
            }
        }
        if ($Global:IsLinux) {
            $driver = Invoke-Expression "dpkg -s amdgpu-pro 2>&1 | grep `'^Version: `' | sed `'s/Version: //`' | awk -F`'-`' `'{print `$1}`'";
            if ([string]$driver -eq "") { $driver = invoke-expression "dpkg -s amdgpu 2>&1 | grep `'^Version: `' | sed `'s/Version: //`' | awk -F`'-`' `'{print `$1}`'" };
            if ([string]$Driver -eq "") { $driver = Invoke-Expression "dpkg -s opencl-amdgpu-pro-icd 2>&1 | grep `'^Version: `' | sed `'s/Version: //`' | awk -F`'-`' `'{print `$1}`'" };
        }
        return $driver;
    }
}