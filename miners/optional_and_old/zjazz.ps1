$NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($nvidia.zjazz.$ConfigType) { $Path = "$($nvidia.zjazz.$ConfigType)" }
    else { $Path = "None" }
    if ($nvidia.zjazz.uri) { $Uri = "$($nvidia.zjazz.uri)" }
    else { $Uri = "None" }
    if ($nvidia.zjazz.minername) { $MinerName = "$($nvidia.zjazz.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "zjazz-$Num"; $Port = "6100$Num";

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
    $GetConfig = "$dir\config\miners\zjazz.json"
    try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
    catch { Write-Log "Warning: No config found at $GetConfig" }

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $dir "build\export"

    ##Prestart actions before miner launch
    $BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
    $Prestart = @()
    if (Test-Path $BE) { $Prestart += "export LD_PRELOAD=libcurl-compat.so.3.0.0" }
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $Config.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $Algorithm -and $Name -notin $global:Exclusions.$MinerAlgo.exclusions -and $ConfigType -notin $global:Exclusions.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
            $Check = $Global:Miner_HashTable | Where Miner -eq $Name | Where Algo -eq $MinerAlgo | Where Type -Eq $ConfigType
            
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                if ($Check.RAW -ne "Bad") {
                    if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                    [PSCustomObject]@{
                        MName      = $Name
                        Coin       = $Coins
                        Delay      = $Config.$ConfigType.delay
                        Fees       = $Config.$ConfigType.fee.$($_.Algorithm)
                        Symbol     = "$($_.Symbol)"
                        MinerName  = $MinerName
                        Prestart   = $PreStart
                        Type       = $ConfigType
                        Path       = $Path
                        Devices    = $Devices
                        DeviceCall = "zjazz"
                        Arguments  = "-a $($Config.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Host):$($_.Port) -b 0.0.0.0:$Port --hashrate-per-gpu -u $($_.$User) -p $($_.$Pass)$($Diff) $($Config.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                        Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        ocpower    = if ($Config.$ConfigType.oc.$($_.Algorithm).power) { $Config.$ConfigType.oc.$($_.Algorithm).power }else { $OC."default_$($ConfigType)".Power }
                        occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) { $Config.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                        ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) { $Config.$ConfigType.oc.$($_.Algorithm).memory }else { $OC."default_$($ConfigType)".memory }
                        ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) { $Config.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                        MinerPool  = "$($_.Name)"
                        FullName   = "$($_.Mining)"
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
