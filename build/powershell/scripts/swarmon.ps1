param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Action
)

if($Action) {
    $SMOS_CONFIG = "/root/utils/update_register.sh"
    if(test-path ($SMOS_CONFIG)){ $Changed = Get-Content $SMOS_CONFIG }    

    switch($Action) {
        "on" {
            $Changed = $Changed -replace "    /root/utils/update_configGet.sh","    /root/utils/update_configGet.sh`n    if [ -f /root/swarm_mode.txt ]; then`n    SWARM_MODE=``cat /miners/SWARM_MODE```n        if [ `"`$SWARM_MODE`" = `"Yes`"]; then`n            pwsh -command `"./root/SWARM/build/powershell/scripts/smos_config.ps1`"`n        fi`n    fi"
        }
        "off" {
            $Changed = $Changed.Replace("    if [ -f /root/swarm_mode.txt ]; then`n    SWARM_MODE=``cat /miners/SWARM_MODE```n        if [ `"`$SWARM_MODE`" = `"Yes`"]; then`n            pwsh -command `"./root/SWARM/build/powershell/scripts/smos_config.ps1`"`n        fi`n    fi","")
        }
    }
    $Changed | Set-Content "$SMOS_CONFIG"
}