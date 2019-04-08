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
$global:BHashRates = $global:BHashRates | foreach {$_ -replace ("GPU=","")}
$global:BHashRates = $global:BHashRates | foreach {$_ -replace ("$($_)","$($_)")}
$global:BPower = $global:BPower | foreach {$_ -replace ("POWER=","")}
$global:BPower = $global:BPower | foreach {$_ -replace ("$($_)","$($_)")}
$global:BFans = $global:BFans | foreach {$_ -replace ("FAN=","")}
$global:BFans = $global:BFans | foreach {$_ -replace ("$($_)","$($_)")}
$global:BTemps = $global:BTemps | foreach {$_ -replace ("TEMP=","")}
$global:BTemps = $global:BTemps | foreach {$_ -replace ("$($_)","$($_)")}
$AR = @("$global:BACC","$global:BREJ")

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
   hs = @($global:BHashRates)
   hs_units = "khs"
   temp = @($global:BTemps)
   fan = @($global:BFans)
   uptime = $global:BUPTIME
   ar = @($AR)
   algo = $CurAlgo
   bus_numbers = @($BusNumbers)
   }
   total_khs = $global:BKHS
   power = @($global:BPower)
   mem = @($mem)
   cpuavg = $LoadAverages
   df = "0"
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

