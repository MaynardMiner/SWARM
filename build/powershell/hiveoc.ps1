
function Start-NVIDIAOC {
param (
[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
[object]$InputObject
)

$script = @()
$script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
$OcArgs = @()
$HiveNVOC = $InputObject | ConvertFrom-StringData
$ocmessage = @()

$HiveNVOC.Keys | %{
$key = $_
 Switch($key)
 {
  "FAN"
  {
    $NVOCFan = $HiveNVOC.FAN -replace "`"",""
    $NVOCFAN = $NVOCFan -split " "
    for($i=0; $i -lt $NVOCFAN.Count; $i++)
    {
     $OCArgs += "-setFanSpeed:$i,$($NVOCFAN[$i]) "
     $ocmessage += "Setting GPU $i Fan Speed To $($NVOCFan[$i])`%"
    }
  }
  "MEM"
  {
    $NVOCMem = $HiveNVOC.MEM -replace "`"",""
    $NVOCMem = $NVOCMem -split " "
    for($i=0; $i -lt $NVOCMem.Count; $i++)
    {
        $OCArgs += "-setMemoryClockOffset:$($i),0,$($NVOCMem[$i]) "
        $ocmessage += "Setting GPU $i Memory Offset To $($NVOCMem[$i])"
    }
  }
  "CLOCK"
  {
    $NVOCCore = $HiveNVOC.CLOCK -replace "`"",""
    $NVOCCore = $NVOCCore -split " "
    for($i=0; $i -lt $NVOCCore.Count; $i++)
    {
        $OCArgs += "-setBaseClockOffset:$($i),0,$($NVOCCore[$i]) "
        $ocmessage += "Setting GPU $i Clock Offset To $($NVOCCore[$i])"
    }
  }
  "PLIMIT"
  {
    $NVOCPL = $HiveNVOC.PLIMIT -replace "`"",""
    $NVOCPL = $NVOCPL -split " "
    for($i=0; $i -lt $NVOCPL.Count; $i++)
    {
       $OCArgs += "-setPowerTarget:$($i),$($NVOCPL[$i]) "
       $ocmessage += "Setting GPU $i Power Limit To $($NVOCPL[$i])"
    }
  }
 }
}

$script += "Invoke-Expression `'.\nvidiaInspector.exe $OCArgs`'"
Set-Location ".\build\apps"
$script | Out-File "nvoc-start.ps1"
$Command = start-process "powershell.exe" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\nvoc-start.ps1""" -PassThru -WindowStyle Minimized
Set-Location $WorkingDir
Start-Sleep -s 1
$ocmessage | Set-Content ".\build\txt\ocmessage.txt"
Start-Sleep -S 1
$ocmessage
}