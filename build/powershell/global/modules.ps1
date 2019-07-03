function Global:Add-LogErrors {
    if ($Error.Count -gt 0) {
        $TimeStamp = (Get-Date)
        $errormesage = "[$TimeStamp]: SWARM Generated The Following Warnings/Errors-"
        $errormesage | Add-Content $global:log_params.logname
        $Message = @()
        $error | foreach { $Message += "$($_.InvocationInfo.InvocationName)`: $($_.Exception.Message)"; $Message += $_.InvocationINfo.PositionMessage; $Message += $_.InvocationInfo.Line; $Message += $_.InvocationINfo.Scriptname; $MEssage += "" }
        $Message | Add-Content $global:log_params.logname
        $error.clear()
    }
}

function Global:Get-ChildItemContent {
    param(
        [Parameter(Mandatory = $false)]
        [String]$Path,
        [Parameter(Mandatory = $false)]
        [array]$Items
    )

    if ($Items) { $Child = $Items }
    else { $Child = Get-ChildItem $Path }

    $ChildItems = $Child | ForEach-Object {
        $Name = $_.BaseName
        $FullName = $_.FullName
        $Content = @()
        if ($_.Extension -eq ".ps1") {
            $Content = &$_.FullName
        }
        else {
            try { $Content = $_ | Get-Content | ConvertFrom-Json }catch { log "WARNING: Could Not Identify $FullName, It Is Corrupt- Remove File To Stop." -ForegroundColor Red }
        }
        $Content | ForEach-Object {
            [PSCustomObject]@{Name = $Name; Content = $_ }
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

    $AllContent = New-Object System.Collections.ArrayList
    $ChildItems | % { $AllContent.Add($_) | Out-Null }
    $AllContent
}

function Global:start-killscript {

    ##Clear-Screens In Case Of Restart
    $OpenScreens = @()
    $OpenScreens += "NVIDIA1"
    $OpenScreens += "NVIDIA2"
    $OpenScreens += "NVIDIA3"
    $OpenScreens += "AMD1"
    $OpenScreens += "AMD2"
    $OpenScreens += "AMD3"
    $OpenScreens += "CPU"
    $OpenScreens += "OC_AMD"
    $OpenScreens += "OC_NVIDIA1"
    $OpenScreens += "OC_NVIDIA2"
    $OpenScreens += "OC_NVIDIA3"
    $OpenScreens += "pill-NVIDIA1"
    $OpenScreens += "pill-NVIDIA2"
    $OpenScreens += "pill-NVIDIA3"
    $OpenScreens += "API"
    $OpenScreens | foreach {
        $Proc = Start-Process ".\build\bash\killall.sh" -ArgumentList $_ -PassThru
        $Proc | Wait-Process
    }
    $Proc = Start-Process ".\build\bash\killall.sh" -ArgumentList "background" -PassThru
    $Proc | Wait-Process
}

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
            $Global:Config.vars.Remove($_)
        }
        $Global:Config.vars.Active_Variables = (New-Object System.Collections.ArrayList)
    }
}

function Global:Write-Log {
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$In,
        [Parameter(Mandatory = $false)]
        [string]$ForeGroundColor,
        [Parameter(Mandatory = $false)]
        [string]$ForeGround,
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,
        [Parameter(Mandatory = $false)]
        [switch]$Start,
        [Parameter(Mandatory = $false)]
        [switch]$End
    )
    
    $Date = (Get-Date)
    $File = $global:log_params.logname

    if ($ForeGround) { $Color = $ForeGround }
    if ($ForeGroundColor) { $Color = $ForeGroundColor }

    if ($NoNewLine) {
        if ($Start) { Add-Content -Path $File -Value "[$Date]`: " -NoNewline }
        Add-Content -Path $file -Value "$In" -NoNewline
    } 
    else {
        if ($End) { Add-Content -Path $file -Value "$In" }
        else { Add-Content -Path $file -Value "[$Date]`: $In" }
    }


    if ($NoNewLine) {
        if ($ForeGroundColor -or $ForeGround) {
            if ($Start) { Write-Host "[$Date]`: " -NoNewline }
            Write-Host $In -ForeGroundColor $Color -NoNewline
        } 
        else {
            if ($Start) { Write-Host "[$Date]`: " -NoNewline }
            Write-Host $In -NoNewline
        }
    }
    else {
        if ($ForeGroundColor -or $ForeGround) {
            if ($End) { Write-Host "$In" -ForeGroundColor $Color }
            else {
                Write-Host "[$Date]`: " -NoNewline
                Write-Host "$In" -ForegroundColor $Color
            }
        }
        else {
            if ($End) { Write-Host "$In" }
            else {
                Write-Host "[$Date]`: " -NoNewline
                Write-Host "$In"
            }
        }
    }

}

function Global:Confirm-Var([string]$X){ if($Global:Config.vars.ContainsKey($X)){return $true} else{return $false}}

Set-Alias -Name vars -Value Global:Get-Var -Scope Global
Set-Alias -Name arg -Value Global:Get-Param -Scope Global
Set-Alias -Name create -Value Global:Build-Var -Scope Global
Set-Alias -Name remove -Value Global:Remove-Var -Scope Global
Set-Alias -Name check -Value Global:Confirm-Var -Scope Global
Set-Alias -Name log -Value Global:Write-Log -Scope Global
