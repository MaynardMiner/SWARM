
function Global:Invoke-MinerSuccess {
    Global:Write-Log "         
        
                         //\\  _______
                        //  \\//~//.--|
                        Y   /\\~~//_  |
                       _L  |_((_|___L_|
                      (/\)(____(_______)      
Waiting 15 Seconds For Miners To Load & Restarting Background Tracking
" -ForegroundColor Magenta
    if ($global:Config.Params.Platform -eq "linux") {
        Global:Write-Log "

Type `'mine`' in another terminal to see miner working- This is NOT a remote command!

Type `'get-screen [MinerType]`' to see last 100 lines of log- This IS a remote command!

https://github.com/MaynardMiner/SWARM/wiki/Commands-&-Suggested-Apps For More Info

" -ForegroundColor Magenta
    }
    elseif ($global:Config.Params.Platform -eq "windows") {
        Global:Write-Log "

There is now a new window where miner is working. The output may be different from

using without SWARM, as SWARM is logging miner data. Agent window will show SWARM real time

tracking of algorithms and GPU information. It can be used to observe issues, if any.
" -foreground Magenta
    }
    Start-Sleep -s 15
}


function Global:Invoke-MinerWarning {
    ##Notify User Of Failures
    Global:Write-Log "
   
There are miners that have failed! Check Your Settings And Arguments!
" -ForegroundColor DarkRed

    if ($global:Config.Params.Platform -eq "linux") {
        Global:Write-Log "

Type `'mine`' in another terminal to see background miner, and its reason for failure.
You may also view logs with in the `"logs`" directory, or `'get-screen [Type]`'
If miner is not your primary miner (AMD1 or NVIDIA1), type `'screen -r [Type]`'
https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration) >> Right Click `'Open URL In Browser`'
" -ForegroundColor Darkred
    }
    elseif ($global:Config.Params.Platform -eq "windows") {
        Global:Write-Log "
 
 SWARM attempts to catch screen output, and is stored in `'logs`' folder.
 SWARM has also created a executable called `'swarm-start.bat`' located in the `'bin`'
 directory and folder of the miner. `'swarm-start.bat`' starts miner with last known settings, 
 and window stays open, so you may view issue.
" -ForegroundColor DarkRed
    }
    Start-Sleep -s 10
}

function Global:Invoke-NoChange {
    Global:Write-Log "
        
        
Most Profitable Miners Are Running
" -foreground DarkCyan
    Start-Sleep -s 5
}

function Global:Get-LaunchNotification {
    $global:MinerWatch.Restart()
    if ($global:Restart -eq $true -and $global:NoMiners -eq $true) { Global:Invoke-MinerWarning }
    if ($global:Config.Params.Platform -eq "linux" -and $global:Restart -eq $true -and $global:NoMiners -eq $false) { Global:Invoke-MinerSuccess }
    if ($global:Config.Params.Platform -eq "windows" -and $global:Restart -eq $true -and $global:NoMiners -eq $false) { Global:Invoke-MinerSuccess }
    if ($global:Restart -eq $false) { Global:Invoke-NoChange }
}

function Global:Get-Interval {
    ##Determine Benchmarking
    $global:BestActiveMiners | ForEach-Object {
        $StatAlgo = $_.Algo -replace "`_", "`-"        
        if (-not (Test-Path ".\stats\$($_.Name)_$($StatAlgo)_hashrate.txt")) { 
            $global:BenchmarkMode = $true; 
        }
    }

    if ($global:BenchmarkMode -eq $true) {
        Global:Write-Log "SWARM is Benchmarking Miners." -Foreground Yellow;
        $global:MinerInterval = $global:Config.Params.Benchmark
        $global:MinerStatInt = 1
    }
    else {
        if ($global:Config.Params.SWARM_Mode -eq "Yes") {
            $global:SWARM_IT = $true
            Global:Write-Log "SWARM MODE ACTIVATED!" -ForegroundColor Green;
            $global:SwitchTime = Get-Date
            Global:Write-Log "SWARM Mode Start Time is $global:SwitchTime" -ForegroundColor Cyan;
            $global:MinerInterval = 10000000;
            $global:MinerStatInt = $global:Config.Params.StatsInterval
        }
        else { $global:MinerInterval = $global:Config.Params.Interval; $global:MinerStatInt = $global:Config.Params.StatsInterval }
    }
}

function Global:Get-CoinShares {

    . .\build\api\pools\zergpool.ps1;
    . .\build\api\pools\nlpool.ps1;    
    . .\build\api\pools\ahashpool.ps1;
    . .\build\api\pools\blockmasters.ps1;
    . .\build\api\pools\hashrefinery.ps1;
    . .\build\api\pools\phiphipool.ps1;
    . .\build\api\pools\fairpool.ps1;
    . .\build\api\pools\blazepool.ps1;

    $global:Config.Params.Type | ForEach-Object { $global:Share_Table.Add("$($_)", @{ }) }

    ##For 
    $global:Config.Params.Poolname | % {
        switch ($_) {
            "zergpool" { Get-ZergpoolData }
            "nlpool" { Get-NlPoolData }        
            "ahashpool" { Get-AhashpoolData }
            "blockmasters" { Get-BlockMastersData }
            "hashrefinery" { Get-HashRefineryData }
            "phiphipool" { Get-PhiphipoolData }
            "fairpool" { Get-FairpoolData }
            "blazepool" { Get-BlazepoolData }
        }
    }
}