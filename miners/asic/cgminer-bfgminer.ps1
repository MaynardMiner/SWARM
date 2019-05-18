$ASICTypes | ForEach-Object {

    $ConfigType = $_; $Num = $ConfigType -replace "ASIC", ""

    ## Miner Path Information
    $URI = "Not Needed"
    $MinerName = "cgminer"
    $Path = "no path"

    $User = "User1"; $Name = "asicminer-$Num"

    $Devices = $null

    if ($Coins -eq $true) { $Pools = $CoinPools } else { $Pools = $AlgoPools }

    $global:Config.Params.ASIC_ALGO | ForEach-Object {

        $MinerAlgo = $_
        $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"

        if ($MinerAlgo -in $Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $global:banhammer) {
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                $Pass = $_.Pass1 -replace ",", "`\,"
                if($global:ASICS.$ConfigType.NickName) {
                $Pass = $Pass -replace "$($global:Config.Params.Rigname1)","$($global:ASICS.$ConfigType.NickName)"
                }
                [PSCustomObject]@{
                    MName      = $Name
                    Coin       = $Coins
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
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Hour}
                    Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                    MinerPool  = "$($_.Name)"
                    FullName   = "$($_.Mining)"
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