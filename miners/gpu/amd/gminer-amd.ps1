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
    $Log = Join-Path $dir "logs\$ConfigType.log"

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
    $GetConfig = "$dir\config\miners\$CName.json"
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
                        ArgDevices = $ArgDevices
                        DeviceCall = "gminer"
                        Arguments  = "--api $Port --server $($_.Host) --port $($_.Port) --user $($_.$User) --logfile `'$Log`' --pass $($_.$Pass)$Diff $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
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