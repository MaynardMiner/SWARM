function Set-Countdown {
    if ($global:Config.Params.SWARM_Mode -eq "Yes" -and $global:BenchmarkMode -eq $false) { $CountDown = Invoke-SWARMMode $global:SwitchTime; $CountDown = $Countdown * -1 }
    else { $Countdown = ([math]::Round(($global:MinerInterval - 20) - $global:MinerWatch.Elapsed.TotalSeconds)) }
    if ($global:Config.Params.SWARM_Mode -eq "Yes" -and $global:BenchmarkMode -eq $false) { $CountMessage = "SWARM Mode Starts: $($Countdown) seconds" }
    else { $CountMessage = "Time Left Until Database Starts: $($Countdown) seconds" }
    Write-Log "$CountMessage 
"-foreground DarkMagenta
}

function Invoke-SwarmMode {

    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [datetime]$SwarmMode_Start,
        [Parameter(Position = 1, Mandatory = $false)]
        [int]$ModeDeviation = 5
    )

    $DateMinute = [Int]$SwarmMode_Start.Minute + $ModeDeviation
    $DateMinute = ([math]::Floor(($DateMinute / $ModeDeviation)) * $ModeDeviation)
    if ($DateMinute -gt 59) { $DateMinute = 0; $DateHour = [Int]$SwarmMode_Start.Hour; $DateHour = [int]$DateHour + 1 }else { $DateHour = [Int]$SwarmMode_Start.Hour; $DateHour = [int]$DateHour }
    if ($DateHour -gt 23) { $DateHour = 0; $DateDay = [Int]$SwarmMode_Start.Day; $DateDay = [int]$DateDay + 1 }else { $DateDay = [Int]$SwarmMode_Start.Day; $DateDay = [int]$DateDay }
    if ($DateDay -gt 31) { $DateDay = 1; $DateMonth = [Int]$SwarmMode_Start.Month; $DateMonth = [int]$DateMonth + 1 }else { $DateMonth = [Int]$SwarmMode_Start.Month; $DateMonth = [int]$DateMonth }
    if ($DateMonth -gt 12) { $DateMonth = 1; $DateYear = [Int]$SwarmMode_Start.Year; $DateYear = [int]$DateYear + 1 }else { $DateYear = [Int]$SwarmMode_Start.Year; $DateYear = [int]$DateYear }
    $ReadyValue = (Get-Date -Year $DateYear -Month $DateMonth -Day $DateDay -Hour $DateHour -Minute $DateMinute -Second 0 -Millisecond 0)
    $StartValue = [math]::Round((([DateTime](Get-Date)) - $ReadyValue).TotalSeconds)
    $StartValue
}

function Restart-Miner {
    Import-Module "$global:Control\run.psm1"
    Start-NewMiners -Reason "Restart"
    Remove-Module -Name "run"
}


function Start-MinerLoop {
    Get-Job -State Completed | Remove-Job
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
    Do {
        Set-Countdown
        Get-MinerHashRate
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:MinerWatch.Elapsed.TotalSeconds -ge ($global:MinerInterval - 20)) { break }
        Set-Countdown
        Get-MinerHashRate
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:MinerWatch.Elapsed.TotalSeconds -ge ($global:MinerInterval - 20)) { break }
        Set-Countdown
        Restart-Miner
        write-Log "

  Type 'get stats' in a new terminal to view miner statistics- This IS a remote command!
        Windows Users: Open cmd.exe or SWARM TERMINAL on desktop and enter command
    https://github.com/MaynardMiner/SWARM/wiki/Commands-&-Suggested-Apps for more info.

" -foreground Magenta
        Get-MinerHashRate
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:MinerWatch.Elapsed.TotalSeconds -ge ($global:MinerInterval - 20)) { break }
        Set-Countdown
        Get-MinerHashRate
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:MinerWatch.Elapsed.TotalSeconds -ge ($global:MinerInterval - 20)) { break }
        Set-Countdown
        Restart-Miner
        Get-MinerHashRate
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:MinerWatch.Elapsed.TotalSeconds -ge ($global:MinerInterval - 20)) { break }
        Set-Countdown
        write-Log "

  Type 'get active' in a new terminal to view all active miner details- This IS a remote command!
          Windows Users: Open cmd.exe or SWARM TERMINAL on desktop and enter command
       https://github.com/MaynardMiner/SWARM/wiki/Commands-&-Suggested-Apps for more info.
      
" -foreground Magenta
        Get-MinerHashRate
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:SWARM_IT) { $global:ModeCheck = Invoke-SWARMMode $global:SwitchTime }
        if ($global:ModeCheck -gt 0) { break }
        Start-Sleep -s 5
        if ($global:MinerWatch.Elapsed.TotalSeconds -ge ($global:MinerInterval - 20)) { break }

    }While ($global:MinerWatch.Elapsed.TotalSeconds -lt ($global:MinerInterval - 20))
}