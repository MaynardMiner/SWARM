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
        Add-Type -Path "./build/apps/opencl/OpenCL.NetCore.dll"
        [OpenCL.NetCore.ErrorCode]$err = [OpenCL.NetCore.ErrorCode]::Unknown
        [OpenCL.NetCore.Platform[]]$Platforms = [OpenCL.NetCore.Cl]::GetPlatformIDs([ref]$err)
        if ($err -ne [OpenCL.NetCore.ErrorCode]::Success)
        {
            log "Failed to get OpenCL plaform. Use -CLPlatform. $err.ToString()" -ForegroundColor Red 
            return 0;
        }
        [String[]]$PlatFormInfo = @();
        foreach ($Platform in $Platforms) {
            $PlatFormInfo += [Cl]::GetPlatformInfo($Platform, [PlatformInfo]::Name,[ref]$err).ToString()   
         }
         for($i=0; $i -lt $PlatFormInfo.Count;$i++) {
            if($PlatFormInfo[$i] -eq "AMD Accelerated Parallel Processing" -or $PlatFormInfo[$i] -eq "Advanced Micro Devices, Inc.") {
                return $i
            }
         }
         return 0;
}