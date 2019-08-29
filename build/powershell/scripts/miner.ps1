[cultureinfo]::CurrentCulture = 'en-US'
$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp","/root"
Set-Location $dir

$Trigger = $args
$Id = if(Test-Path ".\build\pid\miner_pid.txt"){cat ".\build\pid\miner_pid.txt"}

Switch($Args) {
    "restart" {
        if($Id) {
            Write-Host "Searching for SWARM Process ID $ID"
            $Found = Get-Process -Id $Id -ErrorAction SilentlyContinue
            if($found) {
                Write-Host "Found running SWARM process- Stopping"
                Stop-Process -Id $Found.Id -Force -ErrorAction SilentlyContinue
            } else { Write-Host "Could not find running SWARM Process"}      
            Write-Host "Starting SWARM"      
            Start-Process ".\SWARM.bat"
        } else {Write-Host "No SWARM process found"}
    }
    "stop" {
        if($Id) {
            Write-Host "Searching for SWARM Process ID $ID"
            $Found = Get-Process -Id $Id -ErrorAction SilentlyContinue
            if($found) {
                Write-Host "Found running SWARM process- Stopping"
                Stop-Process -Id $Found.Id -Force -ErrorAction SilentlyContinue
            } else { Write-Host "Could not find running SWARM Process"}      
        }
    }
    "start" {
        Write-Host "Starting SWARM"
        Start-Process ".\SWARM.bat"
    }
    "log" {
        $Active = Get-ChildItem ".\logs" | Where BaseName -like "*Active*" | Select -First 1
        if($Active) {
            $Log = Get-Content $Active
            $Log | Out-Host
        } else {Write-Host "No Active Miner Log Found"}
    }
    default {
        Write-Host "Usage stop|start|restart|log"
    }
}