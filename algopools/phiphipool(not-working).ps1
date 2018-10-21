
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
 
 $phiphipool_Request = [PSCustomObject]@{} 

 if($Poolname -eq $Name)
  {
 try { 
     [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
     $phiphipool_Request = Invoke-RestMethod "https://www.phi-phi-pool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "SWARM Contacted ($Name) for a failed API check. " 
     return 
 }
 
 if (($phiphipool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SWARM sniffed near ($Name) but ($Name) Pool API had no scent. " 
     return 
 } 
  
$Location = 'Europe', 'US'
$phiphipool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$phiphipool_Request.$_.hashrate -gt 0} | ForEach-Object {
    
#$phiphipool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$phiphipool_Request.$_.hashrate -gt 0} | foreach {
    $phiphipool_Port = $phiphipool_Request.$_.port
    $phiphipool_Algorithm = Get-Algorithm $phiphipool_Request.$_.name
    $phiphipool_Host = "pool1.phi-phi-pool.com"
    $Divisor = (1000000*$phiphipool_Request.$_.mbtc_mh_factor)

    if($Algorithm -eq $phiphipool_Algorithm)
     {
    if((Get-Stat -Name "$($Name)_$($phiphipool_Algorithm)_profit") -eq $null){$Stat = Set-Stat -Name "$($Name)_$($phiphipool_Algorithm)_profit" -Value ([Double]$phiphipool_Request.$_.estimate_current/$Divisor*(1-($phiphipool_Request.$_.fees/100)))}
    else{$Stat = Set-Stat -Name "$($Name)_$($phiphipool_Algorithm)_profit" -Value ([Double]$phiphipool_Request.$_.estimate_current/$Divisor *(1-($phiphipool_Request.$_.fees/100)))}
     
    
     
       if($Wallet)
	    {
        [PSCustomObject]@{
            Coin = "No"
            Symbol = $phiphipool_Algorithm
            Mining = $phiphipool_Algorithm
            Algorithm = $phiphipool_Algorithm
            Price = $Stat.$Stat_Algo
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
  }
