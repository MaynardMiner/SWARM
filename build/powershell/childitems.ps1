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

function Get-ChildItemContent {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    $ChildItems = Get-ChildItem $Path | ForEach-Object {
        $Name = $_.BaseName
        $FullName = $_.FullName
        $Content = @()
        if ($_.Extension -eq ".ps1") {
            $Content = &$_.FullName
        }
        else {
            try{$Content = $_ | Get-Content | ConvertFrom-Json}catch{Write-Host "Warning: Could Not Identify $FullName- Remove to stop this error" -ForegroundColor Red}
        }
        $Content | ForEach-Object {
            [PSCustomObject]@{Name = $Name; Content = $_}
        }
    }

    $ChildItems | ForEach-Object {
        $Item = $_
        $ItemKeys = $Item.Content.PSObject.Properties.Name.Clone()
        $ItemKeys | ForEach-Object {
            if ($Item.Content.$_ -is [String]) {
                $Item.Content.$_ = Invoke-Expression "`"$($Item.Content.$_)`""
            }
            elseif ($Item.Content.$_ -is [PSCustomObject]) {
                $Property = $Item.Content.$_
                $PropertyKeys = $Property.PSObject.Properties.Name
                $PropertyKeys | ForEach-Object {
                    if ($Property.$_ -is [String]) {
                        $Property.$_ = Invoke-Expression "`"$($Property.$_)`""
                    }
                }
            }
        }
    }

    [System.Collections.ArrayList]$AllContent = $ChildItems | %{$_};
    $AllContent
}

function Get-Combination {
    param(
        [Parameter(Mandatory = $true)]
        [Array]$Value,
        [Parameter(Mandatory = $false)]
        [Int]$SizeMax = $Value.Count,
        [Parameter(Mandatory = $false)]
        [Int]$SizeMin = 1
    )

    $Combination = [PSCustomObject]@{}

    for ($i = 0; $i -lt $Value.Count; $i++) {
        $Combination | Add-Member @{[Math]::Pow(2, $i) = $Value[$i]}
    }

    $Combination_Keys = $Combination | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

    for ($i = $SizeMin; $i -le $SizeMax; $i++) {
        $x = [Math]::Pow(2, $i) - 1

        while ($x -le [Math]::Pow(2, $Value.Count) - 1) {
            [PSCustomObject]@{Combination = $Combination_Keys | Where-Object {$_ -band $x} | ForEach-Object {$Combination.$_}}
            $smallest = ($x -band - $x)
            $ripple = $x + $smallest
            $new_smallest = ($ripple -band - $ripple)
            $ones = (($new_smallest / $smallest) -shr 1) - 1
            $x = $ripple -bor $ones
        }
    }
}    