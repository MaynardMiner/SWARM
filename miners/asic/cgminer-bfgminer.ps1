$Global:ASICTypes | ForEach-Object {

    $ConfigType = $_; $Num = $ConfigType -replace "ASIC", ""

    ## Miner Path Information
    $URI = "Not Needed"
    $MinerName = "cgminer"
    $Path = "no path"

    $User = "User1"; $Name = "asicminer-$Num"

    $Devices = $null

    if ($Global:Coins -eq $true) { $Pools = $global:CoinPools } else { $Pools = $global:AlgoPools }

    $global:Config.Params.ASIC_ALGO | ForEach-Object {

        $MinerAlgo = $_
        $StatAlgo = $MinerAlgo -replace "`_","`-"
        $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"

        if ($MinerAlgo -in $global:Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                $Pass = $_.Pass1 -replace ",", "`\,"
                if($global:ASICS.$ConfigType.NickName) {
                $Pass = $Pass -replace "$($global:Config.Params.Rigname1)","$($global:ASICS.$ConfigType.NickName)"
                }
                [PSCustomObject]@{
                    MName      = $Name
                    Coin       = $Global:Coins
                    Delay      = $MinerConfig.$ConfigType.delay
                    Fees       = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                    Platform   = $global:Config.Params.Platform
                    Symbol     = "$($_.Symbol)"
                    MinerName  = $MinerName
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    DeviceCall = "cgminer"
                    Wallet     = "$($_.$User)"
                    Arguments  = "stratum+tcp://$($_.Host):$($_.Port),$($_.$User),$Pass"
                    HashRates  = $Stat.Hour
                    Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                    Power     = [PSCustomObject]@{$($_.Algorithm) = if ($global:Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $global:Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($global:Watts.default."$($ConfigType)_Watts") { $global:Watts.default."$($ConfigType)_Watts" }else { 0 } }
                    MinerPool  = "$($_.Name)"
                    Port       = 4028
                    API        = "cgminer"
                    URI        = $Uri
                    Server     = $global:ASICS.$ConfigType.IP
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                    Log        = "miner_generated"
                }
            }
        }
    }
}
