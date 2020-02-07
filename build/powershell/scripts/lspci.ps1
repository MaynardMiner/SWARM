<#
PCIUtils FOR POWERSHELL
This is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

If you use my code, please include my github: https://github.com/maynardminer

If you find it useful - Consider a BTC donation: 1FpuMha1QPaWS4PTPZpU1zGRzKMevnDpwg
#>

Using namespace Microsoft.Win32;

## A single device
class Device {
    [string]$HardwareID
    [string]$CompatIds
    [string]$iRev
    [string]$iTitle
    [string]$iVendor
    [string]$imanufacturer
    [string]$iDevice
    [string]$iDeviceId
    [string]$iLocation

    Device([string]$id, [string]$loc, [string]$compat) {
        $this.HardwareID = $id;
        $this.CompatIds = $compat;
        $location_map = $loc.split(";")[2].TrimStart("(").TrimEnd(")").split(",");
        [int]$get_busid = $location_map[0];
        [int]$get_deviceID = $location_map[1]
        [int]$get_functionId = $location_map[2]
        $new_busid = "{0:x2}" -f $get_busid
        $new_deviceID = "{0:x2}" -f $get_deviceID
        $this.iLocation = "$new_busid`:$new_deviceID`.$get_functionId"
    }
}


## USE CIM to get to PnP Devices- To my knowledge this should not require administrator,
## but you know...Windows...
## Scratch that- Get-CimInstace Win32_PnPEntity is garbage. I found it missing PCI devices.
#$Devices = Get-CimInstance -class Win32_PnPEntity | Where { $_.PNPDeviceID -match "PCI\\*" } | Select -Unique

## Use registry entries instead
Set-Location $ENV:SWARM_DIR
$Devices = @()
$PCI_List = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI"
$Registry = [RegistryKey]::OpenBaseKey([RegistryHive]::LocalMachine, [RegistryView]::Default).OpenSubKey("SYSTEM\CurrentControlSet\Enum\PCI")
$PCI_List = $Registry.GetSubKeyNames()
foreach ($item in $PCI_List) {
    $pci_key = $Registry.OpenSubKey($item)
    $sub_names = $pci_key.GetSubKeyNames()
    foreach ($sub_value in $sub_names) {
        $Sub_key = $pci_key.OpenSubKey($sub_value)
        $key_names = $Sub_key.GetSubKeyNames()
        if ("Control" -in $key_names -or $key_names.count -eq 1) {
            $names = $Sub_key.GetValueNames()
            if (
                "HardwareID" -in $names -and
                "LocationInformation" -in $names -and
                "CompatibleIDs" -in $names
            ) { 
                $HID = $sub_key.GetValue("HardwareID") | Where { $_ -like "*REV*" } | Select -First 1;
                $LOC = $sub_key.GetValue("LocationInformation") | Select -First 1
                $COM = $sub_key.GetValue("CompatibleIDs") | Where { $_ -like "*CC*" } | Select -First 1;
                $Devices += [Device]::New($HID, $LOC, $COM)
            }
        }
    }   
}
## This is a json list of pci.ids.
$pci = Get-Content ".\build\apps\device\pci_ids.json" | ConvertFrom-Json

## IF using parsable argument to get a single device
if ($args[0] -eq "-vmms") {
    $Devices = $Devices | Where ilocation -eq $args[1]
}
else {
    $Devices = $Devices | Where ilocation -ne $null
}

## I only have so many devices to test with
## but so far I haven't found a device yet
## that doesn't match pci.ids
foreach ($Device in $Devices) {
    $IDs = $Device.HardwareID.Split('&')
    $vendorId = $IDs[0].Substring($IDs[0].Length - 4)
    $deviceId = $IDs[1].Substring($IDs[1].Length - 4)
    $deviceSubsysId = $IDs[2].Substring($IDs[2].Length - 4) + ' ' + $IDs[2].Substring($IDs[2].Length - 8, 4)
    $manufacturerId = $IDs[2].Substring($IDs[2].Length - 4)
 
    $vendor = $pci.PSobject.Properties.name | Where { $_.substring(0, 4) -eq $vendorId }
    $device_name = $pci.$vendor.PSObject.Properties.Name | Where { $_.substring(0, 4) -eq $deviceId }
    $ideviceSubsys = $pci.$vendor.$device_name.$deviceSubsysId
    if ($null -eq $ideviceSubsys) { 
        $ideviceSubsys = if ($device_name) { $device_name.split("   ")[1] } else { "Device $deviceId" }
    }
    $manufacturer = $pci.PSobject.Properties.name | Where { $_.substring(0, 4) -eq $manufacturerId }

    $CC = $device.CompatIds | Where { $_ -like "*CC_*" } | Select -First 1
    $CC = $CC.Substring(13 + 3, 4)
    $Code = $CC.Substring(0, 2)
    $Code_Id = $CC.Substring(2, 2)
    $title = $pci.PSObject.Properties.Name | Where { $_.substring(0, 4) -eq "C $Code" }
    if ($pci.$title.PSObject.Properties.Name) {
        $title = $pci.$title.PSObject.Properties.Name | Where { $_.substring(0, 2) -eq $Code_Id }
    }

    $Device_Title = "Device $deviceId"
    if($null -eq $vendor){
        $vendor = $Device_Title
    }
    else{
        $vendor = $vendor.split("   ")[1]
    }
    $rev = $Device.HardwareID.IndexOf("REV_")
    $revision = $Device.HardwareID.substring($rev + 4, 2)
    $new_rev = "{0:x2}" -f $revision

    $Device.Irev = $new_rev
    $Device.iTitle = ($title.split("   ")[1])
    $Device.iVendor = $vendor
    $Device.IDevice = $ideviceSubsys
    $Device.IDeviceId = $Device_Title
    $Device.iManufacturer = if ($manufacturer) { ($manufacturer.split("   ")[1]) } 
}

## Print single view
if ($args[0] -eq "-vmms") {
    $Devices | % {
        Write-Host "Slot:`t$($_.ilocation)"
        Write-Host "Class:`t$($_.ititle)"
        Write-Host "Vendor:`t$($_.ivendor)"
        Write-Host "Device:`t$($_.IDevice)"
        if ($_.imanufacturer) {
            Write-Host "SVendor:`t$($_.imanufacturer)"
            Write-Host "SDevice:`t$($_.IDeviceId)"
        }
        Write-Host "Rev:`t$($_.irev)"
    }
}
## Print list just like PCIUtils
else {
    $Devices | Sort-Object ilocation | ForEach-Object {
        $a = " $($_.IDevice)"
        $b = " (rev $($_.irev))"
        Write-Host "$($_.ilocation) $($_.ititle): $($_.ivendor)$a$b"
    }
}

## I have found this to be slightly slower than lscpi
## mainly because its using .json rather than binary,
## but still seems to work fine for me.