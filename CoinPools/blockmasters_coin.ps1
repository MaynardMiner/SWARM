
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Location = 'US'

$blockpool_Request = [PSCustomObject]@{}
$blockpoolAlgo_Request = [PSCustomObject]@{}
$blockcoinalgo = $CoinAlgo
$blockcoinalgo | foreach {
switch ($_) {
  "aeriumx"{$_ = "aergo"}
}
}

 if($Poolname -eq $Name)
  {

   try {
     $blockpool_Request = Invoke-RestMethod "http://blockmasters.co/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
     $blockpool_factor_Request = Invoke-RestMethod "http://blockmasters.co/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
       }
   catch {
     Write-Warning "MM.Hash contacted ($Name) for a failed API check. (Coins)"
     return
        }

 if (($blockpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
     Write-Warning "MM.Hash contacted ($Name) but ($Name) Pool API was unreadable. "
     return
   }
  
$blockpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | foreach {

 if($blockcoinalgo -eq $blockpool_Request.$_.algo)
  {
  if($blockpool_Request.$_.hashrate -ne "0")
   {
   if($blockpool_Request.$_.estimate -ne "0.00000")
    {

    $blockpool_Coin = "$($_)".ToUpper()
    $blockpool_Symbol = "$($_)".ToUpper()
    switch ($blockpool_Symbol) {
     "HSR"{$blockpool_Symbol = "HSR-Coin"}
     "SIB"{$blockpool_Symbol = "SIB-Coin"}
     '$PAC'{$blockpool_Symbol = "PAC-Coin"}
     'DGB-SKEIN'{$blockpool_Symbol = "DGBskein"}
    }
    $blockpool_Port = $blockpool_Request.$_.port
    $blockpool_Algorithm = Get-Algorithm $blockpool_Request.$_.algo
    $blockpool_Host = "blockmasters.co"
    $blockpool_Fees = .25
    $blockpool_CoinName = $blockpool_Request.$_.name
    $blockpool_Estimate = [Double]$blockpool_Request.$_.estimate*.001
    $blockpool_24h= "24h_btc"
    $Divisor = (1000000*($blockpool_factor_Request.$blockpool_Algorithm.mbtc_mh_factor))
    

    $Stat = Set-Stat -Name "$($Name)_$($blockpool_Symbol)_Profit"-Value ([Double]$blockpool_Estimate/$Divisor *(1-($blockpool_fees/100)))
    

    if($Wallet)
    {
     If($BlockmastersWallet1 -ne ''){$blockWallet1 = $BlockmastersWallet1}
     else{$blockWallet1 = $Wallet1}
     if($BlockmastersWallet2 -ne ''){$blockWallet2 = $BlockmastersWallet2}
     else{$blockWallet2 = $Wallet2}
     if($BlockmastersWallet1 -ne ''){$blockWallet3 = $BlockmastersWallet3}
     else{$blockWallet3 = $Wallet3}
     if($Blockmasterspassword1 -ne ''){$blockpass1 = $Blockmasterspassword1}
     else{$blockpass1 = $Passwordcurrency1}
     if($Blockmasterspassword2 -ne ''){$blockpass2 = $Blockmasterspassword2}
     else{$blockpass2 = $Passwordcurrency2}
     if($Blockmasterspassword3 -ne ''){$blockpass3 = $Blockmasterspassword3}
     else{$blockpass3 = $Passwordcurrency3}
     [PSCustomObject]@{
      Coin = "Yes"
      Symbol = $blockpool_Symbol
      Mining = $blockpool_CoinName
      Algorithm = $blockpool_Algorithm
      Price = $Stat.Live
      StablePrice = $Stat.Week
      MarginOfError = $Stat.Fluctuation
      Protocol = "stratum+tcp"
      Host = $blockpool_Host
      Port = $blockpool_Port
      User1 = $blockWallet1
      User2 = $blockWallet2
      User3 = $blockWallet3
      CPUser = $CPUWallet
      CPUPass = "c=$CPUcurrency,mc=$blockpool_Coin"
      Pass1 = "c=$blockpass1,mc=$blockpool_Coin"
      Pass2 = "c=$blockpass2,mc=$blockpool_Coin"
      Pass3 = "c=$blockpass3,mc=$blockpool_Coin"
      Location = $Location
      SSL = $false
              }
             }
            }
          }
        }
      }
    }
