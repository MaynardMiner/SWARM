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

function Global:get-AMDPlatform {

    if ($(arg).Platform -eq "linux") {
        $A = Invoke-Expression ".\build\apps\platforms\getplatforms" | Tee-Object -Variable amdclplatform
        Start-Sleep -S .5
        $GPUPlatform = $amdclplatform | Select-String "AMD Accelerated Parallel Processing"
        $GPUPlatform = $GPUPlatform -replace (" ", "")
        $GPUPlatform = $GPUPlatform -split "AMD" | Select -First 1
        $GPUPlatform
    }

    if ($(arg).Platform -eq "windows") {
        $A = (clinfo) | Select-string "Platform Vendor"
        $PlatformA = @()
        for ($i = 0; $i -lt $A.Count; $i++) { $PlatSel = $A | Select -Skip $i -First 1; $PlatSel = $PlatSel -replace "Platform Vendor", "$i"; $PlatSel = $PlatSel -replace ":", "="; $PlatformA += $PlatSel}
        $PlatformA = $PlatformA | ConvertFrom-StringData
        $PlatformA.keys | % {if ($PlatformA.$_ -eq "AMD Accelerated Parallel Processing" -or $PlatformA.$_ -eq "Advanced Micro Devices, Inc.") {$B = $_}}
        $B
    }
}
