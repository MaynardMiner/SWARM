
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
 
 
 $nicehash_Request = [PSCustomObject]@{} 
 
 if($Auto_Algo -eq "Yes")
  {
  if($Poolname -eq $Name)
   {
 try { 
     $nicehash_Request = Invoke-RestMethod "https://api.nicehash.com/api?method=simplemultialgo.info" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "SWARM contacted ($Name) for a failed API. "
     return 
 }
 
 if (($nicehash_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "SWARM contacted ($Name) but ($Name) Pool API had issues. " 
     return 
 } 
  
 if($Location -eq "US")
  {
    $Region = "usa"
    $Location = "US"
  }

 if($Location -eq "ASIA")
  {
    $Region = "hk"
    $Location = "ASIA"
  }

if($Location -eq "EUROPE")
 {
   $Region = "eu"
   $Location = "EUROPE" 
 }

$nicehash_Request.result | Select-Object -ExpandProperty simplemultialgo | Where paying -ne 0 | ForEach-Object {
  
    $nicehash_Host = "$($_.name).$Region.nicehash.com"
    $nicehash_Port = $_.port
    $nicehash_Algorithm = Get-Algorithm $_.name
    $nicehash_Fees = $Nicehash_Fee
    $Divisor = 1000000000

    if($Algorithm -eq $nicehash_Algorithm)
     {
        $Stat = Set-Stat -Name "$($Name)_$($Nicehash_Algorithm)_Profit" -Value ([Double]$_.paying/$Divisor*(1-($Nicehash_Fees/100)))
        $Price = (($Stat.Live*(1-[Math]::Min($Stat.Day_Fluctuation,1)))+($Stat.Day*(0+[Math]::Min($Stat.Day_Fluctuation,1))))
     
     
     if($Wallet)
	    {
     if($Nicehash_Wallet1 -ne '' -or $Nicehash_Wallet2 -ne '' -or $Nicehash_Wallet3 -ne '')
        {  
        [PSCustomObject]@{
            Coin = "No"
            Symbol = $nicehash_Algorithm
            Mining = $nicehash_Algorithm
            Algorithm = $nicehash_Algorithm
            Price = $Price
            Fees = $nicehash_Fees
            StablePrice = $Stat.Week
            Protocol = "stratum+tcp"
            Host = $nicehash_Host
            Port = $nicehash_Port
            User1 = "$Nicehash_Wallet1.$Rigname1"
	    User2 = "$Nicehash_Wallet2.$Rigname2"
            User3 = "$Nicehash_Wallet3.$Rigname3"
            CPUser = "$Nicehash_Wallet1.$Rigname1"
            CPUPass = "x"
            Pass1 = "x"
            Pass2 = "x"
	          Pass3 = "x"
            Location = $Location
            SSL = $false
         }
        }
      }
    }
   }
 }
}
