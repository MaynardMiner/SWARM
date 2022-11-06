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

function Global:Get-LogDate([string]$Logname) {
    $Parse = $Logname.Split("__");
    $Hour = $Parse[1].Split("_")[0];
    $Minute = $Parse[1].Split("_")[1];
    $Day = $Parse[2];
    $Month = $Parse[3];
    $Year = $Parse[4].Replace(".log", "");
    return [datetime]::New($Year, $Month, $Day, $Hour, $Minute, 0);
}

function Global:Update-Log {
    $Current_Log_Date = Global:Get-LogDate $Global:log_params.logname;
    ## If it > 24 hours, Roll log over.
    $IsNewDay = ([math]::Round(((Get-Date) - $Current_Log_Date).TotalSeconds)) -gt 86400;
    if ($IsNewDay) {
        $LogName = Get-Date -Format "HH_mm__dd__MM__yyyy"
        $Global:log_params.logname = Join-Path $($(vars).dir) "logs\swarm__$LogName.log"
    }
    $SWARM_Logs = Get-ChildItem ".\logs" | Where-Object { $_.Name -like "*swarm*" };
    ## Delete any log older that 5 days.
    foreach ($Log in $SWARM_Logs) {
        $Swarm_Log_Date = Global:Get-LogDate $Log.Name
        $IsWeek = ([math]::Round(((Get-Date) - $Swarm_Log_Date).TotalDays)) -gt 4;
        if ($IsWeek) {
            Remove-Item $Log -Force | Out-Null;
        }
    }
}
