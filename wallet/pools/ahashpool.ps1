. .\build\powershell\childitems.ps1
. .\build\powershell\statcommand.ps1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Getkeys = if(Test-Path ".\wallet\keys"){Get-ChildItemContent ".\wallet\keys" | % {$_.Content | Add-Member @{Name = $_.Content.Wallet} -PassThru}}
$AltWallets = ("AltWallet1","AltWallet2","AltWallet3")
$AltPool = $false
if($AltPool = $true){$Wallets = $AltWallets}else{$Wallets = ("Wallet1","Wallet2","Wallet3")}
$PoolQuery = "https://ahashpool.com/api/wallet/?address="

$Getkeys | %{if($Wallets -match $_.Name){try{$_.Response = Invoke-RestMethod "$PoolQuery$($_.address)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop}Catch{$_.Response = ""}}}

$Getkeys | % {
    if($_.Response -ne "")
     {
     Set-WStat -Name "$($Name)_$($_.Address)" -balance $_.response.balance -unpaid $_.response.unpaid
     }
   }
   