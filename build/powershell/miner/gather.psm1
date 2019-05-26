function Get-Miners {
    
    ## Reset Arrays In Case Of Weirdness
    $GetPoolBlocks = $null
    $GetAlgoBlocks = $null
    $GetMinerBlocks = $null
    $GPUMiners = $false
    $ASICMiners = $false
    $NVB = $false
    $AMDB = $false
    $CPUB = $false

    ## Pool Bans From File && Specify miner folder based on platform
    if (Test-Path ".\timeout\pool_block\pool_block.txt") { $GetPoolBlocks = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json }
    if (Test-Path ".\timeout\algo_block\algo_block.txt") { $GetAlgoBlocks = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json }
    if (Test-Path ".\timeout\miner_block\miner_block.txt") { $GetMinerBlocks = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json }
    if (Test-Path ".\timeout\download_block\download_block.txt") { $GetDownloadBlocks = Get-Content ".\timeout\download_block\download_block.txt" | ConvertFrom-Json }

    $Global:Config.Params.Type | ForEach-Object {
        if ($_ -like "*ASIC*" ) { $ASICMiners = $true; $SItems = Get-ChildItem ".\miners\asic" }
        if ($_ -like "*NVIDIA*" ) { $NVB = $true; $GPUMiners = $true; $NItems = Get-ChildItem ".\miners\gpu\nvidia" }
        if ($_ -like "*AMD*" ) { $AMDB = $true; $GPUMiners = $true; $AItems = Get-ChildItem ".\miners\gpu\amd" }
        if ($_ -like "*CPU*" ) { $CPUB = $true; $GPUMiners = $true; $CItems = Get-ChildItem ".\miners\cpu" }
    }

    ## Start Running miner scripts, Create an array of Miner Hash Tables
    $GetMiners = New-Object System.Collections.ArrayList

    if ($GPUMiners -eq $true) {
        if ($NVB -eq $true) {
            $NVIDIAMiners = Get-ChildItemContent -Path ".\miners\gpu\nvidia" | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
                Where-Object { $global:Config.Params.Type.Count -eq 0 -or (Compare-Object $global:Config.Params.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
                Where-Object { $_.Path -ne "None" } |
                Where-Object { $_.Uri -ne "None" } |
                Where-Object { $_.MinerName -ne "None" }
        }
        if ($AMDB -eq $true) {
            $AMDMiners = Get-ChildItemContent -Path ".\miners\gpu\amd" | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
                Where-Object { $global:Config.Params.Type.Count -eq 0 -or (Compare-Object $global:Config.Params.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
                Where-Object { $_.Path -ne "None" } |
                Where-Object { $_.Uri -ne "None" } |
                Where-Object { $_.MinerName -ne "None" }
        }
        if ($CPUB -eq $true) {
            $CPUMiners = Get-ChildItemContent -Path ".\miners\cpu" | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
                Where-Object { $global:Config.Params.Type.Count -eq 0 -or (Compare-Object $global:Config.Params.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
                Where-Object { $_.Path -ne "None" } |
                Where-Object { $_.Uri -ne "None" } |
                Where-Object { $_.MinerName -ne "None" }
        }

        if ($NVIDIAMiners) { $NVIDIAminers | ForEach-Object { $_.Name = $_.MName; $GetMiners.Add($_) | Out-Null } }
        if ($AMDMiners) { $AMDMiners | ForEach-Object { $_.Name = $_.MName; $GetMiners.Add($_) | Out-Null } }
        if ($CPUMiners) { $CPUMiners | ForEach-Object { $_.Name = $_.MName; $GetMiners.Add($_) | Out-Null } }
    }

    if ($ASICMiners -eq $True) {
        $ASICMiners = Get-ChildItemContent -Path ".\miners\asic" | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
            Where-Object { $global:Config.Params.Type.Count -eq 0 -or (Compare-Object $global:Config.Params.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 }
        $ASICMiners | ForEach-Object { $_.Name = $_.MName; $GetMiners.Add($_) | Out-Null }
    }
    $Note = @()
    $ScreenedMiners = @()

    ## This Creates A New Array Of Miners, Screening Miners That Were Bad. As it does so, it notfies user.
    $GetMiners | ForEach-Object {
      
        $TPoolBlocks = $GetPoolBlocks | Where-Object Algo -eq $_.Algo | Where-Object Name -eq $_.Name | Where-Object Type -eq $_.Type | Where-Object MinerPool -eq $_.Minerpool
        $TAlgoBlocks = $GetAlgoBlocks | Where-Object Algo -eq $_.Algo | Where-Object Name -eq $_.Name | Where-Object Type -eq $_.Type
        $TMinerBlocks = $GetMinerBlocks | Where-Object Name -eq $_.Name | Where-Object Type -eq $_.Type
        $TDownloadBlocks = $GetDownloadBlocks | Where-Object Name -eq $_.Name

        if ($TPoolBlocks) {
            $Warning = "Warning: Blocking $($_.Name) mining $($_.Algo) on $($_.MinerPool) for $($_.Type)"; 
            if ($Note -notcontains $Warning) { $Note += $Warning }
            $ScreenedMiners += $_
        }
        elseif ($TAlgoBlocks) {
            $Warning = "Warning: Blocking $($_.Name) mining $($_.Algo) on all pools for $($_.Type)"; 
            if ($Note -notcontains $Warning) { $Note += $Warning }
            $ScreenedMiners += $_
        }
        elseif ($TMinerBlocks) {
            $Warning = "Warning: Blocking $($_.Name) for $($_.Type)"; 
            if ($Note -notcontains $Warning) { $Note += $Warning }
            $ScreenedMiners += $_
        }
        elseif ($TDownloadBlocks) {
            $Warning = "Warning: Blocking $($_.Name) - Download Failed"; 
            if ($Note -notcontains $Warning) { $Note += $Warning }
            $ScreenedMiners += $_
        }
    }
    
    $ScreenedMiners | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
    if ($Note) { $Note | ForEach-Object { Write-Log "$($_)" -ForegroundColor Magenta } }
    $GetMiners
}
function Get-AlgoMiners {
    if ($global:AlgoPools.Count -gt 0) {
        $global:QuickTimer.Restart()
        write-Log "Checking Algo Miners. . . ." -ForegroundColor Yellow
        ##Load Only Needed Algorithm Miners
        $Global:AlgoMiners = New-Object System.Collections.ArrayList
        $SearchMiners = Get-Miners
        $SearchMiners | % { $Global:AlgoMiners.Add($_) | Out-Null }
        $SearchMiners = $null
        $global:AlgoPools = $null
        if ($Global:AlgoMiners) { $Global:AlgoMiners | % { $Global:Miners.Add($_) | Out-Null } }
        $Global:AlgoMiners = $null
        $global:QuickTimer.Stop()
        Write-Log "Algo Miners Loading Time: $([math]::Round($global:QuickTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green    
    }
}

function Get-CoinMiners {
    if ($global:CoinPools.Count -gt 0) {
        $global:QuickTimer.Restart()
        $Global:Coins = $true
        write-Log "Checking Coin Miners. . . . ." -ForegroundColor Yellow
        ##Load Only Needed Coin Miners
        $Global:CoinMiners = New-Object System.Collections.ArrayList
        $SearchMiners = Get-Miners
        $SearchMiners | % { $Global:CoinMiners.Add($_) | Out-Null }
        $SearchMiners = $Null
        $global:CoinPools = $null
        if ($Global:CoinMiners) { $Global:CoinMiners | % { $Global:Miners.Add($_) | Out-Null } }
        $Global:CoinMiners = $null
        $global:QuickTimer.Stop()
        Write-Log "Coin Miners Loading Time: $([math]::Round($global:QuickTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green    
    }
}