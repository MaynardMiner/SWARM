$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$phiphipool_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

if($Poolname -eq $Name)
 {
  try{$phiphipool_Request = Invoke-RestMethod "https://www.phi-phi-pool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
  catch{Write-Warning "SWARM Contacted ($Name) for a failed API check.";return}
 
  if(($phiphipool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SWARM contacted ($Name) but ($Name) Pool API was unreadable." 
     return 
  }
  
  switch($Location)
  {
   "ASIA"{$region = "asia"}
   "US"{$region = "us"}
   "EUROPE"{$Region = "eu"}
  }
  
  $phiphipool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$phiphipool_Request.$_.hashrate -gt 0} |  Where-Object {$Naming.$($phiphipool_Request.$_.name)} | ForEach-Object {

  $phiphipool_Algorithm = Get-Algorithm $phiphipool_Request.$_.name

  if($Algorithm -eq $phiphipool_Algorithm)
  {
    $phiphipool_Port = $phiphipool_Request.$_.port
    $phiphipool_Host = "$($Region).phi-phi-pool.com"
    $Divisor = (1000000*$phiphipool_Request.$_.mbtc_mh_factor)
    $Fees = $phiphipool_Request.$_.fees
    $Workers = $phiphipool_Request.$_.Workers
    $Estimate = if($Stat_Algo -eq "Day"){[Double]$phiphipool_Request.$_.estimate_last24h}else{[Double]$phiphipool_Request.$_.estimate_current}
    $Cut = ConvertFrom-Fees $Fees $Workers $Estimate

    $SmallestValue = 1E-20
    $Stat = Set-Stat -Name "$($Name)_$($phiphipool_Algorithm)_profit" -Value ([Math]::Max([Double]($Estimate-$Cut)/$Divisor,$SmallestValue))
    if($Stat_Algo -eq "Day"){$Stats = $Stat.Live}else{$Stats = $Stat.$Stat_Algo}

    [PSCustomObject]@{
     Priority = $Priorities.Pool_Priorities.$Name
     Symbol = $phiphipool_Algorithm
     Mining = $phiphipool_Algorithm
     Algorithm = $phiphipool_Algorithm
     Price = $Stats
     StablePrice = $Stat.Week
     MarginOfError = $Stat.Fluctuation
     Protocol = "stratum+tcp"
     Host = $phiphipool_Host
     Port = $phiphipool_Port
     User1 = $Wallet1
     User2 = $Wallet2
     User3 = $Wallet3
     CPUser = $CPUWallet
     CPUPass = "c=$CPUcurrency,ID=$Rigname1"
     Pass1 = "c=$Passwordcurrency1,ID=$Rigname1"
     Pass2 = "c=$Passwordcurrency2,ID=$Rigname2"
	 Pass3 = "c=$Passwordcurrency3,ID=$Rigname3"
     Location = $Location
     SSL = $false
    }
   }
  }
 }
