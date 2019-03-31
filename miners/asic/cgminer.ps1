$MinerName = "cgminer"
$Path = ".\config\asic\asic-list.json"


$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

if($CoinAlgo -eq $null)
{
  $Algorithm | ForEach-Object {
  $MinerAlgo = $_
  $Pools | Where Algorithm -eq $MinerAlgo | foreach {
  if($MinerAlgo -eq "$($_.Algorithm)")
  {
    $NewPass = $($_.Pass1) -split "," | Select -First 1
    [PSCustomObject]@{
    Symbol = "$($_.Algorithm)"
    MinerName = $MinerName
    Type = "ASIC"
    DeviceCall = "cgminer"
    Path = $Path
    PowerX = $null
    Arguments = "stratum+tcp://$($_.Host):$($_.Port),$($_.User1),$NewPass"
    HashRates = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
    Quote = if($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)){$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)*($_.Price)}else{0}
    MinerPool = "$($_.Name)"
    FullName = "$($_.Mining)"
    Port = $Config.Port
    API = "cgminer"
    Algo = "$($_.Algorithm)"
     }
    }
   }
  }
 }
