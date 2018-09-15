. .\IncludeCoin.ps1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
 
 
 $zergpool_Request = [PSCustomObject]@{} 
 
 
 try { 
     $zergpool_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
     #$ZergpoolCoins_Request = Invoke-RestMethod "http://api.zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop 
 } 
 catch { 
     Write-Warning "MM.Hash contacted ($Name) for a failed API check. " 
     return 
 }
 
 if (($zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
     Write-Warning "MM.Hash contacted ($Name) but ($Name) Pool API was unreadable. " 
     return 
 } 
  
$Location = 'US'
$zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
#$zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$zergpool_Request.$_.hashrate -gt 0} | foreach {
    $zergpool_Coin = Get-Coin $_
    $zergpool_Port = $zergpool_Request.$_.port
    $zergpool_Algorithm = Get-Algorithm $zergpool_Request.$_.algo
    $zergpool_Fees = $zergpool_Request.$_.fees
    $zergpool_Workers = $zergpool_Request.$_.workers
    $zergpool_Host = "$zergpool_Algorithm.mine.zergpool.com"
    $zergpool_Auto = $zergpool_Request.$_.noautotrade

    if($zergpool_Algorithm -eq "Allium","Yescrypt","Yescryptr16","Neoscrypt","Allium","HMQ1725","Keccak","Lyra2z","Keccakc","Xevan","X16r","Hsr","X17","Blake2s","lyra2v2","Bitcore","X16s","Phi","Timetravel","Skunk","Tribus","Sib","Skein","Groestl","Nist5","c11")
     {
      if($zergpool_Auto -eq "0")
       {
    Write-Host "$zergpool_Coin"
       }
     }

}


