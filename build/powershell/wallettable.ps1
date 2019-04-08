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
function Get-WalletTable {

    if(Test-Path ".\wallet\values\*"){Remove-Item ".\wallet\values\*" -Force}

    $WalletKeys = [PSCustomObject]@{}
    Get-ChildItemContent ".\wallet\keys" | ForEach {$WalletKeys | Add-Member $_.Name $_.Content}

    if(Test-path ".\wallet\pools"){Get-ChildItemContent ".\wallet\pools"}

    $WalletTable = @()
    if (-not $GetWStats) {$GetWStats = get-wstats}

    $Sym = @()

    $GetWStats | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {
        $WalletTable += [PSCustomObject]@{
            Address        = $GetWStats.$_.Address
            Pool           = $GetWStats.$_.Pool
            Ticker         = $GetWStats.$_.Symbol
            Unpaid         = $GetWStats.$_.Unpaid -as [decimal]
            Balance        = $GetWStats.$_.Balance -as [decimal]
            "Last Checked" = $GetWStats.$_.Date
        }
        if($Sym -notcontains $GetWStats.$_.Symbol){$Sym += $GetWStats.$_.Symbol}
    }

    $Format = @()
    $Format += ""
    $WalletTable | %{
     $Format += "Address: $($_.Address)"
     $Format += "Pool: $($_.Pool)"
     $Format += "Ticker: $($_.Ticker)"
     $Format += "Unpaid: $($_.Unpaid)"
     $Format += "Balance: $($_.Balance)"
     $Format += "Last Checked: $($_."Last Checked")"
     $Format += ""
    }

    $Sym | %{
     $Grouping = $WalletTable | Where Ticker -eq $_
     $Total_Unpaid = 0
     $Total_Balace = 0
     $Grouping.Unpaid | %{$Total_Unpaid += $_ }
     $Grouping.Balance | %{$Total_Balance += $_ }

     $Format += ""
     $Format += "Total $($_) Unpaid = $Total_Unpaid"
     $Format += "Total $($_) Balance = $Total_Balance"
     $Format += "Total Current $($_) Profit = $([Decimal]$Total_Unpaid + [Decimal]$Total_Balance)"
     $Format += ""
    }

    $Format

}