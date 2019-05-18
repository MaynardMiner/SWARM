$NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($nvidia.bminer.$ConfigType) { $Path = "$($nvidia.bminer.$ConfigType)" } else { $Path = "None" }
    if ($nvidia.bminer.uri) { $Uri = "$($nvidia.bminer.uri)" } else { $Uri = "None" }
    if ($nvidia.bminer.MinerName) { $MinerName = "$($nvidia.bminer.MinerName)" } else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "bminer-$Num"; $Port = "4000$Num"

    Switch ($Num) {
        1 { $Get_Devices = $NVIDIADevices1 }
        2 { $Get_Devices = $NVIDIADevices2 }
        3 { $Get_Devices = $NVIDIADevices3 }
    }

    ##Log Directory
    $Log = Join-Path $($global:Dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.bminer

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($global:Dir) "build\export"

    ##Prestart actions before miner launch
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
            $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        
            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    $Sel = $_.Algorithm
                    $SelName = $_.Name
                    Switch ($SelName) {
                        "nicehash" {
                            switch ($Sel) {
                                "ethash" { $Pass = ""; $Naming = "ethstratum"; $AddArgs = "" }
                                "cuckaroo29" { $Pass = ""; $Naming = "cuckaroo29"; $AddArgs = "-pers auto " }
                                "cuckatoo31" { $Pass = ""; $Naming = "cuckatoo31"; $AddArgs = "-pers auto " }
                                "equihash_150/5" { $Pass = ""; $Naming = "beam"; $AddArgs = "" }
                                "equihash_144/5" { $Pass = ""; $Naming = "zhash"; $AddArgs = "" }
                            }
                        }
                        "whalesburg" {
                            switch ($Sel) {
                                "ethash" { $Pass = ""; $Naming = "ethproxy+ssl"; $AddArgs = "" }
                            }
                        }
                        default {
                            switch ($Sel) {
                                "equihash_144/5" { $Pass = ".$($($_.$Pass) -replace ",","%2C")"; $Naming = "equihash1445"; $AddArgs = "-pers auto " }
                            }
                        }
                    }
                    if ($_.Worker) { $Pass = ".$($_.Worker)" }
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = "%2Cd=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
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
                        DeviceCall = "bminer"
                        Arguments  = "-uri $($Naming)://$($_.$User)$Pass$Diff@$($_.Host):$($_.Port) $AddArgs-logfile `'$Log`' -api 127.0.0.1:$Port"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Hour }
                        Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        MinerPool  = "$($_.Name)"
                        FullName   = "$($_.Mining)"
                        Port       = $Port
                        API        = "bminer"
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