$NewAlgoMiners = @()
$Type | Foreach {
$GetType = $_; 
$AlgoMiners.Symbol | Select -Unique | foreach {
$zero = $AlgoMiners | Where Type -eq $GetType | Where Hashrates -match $_ | Where Quote -EQ 0; 
if($zero)
{
 $zerochoice = $zero | Sort-Object Quote -Descending | Select -First 1; 
 if(-not ($NewAlgoMiners | Where Name -EQ $zerochoice.Name | Where Arguments -EQ $zerochoice.Arguments))
  {
   $NewAlgoMiners += $zerochoice
  }
}
else
{
 $nonzero = $AlgoMiners | Where Type -eq $GetType | Where Hashrates -match $_ | Where Quote -NE 0; 
 $nonzerochoice = $nonzero | Sort-Object Quote -Descending | Select -First 1; 
 if(-not ($NewAlgoMiners | Where Name -EQ $nonzerochoice.Name | Where Arguments -EQ $nonzerochoice.Arguments))
   {
    $NewAlgoMiners += $nonzerochoice
   }
  }
 }
}
$AlgoMiners = $NewAlgoMiners
if($AlgoMiners.Count -eq 0){"No Miners!" | Out-Host; start-sleep $Interval; continue}
$ProfitTable = $null
$ProfitTable = @()
$Miners | foreach {
$ProfitTable += [PSCustomObject]@{
 Power = [Decimal]$($_.Power*24)/1000*$WattEX
 Pool_Estimate = $_.Pool_Estimate
 Type = $_.Type
 Miner = $_.Name
 Name = $($_.Symbol)
 Arguments = $($_.Arguments)
 HashRates = $_.HashRates.$($_.Symbol)
 Profits = $_.Profit_Bias
 Algo = $_.Algo
 Fullname = $_.FullName
 MinerPool = $_.MinerPool
}
}

$BestMiners_Combo | ForEach {
    if(-not ($ActiveMinerPrograms | Where Path -eq $_.Path | Where Arguments -eq $_.Arguments ))
     {
       $ActiveMinerPrograms += [PSCustomObject]@{
           Name = $_.Name
           Type = $_.Type
           Devices = 0
           DeviceCall = $_.DeviceCall
           MinerName = $_.MinerName
           Path = $_.Path
           Arguments = $_.Arguments
           API = $_.API
           Port = $_.Port
           Coins = $_.Symbol
           Active = [TimeSpan]0
           Activated = 0
           Status = "Idle"
           HashRate = 0
           Benchmarked = 0
           WasBenchmarked = $false
           MinerPool = $_.MinerPool
           Algo = $_.Algo
           FullName = $_.FullName
           BestMiner = $false
           quote = 0
          }
         }
        }
   