$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolQuery = "https://api.nicehash.com/api?method=stats.provider&addr="

$Query = @()
if ($Global:WalletKeys.Nicehash_Wallet1.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Nicehash_Wallet1.BTC.pools | % {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Nicehash_Wallet1.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Nicehash_Wallet1.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Nicehash_Wallet1.BTC.address; Response = ""}
        }
    }
}

if ($Global:WalletKeys.Nicehash_Wallet2.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Nicehash_Wallet2.BTC.pools | % {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Nicehash_Wallet2.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Nicehash_Wallet2.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Nicehash_Wallet2.BTC.address; Response = ""}
        }
    }
}

if ($Global:WalletKeys.Nicehash_Wallet3.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Nicehash_Wallet3.BTC.pools | % {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Nicehash_Wallet3.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Nicehash_Wallet3.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Nicehash_Wallet3.BTC.address; Response = ""}
        }
    }
}

$Query | % {
    try {$Response = Invoke-RestMethod "$PoolQuery$($_.address)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop}
    Catch {Write-Warning "failed to contact $Name For $($_.Address) Info"; $Response = $Null}
    $_.Response = $Response
}

$Query| % {
    if ($_.Response.result) {
        $unpaid = 0
        $nhbalance = 0
        $_.Response.result.Stats | % {$nhbalance += $_.balance}
        Set-WStat -Name "$($Name)_$($_.Address)" -Symbol $_.symbol -address $_.address -balance $nhbalance -unpaid $unpaid
    }
}

