 

 $Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
 
 $Hashrefinery_Request = [PSCustomObject]@{} 

 [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
   if($Poolname -eq $Name)
    {
 try {
     $Hashrefinery_Request = Invoke-RestMethod "http://pool.hashrefinery.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "SWARM contacted ($Name) for a failed API. "
     return 
 } 
 
 
 if (($Hashrefinery_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SWARM contacted ($Name) but ($Name) Pool API was unreadable. " 
     return 
 }  
 
 $Hashrefinery_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$Hashrefinery_Request.$_.hashrate -gt 0} |  Where-Object {$Naming.$($Hashrefinery_Request.$_.name)} | ForEach-Object {
     
    $Hashrefinery_Host = "$_.us.hashrefinery.com"
    $Hashrefinery_Port = $Hashrefinery_Request.$_.port
    $Hashrefinery_Algorithm = Get-Algorithm $Hashrefinery_Request.$_.name
    $Divisor = (1000000*$Hashrefinery_Request.$_.mbtc_mh_factor)

    if($Algorithm -eq $hashrefinery_Algorithm)
    {
     if($Stat_Algo -ne "Day"){$Stat = Set-Stat -Name "$($Name)_$($Hashrefinery_Algorithm)_profit" -Value ([Double]$Hashrefinery_Request.$_.estimate_current/$Divisor*(1-($Hashrefinery_Request.$_.fees/100)))}
     else{$Stat = Set-Stat -Name "$($Name)_$($Hashrefinery_Algorithm)_profit" -Value ([Double]$Hashrefinery_Request.$_.estimate_last24h/$Divisor *(1-($Hashrefinery_Request.$_.fees/100)))}
        
       if($Wallet)
	    {
        [PSCustomObject]@{
            Coin = "No"
            Symbol = $Hashrefinery_Algorithm
            Mining = $Hashrefinery_Algorithm
            Algorithm = $Hashrefinery_Algorithm
            Price = if($Stat_Algo -eq "Day"){$Stat.Live}else{$Stat.$Stat_Algo}
            StablePrice = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $Hashrefinery_Host
            Port = $Hashrefinery_Port
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
    
