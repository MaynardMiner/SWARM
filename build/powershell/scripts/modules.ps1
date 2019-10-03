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

Param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Path,
    [Parameter(Position = 2, Mandatory = $true)]
    [string]$Phase,
    [Parameter(Position = 3, Mandatory = $true)]
    [string]$Style
)

[cultureinfo]::CurrentCulture = 'en-US'
$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp","/root"
Set-Location $dir

$message = @()

if (Test-Path $Path) {

    $Item = Get-Item $Path
    $message += "First Stopping SWARM"

    ## First Stop SWARM
    if ($Item.Name -like "*psm1*") {
        if (test-path ".\build\pid\miner_pid.txt") {
            ##windows
            if ($IsWindows) {
                $MPID = Get-Content ".\build\pid\miner_pid.txt" | % { Get-Process -Id $_ -ErrorAction SilentlyContinue }
                if ($MPID) {
                    Stop-Process -Id $MPID.ID
                    Start-Sleep -S 5
                }
            }
            else { $Proc = Start-Process "miner" -ArgumentList "stop" -PassThru; $Proc | Wait-Process }

            ## Copy User's Module To Global Dir
            Copy-Item -Path $Item.FullName -Destination ".\build\powershell\global" -Force
            $message += "Module copied to global folder. Adding Module to SWARM" 
            $SWARMPS1 = Get-Content ".\swarm.ps1"

            Switch ($Style) {
                "single" {
                    switch($Phase){
                        "startup" {$Location = "##Insert Startup Single Modules Here"}
                        "build" {$Location = "##Insert Build Single Modules Here"}
                        "pools" {$Location = "##Insert Pools Single Modules Here"}
                        "miners" {$Location = "##Insert Miners Single Modules Here"}
                        "control" {$Location = "##Insert Control Single Modules Here"}
                        "run" {$Location = "##Insert Run Single Modules Here"}
                        "benchmark" {$Location = "##Insert Benchmark Single Modules Here"}
                    }
                    $message += "User specifed module is a single-run module. Adding in startup phase."
                    $SWARMPS1 = $SWARMPS1 -replace "$Location", "Global:Add-Module `"`$($(vars).global)\$($Item.Name)`"`n$Location"
                }
                "looping" {
                    Switch($Phase){
                    "startup" {$Location = "##Insert Startup Looping Modules Here"}
                    "build" {$Location = "##Insert Build Looping Modules Here"}
                    "pools" {$Location = "##Insert Pools Looping Modules Here"}
                    "miners" {$Location = "##Insert Miners Looping Modules Here"}
                    "control" {$Location = "##Insert Control Looping Modules Here"}
                    "run" {$Location = "##Insert Run Looping Modules Here"}
                    "benchmark" {$Location = "##Insert Benchmark Looping Modules Here"}
                    }
                    $message += "User specifed module is a looping module. Adding in build phase."
                    $SWARMPS1 = $SWARMPS1 -replace "        $Location", "        Global:Add-Module `"`$($(vars).global)\$($Item.Name)`"`n        $Location"
                    ##Insert Single Modules Here
                }
            }

            $SWARMPS1 | Set-Content ".\swarm.ps1" -Encoding UTF8
            $message += "Module added. Restarting SWARM"

            if ($IsWindows) { Start-Process ".\SWARM.bat" }
            else { $Proc = Start-Process "miner" -ArgumentList "start" -PassThru; $Proc | Wait-Process }
        }
    }
    else {
        $message += "$Path is not a .psm1 file. Exiting."
    }
}
else {
    $message += "$Path could not be found. Exiting"
}

$message