function Add-Module($Path) {
    $name = $(Get-Item $Path).BaseName
    $A = Get-Module | Where Name -eq $name
    if (-not $A) { Import-Module -Name $Path }
    if ($name -notin $global:Modules) { $global:Modules += $Name }
}

function Remove-Modules {
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$Path = $Null
    )

    $Mods = $(Get-Module).Name

    if ($Path) {
        $name = $(Get-Item $Path).BaseName
        if ($Name -in $mods) {
            Remove-Module -Name $name
            $global:Modules = $global:Modules | where {$_ -ne $name}
        }
    }
    else {
        $global:Modules | ForEach-Object {
            $Sel = $_
            if ($Sel -in $mods) {
                Remove-Module -Name "$Sel"
            }
        }
        $global:Modules = @()
    }
}