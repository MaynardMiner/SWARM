function Start-Background {
  
    $BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
    $command = Start-Process "pwsh" -WorkingDirectory "$($global:Dir)\build\powershell" -ArgumentList "-executionpolicy bypass -NoExit -windowstyle minimized -command `"&{`$host.ui.RawUI.WindowTitle = `'Background Agent`'; &.\Background.ps1 -WorkingDir `'$($global:Dir)`'}`"" -WindowStyle Minimized -PassThru -Verb Runas
    $command.ID | Set-Content ".\build\pid\background_pid.txt"
    $BackgroundTimer.Restart()
    do {
        Start-Sleep -S 1
        write-log "Getting Process ID for Background Agent"
        $ProcessId = if (Test-Path ".\build\pid\background_pid.txt") {Get-Content ".\build\pid\background_pid.txt"}
        if ($ProcessID -ne $null) {$Process = Get-Process $ProcessId -ErrorAction SilentlyContinue}
    }until($ProcessId -ne $null -or ($BackgroundTimer.Elapsed.TotalSeconds) -ge 10)  
    $BackgroundTimer.Stop()
}

function Set-NewPath {
    param (
     [Parameter(Mandatory=$true,Position=0)]
     [string]$Action,
     [Parameter(Mandatory=$true,Position=1)]
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


function Start-AgentCheck {

    $Global:dir | Set-Content ".\build\cmd\dir.txt"

    ##Get current path envrionments
    $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path

    ##First remove old Paths, in case this is an update / new dir
    $oldpathlist = "$oldpath" -split ";"
    $oldpathlist | ForEach-Object { if ($_ -like "*SWARM*" -and $_ -notlike "*$($global:dir)\build\cmd*" ) { Set-NewPath "remove" "$($_)" } }

    if ($oldpath -notlike "*;$($global:dir)\build\cmd*") {
        write-Log "
Setting Path Variable For Commands: May require reboot to use.
" -ForegroundColor Yellow
        $newpath = "$global:dir\build\cmd"
        Set-NewPath "add" $newpath
    }
    $newpath = "$oldpath;$($global:dir)\build\cmd"
    write-Log "Stopping Previous Agent"
    $ID = ".\build\pid\background_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    $ID = ".\build\pid\pill_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }    
}


