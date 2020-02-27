
function Global:Invoke-MinerSuccess {
    log "         
        
                         //\\  _______
                        //  \\//~//.--|
                        Y   /\\~~//_  |
                       _L  |_((_|___L_|
                      (/\)(____(_______)      
Waiting 15 Seconds For Miners To Load & Restarting Background Tracking
" -ForegroundColor Magenta
    if ($(arg).Platform -eq "linux") {
        log "

Type `'mine`' in another terminal to see miner working- This is NOT a remote command!

Type `'get-screen [MinerType]`' to see last 100 lines of log- This IS a remote command!

https://github.com/MaynardMiner/SWARM/wiki/Commands-&-Suggested-Apps For More Info

" -ForegroundColor Magenta
    }
    elseif ($(arg).Platform -eq "windows") {
        log "

There is now a new window where miner is working. The output may be different from

using without SWARM, as SWARM is logging miner data. Agent window will show SWARM real time

tracking of algorithms and GPU information. It can be used to observe issues, if any.
" -foreground Magenta
    }
    Start-Sleep -s 15
}


function Global:Invoke-MinerWarning {
    ##Notify User Of Failures
    log "
   
There are miners that have failed! Check Your Settings And Arguments!
" -ForegroundColor DarkRed

    if ($(arg).Platform -eq "linux") {
        log "

Type `'mine`' in another terminal to see background miner, and its reason for failure.
You may also view logs with in the `"logs`" directory, or `'get-screen [Type]`'
If miner is not your primary miner (AMD1 or NVIDIA1), type `'screen -r [Type]`'
https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration) >> Right Click `'Open URL In Browser`'
" -ForegroundColor Darkred
    }
    elseif ($(arg).Platform -eq "windows") {
        log "
 
 SWARM attempts to catch screen output, and is stored in `'logs`' folder.
 SWARM has also created a executable called `'swarm-start.bat`' located in the `'bin`'
 directory and folder of the miner. `'swarm-start.bat`' starts miner with last known settings, 
 and window stays open, so you may view issue.
" -ForegroundColor DarkRed
    }
    Start-Sleep -s 10
}

function Global:Invoke-NoChange {
    log "
        
        
Most Profitable Miners Are Running
" -foreground DarkCyan
    Start-Sleep -s 5
}

function Global:Get-LaunchNotification {
    $(vars).MinerWatch.Restart()
    if ($(vars).Restart -eq $true -and $(vars).NoMiners -eq $true) { Global:Invoke-MinerWarning }
    if ($(arg).Platform -eq "linux" -and $(vars).Restart -eq $true -and $(vars).NoMiners -eq $false) { Global:Invoke-MinerSuccess }
    if ($(arg).Platform -eq "windows" -and $(vars).Restart -eq $true -and $(vars).NoMiners -eq $false) { Global:Invoke-MinerSuccess }
    if ($(vars).Restart -eq $false) { Global:Invoke-NoChange }
}

function Global:Get-Interval {
    ##Determine Benchmarking
    $NoHash = $false
    log "Stats and active miners have been updated for commands." -foreground Yellow;
    $(vars).BestActiveMiners | ForEach-Object {
        $StatAlgo = $_.Algo -replace "`_", "`-"
        $StatAlgo = $StatAlgo -replace "`/", "`-"        
        if (-not (Test-Path ".\stats\$($_.Name)_$($StatAlgo)_hashrate.txt")) { 
            $NoHash = $true
            $(vars).BenchmarkMode = $true; 
        }
    }
    if ($NoHash -eq $true) {
        log "SWARM is Benchmarking Miners." -Foreground Yellow;
        $(vars).MinerStatInt = 1
    }
    else {
        $(vars).BenchmarkMode = $false
        $(vars).MinerStatInt = $(arg).StatsInterval
        if ($(arg).SWARM_Mode -eq "Yes") {
            $(vars).SWARM_IT = $true
            log "SWARM MODE ACTIVATED!" -ForegroundColor Green;
            $global:SwitchTime = Get-Date
            log "SWARM Mode Start Time is $global:SwitchTime" -ForegroundColor Cyan;
            $(vars).MinerInterval = 10000000;
        }
        else { 
            $(vars).MinerInterval = [math]::Round([math]::Max((300 - $(vars).Load_Timer.Elapsed.TotalSeconds),1))
        }
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

    $(arg).Type | ForEach-Object { $(vars).Share_Table.Add("$($_)", @{ }) }

    ##For 
    $(arg).Poolname | % {
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

function Global:Confirm-Nofitication {
    if ([Double]$(vars).BanPass -ne (0.65 + 0.85)) { 
        $(vars).BanPass = (2.65 + 2.35) 
        $(vars).BanCount = (2.65 + 2.53)
    }
}