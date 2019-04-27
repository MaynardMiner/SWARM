$CPUTypes | ForEach-Object {
    
    $ConfigType = $_;

    ##Miner Path Information
    if ($cpu.sugarchain.$ConfigType) { $Path = "$($cpu.sugarchain.$ConfigType)" }
    else { $Path = "None" }
    if ($cpu.sugarchain.uri) { $Uri = "$($cpu.sugarchain.uri)" }
    else { $Uri = "None" }
    if ($cpu.sugarchain.minername) { $MinerName = "$($cpu.sugarchain.minername)" }
    else { $MinerName = "None" }

    $Name = "sugarchain";

    ##Log Directory
    $Log = Join-Path $dir "logs\$ConfigType.log"

    ##Parse -CPUThreads
    if ($CPUThreads -ne '') { $Devices = $CPUThreads }

    ##Get Configuration File
    $GetConfig = "$dir\config\miners\sugarchain.json"
    try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
    catch { Write-Log "Warning: No config found at $GetConfig" }

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $dir "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    if (Test-Path $BE) { $Prestart += "export LD_PRELOAD=libcurl.so.4.5.0" }
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $Config.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
        $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        if ($Check.RAW -ne "Bad") {
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                if ($_.Algorithm -in $Algorithm -and $Name -notin $global:Exclusions.$($_.Algorithm).exclusions -and $Name -notin $global:banhammer) {
                    if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                    [PSCustomObject]@{
                        MName      = $Name
                        Coin       = $Coins
                        Delay      = $Config.$ConfigType.delay
                        Fees       = $Config.$ConfigType.fee.$($_.Algorithm)
                        Symbol     = "$($($_.Algorithm))"
                        MinerName  = $MinerName
                        Prestart   = $PreStart
                        Type       = $ConfigType
                        Path       = $Path
                        Devices    = $Devices
                        DeviceCall = "cpuminer-opt"
                        Arguments  = "-a $($Config.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Host):$($_.Port) -b 0.0.0.0:10001 -u $($_.User1) -p $($_.Pass1)$($Diff) $($Config.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                        Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        MinerPool  = "$($_.Name)"
                        FullName   = "$($_.Mining)"
                        Port       = 10001
                        API        = "cpuminer"
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