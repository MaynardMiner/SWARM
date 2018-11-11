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
 $GetInfo += Get-Content $ParseLog
 $GetIntensity = $GetInfo | Select-String "intensity"
 $GetDifficulty = $GetInfo | Select-String "difficulty"
 $NotePath = Split-Path $GetLogMiner.Path
 if($GetIntensity){$GetIntensity | Set-Content "$NotePath\$($GetLogMiner.Algo)_Intensity.txt"}
 if($GetDifficulty){$GetInfo | Set-Content "$NotePath\$($GetLogMiner.Algo)_Difficulty.txt"}
}
}