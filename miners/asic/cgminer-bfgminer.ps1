$URI = "Not Needed"
$MinerName = "cgminer"
$Path = "no path"

$ConfigType = "ASIC"
$User = "User1"

$Devices = $null

if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$ASIC_ALGO | ForEach-Object {
    $MinerAlgo = $_
    $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
        if ($ASIC_ALGO -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
            $Pass = $_.Pass1 -replace ",","`\,"
            [PSCustomObject]@{
                Delay      = $Config.$ConfigType.delay
                Platform   = $Platform
                Symbol     = "$($_.Symbol)"
                MinerName  = $MinerName
                Type       = $ConfigType 
                Path       = $Path
                Devices    = $Devices
                DeviceCall = "cgminer"
                Wallet     = "$($_.$User)"
                Arguments  = "stratum+tcp://$($_.Host):$($_.Port),$($_.$User),$Pass"
                HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) }
                Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) { $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price) }else { 0 }
                PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                MinerPool  = "$($_.Name)"
                FullName   = "$($_.Mining)"
                Port       = 4028
                API        = "cgminer"
                Wrap       = $false
                URI        = $Uri
                Server     = $ASIC_IP
                BUILD      = $Build
                Algo       = "$($_.Algorithm)"
                Log        = "miner_generated"
            }
        }
    }
}