function Global:Add-Module($Path) {
    $name = $(Get-Item $Path).BaseName
    $A = Get-Module | Where Name -eq $name
    if (-not $A) { Import-Module -Name $Path -Scope Global }
    if ($name -notin $global:Config.var.modules) { $global:Config.var.modules += $Name }
}

function Global:Remove-Modules {
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$Path = $Null
    )

    $Mods = $(Get-Module).Name

    if ($Path) {
        $name = $(Get-Item $Path).BaseName
        if ($Name -in $mods) {
            Remove-Module -Name $name
            $global:Config.var.modules = $global:Config.var.modules | where {$_ -ne $name}
        }
    }
    else {
        $global:Config.var.modules | ForEach-Object {
            $Sel = $_
            if ($Sel -in $mods) {
                Remove-Module -Name "$Sel"
            }
        }
        $global:Config.var.modules = @()
    }
}

function global:variable($X) { if($X) {$Global:Config.var.$X} else {$global:Config.var} }
Set-Alias -Name v -Value global:variable -Scope Global
