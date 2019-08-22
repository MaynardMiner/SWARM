$(vars).NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    $CName = "tt-miner"

    ##Miner Path Information
    if ($(vars).nvidia.$CName.$ConfigType) { $Path = "$($(vars).nvidia.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).nvidia.$CName.uri) { $Uri = "$($(vars).nvidia.$CName.uri)" }
    else { $Uri = "None" }
    if ($(vars).nvidia.$CName.minername) { $MinerName = "$($(vars).nvidia.$CName.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "$CName-$Num"; $Port = "5100$Num";

    Switch ($Num) {
        1 { $Get_Devices = $(vars).NVIDIADevices1; $Rig = $(arg).RigName1 }
        2 { $Get_Devices = $(vars).NVIDIADevices2; $Rig = $(arg).RigName2 }
        3 { $Get_Devices = $(vars).NVIDIADevices3; $Rig = $(arg).RigName3 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $MinerConfig = $Global:config.miners.$CName

    ##Export would be /path/to/[SWARMVERSION]/build/export##
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
                    $continue = $false
                    if ($_.Worker) { $Worker = "-worker $($_.Worker) " }else { $Worker = $Null }
                    if ($IsWindows) { $continue = $true }
                    ## only three algos for now
                    elseif ($IsLinux -and "tt-miner" -in $(args).optional) {
                        switch ($MinerAlgo) {
                            "mtp" { $continue = $true }
                            "ethash" { $continue = $true }
                            "progpow" { $continue = $true }
                        }
                    }
                    if ($continue -eq $true) {
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
                            Version    = "$($(vars).nvidia.$CName.version)"
                            DeviceCall = "ttminer"
                            Arguments  = "-a $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) --nvidia -o $($_.Protocol)://$($_.Pool_Host):$($_.Port) $Worker-b localhost:$Port -u $($_.$User) -p $($_.$Pass) $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                            HashRates  = $Stat.Hour
                            Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                            Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                            MinerPool  = "$($_.Name)"
                            Port       = $Port
                            Worker     = $Rig
                            API        = "claymore"
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