. .\build\powershell\childitems.ps1
. .\build\powershell\statcommand.ps1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Getkeys = if(Test-Path ".\wallet\keys"){Get-ChildItemContent ".\wallet\keys" | % {$_.Content | Add-Member @{Name = $_.Content.Wallet} -PassThru}}
$AltWallets = ("AltWallet1","AltWallet2","AltWallet3")
$AltPool = $false
if($AltPool = $true){$Wallets = $AltWallets}else{$Wallets = ("Wallet1","Wallet2","Wallet3")}
$PoolQuery = "https://api.nicehash.com/api?method=stats.provider&addr="

$Getkeys | %{if($Wallets -match $_.Name)
    {
      try
      {
       $Response = Invoke-RestMethod "$PoolQuery$($_.address)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
      }
      Catch{Write-Warning "failed to contact $Name For Wallet Info"; $Response = $Null}
      $_.Response = $Response
     }
    }
  
  $Getkeys | % {
      if($_.Response.result)
       {
        $unpaid = 0
        $nhbalance = 0
        $_.Response.result.Stats | %{$nhbalance += $_.balance}
        Set-WStat -Name "$($Name)_$($_.Address)" -Symbol $_.symbol -address $_.address -balance $nhbalance -unpaid $unpaid
       }
     }
  