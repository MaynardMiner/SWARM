Param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Path,
    [Parameter(Position = 1, Mandatory = $true)]
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
            if (test-Path "C:\") {
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
                    $message += "User specifed module is a single-run module. Adding in startup phase."
                    $SWARMPS1 = $SWARMPS1 -replace "##Insert Single Modules Here", "Add-Module `"`$global:global\$($Item.Name)`"`n##Insert Single Modules Here"
                }
                "looping" {
                    $message += "User specifed module is a looping module. Adding in build phase."
                    $SWARMPS1 = $SWARMPS1 -replace "        ##Insert Looping Modules Here", "        Add-Module `"`$global:global\$($Item.Name)`"`n        ##Insert Looping Modules Here"
                    ##Insert Single Modules Here
                }
            }

            $SWARMPS1 | Set-Content ".\swarm.ps1" -Encoding UTF8
            $message += "Module added. Restarting SWARM"

            if (test-Path "C:\") { Start-Process ".\SWARM.bat" }
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