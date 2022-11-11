. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;
$(vars).CPUTypes | ForEach-Object {

    $ConfigType = $_;

    $CName = "srbmulti-cpu";

    ##Miner Path Information
    if ($(vars).cpu.$CName.$ConfigType) { $Path = "$($(vars).cpu.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).cpu.$CName.uri) { $Uri = "$($(vars).cpu.$CName.uri)" }
    else { $Uri = "None" }
    if ($(vars).cpu.$CName.minername) { $MinerName = "$($(vars).cpu.$CName.minername)" }
    else { $MinerName = "None" }

    $Name = "$CName";

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$Name.log"

    ##Parse -CPUThreads
    if ($(arg).CPUThreads -ne '') { $Devices = $(arg).CPUThreads }

    ##Get Configuration File
    ##This is located in config\miners
    $MinerConfig = $Global:config.miners.$CName

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = "/usr/local/swarm/lib64"
    $Miner_Dir = Join-Path ($(vars).dir) ((Split-Path $Path).replace(".", ""))

    ##Prestart actions before miner launch
    ##This can be edit in miner.json
    $Prestart = @()
    #if ($IsLinux) { $Prestart += "export LD_PRELOAD=/usr/local/swarm/lib64/libcurl.so.3" }
    $PreStart += "unset LD_LIBRARY_PATH"
    if ($IsLinux) { $Prestart += "export DISPLAY=:0" }
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($(vars).Coins) { $Pools = $(vars).CoinPools } else { $Pools = $(vars).AlgoPools }

    if ($(vars).Bancount -lt 1) { $(vars).Bancount = 5 }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if (
            $MinerAlgo -in $(vars).Algorithm -and
            $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and
            $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and
            $Name -notin $(vars).BanHammer
        ) {
            $StatAlgo = $MinerAlgo -replace "`_", "`-"
            $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate"
            if ($(arg).Rej_Factor -eq "Yes" -and $Stat.Rejections -gt 0 -and $Stat.Rejection_Periods -ge 3) { $HashStat = $Stat.Hour * (1 - ($Stat.Rejections * 0.01)) }
            else { $HashStat = $Stat.Hour }
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                $Nicehash = ""
                if($_.Name -eq "Nicehash") {
                    $Nicehash = "--Nicehash true "
                }
                $Diff = ""
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { 
                    switch($_.Name) {
                        "zergpool" { $Diff = ",sd=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                        default { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                    }
                }
                [PSCustomObject]@{
                    MName      = $Name
                    Coin       = $(vars).Coins
                    Delay      = $MinerConfig.$ConfigType.delay
                    Fees       = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                    Symbol     = "$($_.Symbol)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    Stratum    = "$($_.Protocol)://$($_.Pool_Host):$($_.Port)"
                    Version    = "$($(vars).cpu.$CName.version)"
                    DeviceCall = "srbmulti-cpu"
                    Arguments  = "$Nicehash--disable-gpu --cpu-threads-priority $($(arg).cpu_priority) --disable-worker-watchdog --algorithm $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) --pool $($_.Pool_Host):$($_.Port) --wallet $($_.User1) --password $($_.Pass1)$Diff --api-enable --log-file `'$Log`' --api-port 10001 $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [Decimal]$Stat.Hour
                    HashRate_Adjusted = [Decimal]$Hashstat
                    Quote      = $_.Price
                    Rejections = $Stat.Rejections
                    Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 }
                    MinerPool  = "$($_.Name)"
                    Port       = 10001
                    Worker     = $Rig
                    API        = "srbmulti-cpu"
                    Wallet     = "$($_.$User)"
                    URI        = $Uri
                    Server     = "localhost"
                    Algo       = "$($_.Algorithm)"
                    Log        = "miner_generated"
                }
            }
        }
    }
}
