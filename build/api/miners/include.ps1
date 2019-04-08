## Simplified functions (To Shorten)
function Get-GPUs {$GPU = $Devices[$i]; $GCount.$TypeS.$GPU};

function Write-MinerData1 {
    Write-host " "
    Write-Host "Miner $MinerType is $MinerAPI api"
    Write-Host "Miner Port is $Port"
    Write-Host "Miner Devices is $Devices"
    Write-Host "Miner is Mining $MinerAlgo"
}

function Write-MinerData2 {
    if($MinerType -ne "ASIC") {
        $global:BRAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        Write-Host "Miner $Name was clocked at $($global:BRAW | ConvertTo-Hash)/s" -foreground Yellow
    }
    else {
        $global:ARAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        Write-Host "Miner $Name was clocked at $($global:ARAW | ConvertTo-Hash)/s" -foreground Yellow
    }
    if ($Platforms -eq "linux") {$Process = Get-Process | Where Name -clike "*$($MinerType)*"}
}

function Set-Array {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Object]$ParseRates,
        [Parameter(Position = 1, Mandatory = $true)]
        [int]$i,
        [Parameter(Position = 2, Mandatory = $false)]
        [string]$factor
    )
    try {
        $Parsed = $ParseRates | % {iex $_}
        $Parse = $Parsed | Select -Skip $i -First 1
        if ($null -eq $Parse) {$Parse = 0}
    }
    catch {$Parse = 0}
    $Parse
}

function Set-APIFailure {
    Write-Host "API Summary Failed- Could Not Total Hashrate Or No Accepted Shares" -Foreground Red; 
    $global:BRAW | Set-Content ".\build\txt\$MinerType-hash.txt";
}

## NVIDIA HWMON
function Set-NvidiaStats {

    Switch ($Platforms) {
        "linux" {
            switch ($HiveOS) {
                "No" {
                    timeout -s9 10 ./build/apps/VII-smi | Tee-Object -Variable getstats | Out-Null
                    if ($getstats) {
                        $nvidiai = $getstats | ConvertFrom-StringData
                        $nvinfo = @{}
                        $nvinfo.Add("Fans", @())
                        $nvinfo.Add("Temps", @())
                        $nvinfo.Add("Watts", @())
                        $nvidiai.keys | foreach {if ($_ -like "*fan*") {$nvinfo.Fans += $nvidiai.$_}}
                        $nvidiai.keys | foreach {if ($_ -like "*temperature*") {$nvinfo.Temps += $nvidiai.$_}}
                        $nvidiai.keys | foreach {if ($_ -like "*power*") {if ($nvidiai.$_ -eq "failed to get") {$nvinfo.Watts += "75"}else {$nvinfo.Watts += $nvidiai.$_}}}
                    }
                }
                "Yes" {
                    $HiveStats = "/run/hive/gpu-stats.json"
                    do {
                        for ($i = 0; $i -lt 20; $i++) {
                            if (test-Path $HiveStats) {try {$GetHiveStats = Get-Content $HiveStats | ConvertFrom-Json -ErrorAction Stop}catch {$GetHiveStats = $null}}
                            if ($GetHiveStats -ne $null) {
                                $nvinfo = @{}
                                $nvinfo.Add("Fans", $( $GetHiveStats.fan | % {if ($_ -ne 0) {$_}} ) )
                                $nvinfo.Add("Temps", $( $GetHiveStats.temp | % {if ($_ -ne 0) {$_}} ) )
                            }
                            Start-Sleep -S .5
                        }
                    }while ($GetHiveStats.temp.count -lt 1 -and $GetHiveStats.fan.count -lt 1)
                }
            }
        }

        "windows" {
            invoke-expression ".\build\apps\nvidia-smi.exe --query-gpu=power.draw,fan.speed,temperature.gpu --format=csv" | Tee-Object -Variable nvidiaout | Out-Null
            if ($nvidiaout) {$ninfo = $nvidiaout | ConvertFrom-Csv}
            $NVIDIAFans = $ninfo.'fan.speed [%]' | foreach {$_ -replace ("\%", "")}
            $NVIDIATemps = $ninfo.'temperature.gpu'
            $NVIDIAPower = $ninfo.'power.draw [W]' | foreach {$_ -replace ("\[Not Supported\]", "75")} | foreach {$_ -replace (" W", "")}        
            $NVIDIAStats = @{}
            $NVIDIAStats.Add("Fans", $NVIDIAFans)
            $NVIDIAStats.Add("Temps", $NVIDIATemps)
            $NVIDIAStats.Add("Power", $NVIDIAPower)
            $nvinfo = $NVIDIAStats  
        }
    }
    $nvinfo
}

## AMD HWMON
function Set-AMDStats {

    switch ($Platforms) {
        "windows" {
            Invoke-Expression ".\build\apps\odvii.exe s" | Tee-Object -Variable amdout | Out-Null
            if ($amdout) {
                $AMDStats = @{}
                $amdinfo = $amdout | ConvertFrom-StringData
                $ainfo = @{}
                $aerrors = @{}
                $aerrors.Add("Errors", @())
                $ainfo.Add("Fans", @())
                $ainfo.Add("Temps", @())
                $ainfo.Add("Watts", @())
                $amdinfo.keys | foreach {if ($_ -like "*Fan*") {$ainfo.Fans += $amdinfo.$_}}
                $amdinfo.keys | foreach {if ($_ -like "*Temp*") {$ainfo.Temps += $amdinfo.$_}}
                $amdinfo.keys | foreach {if ($_ -like "*Watts*") {$ainfo.Watts += $amdinfo.$_}}
                $amdinfo.keys | foreach {if ($_ -like "*Errors*") {$aerrors.Errors += $amdinfo.$_}}
                $AMDFans = $ainfo.Fans
                $AMDTemps = $ainfo.Temps
                $AMDPower = $ainfo.Watts
                if ($aerrors.Errors) {
                    Write-Host "Warning Errors Detected From Drivers:" -ForegroundColor Red
                    $aerrors.Errors | % {Write-host "$($_)" -ForegroundColor Red}
                    Write-Host "Drivers/Settings May Be Set Incorrectly/Not Compatible
      " -ForegroundColor Red
                }
            }
        }

        "linux" {
            switch ($HiveOS) {
                "Yes" {
                    $HiveStats = "/run/hive/gpu-stats.json"
                    do {
                        for ($i = 0; $i -lt 20; $i++) {
                            if (test-Path $HiveStats) {try {$GetHiveStats = Get-Content $HiveStats | ConvertFrom-Json -ErrorAction Stop}catch {$GetHiveStats = $null}}
                            if ($GetHiveStats -ne $null) {
                                $AMDStats = @{}
                                $AMDFans = $( $GetHiveStats.fan | % {if ($_ -ne 0) {$_}} )
                                $AMDTemps = $( $GetHiveStats.temp | % {if ($_ -ne 0) {$_}} )
                            }
                            Start-Sleep -S .5
                        }
                    }while ($GetHiveStats.temp.count -lt 1 -and $GetHiveStats.fan.count -lt 1)
                }
                "No" {
                    $AMDStats = @{}
                    timeout -s9 10 rocm-smi -f | Tee-Object -Variable AMDFans | Out-Null
                    $AMDFans = $AMDFans | Select-String "%" | foreach {$_ -split "\(" | Select -Skip 1 -first 1} | foreach {$_ -split "\)" | Select -first 1}
                    timeout -s9 10 rocm-smi -t | Tee-Object -Variable AMDTemps | Out-Null
                    $AMDTemps = $AMDTemps | Select-String -CaseSensitive "Temperature" | foreach {$_ -split ":" | Select -skip 2 -First 1} | foreach {$_ -replace (" ", "")} | foreach {$_ -replace ("c", "")}
                }
            }
        }
    }

    $AMDStats.Add("Fans", $AMDFans)
    $AMDStats.Add("Temps", $AMDTemps)
    $AMDStats.Add("Power", $AMDPower)

    $AMDStats

}

function Get-OhNo{
 Write-Host "Failed To Collect Miner Data" -ForegroundColor Red
}

function Remove-ASICPools {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$AIP,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Port,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Name
    )

    $ASIC_Pools = @{ }
    $Timeout = 5

    Switch ($Name) {
        "cgminer" {
            $ASICM = "cgminer"
            Write-Host "Clearing all previous cgminer pools." -ForegroundColor "Yellow"
            $ASIC_Pools.Add($ASICM, @{ })
            ##First we need to discover all pools
            $Commands = @{command = "pools"; parameter = 0 } | ConvertTo-Json -Compress
            $response = $Null
            $response = Get-TCP -Server $AIP -Port $Port -Message $Commands -Timeout $timeout
            if ($response) {
                $PoolList = $response | ConvertFrom-Json
                $PoolList = $PoolList.POOLS
                $PoolList | ForEach-Object { $ASIC_Pools.$ASICM.Add("Pool_$($_.Pool)", $_.Pool) }
                $ASIC_Pools.$ASICM.keys | ForEach-Object {
                    $PoolNo = $($ASIC_Pools.$ASICM.$_)
                    $Commands = @{command = "removepool"; parameter = "$PoolNo" } | ConvertTo-Json -Compress; 
                    $response = $Null; 
                    $response = Get-TCP -Server $AIP -Port $Port -Message $Commands -Timeout $timeout 
                    $response
                }  
            }
            else { Write-Warning "Failed To Gather cgminer Pool List!" }
        }
    }
}