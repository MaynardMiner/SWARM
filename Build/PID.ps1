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
      [Parameter(Mandatory=$true)]
      [Array]$Name
   )

While($true)
 {
  $Name | foreach {
  if($_ -eq "miner"){$Title = "MM.Hash"}
  else{$Title = "$($_)"}
  Write-Host "Checking To See if Miner $($_) Is Running"
  $MinerPIDPath = ".\PID\$($_)_PID.txt"
  if($MinerPIDPath)
   {
    $MinerContent = Get-Content ".\PID\$($_)_PID.txt"
    if($MinerContent -ne $null)
     {
      Write-Host "Miner Name is $Title"
      Write-Host "Miner Process Id is Currently $($MinerContent)" -foregroundcolor yellow
      $MinerProcess = Get-Process -Id $MinerContent -ErrorAction SilentlyContinue
      if($MinerProcess -ne $null -or $MinerProcess.HasExited -eq $false)
       {
       Write-Host "$($Title) Status: Is Currently Running" -foregroundcolor green
       }
      else
       {
         Write-Host "Closing MM.Hash" -foregroundcolor red
         Start-Process "screen" -ArgumentList "-S miner -X quit"
         Start-Process "screen" -ArgumentList "-S NVIDIA1 -X quit"
         Start-Process "screen" -ArgumentList "-S NVIDIA2 -X quit"
         Start-Process "screen" -ArgumentList "-S NVIDIA3 -X quit"
         Start-Process "screen" -ArgumentList "-S AMD1 -X quit"
         Start-Process "screen" -ArgumentList "-S AMD2 -X quit"
         Start-Process "screen" -ArgumentList "-S AMD3 -X quit"
         Start-Process "screen" -ArgumentList "-S CPU -X quit"
         Start-Process "screen" -ArgumentList "-S LogData -X quit"
         Start-Process "screen" -ArgumentList "-S PIDInfo -X quit"
       }
    }
  }
    else
     {
        Write-Host "Closing MM.Hash" -foregroundcolor red
        Start-Process "screen" -ArgumentList "-S miner -X quit"
        Start-Process "screen" -ArgumentList "-S NVIDIA1 -X quit"
        Start-Process "screen" -ArgumentList "-S NVIDIA2 -X quit"
        Start-Process "screen" -ArgumentList "-S NVIDIA3 -X quit"
        Start-Process "screen" -ArgumentList "-S AMD1 -X quit"
        Start-Process "screen" -ArgumentList "-S AMD2 -X quit"
        Start-Process "screen" -ArgumentList "-S AMD3 -X quit"
        Start-Process "screen" -ArgumentList "-S CPU -X quit"
        Start-Process "screen" -ArgumentList "-S LogData -X quit"
        Start-Process "screen" -ArgumentList "-S PIDInfo -X quit"
     }
  }
 Start-Sleep -S 3.75
 }

  
