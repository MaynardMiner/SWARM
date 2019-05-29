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

Function Get-WalletTable {
    param (
        [Parameter(Mandatory=$false)]
        [switch]$asjson
    )
    [cultureinfo]::CurrentCulture = 'en-US'
    if (Test-Path ".\wallet\values\*") { Remove-Item ".\wallet\values\*" -Force }
    
    $global:WalletKeys = [PSCustomObject]@{ }
    Get-ChildItemContent -Path ".\wallet\keys" | ForEach { $global:WalletKeys | Add-Member $_.Name $_.Content } 
    Get-ChildItemContent -Path ".\wallet\pools"

    $WalletTable = @()
    if (-not $GetWStats) { $GetWStats = get-wstats }

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
        if ($Sym -notcontains $GetWStats.$_.Symbol) { $Sym += $GetWStats.$_.Symbol }
    }

    if (-not $asjson) {
        $global:Format = @()
        $global:Format += ""
        $WalletTable | % {
            $global:Format += "Address: $($_.Address)"
            $global:Format += "Pool: $($_.Pool)"
            $global:Format += "Ticker: $($_.Ticker)"
            $global:Format += "Unpaid: $($_.Unpaid)"
            $global:Format += "Balance: $($_.Balance)"
            $global:Format += "Last Checked: $($_."Last Checked")"
            $global:Format += ""
        }

        $Sym | % {
            $Grouping = $WalletTable | Where Ticker -eq $_
            $Total_Unpaid = 0
            $Total_Balace = 0
            $Grouping.Unpaid | % { $Total_Unpaid += $_ }
            $Grouping.Balance | % { $Total_Balance += $_ }

            $global:Format += ""
            $global:Format += "Total $($_) Balance = $Total_Balance"
            $global:Format += "Total $($_) Unpaid = $Total_Unpaid (Reflects Current Total Potential Earnings)"
            $global:Format += ""
        }
        $global:Format
    }
    else {
        $Json = $WalletTable | ConvertTo-Json
        $Json
    }

}