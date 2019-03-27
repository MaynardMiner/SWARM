. .\build\powershell\childitems.ps1
. .\build\powershell\statcommand.ps1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolQuery = "http://phi-phi-pool.com/api/wallet?address="

$Query = @()

if ($WalletKeys.Wallet1.BTC.Pools -contains $Name) {
        $WalletKeys.Wallet1.BTC.pools | % {
            if ($Query.Name -notcontains "$($Name)_$($WalletKeys.Wallet1.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.Wallet1.BTC.address)"; Symbol = "BTC"; Address = $WalletKeys.Wallet1.BTC.address; Response = ""}
            }
        }
    }

if ($WalletKeys.Wallet2.BTC.Pools -contains $Name) {
        $WalletKeys.Wallet2.BTC.pools | % {
            if ($Query.Name -notcontains "$($Name)_$($WalletKeys.Wallet2.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.Wallet2.BTC.address)"; Symbol = "BTC"; Address = $WalletKeys.Wallet2.BTC.address; Response = ""}
            }
        }
    }

if ($WalletKeys.Wallet3.BTC.Pools -contains $Name) {
        $WalletKeys.Wallet3.BTC.pools | % {
            if ($Query.Name -notcontains "$($Name)_$($WalletKeys.Wallet3.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.Wallet3.BTC.address)"; Symbol = "BTC"; Address = $WalletKeys.Wallet3.BTC.address; Response = ""}
            }
        }
    }

$Query | % {
        try {$Response = Invoke-RestMethod "$PoolQuery$($_.address)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop}
        Catch {Write-Warning "failed to contact $Name For $($_.Address) Info"; $Response = $Null}
        $_.Response = $Response
    }

$Query | % {
    if ($_.Response.unpaid -gt 0) {
        Set-WStat -Name $_.Name -Symbol $_.symbol -address $_.address -balance $_.response.balance -unpaid $_.response.unpaid
    }
}
   