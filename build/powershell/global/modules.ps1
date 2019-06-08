function Global:Add-Module($Path) {
    $name = $(Get-Item $Path).BaseName
    $A = Get-Module | Where Name -eq $name
    if (-not $A) { Import-Module -Name $Path -Scope Global }
    if ($name -notin $global:config.vars.modules) { $global:config.vars.modules += $Name }
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
            $global:config.vars.modules = $global:config.vars.modules | where {$_ -ne $name}
        }
    }
    else {
        $global:config.vars.modules | ForEach-Object {
            $Sel = $_
            if ($Sel -in $mods) {
                Remove-Module -Name "$Sel"
            }
        }
        $global:config.vars.modules = @()
    }
}

function Global:variable($X) { if($X) {$Global:Config.vars.$X} else {$global:Config.vars} }
function Global:params($X) { if($X) {$global:Config.params.$X} else {$global:Config.Params} }
Set-Alias -Name vars -Value global:variable -Scope Global
Set-Alias -Name arg -Value global:params -Scope Global
Set-Alias -Name Log -Value Global:Write-Log