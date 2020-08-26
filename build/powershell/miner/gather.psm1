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

function Global:Get-Miners {
    
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

    $(arg).Type | ForEach-Object {
        if ($_ -like "*ASIC*" ) { $ASICMiners = $true; $SItems = Get-ChildItem ".\miners\asic" }
        if ($_ -like "*NVIDIA*" ) { $NVB = $true; $GPUMiners = $true; $NItems = Get-ChildItem ".\miners\gpu\nvidia" }
        if ($_ -like "*AMD*" ) { $AMDB = $true; $GPUMiners = $true; $AItems = Get-ChildItem ".\miners\gpu\amd" }
        if ($_ -like "*CPU*" ) { $CPUB = $true; $GPUMiners = $true; $CItems = Get-ChildItem ".\miners\cpu" }
    }

    ## Start Running miner scripts, Create an array of Miner Hash Tables
    $GetMiners = New-Object System.Collections.ArrayList

    if ($GPUMiners -eq $true) {
        if ($NVB -eq $true) {            
            $NVIDIAMiners = Global:Get-ChildItemContent -Path ".\miners\gpu\nvidia" | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
            Where-Object { $(arg).Type.Count -eq 0 -or (Compare-Object $(arg).Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
            Where-Object { $_.Path -ne "None" } |
            Where-Object { $_.Uri -ne "None" } |
            Where-Object { $_.MinerName -ne "None" }
        }
        if ($AMDB -eq $true) {
            $AMDMiners = Global:Get-ChildItemContent -Path ".\miners\gpu\amd" | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
            Where-Object { $(arg).Type.Count -eq 0 -or (Compare-Object $(arg).Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
            Where-Object { $_.Path -ne "None" } |
            Where-Object { $_.Uri -ne "None" } |
            Where-Object { $_.MinerName -ne "None" }
        }
        if ($CPUB -eq $true) {
            $CPUMiners = Global:Get-ChildItemContent -Path ".\miners\cpu" | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
            Where-Object { $(arg).Type.Count -eq 0 -or (Compare-Object $(arg).Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
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
        Where-Object { $(arg).Type.Count -eq 0 -or (Compare-Object $(arg).Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 }
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
    if ($Note) { 
        $Note | ForEach-Object { 
            log "$($_)" -ForegroundColor Magenta 
            } 
        log "To clear bans- Run command 'bench bans', or delete timeout folder" -ForegroundColor Magenta
    }
    $GetMiners
}
function Global:Get-AlgoMiners {
    if ($(vars).AlgoPools.Count -gt 0 -and $(vars).AlgoPools -ne 1) {
        $start_time = (Get-Date).ToUniversalTime()
        log "Checking Algo Miners. . . ." -ForegroundColor Yellow
        ##Load Only Needed Algorithm Miners
        Global:Get-Miners | ForEach-Object { $(vars).Miners.Add($_) | Out-Null }
        remove AlgoPools
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        [GC]::Collect()  
        $time = [math]::Round(((Get-Date).ToUniversalTime() - $start_time).TotalSeconds)      
        log "Algo Miners Loading Time: $time seconds" -Foreground Green    
    }
}

function Global:Get-CoinMiners {
    if ($(vars).CoinPools.Count -gt 0 -and $(vars).CoinPools -ne 1) {
        $start_time = (Get-Date).ToUniversalTime()
        $(vars).Coins = $true
        log "Checking Coin Miners. . . . ." -ForegroundColor Yellow
        ##Load Only Needed Coin Miners
        Global:Get-Miners | ForEach-Object { $(vars).Miners.Add($_) | Out-Null }
        remove CoinPools
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        [GC]::Collect()        
        $time = [math]::Round(((Get-Date).ToUniversalTime() - $start_time).TotalSeconds)      
        log "Coin Miners Loading Time: $time seconds" -Foreground Green    
    }
}

function Global:Confirm-Backup {
    if ($(vars).No_Miners -ge 10 -and $(arg).startup -eq "Yes") {
        log "No Miners Last 10 Intervals- Migrating Backup And Then Restarting" -Foreground DarkRed
        if (test-path ".\Backup") {
            $backup_stats = Get-ChildItem ".\backup" | Where-Object BaseName -like "*hashrate*"
            $backup_stats | ForEach-Object {
                Copy-Item $_ -Destination ".\stats" -Force
            }
        }
        log "All backup stats loaded to stats folder, rebooting in 5 seconds." -Foreground Yellow
        Start-Sleep -S 5
        if ($Islinux) {
            Invoke-Expression "reboot"
        }
        elseif ($IsWindows) {
            Restart-Computer
        }
    }
}