
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

 $starpool_Request = [PSCustomObject]@{} 
 
  if($Poolname -eq $Name)
   {
 try {
     [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
     $starpool_Request = Invoke-RestMethod "https://www.starpool.biz/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "SWARM contacted ($Name) for a failed API check. " 
     return 
 }
 
 if (($starpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SWARM contacted ($Name) but ($Name) Pool API had issues. " 
     return 
 } 
  
$Location = "US"

$starpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name |  Where-Object {$starpool_Request.$_.hashrate -gt 0} | ForEach-Object {

    $starpool_Algorithm = Get-Algorithm $starpool_Request.$_.name
    $starpool_Host = "$_.starpool.biz"
    $starpool_Port = $starpool_Request.$_.port
    $Divisor = (1000000*$starpool_Request.$_.mbtc_mh_factor)

    if($Algorithm -eq $starpool_Algorithm)
     {
    if((Get-Stat -Name "$($Name)_$($starpool_Algorithm)_profit") -eq $null){$Stat = Set-Stat -Name "$($Name)_$($starpool_Algorithm)_profit" -Value ([Double]$starpool_Request.$_.estimate_current/$Divisor*(1-($starpool_Request.$_.fees/100)))}
    else{$Stat = Set-Stat -Name "$($Name)_$($starpool_Algorithm)_profit" -Value ([Double]$starpool_Request.$_.estimate_current/$Divisor *(1-($starpool_Request.$_.fees/100)))}
     

       if($Wallet)
	{
        [PSCustomObject]@{
            Coin = "No"
            Symbol = $starpool_Algorithm
            Mining = $starpool_Algorithm
            Algorithm = $starpool_Algorithm
            Price = $Stat.$Stat_Algo
            StablePrice = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol = "stratum+tcp"
            Host = $starpool_Host
            Port = $starpool_Port
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