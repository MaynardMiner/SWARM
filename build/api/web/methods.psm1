

function Global:Get-RigData($CPlat) {

    Switch ($CPlat) {
        "windows" {
            $RigData = @{ }
            $AMDData = $global:BusData
            $NVIDIAData = $global:BusData
            $AMDData = $AMDData | Where PnPID -match "PCI\\VEN_1002*"
            $NVIDIAData = $NVIDIAData | Where PnPID -match "PCI\\VEN_10DE*"
            Invoke-Expression ".\build\apps\nvidia-smi.exe --query-gpu=gpu_bus_id,vbios_version,gpu_name,memory.total,power.min_limit,power.default_limit,power.max_limit --format=csv > "".\build\txt\getgpu.txt"""
            $GetGPU = Get-Content ".\build\txt\getgpu.txt" | ConvertFrom-Csv
            $getuid = (Get-CimInstance win32_networkadapterconfiguration | where { $_.IPAddress -ne $null } | select MACAddress).MacAddress -replace ("`:", "")
            $enc = [system.Text.Encoding]::UTF8
            $string1 = "$getuid".ToLower()
            $data1 = $enc.GetBytes($string1) 
            $sha = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider 
            $result1 = $sha.ComputeHash($data1)
            $uid = [System.Convert]::ToBase64String($result1)
            $RigData.Add("uid", $uid)
            $BootTime = $((Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime).lastbootuptime)
            $Uptime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End ($BootTime.ToUniversalTime())).TotalSeconds
            $UpTime = [Math]::Round($Uptime)
            $RigData.Add("boot_time", $Uptime)
            $Ip = $(Get-CimInstance Win32_NetworkAdapterConfiguration | Where { $_.Ipaddress.length -gt 1 }).ipaddress[0]
            $RigData.Add("ip", "$Ip")
            $GPUS = @()
            if ($AMDData) { for ($i = 0; $i -lt $AMDData.name.Count; $i++) { $GPUS += @{busid = ($AMDData[$i].PCIBusID).ToLower(); name = $AMDData[$i].Name; brand = $AMDData[$i].brand; subvendor = $AMDData[$i].subvendor ; mem = $AMDData[$i].ram; mem_type = "unknown"; vbios = "unknown" } }
            }
            if ($GetGPU) { for ($i = 0; $i -lt $GetGPU.name.count; $i++) { $GPUS += @{busid = "$($GetGPU[$i]."pci.bus_id" -split ":",2 | Select -Last 1)".ToLower(); name = $GetGPU[$i].name; brand = "nvidia"; subvendor = $NVIDIAData[$i].subvendor ; mem = $GetGPU[$i]."memory.total [MiB]"; vbios = "$($GetGPU[$i].vbios_version)".ToLower(); plim_min = $GetGPU[$i]."power.min_limit [W]"; plim_def = $GetGPU[$i]."power.default_limit [W]"; plim_max = $GetGPU[$i]."power.max_limit [W]"; } }
            }
            $RigData.Add("gpu", $GPUS)
            $RigData.Add("gpu_count_amd", "$($AMDData.name.Count)")
            $RigData.Add("gpu_count_nvidia", "$($GetGPU.name.count)")
            $manu = $(Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer).Manufacturer
            $RigData.Add("mb", @{ })
            $RigData.mb.Add("manufacturer", $manu)
            $prod = $(Get-CimInstance Win32_BaseBoard | Select-Object Product).Product
            $RigData.mb.Add("product", $prod)
            $RigData.Add("cpu", @{ })
            $cpud = Get-CimInstance -Class Win32_processor | Select Name, DeviceID, NumberOfCores
            $cpuname = $cpud.name
            $RigData.cpu.Add("model", $cpuname)
            $cpucores = $cpud.NumberOfCores
            $RigData.cpu.Add("cores", $cpucores)
            $cpuid = $cpud.DeviceID
            $RigData.cpu.Add("cpu_id", $cpuid)
            Global:Write-Log "Running Coreinfo For AES detection" -ForegroundColor Yellow
            Invoke-Expression ".\build\apps\Coreinfo.exe" | Tee-Object -Variable AES | Out-Null
            $AES = $AES | Select-String "Supports AES extensions"
            if ($AES) { $HasAES = 1 }else { $HasAES = 0 }
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
            Invoke-Expression ".\build\apps\nvidia-smi.exe --query-gpu=driver_version --format=csv" | Tee-Object -Variable nversion | Out-Null
            $nvidiaversion = $nversion | ConvertFrom-Csv
            $nvidiaversion = $nvidiaversion.driver_version | Select -First 1
            $RigData.Add("nvidia_version", $nvidiaversion)
            Set-Location "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
            $Reg = $(Get-Item * -ErrorAction SilentlyContinue).Name
            $Reg = $Reg | % { $_ -split "\\" | Select -Last 1 } | % { if ($_ -like "*00*") { $_ } }
            $Reg | foreach {
                if ($null -eq $DriverDesc) {
                    $DriverDesc = $(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($_)" -Name "RadeonSoftwareVersion" -ErrorAction SilentlyContinue).RadeonSoftwareVersion;
                }
            }
            if ($DriverDesc) { $AMDDriver = "$DriverDesc" }else { $AMDDriver = "0.0.0" }
            $RigData.Add("amd_version", $AMDDriver)
            Set-Location $($(v).dir)
        }
        "linux" { }
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
        "HiveOS" { $URL = $global:config.hive_params.HiveMirror; }
        "SWARM" { $URL = $global:Config.swarm_params.SWARMMirror; }
    }

    ##Run Command Based on action
    Switch ($Action) {
        "Hello" { 
            $Return = Start-Hello $InputObject 
        }
        "Message" {
            if ($InputObject) { $Get = $InputObject | ConvertTo-Json -Depth 3}
            else {
                $GetParams = @{ }
                if ($method) { $GetParams.Add("method", $method) }
                if ($Type) { $GetParams.Add("Type", $Type) }
                if ($data) { $GetParams.Add("data", $data) }
                if ($payload) { $GetParams.Add("payload", $payload) }
                if ($Id) { $GetParams.Add("Id", $Id) }
                $Get = Set-Response @$GetParams;
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
        [Parameter(Position=0,Mandatory=$true)]
        [string]$Site
    )
    
    Switch($Site) {
        "HiveOS" { $Web_Mods = Get-ChildItem ".\build\api\hiveos";}
        "SWARM" { $Web_Mods = Get-ChildItem ".\build\api\SWARM";}
    }
    $Web_Mods | %{ Global:Add-Module $_.FullName}
}

function Global:Remove-WebModules {
    Param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]$Site
    )
    
    Switch($Site) {
        "HiveOS" { $Web_Mods = Get-ChildItem ".\build\api\hiveos";}
        "SWARM" { $Web_Mods = Get-ChildItem ".\build\api\SWARM";}
    }
    $Web_Mods | %{ Remove-Module -Name "$($_.BaseName)"}
}