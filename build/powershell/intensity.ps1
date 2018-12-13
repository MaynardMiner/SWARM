function Get-Intensity {
param(
    [Parameter(Position=0,Mandatory=$false)]
    [String]$LogMiner,
    [Parameter(Position=1,Mandatory=$false)]
    [String]$LogAlgo,
    [Parameter(Position=0,Mandatory=$false)]
    [String]$LogPath
)

$ParseLog = ".\logs\$($LogMiner).log"
if(Test-Path $ParseLog)
{
 $GetInfo = Get-Content $ParseLog
 $GetIntensity = $GetInfo | Select-String "intensity"
 $GetDifficulty = $GetInfo | Select-String "difficulty"
 $NotePath = Split-Path $LogPath
 if($GetIntensity){$GetIntensity | Set-Content "$NotePath\$($LogAlgo)_intensity.txt"}
 if($GetDifficulty){$GetDifficulty | Set-Content "$NotePath\$($LogAlgo)_difficulty.txt"}
}
}