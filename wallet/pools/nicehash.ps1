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

