$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolQuery = "https://nlpool.nl/api/wallet?address="

$Query = @()

$Global:WalletKeys.AltWallet1.PSObject.Properties.Name | ForEach-Object {
    if ($Global:WalletKeys.AltWallet1.$_.address -ne "" -and $Global:WalletKeys.AltWallet1.$_.Pools -contains $Name) {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.AltWallet1.$_.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.AltWallet1.$_.address)"; Symbol = $_; Address = $Global:WalletKeys.AltWallet1.$_.address; Response = "" }
        }
    }
    elseif ($Global:WalletKeys.Wallet1.BTC.address -ne "" -and $Global:WalletKeys.Wallet1.BTC.Pools -contains $Name) {
        $Global:WalletKeys.Wallet1.BTC.pools | ForEach-Object {
            if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet1.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet1.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet1.BTC.address; Response = "" }
            }
        }
    }    
}

$Global:WalletKeys.AltWallet2.PSObject.Properties.Name | ForEach-Object {
    if ($Global:WalletKeys.AltWallet2.$_.address -ne "" -and $Global:WalletKeys.AltWallet2.$_.Pools -contains $Name) {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.AltWallet2.$_.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.AltWallet2.$_.address)"; Symbol = $_; Address = $Global:WalletKeys.AltWallet2.$_.address; Response = "" }
        }
    }
    elseif ($Global:WalletKeys.Wallet2.BTC.address -ne "" -and $Global:WalletKeys.Wallet2.BTC.Pools -contains $Name) {
        $Global:WalletKeys.Wallet2.BTC.pools | ForEach-Object {
            if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet2.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet2.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet2.BTC.address; Response = "" }
            }
        }
    }    
}

$Global:WalletKeys.AltWallet3.PSObject.Properties.Name | ForEach-Object {
    if ($Global:WalletKeys.AltWallet3.$_.address -ne "" -and $Global:WalletKeys.AltWallet3.$_.Pools -contains $Name) {
        if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.AltWallet3.$_.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.AltWallet3.$_.address)"; Symbol = $_; Address = $Global:WalletKeys.AltWallet3.$_.address; Response = "" }
        }
    }
    elseif ($Global:WalletKeys.Wallet3.BTC.address -ne "" -and $Global:WalletKeys.Wallet3.BTC.Pools -contains $Name) {
        $Global:WalletKeys.Wallet3.BTC.pools | ForEach-Object {
            if ($Query.Name -notcontains "$($Name)_$($Global:WalletKeys.Wallet3.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($Global:WalletKeys.Wallet3.BTC.address)"; Symbol = "BTC"; Address = $Global:WalletKeys.Wallet3.BTC.address; Response = "" }
            }
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
   