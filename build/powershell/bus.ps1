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
            1 { $busID = "01:00.0" }
            2 { $busID = "02:00.0" }
            3 { $busID = "03:00.0" }
            4 { $busID = "04:00.0" }
            5 { $busID = "05:00.0" }
            6 { $busID = "06:00.0" }
            7 { $busID = "07:00.0" }
            8 { $busID = "08:00.0" }
            9 { $busID = "09:00.0" }
            10 { $busID = "0a:00.0" }
            11 { $busID = "0b:00.0" }
            12 { $busID = "0c:00.0" }
            13 { $busID = "0d:00.0" }
            14 { $busID = "0e:00.0" }
            15 { $busID = "0f:00.0" }
            16 { $busID = "0g:00.0" }
            17 { $busID = "0h:00.0" }
            18 { $busID = "0i:00.0" }
            19 { $busID = "0j:00.0" }
            20 { $busID = "0k:00.0" }
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
    $Services = @("nvlddmkm","amdkmdap","igfx","BasicDisplay")
    $Devices = Get-CimInstance -namespace root\cimv2 -class Win32_PnPEntity | where Service -in $Services
    
    for ($i = 0; $i -lt $Devices.Count; $i++) {
        $deviceId = $Devices[$i].PNPDeviceID
        $locationInfo = (get-itemproperty -path "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID" -name locationinformation).locationINformation
        $businfo = Resolve-PCIBusInfo -locationInfo $locationinfo
        $subvendorlist = Get-Content ".\build\data\vendor.json" | ConvertFrom-Json
        $getsubvendor = $Devices[$i].PNPDeviceID -split "&REV_" | Select -first 1
        $getsubvendor = $getsubvendor.Substring($getsubvendor.Length - 4)
        if ($subvendorlist.$getsubvendor) { $subvendor = $subvendorlist.$getsubvendor }
        elseif ($Devices[$i].PNPDeviceID -match "PCI\\VEN_10DE*") { $subvendor = "nvidia" }
        elseif ($Devices[$i].PNPDeviceID -match "PCI\\VEN_1002*") { $subvendor = "amd" }
        else { $subvendor = "microsoft" }

        if ($Devices[$i].PNPDeviceID -match "PCI\\VEN_10DE*") { $brand = "nvidia" }
        elseif ($Devices[$i].PNPDeviceID -match "PCI\\VEN_1002*") { $brand = "amd" }
        else { $Brand = "microsoft" }

        $GPURAM = $Devices[$i].AdapterRam
        $GPURAM = (Get-CimInstance Win32_VideoController | where PNPDeviceID -eq $Devices[$i].PNPDeviceID).AdapterRam
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
        [parameter(Position = 0, Mandatory = $false)]
        [string]$BusData
    )

    $Bus = $BusData | ConvertFrom-Json
    $Bus = $Bus | Sort-Object PCIBusID
    $DeviceList = @{ }
    $OCList = @{ }

    if ($Type -like "*AMD*") { $DeviceList.Add("AMD", @{ })}
    if ($Type -like "*NVIDIA*") { $DeviceList.Add("NVIDIA", @{ })}
    if ($Type -like "*CPU*") { $DeviceList.Add("CPU", @{ })}

    if ($Type -like "*AMD*") { $OCList.Add("AMD", @{ })}
    if ($Type -like "*NVIDIA*") { $OCList.Add("NVIDIA", @{ })}
    $OCList.Add("Onboard", @{ })

    $DeviceCounter = 0
    $OCCounter = 0
    $NvidiaCounter = 0
    $AmdCounter = 0 
    $OnboardCounter = 0 
    $nvidia = "PCI\\VEN_10DE*"
    $amd = "PCI\\VEN_1002*"

    $Bus | Sort-Object PCIBusID | Foreach {
        $Sel = $_
        if ($Sel.PnPID -match $nvidia) {
            if ($Type -like "*NVIDIA*") {
                $DeviceList.Nvidia.Add("$NvidiaCounter", "$DeviceCounter")
                $OCList.Nvidia.Add("$NvidiaCounter", "$DeviceCounter")
                $NvidiaCounter++
                $DeviceCounter++
                $OCCounter++
            }
        }
        elseif ($Sel.PnPID -match $amd) {
            if ($Type -like "*AMD*") {
                $DeviceList.AMD.Add("$AmdCounter", "$DeviceCounter")
                $OCList.AMD.Add("$AmdCounter", "$OCCounter")
                $AmdCounter++
                $DeviceCounter++
                $OCCounter++
            }
        }
        else {
            $OCList.Onboard.Add("$OnboardCounter", "$OCCounter")
            $OnboardCounter++
            $OCCounter++
        }
    }
    if ($Type -like "*CPU*") { for ($i = 0; $i -lt $CPUThreads; $i++) { $DeviceList.CPU.Add("$($i)", $i) } }
    $DeviceList | ConvertTo-Json | Set-Content ".\build\txt\devicelist.txt"
    $OCList | ConvertTo-Json | Set-Content ".\build\txt\oclist.txt"
    $GPUCount = 0
    $GPUCount += $DeviceList.Nvidia.Count
    $GPUCount += $DeviceList.AMD.Count
    $GPUCount
}