
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
 
$Zpool_Request = [PSCustomObject]@{} 

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
 
 if($Poolname -eq $Name)
  {
 try {
     $Zpool_Request = Invoke-RestMethod "http://www.zpool.ca/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "SWARM Contacted ($Name) for a failed API check. "
     return 
 } 
 
 if (($Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SWARM contacted ($Name) but ($Name) Pool was unreadable. " 
     return
 }     

$Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$Zpool_Request.$_.hashrate -gt 0} |  Where-Object {$Naming.$($Zpool_Request.$_.name)} | ForEach-Object {
    

    $Zpool_Port = $Zpool_Request.$_.port
    $Zpool_Algorithm = Get-Algorithm $Zpool_Request.$_.name
    Switch($Location)
    {
     "US"{$Zpool_Host = "$ZPool_Algorithm.na.mine.zpool.ca"}
     "Europe"{$Zpool_Host = "$ZPool_Algorithm.eu.mine.zpool.ca"}
     "Asia"{$Zpool_Host = "$ZPool_Algorithm.sea.mine.zpool.ca"}
    }
    $Divisor = (1000000*$Zpool_Request.$_.mbtc_mh_factor)

    if($Algorithm -eq $Zpool_Algorithm)
     {
        if($Stat_Algo -ne "Day"){$Stat = Set-Stat -Name "$($Name)_$($Zpool_Algorithm)_profit" -Value ([Double]$Zpool_Request.$_.estimate_current/$Divisor*(1-($Zpool_Request.$_.fees/100)))}
        else{$Stat = Set-Stat -Name "$($Name)_$($Zpool_Algorithm)_profit" -Value ([Double]$Zpool_Request.$_.estimate_last24h/$Divisor *(1-($Zpool_Request.$_.fees/100)))}
         
       if($Wallet)
	    {
          If($AltWallet1 -ne ''){$zWallet1 = $AltWallet1}
          else{$zwallet1 = $Wallet1}
          if($AltWallet2 -ne ''){$zWallet2 = $AltWallet2}
          else{$zwallet2 = $Wallet2}
          if($AltWallet3 -ne ''){$zWallet3 = $AltWallet3}
          else{$zwallet3 = $Wallet3}
          if($AltPassword1 -ne ''){$zpass1 = $Altpassword1}
          else{$zpass1 = $Passwordcurrency1}
          if($AltPassword2 -ne ''){$zpass2 = $AltPassword2}
          else{$zpass2 = $Passwordcurrency2}
          if($AltPassword3 -ne ''){$zpass3 = $AltPassword3}
          else{$zpass3 = $Passwordcurrency3}    
        [PSCustomObject]@{
            Priority = $Priorities.Pool_Priorities.$Name
            Coin = "No"
            Symbol = $Zpool_Algorithm
            Mining = $Zpool_Algorithm
            Algorithm = $Zpool_Algorithm
            Price = if($Stat_Algo -eq "Day"){$Stat.Live}else{$Stat.$Stat_Algo}
            StablePrice = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $Zpool_Host
            Port = $Zpool_Port
            User1 = $zWallet1
	        User2 = $zWallet2
            User3 = $zWallet3
            CPUser = $zWallet1
            CPUPass = "c=$zpass1,ID=$Rigname1"
            Pass1 = "c=$zpass1,ID=$Rigname1"
            Pass2 = "c=$zpass2,ID=$Rigname2"
	        Pass3 = "c=$zpass3,ID=$Rigname3"
            Location = $Location
            SSL = $false
         }
        }
      }
     }
    }
