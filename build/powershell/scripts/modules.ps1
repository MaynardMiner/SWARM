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
Set-Location (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))

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
            else { Start-Process "miner" -ArgumentList "stop" -Wait }

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
            else { Start-Process "miner" -ArgumentList "start" -Wait }
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