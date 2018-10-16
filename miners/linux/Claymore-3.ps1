$Path = "$($nvidia.claymore.path3)"
$Uri = "$($nvidia.claymore.uri)"
$MinerName = "$($nvidia.claymore.minername)"

$Build = "Tar"

if($NVIDIADevices3 -ne ''){
  $ClayDevices3  = $NVIDIADevices3 -split ","
  $ClayDevices3  = Switch($ClayDevices3){"10"{"a"};"11"{"b"};"12"{"c"};"13"{"d"};"14"{"e"};"15"{"f"};"16"{"g"};"17"{"h"};"18"{"i"};"19"{"j"};"20"{"k"};default{"$_"};}
  $ClayDevices3  = $ClayDevices3 | foreach {$_ -replace ("$($_)",",$($_)")}
  $ClayDevices3  = $ClayDevices3 -join ""
  $ClayDevices3  = $ClayDevices3.TrimStart(" ",",")  
  $ClayDevices3 = $ClayDevices3 -replace(",","")
  $Devices = $ClayDevices3}

$Commands = [PSCustomObject]@{
"ethash" = '-esm 2'
"daggerhashimoto" = '-esm 3 -estale 0'
"dagger" = ''
}
   
$Difficulty = [PSCustomObject]@{
"ethash" = ''
"daggerhashimoto" = ''
"dagger" = ''
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

if($CoinAlgo -eq $null)
 {
  $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
  if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
   {
    if($Difficulty.$_){$Diff=",d=$($Difficulty.$_)"}
    [PSCustomObject]@{
    Platform = $Platform  
    Symbol = "$($_)"
    MinerName = $MinerName
    Type = "NVIDIA3"
    Path = $Path
    Devices = $Devices
    DeviceCall = "claymore"
    Arguments = "-platform 2 -mport 3335 -mode 1 -allcoins 1 -allpools 1 -epool $($AlgoPools.$_.Protocol)://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -ewal $($AlgoPools.$_.User3) -epsw $($AlgoPools.$_.Pass3)$($Diff) -wd 0 -dbg -1 -eres 1 $($Commands.$_)"
    HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
    PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).AMD1_Watts){$Watts.$($_).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
    FullName = "$($AlgoPools.$_.Mining)"
    API = "claymore"
    Port = 3335
    MinerPool = "$($AlgoPools.$_.Name)"
    Wrap = $false
    URI = $Uri
    BUILD = $Build
    Algo = "$($_)"
    NewAlgo = ''
    }
   }
  }
}
else {
$CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
 Where {$($Commands.$($CoinPools.$_.Algorithm)) -NE $null} |
 foreach {
  if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
  [PSCustomObject]@{
 Platform = $Platform
 Coin = "Yes"
 Symbol = "$($CoinPools.$_.Symbol)"
 MinerName = $MinerName
 Type = "NVIDIA3"
 Path = $Path
 Devices = $Devices
 DeviceCall = "claymore"
 Arguments = "-platform 2 -mport 3335 -mode 1 -allcoins 1 -allpools 1 -epool $($CoinPools.$_.Protocol)://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -ewal $($CoinPools.$_.User3) -epsw $($CoinPools.$_.Pass3)$($Diff) -wd 0 -dbg -1 -eres 1 $($Commands.$($CoinPools.$_.Algorithm))"
 HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
 PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA3_Watts){$Watts.$($_).NVIDIA3_Watts}elseif($Watts.default.NVIDIA3_Watts){$Watts.default.NVIDIA3_Watts}else{0}}
 FullName = "$($CoinPools.$_.Mining)"
 MinerPool = "$($CoinPools.$_.Name)"
 API = "claymore"
 Port = 3335
 Wrap = $false
 URI = $Uri
 BUILD = $Build
 Algo = "$($CoinPools.$_.Algorithm)"
     }
    }
  }