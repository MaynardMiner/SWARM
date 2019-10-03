$(vars).AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""

    ##Miner Path Information
    if ($(vars).amd.lolminer.$ConfigType) { $Path = "$($(vars).amd.lolminer.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).amd.lolminer.uri) { $Uri = "$($(vars).amd.lolminer.uri)" }
    else { $Uri = "None" }
    if ($(vars).amd.lolminer.minername) { $MinerName = "$($(vars).amd.lolminer.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "lolminer-$Num"; $Port = "2400$Num"

    Switch ($Num) {
        1 { $Get_Devices = $(vars).AMDDevices1; $Rig = $(arg).Rigname1 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.lolminer

    ##Export would be /path/to/[SWARMVERSION]/build/export && Bleeding Edge Check##
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
                    $SelAlgo = $_.Algorithm
                    switch ($SelAlgo) {
                        "equihash_144/5" { $AddArgs = "--coin AUTO144_5 " }
                        "equihash_96/5" { $AddArgs = "--coin MNX " }
                        "equihash_125/4" { $AddArgs = "--coin ZEL --tls 0 " }
                        "beamv2" { $AddArgs = "--coin BEAM-II --tls 0 " }
                        "equihash_192/7" { $AddArgs = "--coin AUTO192_7 " }
                        "cuckaroo29" { $AddArgs = "--coin GRIN-AD29 " }
                        "cuckarood29" { $AddArgs = "--coin GRIN-AD29 " }
                        "cuckatoo31" { $AddArgs = "--coin GRIN-AT31 " }
                    }
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
                        Version    = "$($(vars).amd.lolminer.version)"
                        DeviceCall = "lolminer"
                        Arguments  = "--pool $($_.Pool_Host) --port $($_.Port) --user $($_.$User) $AddArgs--pass $($_.$Pass)$($Diff) --apiport $Port --logs 0 $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = $Stat.Hour
                        Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                        Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                        MinerPool  = "$($_.Name)"
                        Port       = $Port
                        Worker     = $Rig
                        API        = "lolminer"
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