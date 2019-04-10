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
function Build-HiveResponse {
$mem = @($($ramfree),$($ramtotal-$ramfree))
$global:GPUHashTable = $global:GPUHashTable | foreach {$_ -replace ("GPUKHS=","")}
$global:GPUPowerTable = $global:GPUPowerTable| foreach {$_ -replace ("GPUWATTS=","")}
$global:GPUFanTable = $global:GPUFanTable| foreach {$_ -replace ("GPUFAN=","")}
$global:GPUTempTable = $global:GPUTempTable| foreach {$_ -replace ("GPUTEMP=","")}
$AR = @("$global:ALLACC","$global:ALLREJ")

$Stats = @{
  method = "stats"
  rig_id = $HiveID
  jsonrpc = "2.0"
  id= "0"
  params = @{
   rig_id = $HiveID
   passwd = $HivePassword
   miner = "custom"
   meta = @{
    custom = @{
    coin = "BTC"
    }
   }
   miner_stats = @{
   hs = @($global:GPUHashTable)
   hs_units = "khs"
   temp = @($global:GPUTempTable)
   fan = @($global:GPUFanTable)
   uptime = $global:UPTIME
   ar = @($AR)
   algo = $StatAlgo
   }
   total_khs = $global:GPUKHS
   temp = @($global:GPUTempTable)
   fan = @($global:GPUFanTable)
   power = @($global:GPUPowerTable)
   df = "$diskspace"
   mem = @($mem)
   cpuavg = $LoadAverages
  }
}
$Stats
}

function Add-HiveResponse{
     Param(
     [Parameter(Mandatory=$false)]
     [string]$method,
     [Parameter(Mandatory=$false)]
     [string]$messagetype,
     [Parameter(Mandatory=$false)]
     [string]$data,
     [Parameter(Mandatory=$false)]
     [array]$payload,
     [Parameter(Mandatory=$false)]
     [string]$HiveID,
     [Parameter(Mandatory=$false)]
     [string]$HivePassword,
     [Parameter(Mandatory=$false)]
     [string]$CommandID
     )
     
       $myresponse = @{
         method = $method
         rig_id = $HiveID
         jsonrpc = "2.0"
         id= "0"
         params = @{
          rig_id = $HiveID
          passwd = $HivePassword
          type = $messagetype
          data = $data
          }
         }


      if($CommandID)
      {
       $myresponse.params.Add("id","$CommandID")
      }
      if($payload)
      {
       $myresponse.params.Add("payload","$Payload")
      }
     
        $myresponse    

}

