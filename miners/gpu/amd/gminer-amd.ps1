$AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""
    $CName = "gminer-amd"

    ##Miner Path Information
    if ($AMD.$CName.$ConfigType) { $Path = "$($AMD.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($AMD.$CName.uri) { $Uri = "$($AMD.$CName.uri)" }
    else { $Uri = "None" }
    if ($AMD.$CName.minername) { $MinerName = "$($AMD.$CName.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "$CName-$Num"; $Port = "3300$Num"

    Switch ($Num) {
        1 { $Get_Devices = $AMDDevices1 }
    }
    
    ##Log Directory
    $Log = Join-Path $($global:Dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") {
        $GPUDevices1 = $Get_Devices
        $GPUDevices1 = $GPUDevices1 -replace ',', ' '
        $Devices = $GPUDevices1
    }
    else { $Devices = $Get_Devices }

    ##gminer apparently doesn't know how to tell the difference between
    ##cuda and amd devices, like every other miner that exists. So now I 
    ##have to spend an hour and parse devices
    ##to matching platforms.
    $ArgDevices = $Null
    if ($Get_Devices -ne "none") {
        $GPUDevices1 = $Get_Devices
        $GPUEDevices1 = $GPUDevices1 -split ","
        $GPUEDevices1 | ForEach-Object { $ArgDevices += "$($GCount.AMD.$_) " }
        $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1)
    }
    else { $GCount.AMD.PSObject.Properties.Name | ForEach-Object { $ArgDevices += "$($GCount.AMD.$_) " }; $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1) }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.$CName

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($global:Dir) "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $StatAlgo = $MinerAlgo -replace "`_","`-"
            $Stat = Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate" 
           $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        
            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    $SelAlgo = $_.Algorithm
                    switch($SelAlgo) {
                        "equihash_150/5" {$AddArgs = "--algo 150_5 --pers auto "}
                        "cuckoo_cycle" {$AddArgs = "--algo aeternity "}
                        "cuckaroo29" {$AddArgs = "--algo grin29 "}
                        "cuckatoo31" {$AddArgs = "--algo grin31 "}
                        "equihash_96/5" {$AddArgs = "--algo 96_5 --pers auto "}
                        "equihash_192/7" {$AddArgs = "--algo 192_7 --pers auto "}
                        "equihash_144/5" {$AddArgs = "--algo 144_5 --pers auto "}
                        "equihash_210/9" {$AddArgs = "--algo 210_9 --pers auto "}
                        "equihash_200/9" {$AddArgs = "--algo 200_9 --pers auto "}            
                    }
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
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
                        Version    = "$($amd.$CName.version)"
                        ArgDevices = $ArgDevices
                        DeviceCall = "gminer"
                        Arguments  = "--api $Port --server $($_.Host) --port $($_.Port) $AddArgs--user $($_.$User) --logfile `'$Log`' --pass $($_.$Pass)$Diff $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Hour}
                        Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        MinerPool  = "$($_.Name)"
                        FullName   = "$($_.Mining)"
                        API        = "gminer"
                        Port       = $Port
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
}