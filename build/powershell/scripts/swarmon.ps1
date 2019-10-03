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

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Action
)
[cultureinfo]::CurrentCulture = 'en-US'

if($Action) {
    $SMOS_CONFIG = "/root/utils/update_register.sh"
    if(test-path ($SMOS_CONFIG)){ $Changed = Get-Content $SMOS_CONFIG }    
    $Save = $False
    switch($Action) {
        "on" {
            if( -not ($Changed | Select-String "swarm_mode.txt") ) { 
                $Changed = $Changed -replace "    /root/utils/update_configGet.sh","    /root/utils/update_configGet.sh`n    if grep -Fxq `"Yes`" /root/swarm_mode.txt`n    then`n        pwsh -command `"/root/SWARM/build/powershell/scripts/smos_config.ps1`"`n    fi"; $Save = $True }
            "Yes" | Set-Content "/root/swarm_mode.txt"
            if(-not (Test-Path "/root/xminer_old.sh")){Move-Item "/root/xminer.sh" "/root/xminer_old.sh" -Force}
            Copy-Item -Path "/root/SWARM/build/bash/xconfig.sh" -Destination "/root/xminer.sh" -Force
            $Proc = Start-Process "chmod" -ArgumentList "+x /root/xminer.sh" -PassThru
            $Proc | Wait-Process
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
            $Proc = Start-Process "chmod" -ArgumentList "+x /root/xminer.sh" -PassThru
            $Proc | Wait-Process
            Write-Host "SWARM will not run at startup- OS will ignore swarm"
        }
    }
    if($Save -eq $True){ $Changed | Set-Content "$SMOS_CONFIG" }
}