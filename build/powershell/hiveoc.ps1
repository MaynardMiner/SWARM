
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
$OCCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-JSon

$HiveNVOC.Keys | %{
$key = $_
 Switch($key)
 {
  "FAN"
  {
    $NVOCFan = $HiveNVOC.FAN -replace "`"",""
    $NVOCFAN = $NVOCFan -split " "
    if($NVOCFAN.Count -eq 1)
     {
      for($i=0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++)
      {
       $OCArgs += "-setFanSpeed:$($OCCount.NVIDIA.$i),$($NVOCFan) "
       $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Fan Speed To $($NVOCFan)`%"
      }
     }
    else{
    for($i=0; $i -lt $NVOCFAN.Count; $i++)
    {
     $OCArgs += "-setFanSpeed:$i,$($NVOCFAN[$i]) "
     $ocmessage += "Setting GPU $i Fan Speed To $($NVOCFan[$i])`%"
    }
   }
  }
  "MEM"
  {
    $NVOCMem = $HiveNVOC.MEM -replace "`"",""
    $NVOCMem = $NVOCMem -split " "
    if($NVOCMem.Count -eq 1)
    {
     for($i=0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++)
     {
      $OCArgs += "-setMemoryClockOffset:$($OCCount.NVIDIA.$i),0,$($NVOCMem) "
      $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Memory Offset To $($NVOCMem)"
     }
   }
   else{
    for($i=0; $i -lt $NVOCMem.Count; $i++)
    {
        $OCArgs += "-setMemoryClockOffset:$($i),0,$($NVOCMem[$i]) "
        $ocmessage += "Setting GPU $i Memory Offset To $($NVOCMem[$i])"
    }
   }
  }
  "CLOCK"
  {
    $NVOCCore = $HiveNVOC.CLOCK -replace "`"",""
    $NVOCCore = $NVOCCore -split " "
    if($NVOCMem.Count -eq 1)
    {
     for($i=0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++)
     {
      $OCArgs += "-setBaseClockOffset:$($OCCount.NVIDIA.$i),0,$($NVOCCore) "
      $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Clock Offset To $($NVOCCore)"
     }
    }
   else{
    for($i=0; $i -lt $NVOCCore.Count; $i++)
      {
        $OCArgs += "-setBaseClockOffset:$($i),0,$($NVOCCore[$i]) "
        $ocmessage += "Setting GPU $i Clock Offset To $($NVOCCore[$i])"
      }
    }
  }
  "PLIMIT"
  {
    $NVOCPL = $HiveNVOC.PLIMIT -replace "`"",""
    $NVOCPL = $NVOCPL -split " "
    if($NVOCMem.Count -eq 1)
    {
     for($i=0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++)
     {
      $OCArgs += "-setPowerTarget:$($OCCount.NVIDIA.$i),$($NVOCPL) "
      $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Power Limit To $($NVOCPL)"
     }
    }
   else{
    for($i=0; $i -lt $NVOCPL.Count; $i++)
      {
       $OCArgs += "-setPowerTarget:$($i),$($NVOCPL[$i]) "
       $ocmessage += "Setting GPU $i Power Limit To $($NVOCPL[$i])"
      }
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

function start-fans {
  $FanFile = Get-Content ".\config\oc\oc-settings.json" | ConvertFrom-Json
  $FanArgs = @()
  
  if($FanFile.'windows fan start')
   {
      $Card = $FanFile.'windows fan start' -split ' '
      for($i=0; $i -lt $Card.count; $i++){$FanArgs += "-setFanSpeed:$i,$($Card[$i]) "}
      Write-Host "Starting Fans" 
      $script = @()
      $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
      $script += "Invoke-Expression `'.\nvidiaInspector.exe $FanArgs`'"
      Set-Location ".\build\apps"
      $script | Out-File "fan-start.ps1"
      $Command = start-process "powershell.exe" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\fan-start.ps1""" -PassThru -WindowStyle Minimized
      Set-Location $Dir
   }
  }
