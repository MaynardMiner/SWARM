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

function Global:Get-AMDPlatform() {
    Add-Type -Path ".\build\apps\psopencl\OpenCl.DotNetCore.dll"
    Add-Type -Path ".\build\apps\psopencl\OpenCl.DotNetCore.Interop.dll"

    $Platforms = @()
    $GetPlatforms = [OpenCl.DotNetCore.Platforms.Platform]::GetPlatforms();

    foreach ($Platform in $GetPlatforms) {
        $Devices = @()    
        try {
            foreach ($device in $GetPlatforms.GetDevices([OpenCl.DotNetCore.Devices.DeviceType]::All)) {
                $Devices += [PSCustomObject]@{
                    platform    = $platform.Name
                    version     = $platform.Version.MajorVersion + "." + $platform.Version.MinorVersion
                    vendor      = $platform.Vendor
                    name        = $device.Name
                    driver      = $device.DriverVersion
                    bits        = $device.AddressBits + "Bit"
                    memory      = [Math]::Round(($device.GlobalMemorySize / 1GB), 2)
                    clock_speed = $device.MaximumClockFrequency + "MHz"
                    available   = $device.IsAvailable ? $true : $false
                }
            }
        }
        catch {

        }
        $Platforms += [PSCustomObject]@{
            Platform = $Platform
            Devices  = $Devices
        }
    }
    For($i=0; $i -lt $platforms.Platform.Count; $i++) {
        if($platforms.Platform[$i].Name -eq "AMD Accelerated Parallel Processing") {
            return $i
        }
    }
  return 0
}


