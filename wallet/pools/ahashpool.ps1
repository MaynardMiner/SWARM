$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolQuery = "https://ahashpool.com/api/wallet/?address="

$Query = @()

if ($Global:WalletKeys.Wallet1.BTC.address -ne "" -and $Global:WalletKeys.Wallet1.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Wallet1.BTC.pools | ForEach-Object {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet1.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet1.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet1.BTC.address; Response = "" }
        }
    }
}

if ($Global:WalletKeys.Wallet2.BTC.address -ne "" -and $Global:WalletKeys.Wallet2.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Wallet2.BTC.pools | ForEach-Object {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet2.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet2.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet2.BTC.address; Response = "" }
        }
    }
}

if ($Global:WalletKeys.Wallet3.BTC.address -ne "" -and $Global:WalletKeys.Wallet3.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Wallet3.BTC.pools | ForEach-Object {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet3.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet3.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet3.BTC.address; Response = "" }
        }
    }
}

$Query | ForEach-Object { try { $Response = Invoke-RestMethod "$PoolQuery$($_.address)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } Catch { Write-Warning "failed to contact $Name For $($_.Address) Info"; $Response = $Null } $_.Response = $Response }

$Query | ForEach-Object {
    if ($_.Response.unsold -eq 0) {
        Set-WStat -Name $_.Name -Symbol $_.symbol -address $_.address -balance $_.response.balance -unpaid $_.response.unsold
    }
}
   