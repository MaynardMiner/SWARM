$Global:AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""
    $CName = "energi-amd"

    ##Miner Path Information
    if ($Global:amd.$CName.$ConfigType) { $Path = "$($Global:amd.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($Global:amd.$CName.uri) { $Uri = "$($Global:amd.$CName.uri)" }
    else { $Uri = "None" }
    if ($Global:amd.$CName.minername) { $MinerName = "$($Global:amd.$CName.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "$CName-$Num"; $Port = "2100$Num"

    Switch ($Num) {
        1 { $Get_Devices = $Global:AMDDevices1 }
    }
    
    ##Log Directory
    $Log = Join-Path $($(v).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") {
        $GPUDevices1 = $Get_Devices
        $GPUDevices1 = $GPUDevices1 -replace ',', ' '
        $Devices = $GPUDevices1
    }
    else { $Devices = $Get_Devices }
  
    ##Get Configuration File
    $MinerConfig = $Global:config.miners.$CName

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
        
            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                        if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                        [PSCustomObject]@{
                            MName      = $Name
                            Coin       = $Global:Coins
                            Delay      = $MinerConfig.$ConfigType.delay
                            Fees       = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                            Platform   = $global:Config.Params.Platform
                            Symbol     = "$($_.Symbol)"
                            MinerName  = $MinerName
                            Prestart   = $PreStart
                            Type       = $ConfigType
                            Path       = $Path
                            Devices    = $Devices
                            Version    = "$($Global:amd.$CName.version)"
                            DeviceCall = "energiminer"
                            Arguments  = "--opencl-platform $Global:AMDPlatform -G stratum://$($_.$User).$($_.$Pass)@$($_.Algorithm).mine.zergpool.com:$($_.Port)"
                            HashRates  = $Stat.Hour
                            Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                            Power     = if ($global:Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $global:Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($global:Watts.default."$($ConfigType)_Watts") { $global:Watts.default."$($ConfigType)_Watts" }else { 0 }
                            MinerPool  = "$($_.Name)"
                            Port       = 0
                            API        = "energiminer"
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