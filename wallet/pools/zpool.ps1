<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolQuery = "https://zpool.ca/api/wallet?address="

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
