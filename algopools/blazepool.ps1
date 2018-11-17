
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 

$blazepool_Request = [PSCustomObject]@{} 
 
  if($Poolname -eq $Name)
   {
 try {
     $blazepool_Request = Invoke-RestMethod "http://api.blazepool.com/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "SWARM contacted ($Name) for a failed API check. " 
     return 
 }
 
 if (($blazepool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SWARM contacted ($Name) but ($Name) Pool API had issues. " 
     return 
 } 
  
$blazepool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$blazepool_Request.$_.hashrate -gt 0} |  Where-Object {$Naming.$($blazepool_Request.$_.name)} | ForEach-Object {

    $blazepool_Algorithm = Get-Algorithm $blazepool_Request.$_.name
    $blazepool_Host = "$_.mine.blazepool.com"
    $blazepool_Port = $blazepool_Request.$_.port
    $Divisor = (1000000*$blazepool_Request.$_.mbtc_mh_factor)

    if($Algorithm -eq $blazepool_Algorithm)
    {
    if($Stat_Algo -ne "Day"){$Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_profit" -Value ([Double]$blazepool_Request.$_.estimate_current/$Divisor*(1-($blazepool_Request.$_.fees/100)))}
    else{$Stat = Set-Stat -Name "$($Name)_$($blazepool_Algorithm)_profit" -Value ([Double]$blazepool_Request.$_.estimate_last24h/$Divisor *(1-($blazepool_Request.$_.fees/100)))}
    

       if($Wallet)
	    {
        [PSCustomObject]@{
            Coin = "No"
            Symbol = $blazepool_Algorithm
            Mining = $blazepool_Algorithm
            Algorithm = $blazepool_Algorithm
            Price = if($Stat_Algo -eq "Day"){$Stat.Live}else{$Stat.$Stat_Algo}
            StablePrice = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $blazepool_Host
            Port = $blazepool_Port
            User1 = $Wallet1
	        User2 = $Wallet2
            User3 = $Wallet3
            CPUser = $Wallet1
            CPUPass = "c=$Passwordcurrency1,ID=$Rigname1"
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