
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
 
$Zpool_Request = [PSCustomObject]@{} 
 
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
    
    Switch($Location)
    {
     "US"{$Zpool_Host = "$_.na.mine.zpool.ca"}
     "Europe"{$Zpool_Host = "$_.eu.mine.zpool.ca"}
     "Asia"{$Zpool_Host = "$_.sea.mine.zpool.ca"}
    }
    $Zpool_Host = "$_.mine.zpool.ca"
    $Zpool_Port = $Zpool_Request.$_.port
    $Zpool_Algorithm = $Zpool_Request.$_.name
    $Divisor = (1000000*$Zpool_Request.$_.mbtc_mh_factor)

    if($Algorithm -eq $Zpool_Algorithm)
     {
    if((Get-Stat -Name "$($Name)_$($zpool_Algorithm)_profit") -eq $null){$Stat = Set-Stat -Name "$($Name)_$($zpool_Algorithm)_profit" -Value ([Double]$zpool_Request.$_.estimate_current/$Divisor*(1-($zpool_Request.$_.fees/100)))}
    else{$Stat = Set-Stat -Name "$($Name)_$($zpool_Algorithm)_profit" -Value ([Double]$zpool_Request.$_.estimate_current/$Divisor *(1-($zpool_Request.$_.fees/100)))}	
     
       if($Wallet)
	    {
        [PSCustomObject]@{
            Coin = "No"
            Symbol = $Zpool_Algorithm
            Mining = $Zpool_Algorithm
            Algorithm = $Zpool_Algorithm
            Price = $Stat.$Stat_Algo
            StablePrice = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $Zpool_Host
            Port = $Zpool_Port
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
