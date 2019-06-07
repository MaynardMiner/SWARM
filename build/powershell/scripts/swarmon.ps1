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
            if(-not ($Changed | Select-String "SWARM_MODE")){ $Changed = $Changed -replace "    /root/utils/update_configGet.sh","    /root/utils/update_configGet.sh`n    if [ -f /root/swarm_mode.txt ]; then`n    SWARM_MODE=``cat /miners/SWARM_MODE```n        if [ `"`$SWARM_MODE`" = `"Yes`"]; then`n            pwsh -command `"./root/SWARM/build/powershell/scripts/smos_config.ps1`"`n        fi`n    fi"; $Save = $True }
            "Yes" | Set-Content "/root/swarm_mode.txt"
        }
        "off" {
            "No" | Set-Content "/root/swarm_mode.txt"
        }
    }
    if($Save -eq $True){ $Changed | Set-Content "$SMOS_CONFIG" }
}