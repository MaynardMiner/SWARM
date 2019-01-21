. .\build\powershell\childitems.ps1
. .\build\powershell\statcommand.ps1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Getkeys = if(Test-Path ".\wallet\keys"){Get-ChildItemContent ".\wallet\keys" | % {$_.Content | Add-Member @{Name = $_.Content.Wallet} -PassThru}}
$AltWallets = ("AltWallet1","AltWallet2","AltWallet3")
$AltPool = $true
$Getkeys | %{if($AltWallets -eq $_.Name){$AltPool = $true}}
if($AltPool = $true){$Wallets = $AltWallets}else{$Wallets = ("Wallet1","Wallet2","Wallet3")}
$PoolQuery = "https://nlpool.nl/api/wallet?address="

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
  if($_.Response.balance -gt 0)
  {
    Set-WStat -Name "$($Name)_$($_.Address)" -Symbol $_.symbol -address $_.address -balance $_.response.balance -unpaid $_.response.unpaid
  }
}

