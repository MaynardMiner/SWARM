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
function Global:Set-Stats($Site) {
    Switch ($Site) {
        "HiveOS" { $Params = "hive_params" }
        "SWARM" { $Params = "Swarm_Params" }
    }
    $mem = @($($global:ramfree), [math]::round($global:ramtotal - $global:ramfree,2))
    $global:GPUHashTable = $global:GPUHashTable | Foreach-Object  { $_ -replace ("GPUKHS=", "") }
    $global:GPUPowerTable = $global:GPUPowerTable | Foreach-Object  { $_ -replace ("GPUWATTS=", "") }
    $global:GPUFanTable = $global:GPUFanTable | Foreach-Object  { $_ -replace ("GPUFAN=", "") }
    $global:GPUTempTable = $global:GPUTempTable | Foreach-Object  { $_ -replace ("GPUTEMP=", "") }
    $AR = @("$global:ALLACC", "$global:ALLREJ")
    if ($GPUHashTable) {
        $miner_stats = @{
            hs       = @($global:GPUHashTable)
            hs_units = "hs"
            temp     = @($global:GPUTempTable)
            fan      = @($global:GPUFanTable)
            uptime   = $global:UPTIME
            ar       = @($AR)
            algo     = $Global:StatAlgo
            bus_numbers = @($global:Bus_Numbers)
        }
    } else {
        $Miner_stats = $null
    }

    if($(vars).onboard){
        $(vars).onboard | Foreach-Object  {
        $Hash = @()
        $Hash += "0"
        $Hash += $global:GPUTempTable
        $HGPUTempTable = $Hash
        $Hash = @()
        $Hash += "0"
        $Hash += $global:GPUFanTable
        $HGPUFanTable = $Hash
        $Hash = @()
        $Hash += "0"
        $Hash += $global:GPUPowerTable
        $HGPUPowerTable = $Hash
        }
    } else {
        $HGPUTempTable = $global:GPUTempTable
        $HGPUFanTable = $global:GPUFanTable
        $HGPUPowerTable =$global:GPUPowerTable
    }

    $Stats = [ordered]@{
        method  = "stats"
        rig_id  = $global:Config.$Params.Id
        jsonrpc = "2.0"
        id      = "0"
        params  = @{
            v         = 1
            rig_id    = $global:Config.$Params.Id
            passwd    = $global:Config.$Params.Password
            miner     = "custom"
            meta      = @{
                custom = @{
                    coin = "BTC"
                }
            }
            miner_stats = $miner_stats
            total_khs = $global:GPUKHS
            temp      = @($HGPUTempTable)
            fan       = @($HGPUFanTable)
            power     = @($HGPUPowerTable)
            df        = "$global:diskspace"
            mem       = @($mem)
            cputemp   = [CPU_Temp]::Get();
            cpuavg    = @($global:load_avg_1m,$global:load_avg_5m,$global:load_avg_15m)
           }
    }
    $Stats | ConvertTo-Json -Compress -Depth 3 | Out-Host
    write-host ""
    $Stats
}

function Global:Set-Response {
    Param(
        [Parameter(Mandatory = $false)]
        [string]$method,
        [Parameter(Mandatory = $false)]
        [string]$messagetype, 
        [Parameter(Mandatory = $false)]
        [string]$data,
        [Parameter(Mandatory = $false)]
        [array]$payload,
        [Parameter(Mandatory = $false)]
        [string]$CommandID,
        [Parameter(Mandatory = $false)]
        [string]$Site
    )
     
    Switch ($Site) {
        "HiveOS" { $Params = "hive_params" }
        "SWARM" { $Params = "Swarm_Params" }
    }
    
    $myresponse = [ordered]@{
        method  = $method
        rig_id  = $global:Config.$Params.Id
        jsonrpc = "2.0"
        id      = "0"
        params  = @{
            rig_id = $global:Config.$Params.Id
            passwd = $global:Config.$Params.Password
            type   = $messagetype
            data   = $data
        }
    }


    if ($CommandID) {
        $myresponse.params.Add("id", "$CommandID")
    }
    if ($payload) {
        $myresponse.params.Add("payload", "$Payload")
    }
     
    $myresponse    

}

