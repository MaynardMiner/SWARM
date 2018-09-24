$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Location = 'US'

$zergpool_Request = [PSCustomObject]@{}
$Zergpool_Sorted = [PSCustomObject]@{}


 if($Poolname -eq $Name)
  {
   try {
     $zergpool_Request = Invoke-RestMethod "http://zergpool.com:8080/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
       }
   catch {
     Write-Warning "SWARM contacted ($Name) for a failed API check. (Coins)"
     return
        }

 if (($zergpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
     Write-Warning "SWARM contacted ($Name) but ($Name) Pool API was unreadable. "
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
    
    $Stat = Set-Stat -Name "$($Name)_$($zergpool_Coin)_Profit"-Value ([Double]$zergpool_Estimate/$Divisor *(1-($zergpool_fees/100)))

      if($Wallet)
       {
        If($ZergpoolWallet1 -ne ''){$ZergWallet1 = $ZergpoolWallet1}
        else{$ZergWallet1 = $Wallet1}
        if($ZergpoolWallet2 -ne ''){$ZergWallet2 = $ZergpoolWallet2}
        else{$ZergWallet2 = $Wallet2}
        if($ZergpoolWallet1 -ne ''){$ZergWallet3 = $ZergpoolWallet3}
        else{$ZergWallet3 = $Wallet3}
        if($Zergpoolpassword1 -ne ''){$Zergpass1 = $Zergpoolpassword1}
        else{$Zergpass1 = $Passwordcurrency1}
        if($Zergpoolpassword2 -ne ''){$Zergpass2 = $Zergpoolpassword2}
        else{$Zergpass2 = $Passwordcurrency2}
        if($Zergpoolpassword3 -ne ''){$Zergpass3 = $Zergpoolpassword3}
        else{$Zergpass3 = $Passwordcurrency3}
        [PSCustomObject]@{
          Coin = "Yes"
          Symbol = $zergpool_Coin
          Algorithm = $zergpool_Algorithm
          Price = $Stat.$Stat_Coin
          StablePrice = $Stat.Week
          MarginOfError = $Stat.Fluctuation
          Protocol = "stratum+tcp"
          Host = $zergpool_Host
          Port = $zergpool_Port
          User1 = $ZergWallet1
          User2 = $ZergWallet2
          User3 = $ZergWallet3
          CPUser = $CPUWallet
          CPUPass = "c=$CPUcurrency,mc=$zergpool_Coin"
          Pass1 = "c=$Zergpass1,mc=$zergpool_Coin"
          Pass2 = "c=$Zergpass2,mc=$zergpool_Coin"
          Pass3 = "c=$Zergpass3,mc=$zergpool_Coin"
          Location = $Location
          SSL = $false
                 } 
             }
           }
          }