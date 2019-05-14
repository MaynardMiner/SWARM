$AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""
    $CName = "claymore-amd"

    ##Miner Path Information
    if ($amd.$CName.$ConfigType) { $Path = "$($amd.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($amd.$CName.uri) { $Uri = "$($amd.$CName.uri)" }
    else { $Uri = "None" }
    if ($amd.$CName.minername) { $MinerName = "$($amd.$CName.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "$CName-$Num"; $Port = "2000$Num"

    Switch ($Num) {
        1 { $Get_Devices = $AMDDevices1 }
    }

    ##Log Directory
    $Log = Join-Path $($global:Dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") {
        $ClayDevices1 = $Get_Devices -split ","
        $ClayDevices1 = Switch ($ClayDevices1) { "10" { "a" }; "11" { "b" }; "12" { "c" }; "13" { "d" }; "14" { "e" }; "15" { "f" }; "16" { "g" }; "17" { "h" }; "18" { "i" }; "19" { "j" }; "20" { "k" }; default { "$_" }; }
        $ClayDevices1 = $ClayDevices1 | ForEach-Object { $_ -replace ("$($_)", ",$($_)") }
        $ClayDevices1 = $ClayDevices1 -join ""
        $ClayDevices1 = $ClayDevices1.TrimStart(" ", ",")  
        $ClayDevices1 = $ClayDevices1 -replace (",", "")
        $Devices = $ClayDevices1
    }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.$CName

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($global:Dir) "build\export"

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
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                    if ($_.Worker) { $MinerWorker = "-eworker $($_.Worker) " }
                    else { $MinerWorker = "-epsw $($_.$Pass)$($Diff) " }
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
                        DeviceCall = "claymore"
                        Arguments  = "-platform 1 -mport $Port -mode 1 -allcoins 1 -allpools 1 -epool $($_.Protocol)://$($_.Host):$($_.Port) -logfile `'$Log`' -ewal $($_.$User) $MinerWorker-wd 0 -gser 2 -dbg -1 -eres 1 $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Hour}
                        Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                        PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                        FullName   = "$($_.Mining)"
                        API        = "claymore"
                        Port       = $Port
                        MinerPool  = "$($_.Name)"
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
