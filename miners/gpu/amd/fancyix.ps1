$(vars).AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""

    ##Miner Path Information
    if ($(vars).amd.fancyix.$ConfigType) { $Path = "$($(vars).amd.fancyix.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).amd.fancyix.uri) { $Uri = "$($(vars).amd.fancyix.uri)" }
    else { $Uri = "None" }
    if ($(vars).amd.fancyix.minername) { $MinerName = "$($(vars).amd.fancyix.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "fancyix-$Num"; $Port = "2200$Num"

    Switch ($Num) {
        1 { $Get_Devices = $(vars).AMDDevices1; $Rig = $(arg).Rigname1 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.fancyix

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
            $Check = $(vars).Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        
            if ($Check.RAW -ne "Bad") {
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
                        Version    = "$($(vars).amd.fancyix.version)"
                        DeviceCall = "sgminer-gm"
                        Arguments  = "--gpu-platform $($(vars).AMDPlatform) --api-listen --api-port $Port -k $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Pool_Host):$($_.Port) -u $($_.$User) -p $($_.$Pass)$($Diff) -T $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = $Stat.Hour
                        Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                        Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                        MinerPool  = "$($_.Name)"
                        Port       = $Port
                        Worker     = $Rig
                        API        = "sgminer-gm"
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