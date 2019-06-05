$Global:NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($Global:nvidia.klaust.$ConfigType) { $Path = "$($Global:nvidia.klaust.$ConfigType)" }
    else { $Path = "None" }
    if ($Global:nvidia.klaust.uri) { $Uri = "$($Global:nvidia.klaust.uri)" }
    else { $Uri = "None" }
    if ($Global:nvidia.klaust.minername) { $MinerName = "$($Global:nvidia.klaust.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "klaust-$Num"; $Port = "5900$Num";

    Switch ($Num) {
        1 { $Get_Devices = $Global:NVIDIADevices1 }
        2 { $Get_Devices = $Global:NVIDIADevices2 }
        3 { $Get_Devices = $Global:NVIDIADevices3 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.klaust

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($(vars).dir) "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    if (Test-Path $BE) { $Prestart += "export LD_PRELOAD=libcurl-compat.so.3.0.0" }
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $global:Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $StatAlgo = $MinerAlgo -replace "`_","`-"
            $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate" 
           $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        
            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    if ($global:Algorithm -eq "$($_.Algorithm)") {
                        if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
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
                        Stratum    = "$($_.Protocol)://$($_.Host):$($_.Port)" 
                            Version    = "$($Global:nvidia.klaust.version)"
                            DeviceCall = "ccminer"
                            Arguments  = "-a $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Host):$($_.Port) -b 0.0.0.0:$Port -u $($_.$User) -p $($_.$Pass)$($Diff) $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                            HashRates  = $Stat.Hour
                            Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                            Power     =  if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                            MinerPool  = "$($_.Name)"
    
                            Port       = $Port
                            API        = "Ccminer"
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
}