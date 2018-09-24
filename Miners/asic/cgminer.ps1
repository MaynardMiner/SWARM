$Path = "./Miners/Asic/cgminer.ps1"
$Uri = "None Needed"
$MinerName = "cgminer"

$Build = "Zip"

$Commands = [PSCustomObject]@{

"Equihash" = [PSCustomObject]@{
"bitmain-use-vil" = "true"
"bitmain-freq" = "575"
"bitmain-fan-ctrl" = "true"
"bitmain-fan-pwm" = "56"
"api-listen" = "true"
"api-network" = "true"
"api-groups" = ""
"api-allow" = "A:127.0.0.1,W:127.0.0.1"
}

}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

if($CoinAlgo -eq $null)
{
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
 if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
  {
    [PSCustomObject]@{
    Platform = $Platform
    Symbol = "$($_)"
    MinerName = $MinerName
    Type = "ASIC"
    Path = $Path
    Devices = $null
    DeviceCall = "cgminer"
    Arguments = $Commands.$_
    HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
    Selected = [PSCustomObject]@{$_ = ""}
    MinerPool = "$($AlgoPools.$_.Name)"
    FullName = "$($AlgoPools.$_.Mining)"
    Port = 4028
    API = "cgminer"
    Wrap = $false
    URI = $Uri
    BUILD = $Build
    Algo = "$($_)"
    NewAlgo = ''
     }
    }
   }
  }

  else{
    $CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
    Where {$($Commands.$($CoinPools.$_.Algorithm)) -NE $null} |
    foreach {
     [PSCustomObject]@{
     Platform = $Platform
     Symbol = "$($CoinPools.$_.Symbol)"
     MinerName = $MinerName
     Type = "AMD1"
     Path = $Path
     Devices = $Devices
     DeviceCall = "sgminer-gm"
     Arguments = "--api-listen --api-port 4028 -k $(Get-AMD($CoinPools.$_.Algorithm)) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1) -T $($CoinPools.$Commands.$($CoinPools.$_.Algorithm))"
     HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
     API = "sgminer-gm"
     Selected = [PSCustomObject]@{$CoinPools.$_.Algorithm = ""}
     FullName = "$($CoinPools.$_.Mining)"
    MinerPool = "$($CoinPools.$_.Name)"
     Port = 4028
     Wrap = $false
     URI = $Uri
     BUILD = $Build
     Algo = "$($CoinPools.$_.Algorithm)"
     }
    }
   }
  

