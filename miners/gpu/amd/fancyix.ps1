$AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""

    ##Miner Path Information
    if ($amd.fancyix.$ConfigType) { $Path = "$($amd.fancyix.$ConfigType)" }
    else { $Path = "None" }
    if ($amd.fancyix.uri) { $Uri = "$($amd.fancyix.uri)" }
    else { $Uri = "None" }
    if ($amd.fancyix.minername) { $MinerName = "$($amd.fancyix.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "fancyix-$Num"; $Port = "2200$Num"

    Switch ($Num) {
        1 { $Get_Devices = $AMDDevices1 }
    }

    ##Log Directory
    $Log = Join-Path $dir "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $GetConfig = "$dir\config\miners\fancyix.json"
    try { $MinerConfig = Get-Content $GetConfig | ConvertFrom-Json }
    catch { Write-Log "Warning: No config found at $GetConfig" }

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $dir "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    if (Test-Path $BE) { $Prestart += "export LD_PRELOAD=libcurl-compat.so.3.0.0" }
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $Algorithm -and $Name -notin $global:Exclusions.$MinerAlgo.exclusions -and $ConfigType -notin $global:Exclusions.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
            $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
        
            if ($Check.RAW -ne "Bad") {
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
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
                        DeviceCall = "sgminer-gm"
                        Arguments  = "--gpu-platform $AMDPlatform --api-listen --api-port $Port -k $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Host):$($_.Port) -u $($_.$User) -p $($_.$Pass)$($Diff) -T $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                        Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        ocdpm      = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).dpm) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).dpm }else { $OC."default_$($ConfigType)".dpm }
                        ocv        = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).v) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).v }else { $OC."default_$($ConfigType)".v }
                        occore     = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).core) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                        ocmem      = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).mem) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).mem }else { $OC."default_$($ConfigType)".memory }
                        ocmdpm     = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).mdpm) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).mdpm }else { $OC."default_$($ConfigType)".mdpm }
                        ocfans     = if ($MinerConfig.$ConfigType.oc.$($_.Algorithm).fans) { $MinerConfig.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                        MinerPool  = "$($_.Name)"
                        FullName   = "$($_.Mining)"
                        Port       = $Port
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