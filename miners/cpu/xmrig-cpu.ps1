$CPUTypes | ForEach-Object {
    
    $ConfigType = $_;
    $CName = "xmrig-cpu"

    ##Miner Path Information
    if ($cpu.$CName.$ConfigType) { $Path = "$($cpu.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($cpu.$CName.uri) { $Uri = "$($cpu.$CName.uri)" }
    else { $Uri = "None" }
    if ($cpu.$CName.minername) { $MinerName = "$($cpu.$CName.minername)" }
    else { $MinerName = "None" }

    $Name = "$CName";

    ##Log Directory
    $Log = Join-Path $dir "logs\$ConfigType.log"

    ##Parse -CPUThreads
    if ($global:Config.Params.CPUThreads -ne '') { $Devices = $global:Config.Params.CPUThreads }

    ##Get Configuration File
    $GetConfig = "$dir\config\miners\$CName.json"
    try { $MinerConfig = Get-Content $GetConfig | ConvertFrom-Json }
    catch { Write-Log "Warning: No config found at $GetConfig" }

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $dir "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $Algorithm -and $Name -notin $global:Exclusions.$MinerAlgo.exclusions -and $ConfigType -notin $global:Exclusions.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
            $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        
        if ($Check.RAW -ne "Bad") {
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                    if ($global:Config.Params.Platform -eq "windows") { $APISet = "--http-enabled --http-port=10002" }
                    else { $APISet = "--api-port=10002" }
                    [PSCustomObject]@{
                        MName      = $Name
                        Coin       = $Coins
                        Delay      = $MinerConfig.$ConfigType.delay
                        Fees       = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                        Symbol     = "$($_.Symbol)"
                        MinerName  = $MinerName
                        Prestart   = $PreStart
                        Type       = $ConfigType
                        Path       = $Path
                        Devices    = $Devices
                        DeviceCall = "xmrig-opt"
                        Arguments  = "-a $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) $APISet -o stratum+tcp://$($_.Host):$($_.Port) -u $($_.User1) -p $($_.Pass1)$($Diff) --donate-level=1 --nicehash $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                        Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        MinerPool  = "$($_.Name)"
                        FullName   = "$($_.Mining)"
                        Port       = 10002
                        API        = "xmrig-opt"
                        Wallet     = "$($_.$User)"
                        URI        = $Uri
                        Server     = "localhost"                        
                        Algo       = "$($_.Algorithm)"
                        Log        = $Log 
                    }            
                }
            }
        }
    }
}