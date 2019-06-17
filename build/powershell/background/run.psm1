
function Global:Get-OhNo {
    Write-Host "Failed To Collect Miner Data" -ForegroundColor Red
}

function Global:Set-APIFailure {
    Write-Host "API Summary Failed- Could Not Total Hashrate Or No Accepted Shares" -Foreground Red; 
}

function Global:Get-GPUs { $GPU = $global:Devices[$i]; $(vars).GCount.$($global:TypeS).$GPU };

function Global:Write-MinerData1 {
    Write-Host " "
    Write-Host "Miner $global:MinerType is $global:MinerAPI api"
    Write-Host "Miner Port is $global:Port"
    Write-Host "Miner Devices is $global:Devices"
    Write-Host "Miner is Mining $global:MinerAlgo"
}

function Global:Write-MinerData2 {
    $global:MinerTable.ADD("$($global:MinerType)",$global:RAW)
    Write-Host "Miner $global:Name was clocked at $( $global:RAW | Global:ConvertTo-Hash )/s" -foreground Yellow
}

function Global:Set-Array {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Object]$ParseRates,
        [Parameter(Position = 1, Mandatory = $true)]
        [int]$i,
        [Parameter(Position = 2, Mandatory = $false)]
        [string]$factor
    )
    try {
        $Parsed = $ParseRates | ForEach-Object { Invoke-Expression $_ }
        $Parse = $Parsed | Select-Object -Skip $i -First 1
        if ($null -eq $Parse) { $Parse = 0 }
    }
    catch { $Parse = 0 }
    $Parse
}

