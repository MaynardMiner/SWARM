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
function Get-GPUCount {

    $nvidiacounted = $false
    $amdcounted = $false
    $DeviceList = @{}
    if ($Type -like "*AMD*") {$DeviceList.Add("AMD", @{})
    }
    if ($Type -like "*NVIDIA*") {$DeviceList.Add("NVIDIA", @{})
    }
    if ($Type -like "*CPU*") {$DeviceList.Add("CPU", @{})
    }

    lspci | Tee-Object ".\build\txt\gpucount.txt" | OUt-Null
    $GetBus = Get-Content ".\build\txt\gpucount.txt"
    $GetBus = $GetBus | Select-String "VGA", "3D"
    $AMDCount = 0
    $NVIDIACount = 0
    $CardCount = 0


    $GetBus | Foreach {
        if ($_ -like "*Advanced Micro Devices*" -or $_ -like "*RS880*" -or $_ -like "*Stoney*" -or $_ -like "*NVIDIA*" -and $_ -notlike "*nForce*") {
            if ($_ -like "*Advanced Micro Devices*" -or $_ -like "*RS880*" -or $_ -like "*Stoney*") {
                if ($Type -like "*AMD*") {
                    $DeviceList.AMD.Add("$AMDCount", "$CardCount")
                    $AMDCount++
                    $CardCount++
                }
            }
            if ($_ -like "*NVIDIA*") {
                if ($Type -like "*NVIDIA*") {
                    $DeviceList.NVIDIA.Add("$NVIDIACount", "$CardCount")
                    $NVIDIACount++
                    $CardCount++
                }
            }
        }
    }

    $DeviceType | Foreach {
        if ($_ -like "*CPU*") {
            Write-Host "Getting CPU Count"
            for ($i = 0; $i -lt $CPUThreads; $i++) { 
                $DeviceList.CPU.Add("$($i)", $i)
            }     
        }
    }

    $DeviceList | ConvertTo-Json | Set-Content ".\build\txt\devicelist.txt"
    $GPUCount = 0
    $GPUCount += $DeviceList.Nvidia.Count
    $GPUCount += $DeviceList.AMD.Count
    $GPUCount
    
}

