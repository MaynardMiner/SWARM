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
    $Opencl = 0;
    $A = ($(clinfo) | Select-String "Platform Vendor").Line;
    if($IsLinux){ 
        $A.Replace("  Platform Vendor                                 ","")
        for($i=0; $i -lt $A.Count; $i++) {
            if($A[$i] -eq "AMD Accelerated Parallel Processing" -or $platform -eq "Advanced Micro Devices, Inc.") {
                $Opencl = $i;
            }
        }
    }
    if($IsWindows) {
        $A = (clinfo) | Select-string "Platform Vendor"
        $PlatformA = @()
        for ($i = 0; $i -lt $A.Count; $i++) { $PlatSel = $A | Select-Object -Skip $i -First 1; $PlatSel = $PlatSel -replace "Platform Vendor", "$i"; $PlatSel = $PlatSel -replace ":", "="; $PlatformA += $PlatSel}
        $PlatformA = $PlatformA | ConvertFrom-StringData
        $PlatformA.keys | ForEach-Object {if ($PlatformA.$_ -eq "AMD Accelerated Parallel Processing" -or $PlatformA.$_ -eq "Advanced Micro Devices, Inc.") {$Opencl = $_}}
    }
    return $Opencl
}