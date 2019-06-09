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

param(
    [parameter(Position = 0, Mandatory = $false)]
    [String]$Command,
    [parameter(Position = 1, Mandatory = $false)]
    [String]$Name,
    [parameter(Position = 2, Mandatory = $false)]
    [String]$Version,
    [parameter(Position = 3, Mandatory = $false)]
    [String]$Uri
)

## Set to SWARM dir
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp", "/root"
Set-Location $dir
$Message = @()
[cultureinfo]::CurrentCulture = 'en-US'

if ($Command -eq "!") { $Message += "No Command Given. Try version query"; Write-Host $($Message | Select -last 1) }
else { $CommandQuery = $Command -replace ("!", "") }
$Name = $Name -replace "!", ""
$Version = $Version -replace "!", ""
$Uri = $Uri -replace "!", ""

$Message += "Selected Miner Is $Name"
Write-Host $($Message | Select -last 1)
$Message += "Selected Version Is $Version"
Write-Host $($Message | Select -last 1)
$Message += "Selected Uri is $URI"
Write-Host $($Message | Select -last 1)

if ($CommandQuery) {
    $Message += "Command is $CommandQuery"
    Write-Host $($Message | Select -last 1)
    $GetCuda = ".\build\txt\cuda.txt"
    if (test-path $GetCuda) { $CudaVersion = Get-Content $GetCuda }
    else { $Message += "Warning: Unable to detect cuda version."; Write-Host $($Message | Select -last 1) }
    $MinerSearch = @()
    Switch ($IsWindows) {
        $true {
            $MinerSearch += Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json
            $MinerSearch += Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json
            $MinerSearch += Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json
        } 
        $false {
            $MinerSearch += Get-Content ".\config\update\nvidia10-linux.json" | ConvertFrom-Json
            $MinerSearch += Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json
            $MinerSearch += Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json  
        }
    }

    switch ($CommandQuery) {
        "Update" {
            $Sel = $MinerSearch | Where { $_.$Name }
            if ($Sel) {
                $Sel.$Name.version = $Version
                $Sel.$Name.uri = $Uri
                $FilePath = Join-Path $dir "\config\update\$($Get.Name).json"
                $Sel | ConvertTo-Json -Depth 3 | Set-Content $FilePath
                $Message += "$Name was found in $($Get.name)."
                Write-Host $($Message | Select -last 1) 
                $Message += "Wrote New Settings to $($Get.name)"
                Write-Host $($Message | Select -last 1)
                $Message += "Stopping Miner & Waiting 5 Seconds"
                Write-Host $($Message | Select -last 1)
                switch ($IsWindows) {
                    $true {
                        $ID = Get-Content ".\build\pid\miner_pid.txt"
                        Stop-Process -Id $ID
                        Start-Sleep -S 5
                    }
                    $false {
                        screen -S miner -X quit
                        Start-Sleep -S 5
                    }
                }
                $Message += "Depending on OS- Miner May Need To Be Manually Restarted."
                Write-Host $($Message | Select -last 1)
            }
            else {
                $Message += "$Name was not found."
                Write-Host $($Message | Select -last 1)                
            }
        }
        "query" {
            $MinerTables = @()
            $MinerSearch | % {
                $MinerTable = $_
                $MinerTable = $MinerTable.PSObject.Properties.Name | % { if ($_ -ne "name") { $MinerTable.$_ } }
                $MinerTables += $MinerTable | Sort-Object -Property Type, Name | Format-Table (@{Label = "Name"; Expression = { $($_.Name) } }, @{Label = "Type"; Expression = { $($_.Type) } }, @{Label = "Executable"; Expression = { $($_.MinerName) } }, @{Label = "Version"; Expression = { $($_.Version) } })
            }
        }
    }
}
 
if ($CudaVersion) { $Message += "Cuda Version is $CudaVersion"; Write-Host $($Message | Select -last 1) }
$Message | Set-Content ".\build\txt\version.txt"
if ($MinerTables) { $MinerTables | Out-Host; $MinerTables | Out-File ".\build\txt\version.txt" -Append }

