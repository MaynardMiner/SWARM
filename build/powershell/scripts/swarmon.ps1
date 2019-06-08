param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Action
)

if($Action) {
    $SMOS_CONFIG = "/root/utils/update_register.sh"
    if(test-path ($SMOS_CONFIG)){ $Changed = Get-Content $SMOS_CONFIG }    
    $Save = $False
    switch($Action) {
        "on" {
            if( -not ($Changed | Select-String "swarm_mode.txt") ) { 
                $Changed = $Changed -replace "    /root/utils/update_configGet.sh","    /root/utils/update_configGet.sh`n    if grep -Fxq `"Yes`" /root/swarm_mode.txt`n    then`n        pwsh -command `"/root/SWARM/build/powershell/scripts/smos_config.ps1`"`n    fi"; $Save = $True }
            "Yes" | Set-Content "/root/swarm_mode.txt"
            Move-Item "/root/xminer.sh" "/root/xminer_old.sh" -Force
            Copy-Item -Path "/root/SWARM/build/bash/xconfig.sh" -Destination "/root/xminer.sh" -Force
            Start-Process "chmod" -ArgumentList "+x /root/xminer.sh" -Wait
            Write-Host "SWARM will not run at startup- OS will ignore other miners."
            Write-Host ""
            Write-Host "Run: 
set_swarm off

As root user to disable
"
        }
        "off" {
            "No" | Set-Content "/root/swarm_mode.txt"
            if(test-Path "/root/xminer_old.sh"){
                $Old = Get-Content "/root/xminer_old.sh"
                $Old | Set-Content "/root/xminer.sh"
            }
            Start-Process "chmod" -ArgumentList "+x /root/xminer.sh" -Wait
            Write-Host "SWARM will not run at startup- OS will ignore swarm"
        }
    }
    if($Save -eq $True){ $Changed | Set-Content "$SMOS_CONFIG" }
}