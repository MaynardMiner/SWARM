$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 

$fairpool_Request = [PSCustomObject]@{} 
 
   if($Poolname -eq $Name)
    {
 try {
     $fairpool_Request = Invoke-RestMethod "https://fairpool.pro/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "SWARM contacted ($Name) for a failed API. "
     return 
 }
 
 if (($fairpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SWARM contacted ($Name) but ($Name) Pool API had issues. " 
     return 
 } 
  
$fairpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$Naming.$($fairpool_Request.$_.name)} | ForEach-Object {
 
    Switch($Location)
    {
     "US" {$fairpool_Host = "us1.fairpool.pro"}
     default {$fairpool_Host = "eu1.fairpool.pro"}
    }
    $fairpool_Port = $fairpool_Request.$_.port
    $fairpool_Algorithm = Get-Algorithm $fairpool_Request.$_.name
    $fairpool_Fees = $fairpool_Request.$_.fees
    $Divisor = (1000000*$fairpool_Request.$_.mbtc_mh_factor)

    if($Algorithm -eq $fairpool_Algorithm)
    {
    if($Stat_Algo -ne "Day"){$Stat = Set-Stat -Name "$($Name)_$($fairpool_Algorithm)_profit" -Value ([Double]$fairpool_Request.$_.estimate_current/$Divisor*(1-($fairpool_Request.$_.fees/100)))}
    else{$Stat = Set-Stat -Name "$($Name)_$($fairpool_Algorithm)_profit" -Value ([Double]$fairpool_Request.$_.estimate_last24h/$Divisor *(1-($fairpool_Request.$_.fees/100)))}

       if($Wallet)
	    {
        [PSCustomObject]@{
            Coin = "No"
            Symbol = $fairpool_Algorithm
            Mining = $fairpool_Algorithm
            Algorithm = $fairpool_Algorithm
            Price = $Stat.$Stat_Algo
            Fees = $fairpool_Fees
            Workers = $fairpool_Workers
            StablePrice = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $fairpool_Host
            Port = $fairpool_Port
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
   }
