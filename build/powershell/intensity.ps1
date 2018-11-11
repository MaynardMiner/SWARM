function Get-Intensity {
param(
    [Parameter(Position=0,Mandatory=$false)]
    [String]$LogMiner
)

$GetLogMiner = $LogMiner | ConvertFrom-Json
$ParseLog = ".\logs\$($GetLogMiner.Type).log"
if(Test-Path $ParseLog)
{
 $GetInfo = @()
 $GetInfo += Get-Content $ParseLog | Select-String "intensity","difficulty"
 $NotePath = Split-Path $GetLogMiner.Path
 $GetInfo | Set-Content "$NotePath\Swarm_$($GetLogMiner.Algo)_Details"
}
}