$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolQuery = "https://api2.nicehash.com/main/api/v2/mining/external/"

$Query = @()
if ($Global:WalletKeys.Wallet1.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Wallet1.BTC.pools | % {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet1.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet1.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet1.BTC.address; Response = "" }
        }
    }
}

if ($Global:WalletKeys.Wallet2.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Wallet2.BTC.pools | % {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet2.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet2.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet2.BTC.address; Response = "" }
        }
    }
}

if ($Global:WalletKeys.Wallet3.BTC.Pools -contains $Name) {
    $Global:WalletKeys.Wallet3.BTC.pools | % {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet3.BTC.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet3.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet3.BTC.address; Response = "" }
        }
    }
}

$Query | % {
    if ([string]$_.address -ne "") {
        try { $Response = Invoke-RestMethod "$PoolQuery$($_.address)/rigs" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
        Catch { Write-Warning "failed to contact $Name For $($_.Address) wallet Info"; $Response = $Null }
        $_.Response = $Response
    }
}

$Query | % {
    if ($_.Response) {
        $unpaid = 0
        $nhbalance = 0
        if ($_.Response.externalBalance -gt 0) { $nhbalance += $_.Response.externalBalance }
        if ($_.Response.unpaidAmount -gt 0) { $unpaid += $_.Response.unpaidAmount }
        Set-WStat -Name "$($Name)_$($_.Address)" -Symbol $_.symbol -address $_.address -balance $nhbalance -unpaid $unpaid
    }
}

