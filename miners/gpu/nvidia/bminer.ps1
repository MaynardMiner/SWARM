$(vars).NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($(vars).nvidia.bminer.$ConfigType) { $Path = "$($(vars).nvidia.bminer.$ConfigType)" } else { $Path = "None" }
    if ($(vars).nvidia.bminer.uri) { $Uri = "$($(vars).nvidia.bminer.uri)" } else { $Uri = "None" }
    if ($(vars).nvidia.bminer.MinerName) { $MinerName = "$($(vars).nvidia.bminer.MinerName)" } else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "bminer-$Num"; $Port = "4000$Num"

    Switch ($Num) {
        1 { $Get_Devices = $(vars).NVIDIADevices1; $Rig = $(arg).RigName1 }
        2 { $Get_Devices = $(vars).NVIDIADevices2; $Rig = $(arg).RigName2 }
        3 { $Get_Devices = $(vars).NVIDIADevices3; $Rig = $(arg).RigName3 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.bminer

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($(vars).dir) "build\export"

    ##Prestart actions before miner launch
    $Prestart = @()
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
            $Check = $(vars).Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        
            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    $Sel = $_.Algorithm
                    $SelName = $_.Name
                    Switch ($SelName) {
                        "nicehash" {
                            switch ($Sel) {
                                "ethash" { $Pass = ""; $Naming = "ethstratum"; $AddArgs = "" }
                                "cuckaroo29" { $Pass = ""; $Naming = "cuckaroo29"; $AddArgs = "-pers auto " }
                                "cuckaroo29d" { $Pass = ""; $Naming = "cuckaroo29d"; $AddArgs = "-pers auto " }
                                "cuckatoo31" { $Pass = ""; $Naming = "cuckatoo31"; $AddArgs = "-pers auto " }
                                "equihash_150/5" { $Pass = ""; $Naming = "beam"; $AddArgs = "" }
                                "equihash_144/5" { $Pass = ""; $Naming = "zhash"; $AddArgs = "" }
                                "beamv2" { $Pass = ""; $Naming = "beamhash2"; $AddArgs = "" }
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
                        Version    = "$($(vars).nvidia.bminer.version)"
                        DeviceCall = "bminer"
                        Arguments  = "-uri $($Naming)://$($_.$User)$Pass$Diff@$($_.Pool_Host):$($_.Port) $AddArgs-logfile `'$Log`' -api 127.0.0.1:$Port $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = $Stat.Hour
                        Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                        Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                        MinerPool  = "$($_.Name)"
                        Port       = $Port
                        Worker     = $Rig
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