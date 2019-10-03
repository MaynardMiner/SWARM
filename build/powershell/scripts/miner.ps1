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