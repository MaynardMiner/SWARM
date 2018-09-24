$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Location = 'US'

$zergpool_Request = [PSCustomObject]@{}
$Zergpool_Sorted = [PSCustomObject]@{}


 if($Poolname -eq $Name)
  {
   try {
     $zergpool_Request = Invoke-RestMethod "http://zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
     #$ZergpoolAlgo_Request = Invoke-RestMethod "http://api.zergpool.com/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
       }
   catch {
     Write-Warning "MM.Hash contacted ($Name) for a failed API check. (Coins)"
     return
        }

 if (($zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
     Write-Warning "MM.Hash contacted ($Name) but ($Name) Pool API was unreadable. "
     return
   }
   
$zergpool_Request.PSObject.Properties.Name | foreach { $zergpool_Request.$_ | Add-Member "sym" $_ }
$CoinAlgo | foreach {
  $Selected = $_
  $Best = $zergpool_Request.PSObject.Properties.Value | Where Algo -eq $Selected | Where noautotrade -eq "0" | Where estimate -ne "0.00000" | Sort-Object Price -Descending | Select -First 1
  if($Best -ne $null){$Zergpool_Sorted | Add-Member $Best.sym $Best}
  }

$Zergpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | foreach {

    $zergpool_Algorithm = Get-Algorithm $Zergpool_Sorted.$_.algo
    $zergpool_Coin = "$($Zergpool_Sorted.$_.sym)".ToUpper()
    switch ($zergpool_Coin) {
     "HSR"{$zergpool_Coin = "HSR-Coin"}
     "SIB"{$zergpool_Coin = "SIB-Coin"}
     '$PAC'{$zergpool_Coin = "PAC-Coin"}
    }
    $zergpool_Port = $Zergpool_Sorted.$_.port
    $zergpool_Host = "$($Zergpool_Sorted.$_.algo).mine.zergpool.com"
    $zergpool_Fees = .5
    $zergpool_Estimate = [Double]$Zergpool_Sorted.$_.estimate*.001
    $zergpool_24h= "24h_btc"
    $Divisor = (1000000*$Zergpool_Sorted.$_.mbtc_mh_factor)
    
    $Coin = $zergpool_Coin
    $Stat = Set-Stat -Name "$($Name)_$($zergpool_Coin)_Profit"-Value ([Double]$zergpool_Estimate/$Divisor *(1-($zergpool_fees/100)))
    
    $Coin
    $Stat
 }
}