
Function Resolve-PCIBusInfo { 

    param ( 
        [parameter(ValueFromPipeline = $true, Mandatory = $true)] 
        [string] 
        $locationInfo 
    ) 
    PROCESS { 
        [void]($locationInfo -match "\d+,\d+,\d+")
        $busId, $deviceID, $functionID = $matches[0] -split "," 
    
        switch ($busId) {
            1 {$busID = "01:00.0"}
            2 {$busID = "02:00.0"}
            3 {$busID = "03:00.0"}
            4 {$busID = "04:00.0"}
            5 {$busID = "05:00.0"}
            6 {$busID = "06:00.0"}
            7 {$busID = "07:00.0"}
            8 {$busID = "08:00.0"}
            9 {$busID = "09:00.0"}
            10 {$busID = "0a:00.0"}
            11 {$busID = "0b:00.0"}
            12 {$busID = "0c:00.0"}
            13 {$busID = "0d:00.0"}
            14 {$busID = "0e:00.0"}
            15 {$busID = "0f:00.0"}
            16 {$busID = "0g:00.0"}
            17 {$busID = "0h:00.0"}
            18 {$busID = "0i:00.0"}
            19 {$busID = "0j:00.0"}
            20 {$busID = "0k:00.0"}
        }

        new-object psobject -property @{ 
            "BusID"      = $busID; 
            "DeviceID"   = "$deviceID" 
            "FunctionID" = "$functionID" 
        } 
    }          
}
    
Function Get-BusFunctionID { 
    #gwmi -query "SELECT * FROM Win32_PnPEntity"
    $Devices = get-wmiobject -namespace root\cimv2 -class Win32_PnPEntity

    for ($i = 0; $i -lt $Devices.length; $i++) { 

        if (!($Devices[$i].PNPDeviceID -match "PCI\\VEN_10DE*" -and $Devices[$i].Name -ne "High Definition Audio Controller" -and $Devices[$i].Name -ne "NVIDIA USB Type-C Port Policy Controller" -and $Devices[$i].Name -ne "NVIDIA USB 3.10 eXtensible Host Controller - 1.10 (Microsoft)" -or $Devices[$i].PNPDeviceID -match "PCI\\VEN_1002*" -and $Devices[$i].Name -ne "High Definition Audio Controller" -and $Devices[$i].Name -ne "High Definition Audio Bus")) {
            continue
        }
        $deviceId = $Devices[$i].PNPDeviceID
        $locationInfo = (get-itemproperty -path "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID" -name locationinformation).locationINformation

        $businfo = Resolve-PCIBusInfo -locationInfo $locationinfo
        $subvendorlist = Get-Content ".\build\data\vendor.json" | ConvertFrom-Json
        $getsubvendor = $Devices[$i].PNPDeviceID -split "&REV_" | Select -first 1
        $getsubvendor = $getsubvendor.Substring($getsubvendor.Length - 4)
        if ($subvendorlist.$getsubvendor) {$subvendor = $subvendorlist.$getsubvendor}
        elseif ($Devices[$i].PNPDeviceID -match "PCI\\VEN_10DE*") {$subvendor = "nvidia"}
        else {$subvendor = "amd"}
        if ($Devices[$i].PNPDeviceID -match "PCI\\VEN_10DE*") {$brand = "nvidia"}else {$brand = "amd"}
        $GPURAM = $Devices[$i].AdapterRam
        $GPURAM = (Get-WmiObject Win32_VideoController | where PNPDeviceID -eq $Devices[$i].PNPDeviceID).AdapterRam
        $GPURAM = "{0:f0}" -f $($GPURAM / 1000000)
        $GPURAM = "$($GPURAM)M"

        new-object psobject -property @{ 
            "Name"      = $Devices[$i].Name;
            "PnPID"     = $Devices[$i].PNPDeviceID
            "PCIBusID"  = $businfo.BusID; 
            "subvendor" = $subvendor
            "Brand"     = $brand
            "ram"       = $GPURAM
        } 
    }
}

function Get-GPUCount {
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [string]$BusData
    )

    $Bus = $BusData | ConvertFrom-Json
    $Bus = $Bus | Sort-Object PCIBusID
    $DeviceList = @{}
    if ($Type -like "*AMD*") {$DeviceList.Add("AMD", @{})
    }
    if ($Type -like "*NVIDIA*") {$DeviceList.Add("NVIDIA", @{})
    }
    if ($Type -like "*CPU*") {$DeviceList.Add("CPU", @{})
    }
    $Counter = 0
    $NvidiaCounter = 0
    $AmdCounter = 0 
    $nvidia = "PCI\\VEN_10DE*"
    $amd = "PCI\\VEN_1002*"
    $TotalGPUS = $Bus.PCIBusID.Count
    $BusCount = 0
    $Bus | Foreach {$BusCount++}
    for ($i = 0; $i -lt $BusCount; $i++) {

        $B = $Bus[$i]
     
        if ($Type -like "*NVIDIA*") {
            if ($B.PnPID -match $nvidia) {
                $DeviceList.Nvidia.Add("$NvidiaCounter", "$Counter")
                $Counter++
                $NvidiaCounter++
            }
        } 
        if ($Type -like "*AMD*") {  
            if ($B.PnPID -match $amd) {
                $DeviceList.AMD.Add("$AmdCounter", "$Counter")
                $Counter++
                $AmdCounter++
            }
        }
    }
    if ($Type -like "*CPU*") {for ($i = 0; $i -lt $CPUThreads; $i++) { $DeviceList.CPU.Add("$($i)", $i) }}
    $DeviceList | ConvertTo-Json | Set-Content ".\build\txt\devicelist.txt"
    $GPUCount = 0
    $GPUCount += $DeviceList.Nvidia.Count
    $GPUCount += $DeviceList.AMD.Count
    $GPUCount
}