function Global:Add-Module($Path) {
    $name = $(Get-Item $Path).BaseName
    $A = Get-Module | Where Name -eq $name
    if (-not $A) { Import-Module -Name $Path -Scope Global }
    if ($name -notin $global:config.vars.modules) {
        $DoNotAdd = @("")
        $global:config.vars.modules += $Name 
    }
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


function Global:Get-Var([string]$X) { if($X) {$Global:Config.vars.$X} else {$global:Config.vars} }

function Global:Get-Param([string]$X) { if($X) {$global:Config.params.$X} else {$global:Config.Params} }

function Global:Build-Var([string]$X,$Y) {
    if($X -notin $Global:Config.vars.Active_Variables){ $Global:Config.vars.Active_Variables.Add($X) | Out-Null }
    $Global:Config.vars.Add($X,$Y)
}

function Global:Remove-Var([string]$X) {
    if($X -ne "all"){
        $Global:Config.vars.Remove($X)
        if($X -in $Global:Config.vars.Active_Variables){ $Global:Config.vars.Active_Variables.Remove($X) | Out-Null }
    } else {
        $Global:Config.vars.Active_Variables | ForEach-Object {
            $Global:Config.vars.Active_Variables.Remove($_)
        }
        $Global:Config.vars.Active_Variables = (New-Object System.Collections.ArrayList)
    }
}

function Global:Confirm-Var([string]$X){ if($Global:Config.vars.ContainsKey($X)){return $true} else{return $false}}

Set-Alias -Name vars -Value Global:Get-Var -Scope Global
Set-Alias -Name arg -Value Global:Get-Param -Scope Global
Set-Alias -Name build -Value Global:Build-Var -Scope Global
Set-Alias -Name remove -Value Global:Remove-Var -Scope Global
Set-Alias -Name check -Value Global:Confirm-Var -Scope Global
Set-Alias -Name Log -Value Global:Write-Log
