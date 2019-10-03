<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

function Global:Invoke-SwarmMode {

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

function Global:Set-Countdown {
    if ($(arg).SWARM_Mode -eq "Yes" -and $(vars).BenchmarkMode -eq $false) { 
        $CountDown = Global:Invoke-SWARMMode $global:SwitchTime; $CountDown = $Countdown * -1 
        $CountMessage = "SWARM Mode Starts: $($Countdown) seconds"
    }
    else { 
        $Countdown = ([math]::Round(($(vars).MinerInterval - 20) - $(vars).MinerWatch.Elapsed.TotalSeconds)) 
        $CountMessage = "Time Left Until Database Starts: $($Countdown) seconds"
    }
    log "$CountMessage 
"-foreground DarkMagenta
}

function Global:Restart-Miner {
    Import-Module "$($(vars).control)\run.psm1"
    Global:Start-NewMiners -Reason "Restart"
    Remove-Module -Name "run"
}

function Global:Start-Timer {
    $i = 0;
    do {
        if ($(vars).SWARM_IT) { $(vars).ModeCheck = Global:Invoke-SWARMMode $global:SwitchTime }
        if ($(vars).ModeCheck -gt 0) { $global:continue = $false }
        if ($(vars).MinerWatch.Elapsed.TotalSeconds -ge ($(vars).MinerInterval - 20)) { $global:continue = $false }
        Start-Sleep -S 1
        $i++
    }until($i -ge 15 -or $global:continue -eq $false)
}

function Global:Get-MinerChart {
    log "
    
Current Miners:
"

    $(vars).BestActiveMiners | ForEach-Object {
        $Rj = "$(Get-Rejections -Type $_.Type)"
        $Percent = $RJ -split "`:" | Select-Object -First 1
        $Shares = $RJ -split "`:" | Select-Object -Last 1

        log "Miner: " -foreground Green -NoNewLine -Start
        log "$($_.MinerName)" -End
        log "Rejection Percent: " -foreground Red -NoNewLine -Start
        log "$([math]::Round($Percent,0))" -End
        log "Total Shares: " -foregroundcolor Yellow -NoNewLine -Start
        log "$Shares" -End
        log "Current Screen: " -foreground Cyan -NoNewLine -Start
        log "$($_.Type) (Run `'screen -r $($_.Type)`' To View Active Mining Screen)" -End
        log "Arguments: " -foreground Magenta -NoNewLine -Start
        log "$($_.Arguments)" -End
        Write-Host ""
    }

}

function Global:Start-MinerLoop {
    $global:continue = $true
    Do {
        ## Step 1 0 sec
        Global:Set-Countdown
        Global:Get-MinerHashRate
        Global:Start-Timer
        if ($global:continue -eq $false) { break }

        ## Step 2 15 sec
        log "

    Type 'get stats' in a new terminal to view miner statistics- This IS a remote command!
        Windows Users: Open cmd.exe or SWARM TERMINAL on desktop and enter command
    https://github.com/MaynardMiner/SWARM/wiki/Commands-&-Suggested-Apps for more info.
        
        " -foreground Magenta        
        Global:Set-Countdown
        Global:Get-MinerHashRate
        Global:Start-Timer
        if ($global:continue -eq $false) { break }

        ## Step 3 30 sec
        Global:Set-Countdown
        Global:Restart-Miner
        Global:Get-MinerHashRate
        Global:Start-Timer
        if ($global:continue -eq $false) { break }

        ## Step 4 45 sec
        log "

    Type 'get active' in a new terminal to view miner launch commands- This IS a remote command!
            Windows Users: Open cmd.exe or SWARM TERMINAL on desktop and enter command
       https://github.com/MaynardMiner/SWARM/wiki/Commands-&-Suggested-Apps for more info.
        " -foreground Magenta        
        Global:Set-Countdown
        Global:Get-MinerHashRate
        Global:Start-Timer
        if ($global:continue -eq $false) { break }

        ## Step 12 60 sec
        Global:Set-Countdown
        Global:Restart-Miner
        Global:Get-MinerChart
        Global:Start-Timer
        if ($global:continue -eq $false) { break }
    }While ($(vars).MinerWatch.Elapsed.TotalSeconds -lt ($(vars).MinerInterval - 20))
}