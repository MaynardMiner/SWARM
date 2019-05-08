$NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($nvidia.nbminer.$ConfigType) { $Path = "$($nvidia.nbminer.$ConfigType)" }
    else { $Path = "None" }
    if ($nvidia.nbminer.uri) { $Uri = "$($nvidia.nbminer.uri)" }
    else { $Uri = "None" }
    if ($nvidia.nbminer.minername) { $MinerName = "$($nvidia.nbminer.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "nbminer-$Num"; $Port = "6200$Num";

    Switch ($Num) {
        1 { $Get_Devices = $NVIDIADevices1 }
        2 { $Get_Devices = $NVIDIADevices2 }
        3 { $Get_Devices = $NVIDIADevices3 }
    }

    ##Log Directory
    $Log = Join-Path $dir "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $GetConfig = "$dir\config\miners\nbminer.json"
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

            switch ($MinerAlgo) {
                "daggerhashimoto" { $Stratum = "ethnh+tcp://"; $A = "ethash" }
                "grincuckaroo29" { $Stratum = "stratum+tcp://"; $A = "cuckaroo" }
                "grincuckatoo31" { $Stratum = "stratum+tcp://"; $A = "cuckatoo" }
                "ethash" { $Stratum = "stratum+ssl://"; $A = "ethash" }
                default { $Stratum = "stratum+tcp://" }
            }
            $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
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
                        DeviceCall = "ccminer"
                        Arguments  = "-a $A --api 0.0.0.0:$Port --url $Stratum$($_.Host):$($_.Port) --user $($_.$User) $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                        Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        ocpower    = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).power) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).power }else { $OC."default_$($ConfigType)".Power }
                        occore     = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).core) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                        ocmem      = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).memory) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).memory }else { $OC."default_$($ConfigType)".memory }
                        ocfans     = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).fans) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                        ethpill    = $MinerConfig.$ConfigType.oc.$($_.Algorithm).ethpill
                        pilldelay  = $MinerConfig.$ConfigType.oc.$($_.Algorithm).pilldelay
                        MinerPool  = "$($_.Name)"
                        FullName   = "$($_.Mining)"
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