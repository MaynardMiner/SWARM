## Sample Usage:
## .\runtimes.ps1 08:00 17:30

## Allows SWARM to only run between those times. Will check every 5 minutes
## It will stop SWARM, and start SWARM when required.

## Linux requires install_linux (if not HiveOS) for commands to be installed.
## Windows requires SWARM to have ran at least once for commands to be installed.

## Keep file in main directory of SWARM. Should be ran while in main directory of SWARM

param($start_hour, $stop_hour)

While ($True) {
    ##$min = Get-Date '08:00'
    ##$max = Get-Date '17:30'
    $min = Get-Date "$start_hour"
    $max = Get-Data "$stop_hour"

    $should_run = $false

    $now = Get-Date

    if ($min.TimeOfDay -le $now.TimeOfDay -and $max.TimeOfDay -ge $now.TimeOfDay) {
        $should_run = $true
    }

    ## Check for swarm
    if (test-path ".\build\pid\miner_pid.txt") {
        $SWARM_PID = Get-Content ".\build\pid\miner_pid.txt"
        $SWARM_Process = Get-Process | Where id -eq $SWARM_PID
        if ($SWARM_Process) {
            ## Check if it should be running
            if(-not $should_run) {
                invoke-expression 'miner stop'
            }
        }
        elseif($should_run) {
            Invoke-Expression 'miner start'
        }
    }
    elseif($should_run) {
        Invoke-Expression 'miner start'
    }
    elseif(-not $should_run) {
        ## Stop just in case..Does nothing if not running
        Invoke-Expression 'miner stop'
    }

    Start-Sleep -S 300
}