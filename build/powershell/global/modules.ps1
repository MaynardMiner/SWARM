function Global:Using-Object
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock
    )

    try
    {
        . $ScriptBlock
    }
    finally
    {
        if ($null -ne $InputObject -and $InputObject -is [System.IDisposable])
        {
            $InputObject.Dispose()
        }
    }
}

function Global:Add-LogErrors {
    if ($Error.Count -gt 0) {
        $TimeStamp = (Get-Date)
        $errormesage = "[$TimeStamp]: SWARM Generated The Following Warnings/Errors-"
        $errormesage | Add-Content $global:log_params.logname
        $Message = @()
        $error | ForEach-Object { $Message += "$($_.InvocationInfo.InvocationName)`: $($_.Exception.Message)"; $Message += $_.InvocationINfo.PositionMessage; $Message += $_.InvocationInfo.Line; $Message += $_.InvocationINfo.Scriptname; $MEssage += "" }
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
    $ChildItems = @();
    $Child | ForEach-Object {
        $Name = $_.BaseName
        $FullName = $_.FullName
        if ($_.Extension -eq ".ps1") {
            $Runspace = [runspacefactory]::CreateRunspace();
            $Runspace.Open();
            $PowerShell = [powershell]::Create()
            $PowerShell.runspace = $Runspace
            $Script_Content = [IO.File]::ReadAllText($_.FullName);
            $script = [Scriptblock]::Create($Script_Content);
            $Runspace.SessionStateProxy.SetVariable("Wallets", $Global:Wallets);
            $Runspace.SessionStateProxy.SetVariable("Config", $Global:Config);
            $Runspace.SessionStateProxy.SetVariable("log_params", $Global:log_params);
            $Runspace.SessionStateProxy.SetVariable("Name", $Name);
            $Runspace.SessionStateProxy.SetVariable("WalletKeys",$Global:WalletKeys);
            $Runspace.SessionStateProxy.Path.SetLocation($env:SWARM_DIR) | Out-Null;
            $handle = $PowerShell.AddScript($script).BeginInvoke();
            While (!$handle.IsCompleted) {
                Start-Sleep -Milliseconds 200
            }
            $Content = $PowerShell.EndInvoke($handle);
            if ($Powershell.Streams.Error) {
                foreach ($e in $PowerShell.Streams.Error) {
                    log "
$($e.Exception.Message)
$($e.InvocationInfo.PositionMessage)
    | Category: $($e.CategoryInfo.Category)     | Activity: $($e.CategoryInfo.Activity)
    | Reason: $($e.CategoryInfo.Reason)     | Runspace: $FullName
    | Target Name: $($e.CategoryInfo.TargetName)    | Target Type: $($e.CategoryInfo.TargetType)
" -ForeGround Red; 
                }
            }
            $PowerShell.Dispose();
            $Runspace.Close();
            $Runspace.Dispose();
            if ($Content.Count -gt 0) {
                if ($Content[0].GetType() -eq [string]) {
                    foreach($item in $Content) {
                        log $item -ForeGroundColor Yellow;
                    }
                    $Content.Clear();
                }
            }
        }
        else {
            try { $Content = $_ | Get-Content | ConvertFrom-Json }catch { log "WARNING: Could Not Identify $FullName, It Is Corrupt- Remove File To Stop." -ForegroundColor Red }
        }
        $Content | ForEach-Object {
            $ChildItems += [PSCustomObject]@{Name = $Name; Content = $_ }
        }
    }

    $AllContent = New-Object System.Collections.ArrayList
    $ChildItems | ForEach-Object { $AllContent.Add($_) | Out-Null }
    $AllContent
}

function Global:start-killscript {

    ## Get Processes That Could Be Running:
    $To_Kill = @()
    if (test-path ".\build\pid") {
        $Miner_PIDs = Get-ChildItem ".\build\pid" | Where-Object BaseName -like "*info*"
        if ($Miner_PIDs) {
            $Miner_PIDs | ForEach-Object {
                $Content = Get-Content $_ | ConvertFrom-Json
                $Name = Split-Path $Content.miner_exec -Leaf
                $To_Kill += Get-Process | Where-Object Id -eq $Content.pid | Where-Object Name -eq $Name
            }
        }
    }

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

    ## Send CTRL+C to all screens
    $OpenedScreens = @()
    $GetScreens = (invoke-expression "screen -ls" | Select-String $OpenScreens).Line
    foreach ($screen in $OpenScreens) { 
        $GetScreens | ForEach-Object { 
            if ($_ -like "*$screen*") { 
                $OpenedScreens += $screen 
            }
        }
    }
    foreach ($screen in $OpenedScreens) { 
        $Proc = Start-Process "screen" -ArgumentList "-S $screen -X stuff `^C" -PassThru
        $Proc | Wait-Process
    }

    ## Wait For Process To Exit
    $Time = 0;
    do {
        $Time++
        Write-Host "Waiting For Processes To Close"
        Start-Sleep -S 1
    }until(
        $false -notin $To_Kill.HasExited -or
        $Time -gt 10
    )

    ## See which screens are still open
    $OpenedScreens = @()
    $GetScreens = (invoke-expression "screen -ls" | Select-String $OpenScreens).Line
    foreach ($screen in $OpenScreens) { 
        $GetScreens | ForEach-Object { 
            if ($_ -like "*$screen*") { 
                $OpenedScreens += $screen 
            }
        }
    }

    ## Close those screens
    foreach ($screen in $OpenedScreens) {
        $Proc = Start-Process "screen" -ArgumentList "-S $screen -X quit" -PassThru
        $Proc | Wait-Process
    }
    
    <# Reset Hugepages #>
    if (test-path "/hive/bin") {
        <# Is HiveOS #>
        Invoke-expression "hugepages -r";
    }

    ## Close background
    Invoke-Expression "screen -S background -X quit"
}

function Global:Add-Module($Path) {
    $name = $(Get-Item $Path).BaseName
    $A = Get-Module | Where-Object Name -eq $name
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
            $global:config.vars.modules = $global:config.vars.modules | Where-Object { $_ -ne $name }
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


function Global:Get-Vars([string]$X) { if ($X) { $Global:Config.vars.$X } else { $global:Config.vars } }

function Global:Get-Args([string]$X) { if ($X) { $global:Config.params.$X } else { $global:Config.Params } }

function Global:Build-Vars([string]$X, $Y) {

    if ($X -notin $Global:Config.vars.Active_Variables) { $Global:Config.vars.Active_Variables.Add($X) | Out-Null }
    if (-not $Global:Config.vars.ContainsKey($X)) { $Global:Config.vars.Add($X, $Y) }

}
function Global:Confirm-Vars([string]$X) { if ($Global:Config.vars.ContainsKey($X)) { return $true } else { return $false } }

Set-Alias -Name vars -Value Global:Get-Vars -Scope Global
Set-Alias -Name arg -Value Global:Get-Args -Scope Global
Set-Alias -Name create -Value Global:Build-Vars -Scope Global
Set-Alias -Name remove -Value Global:Remove-Vars -Scope Global
Set-Alias -Name check -Value Global:Confirm-Vars -Scope Global
Set-Alias -Name log -Value Global:Write-Log -Scope Global

function Global:Remove-Vars([string]$X) {
    if ($X -ne "all") {
        if (check $X) { $Global:Config.vars.Remove($X) }
        if ($X -in $Global:Config.vars.Active_Variables) { $Global:Config.vars.Active_Variables.Remove($X) | Out-Null } 
    }
    else {
        $Global:Config.vars.Active_Variables | ForEach-Object { if (check $_) { $Global:Config.vars.Remove($_) } }
        $Global:Config.vars.Active_Variables = (New-Object System.Collections.ArrayList)
    }
}


Set-Alias -Name remove -Value Global:Remove-Vars -Scope Global
Set-Alias -Name check -Value Global:Confirm-Vars -Scope Global
Set-Alias -Name log -Value Global:Write-Log -Scope Global

Class Expression {
    static [string] Invoke([string]$command, [string]$arguments) {
        $output = [string]::Empty;
        $Proc = [System.Diagnostics.Process]::New();
        $Proc.StartInfo.FileName = $command;
        $Proc.StartInfo.Arguments = "$arguments";
        $Proc.StartInfo.CreateNoWindow = $true;
        $Proc.StartInfo.UseShellExecute = $false;
        $Proc.StartInfo.RedirectStandardOutput = $true;
        $Proc.StartInfo.RedirectStandardError = $true;
        $Proc.Start() | Out-Null;
        while (-not $Proc.StandardOutput.EndOfStream -or -not $Proc.StandardError.EndOfStream) {
            if ($Proc.StandardOutput.Peek() -gt -1) {
                $output += "$($Proc.StandardOutput.ReadLine())`n";
            }
            if ($Proc.StandardError.Peek() -gt -1) {
                $output += "$($Proc.StandardError.ReadLine())`n";
            }
        }    
        $Proc.WaitForExit();
        return $output;
    }
}