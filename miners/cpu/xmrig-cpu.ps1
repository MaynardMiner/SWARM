$(vars).CPUTypes | ForEach-Object {
    
    $ConfigType = $_;
    $CName = "xmrig-cpu"

    ##Miner Path Information
    if ($(vars).cpu.$CName.$ConfigType) { $Path = "$($(vars).cpu.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).cpu.$CName.uri) { $Uri = "$($(vars).cpu.$CName.uri)" }
    else { $Uri = "None" }
    if ($(vars).cpu.$CName.minername) { $MinerName = "$($(vars).cpu.$CName.minername)" }
    else { $MinerName = "None" }

    $Name = "$CName";

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -CPUThreads
    if ($(arg).CPUThreads -ne '') { $Devices = $(arg).CPUThreads }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.$CName
    
    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($(vars).dir) "build\export"

    ##Prestart actions before miner launch
    $Prestart = @()
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    if (Test-Path $BE) { $Prestart += "export LD_PRELOAD=libcurl-compat.so.3.0.0" }
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($(vars).Coins) { $Pools = $(vars).CoinPools } else { $Pools = $(vars).AlgoPools }

    if ($(vars).Bancount -lt 1) { $(vars).Bancount = 5 }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $(vars).Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $(vars).BanHammer) {
            $StatAlgo = $MinerAlgo -replace "`_", "`-"
            $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate" 
        
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
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
                    DeviceCall = "xmrig-opt"
                    Arguments  = "-a $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) --http-enabled --http-port=10002 -o stratum+tcp://$($_.Pool_Host):$($_.Port) -u $($_.User1) -p $($_.Pass1)$($Diff) --donate-level=1 --nicehash $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = $Stat.Hour
                    Worker     = $(arg).Rigname1
                    Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                    Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                    MinerPool  = "$($_.Name)"
                    Port       = 10002
                    API        = "xmrig-opt"
                    Wallet     = "$($_.User1)"
                    URI        = $Uri
                    Server     = "localhost"                        
                    Algo       = "$($_.Algorithm)"
                    Log        = $Log 
                }            
            }
        }
    }
}