. .\build\powershell\childitems.ps1
. .\build\powershell\statcommand.ps1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolQuery = "https://zpool.ca/api/wallet?address="

$Query = @()

$WalletKeys.AltWallet1.PSObject.Properties.Name | ForEach-Object {
    if ($WalletKeys.AltWallet1.$_.Pools -contains $Name) {
        if ($Query.Name -notcontains "$($Name)_$($WalletKeys.AltWallet1.$_.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.AltWallet1.$_.address)"; Symbol = $_; Address = $WalletKeys.AltWallet1.$_.address; Response = ""}
        }
    }
    elseif ($WalletKeys.Wallet1.BTC.Pools -contains $Name) {
        $WalletKeys.Wallet1.BTC.pools | % {
            if ($Query.Name -notcontains "$($Name)_$($WalletKeys.Wallet1.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.Wallet1.BTC.address)"; Symbol = "BTC"; Address = $WalletKeys.Wallet1.BTC.address; Response = ""}
            }
        }
    }    
}

$WalletKeys.AltWallet2.PSObject.Properties.Name | ForEach-Object {
    if ($WalletKeys.AltWallet2.$_.Pools -contains $Name) {
        if ($Query.Name -notcontains "$($Name)_$($WalletKeys.AltWallet2.$_.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.AltWallet2.$_.address)"; Symbol = $_; Address = $WalletKeys.AltWallet2.$_.address; Response = ""}
        }
    }
    elseif ($WalletKeys.Wallet2.BTC.Pools -contains $Name) {
        $WalletKeys.Wallet2.BTC.pools | % {
            if ($Query.Name -notcontains "$($Name)_$($WalletKeys.Wallet2.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.Wallet2.BTC.address)"; Symbol = "BTC"; Address = $WalletKeys.Wallet2.BTC.address; Response = ""}
            }
        }
    }    
}

$WalletKeys.AltWallet3.PSObject.Properties.Name | ForEach-Object {
    if ($WalletKeys.AltWallet3.$_.Pools -contains $Name) {
        if ($Query.Name -notcontains "$($Name)_$($WalletKeys.AltWallet3.$_.address)") {
            $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.AltWallet3.$_.address)"; Symbol = $_; Address = $WalletKeys.AltWallet3.$_.address; Response = ""}
        }
    }
    elseif ($WalletKeys.Wallet3.BTC.Pools -contains $Name) {
        $WalletKeys.Wallet3.BTC.pools | % {
            if ($Query.Name -notcontains "$($Name)_$($WalletKeys.Wallet3.BTC.address)") {
                $Query += [PSCustomObject]@{Name = "$($Name)_$($WalletKeys.Wallet3.BTC.address)"; Symbol = "BTC"; Address = $WalletKeys.Wallet3.BTC.address; Response = ""}
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
