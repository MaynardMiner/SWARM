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
function Get-Power {
    param(
        [Parameter(Mandatory = $false)]
        [Array]$PwrType = "none",
        [Parameter(Mandatory = $false)]
        [string]$Platforms = "none"
    )

    if ($Platforms -eq "linux") {
        switch ($PwrType) {
            "NVIDIA" {
                $CardPower = ".\build\txt\nvidiapower.txt"
                if (Test-Path $CardPower) {Clear-Content $CardPower}
                timeout -s9 30 ./build/apps/VII-smi | Tee-Object -Variable statpower | Out-Null
                if ($statpower) {$statpower | Set-Content ".\build\txt\nvidiapower.txt"}
                else {Write-Host "Failed To Get NVIDIA Power Usage- Driver is too busy" -ForegroundColor Red}
            }

            "AMD" {
                $CardPower = ".\build\txt\amdpower.txt"
                if (Test-Path $CardPower) {Clear-Content $CardPower}
                timeout -s9 30 rocm-smi -P | Tee-Object -Variable statpower | Out-Null
                if ($statpower) {$statpower | Set-Content ".\build\txt\amdpower.txt"}
                else {Write-Host "Failed To Get AMD Power Usage- Driver is too busy" -ForegroundColor Red} 
            }

        }
    }
}


function Set-Power {
    param(
        [Parameter(Mandatory = $false)]
        [String]$MinerDevices,
        [Parameter(Mandatory = $false)]
        [String]$Command,
        [Parameter(Mandatory = $false)]
        [String]$PwrType
    ) 

    if ($Platform -eq "linux") {
        if (Test-Path ".\build\txt\nvidiapower.txt") {$NPow = get-content ".\build\txt\nvidiapower.txt"}
        if (Test-Path ".\build\txt\amdpower.txt") {$APow = Get-Content ".\build\txt\amdpower.txt" | Select-String -CaseSensitive "W" | foreach {$_ -split (":", "") | Select -skip 2 -first 1} | foreach {$_ -replace ("W", "")}}
    }

    $PwrDevices = get-content ".\build\txt\devicelist.txt" | ConvertFrom-Json
    $PwrMiners = get-content ".\build\txt\bestminers.txt" | ConvertFrom-Json

    if ($Platform -eq "windows") {
        $POWN = $false
        $POWA = $false
        $PwrMiners | foreach {if ($_.Type -like "*NVIDIA*") {$POWN = $true}; if ($_.Type -like "*AMD*") {$POWA = $true}}
        if ($POWN -eq $true) {
            if ($nvidiaout) {Clear-Variable nvidiaout}
            invoke-expression ".\build\apps\nvidia-smi.exe --query-gpu=power.draw --format=csv" | Tee-Object -Variable nvidiaout | OUt-Null
            $NPow = $nvidiaout | ConvertFrom-Csv
        }
        if ($POWA -eq $true) {
            if ($amdout) {Clear-Variable amdout}
            Invoke-Expression ".\build\apps\odvii.exe s" | Tee-Object -Variable amdout | OUt-Null
            $amdinfo = $amdout | ConvertFrom-StringData
            $APow = @()
            $amdinfo.keys | foreach {if ($_ -like "*Watts*") {$APow += $amdinfo.$_}}
        }
    }

    if ($PwrType -like "*NVIDIA*") {
        if ($Platform -eq "linux") {
            $TypeS = "NVIDIA"
            if ($MinerDevices -ne "none") {$Devices = Get-DeviceString -TypeDevices "$($MinerDevices)"}
            else {$Devices = Get-DeviceString -TypeCount $($PwrDevices.$TypeS.PSObject.Properties.Value.Count)}
            $TotalPower = 0
            $NVIDIAStats = @{}
            $NVIDIAStats.Add("power", @{})
            $Npower = $NPow | Select-String "power" | foreach {$_ -replace "GPU ", ""} | foreach {$_ -replace " power", ""} | ConvertFrom-StringData
            $NPower.keys | foreach {$NVIDIAStats.power.Add("$($_)", "$($NPower."$($_)" -replace "failed to get","75")")}
            $Devices | foreach {$TotalPower += $NVIDIAStats.power."$($_)" -replace " ", ""}
            if ($Command -eq "hive") {$PowerArray}
            elseif ($Command -eq "stat") {$TotalPower}
        }
        else {
            $GPUPower = [PSCustomObject]@{}
            $TypeS = "NVIDIA"
            if ($MinerDevices -ne "none") {$Devices = Get-DeviceString -TypeDevices "$($MinerDevices)"}
            else {$Devices = Get-DeviceString -TypeCount $($PwrDevices.$TypeS.PSObject.Properties.Value.Count)}
            for ($i = 0; $i -lt $PwrDevices.NVIDIA.PSObject.Properties.Value.Count; $i++) {$GPUPower | Add-Member -MemberType NoteProperty -Name "$($PwrDevices.NVIDIA.$i)" -Value 0}
            $PowerArray = @()
            $Power = $NPow."power.draw [W]" | foreach { $_ -replace ("W", "")}
            $Power = $Power | foreach {$_ -replace ("\[Not Supported\]", "75")}  
            for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $GPUPower.$($PwrDevices.$TypeS.$GPU) = $(if ($Power.Count -eq 1) {$Power}else {$Power[$GPU]})}
            if ($GPUPower -ne $null) {$GPUPower | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$PowerArray += [Double]$($GPUPower.$_)}}
            $TotalPower = 0
            $PowerArray | foreach {$TotalPower += $_}
            if ($Command -eq "hive") {$PowerArray}
            elseif ($Command -eq "stat") {$TotalPower}
        }
    }

    if ($PwrType -like "*AMD*") {
        $GPUPower = [PSCustomObject]@{}
        $TypeS = "AMD"
        if ($MinerDevices -ne "none") {$Devices = Get-DeviceString -TypeDevices $MinerDevices}
        else {$Devices = Get-DeviceString -TypeCount $($PwrDevices.$TypeS.PSObject.Properties.Value.Count)}
        for ($i = 0; $i -lt $PwrDevices.AMD.PSObject.Properties.Value.Count; $i++) {$GPUPower | Add-Member -MemberType NoteProperty -Name "$($PwrDevices.AMD.$i)" -Value 0}
        $PowerArray = @()
        if ($Platform -eq "linux") {$Power = $APow | foreach {$_ -split $_[1] | Select -last 1}}
        else {$Power = $APow}
        for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $GPUPower.$($PwrDevices.$TypeS.$GPU) = $(if ($Power.Count -eq 1) {$Power}else {$Power[$GPU]})}
        if ($GPUPower -ne $null) {$GPUPower | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$PowerArray += [Double]$($GPUPower.$_)}}
        $TotalPower = 0
        $PowerArray | foreach {$TotalPower += $_}
        if ($Command -eq "hive") {$PowerArray}
        elseif ($Command -eq "stat") {$TotalPower}
    }
}