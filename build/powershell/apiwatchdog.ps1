param (
  [Parameter(Position=0, Mandatory = $true)]
  [int]$Port
 )

$GETPID = Get-Content ".\build\pid\miner_pid.txt"
$SWARM = Get-Process -ID $GETPID

While($true)
{
 if($SWARM.HasExited)
  {
    try{Invoke-RestMethod "http://localhost:$Port/end" -UseBasicParsing -TimeoutSec 5}catch{}
    exit
  }
 Start-Sleep -S 1
}