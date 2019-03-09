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
$HashRates = $HashRates | foreach {$_ -replace ("GPU=","")}
$HashRates = $HashRates | foreach {$_ -replace ("$($_)","$($_)")}
$Power = $Power | foreach {$_ -replace ("POWER=","")}
$Power = $Power | foreach {$_ -replace ("$($_)","$($_)")}
$Fans = $Fans | foreach {$_ -replace ("FAN=","")}
$Fans = $Fans | foreach {$_ -replace ("$($_)","$($_)")}
$Temps = $Temps | foreach {$_ -replace ("TEMP=","")}
$Temps = $Temps | foreach {$_ -replace ("$($_)","$($_)")}
$AR = @("$ACC","$REJ")

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
   hs = @($HashRates)
   hs_units = "khs"
   temp = @($Temps)
   fan = @($Fans)
   uptime = $UPTIME
   ar = @($AR)
   algo = $HIVEALGO
   bus_numbers = @($BusNumbers)
   }
   total_khs = $KHS
   power = @($Power)
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

