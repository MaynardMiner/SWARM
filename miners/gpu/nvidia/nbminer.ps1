$Global:NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($Global:nvidia.nbminer.$ConfigType) { $Path = "$($Global:nvidia.nbminer.$ConfigType)" }
    else { $Path = "None" }
    if ($Global:nvidia.nbminer.uri) { $Uri = "$($Global:nvidia.nbminer.uri)" }
    else { $Uri = "None" }
    if ($Global:nvidia.nbminer.minername) { $MinerName = "$($Global:nvidia.nbminer.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "nbminer-$Num"; $Port = "6200$Num";

    Switch ($Num) {
        1 { $Get_Devices = $Global:NVIDIADevices1 }
        2 { $Get_Devices = $Global:NVIDIADevices2 }
        3 { $Get_Devices = $Global:NVIDIADevices3 }
    }

    ##Log Directory
    $Log = Join-Path $($(v).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.nbminer

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($(v).dir) "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Global:Coins -eq $true) { $Pools = $global:CoinPools }else { $Pools = $global:AlgoPools }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $global:Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $StatAlgo = $MinerAlgo -replace "`_","`-"
            $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate" 
           $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
            $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    $SelName = $_.Name
                    switch ($MinerAlgo) {
                        "ethash" {
                            Switch($SelName) {
                                "nicehash" {$Stratum = "ethnh+tcp://"; $A = "ethash"}
                                "whalesburg" {$Stratum = "stratum+ssl://"; $A = "ethash"}
                            }
                        }
                        "cuckaroo29" { $Stratum = "stratum+tcp://"; $A = "cuckaroo" }
                        "cuckatoo31" { $Stratum = "stratum+tcp://"; $A = "cuckatoo" }
                        default { $Stratum = "stratum+tcp://" }
                    }        
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                    [PSCustomObject]@{
                        MName      = $Name
                        Coin       = $Global:Coins
                        Delay      = $MinerConfig.$ConfigType.delay
                        Fees       = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                        Symbol     = "$($_.Symbol)"
                        MinerName  = $MinerName
                        Prestart   = $PreStart
                        Type       = $ConfigType
                        Path       = $Path
                        Devices    = $Devices
                        Version    = "$($Global:nvidia.nbminer.version)"
                        DeviceCall = "ccminer"
                        Arguments  = "-a $A --api 0.0.0.0:$Port --url $Stratum$($_.Host):$($_.Port) --user $($_.$User) $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = $Stat.Hour
                        Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                        Power     =  if ($global:Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $global:Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($global:Watts.default."$($ConfigType)_Watts") { $global:Watts.default."$($ConfigType)_Watts" }else { 0 } 
                        MinerPool  = "$($_.Name)"
                        API        = "nebutech"
                        Port       = $Port
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