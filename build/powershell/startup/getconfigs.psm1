function Global:Start-Background {
  
    $BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
    $command = Start-Process "pwsh" -WorkingDirectory "$($(vars).dir)\build\powershell\scripts" -ArgumentList "-executionpolicy bypass -NoExit -windowstyle minimized -command `"&{`$host.ui.RawUI.WindowTitle = `'Background Agent`'; &.\Background.ps1 -WorkingDir `'$($(vars).dir)`'}`"" -WindowStyle Minimized -PassThru -Verb Runas
    $command.ID | Set-Content ".\build\pid\background_pid.txt"
    $BackgroundTimer.Restart()
    do {
        Start-Sleep -S 1
        log "Getting Process ID for Background Agent"
        $ProcessId = if (Test-Path ".\build\pid\background_pid.txt") { Get-Content ".\build\pid\background_pid.txt" }
        if ($ProcessID -ne $null) { $Process = Get-Process $ProcessId -ErrorAction SilentlyContinue }
    }until($ProcessId -ne $null -or ($BackgroundTimer.Elapsed.TotalSeconds) -ge 10)  
    $BackgroundTimer.Stop()
}

function Global:Set-NewPath {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Action,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Addendum
    )

    $regLocation = 
    "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"
    $path = (Get-ItemProperty -Path $regLocation -Name PATH).path

    # Add an item to PATH
    if ($action -eq "add") {
        $path = "$path;$addendum"
        Set-ItemProperty -Path $regLocation -Name PATH -Value $path
    }

    # Remove an item from PATH
    if ($action -eq "remove") {
        $path = ($path.Split(';') | Where-Object { $_ -ne "$addendum" }) -join ';'
        Set-ItemProperty -Path $regLocation -Name PATH -Value $path
    }

}


function Global:Start-AgentCheck {

    $($(vars).dir) | Set-Content ".\build\cmd\dir.txt"

    ##Get current path envrionments
    $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path

    ##First remove old Paths, in case this is an update / new dir
    $oldpathlist = "$oldpath" -split ";"
    $oldpathlist | ForEach-Object { if ($_ -like "*SWARM*" -and $_ -notlike "*$($(vars).dir)\build\cmd*" ) { Global:Set-NewPath "remove" "$($_)" } }

    if ($oldpath -notlike "*;$($(vars).dir)\build\cmd*") {
        log "
Setting Path Variable For Commands: May require reboot to use.
" -ForegroundColor Yellow
        $newpath = "$($(vars).dir)\build\cmd"
        Global:Set-NewPath "add" $newpath
    }
    $newpath = "$oldpath;$($(vars).dir)\build\cmd"
    log "Stopping Previous Agent"
    $ID = ".\build\pid\background_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    $ID = ".\build\pid\pill_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    log "Stopping Previous Autofan"
    $ID = ".\build\pid\autofan.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }       
}


function Global:Get-Optional {
    Get-ChildItem ".\miners\optional_and_old" | Where BaseName -in $(arg).Optional | ForEach-Object {
        $Path = $_.FullName
        $FileType = Get-Content $Path
        if ( $FileType[0] -like "*`$(vars).AMDTypes*" ) {
            $CheckA = Join-Path "$($(vars).dir)\miners\gpu\amd" $_.Name
            if (-not (Test-Path $CheckA)) { Move-Item -Path $Path -Destination ".\miners\gpu\amd" }
        }
        if ( $FileType[0] -like "*`$(vars).NVIDIATypes*" ) {
            $CheckN = Join-Path "$($(vars).dir)\miners\gpu\nvidia" $_.Name
            if (-not (Test-Path $CheckN)) { Move-Item -Path $Path -Destination ".\miners\gpu\nvidia" }
        }
    }
    ## Move Out Additional Miners
    if ($IsLinux) {
        $AMD = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json 
        $AMD = $AMD | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Where { $AMD.$_.optional -eq "Yes" } | % { $AMD.$_ }
        $NVIDIA = Get-Content ".\config\update\nvidia-linux.json" | ConvertFrom-Json
        $NVIDIA = $NVIDIA | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Where { $NVIDIA.$_.optional -eq "Yes" } | % { $NVIDIA.$_ }
    }
    else {
        $AMD = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json
        $AMD = $AMD | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Where { $AMD.$_.optional -eq "Yes" } | % { $AMD.$_ }
        $NVIDIA = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json
        $NVIDIA = $NVIDIA | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Where { $NVIDIA.$_.optional -eq "Yes" } | % { $NVIDIA.$_ }
    }
    ##AMD
    if ($(arg).Type -like "*AMD*") {
        $list = Get-ChildItem ".\miners\gpu\amd"
        $AMD | ForEach-Object {
            if ($_.Name -in $list.basename -and $_.Name -notin $(arg).optional) {
                Write-Log "Found $($_.Name) in active miner folder, not specified in -optional parameter, moving to optional_and_old" -ForegroundColor Yellow
                $file = $List | Where BaseName -eq $($_.Name)
                Move-Item -path $file -Destination ".\miners\optional_and_old\$($_.Name).ps1" -Force
            }
        }
    }
    ##NVIDIA
    if ($(arg).Type -like "*NVIDIA*") {
        $list = Get-ChildItem ".\miners\gpu\nvidia"
        $NVIDIA | ForEach-Object {
            if ($_.Name -in $list.basename -and $_.Name -notin $(arg).optional) {
                Write-Log "Found $($_.Name) in active miner folder, not specified in -optional parameter, moving to optional_and_old" -ForegroundColor Yellow
                $file = $List | Where BaseName -eq $($_.Name)
                Move-Item -path $file -Destination ".\miners\optional_and_old\$($_.Name).ps1" -Force
            }
        }
    }
}