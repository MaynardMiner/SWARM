
function Start-OC {
    param (
      [Parameter(Mandatory=$false)]
      [String]$OCType,
      [Parameter(Mandatory=$false)]
      [String]$Miner_Algo,
      [Parameter(Mandatory=$false)]
      [String]$Platforms,
      [Parameter(Mandatory=$false)]
      [String]$Dir,
      [Parameter(Mandatory=$false)]
      [String]$Devices,
      [Parameter(Mandatory=$false)]
      [String]$Pill
    )

if($OCType -like "*NVIDIA*")
{
$GetDevices = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
$OCDevices = $GetDevices.NVIDIA
Write-Host "OCType is NVIDIA"
Write-Host "Platform is $Platforms"
$OCSettings = Get-Content ".\config\oc\oc-nvidia.conf" | ConvertFrom-Json
$DefaultCore = $OCSettings.Default.Core -split ' '
$DefaultMem = $OCSettings.Default.Memory -split ' '
$DefaultPower = $OCSettings.Default.Power -split ' '
$Core = $OCSettings.$Miner_Algo.Core -split ' '
$Mem = $OCSettings.$Miner_Algo.Memory -split ' '
$Power = $OCSettings.$Miner_Algo.Power -split ' '
$Card = $OCSettings.Cards.Cards -split ' '
$Default = $true
if($Platforms -eq "linux"){Start-Process "./build/bash/killall.sh" -ArgumentList "pill"}
if($Card -ne "" -and $DefaultCore -ne "")
 {
 if($Core)
  {
   if($Platforms -eq "linux" -and $OCSettings.$Miner_Algo.ETHPill)
    {
     Start-Process "./build/bash/killall.sh" -ArgumentList "pill" -Wait
     $PillArgs = $OCSettings.$Miner_Algo.ETHPill
     $Pillconfig = "./build/apps/OhGodAnETHlargementPill-r2 $PillArgs"
     $Pillconfig | Set-Content ".\build\bash\pillconfig.sh"
     if($OCSettings.$Miner_Algo.PillDelay){$PillSleep = $OCSettings.$Miner_Algo.PillDelay}
     else{$PillSleep = 1}
     Start-Process "./build/bash/pill.sh" -ArgumentList "$PillSleep" -Wait
     Start-Sleep -S 1
     Start-Process "sync" -Wait
    }
   $Default = $false
   $OCArgs = @()
   for($i=0; $i -lt $OCDevices.PSObject.Properties.Value.Count; $i++)
    {
     $PWLSelected = $Power[$($OCDevices.$i)]
     if($Platforms -eq "linux"){Start-Process "nvidia-smi" -ArgumentList "-i $($OCDevices.$i) -pl $PWLSelected" -Wait}
     elseif($Platforms -eq "windows"){$OCArgs += "-setPowerTarget:$($OCDevices.$i),$PWLSelected "}
    }
   for($i=0; $i -lt $OCDevices.PSObject.Properties.Value.Count; $i++)
   {
   $X = 3
   Switch($Card[$($OCDevices.$i)]){
   "1050"{$X = 2}
   "1050ti"{$X = 2}
   "P106-100"{$X = 2}
   "P106-090"{$X = 1}
   "P104-100"{$X = 1}
   "P102-100"{$X = 1}
    }
   $OCArgs += " -a [gpu:$($OCDevices.$i)]/GPUGraphicsClockOffset[$X]=$($Core[$($OCDevices.$i)]) "
   $OCArgs += " -a [gpu:$($OCDevices.$i)]/GPUMemoryTransferRateOffset[$X]=$($Mem[$($OCDevices.$i)]) "
   if($Platforms -eq "windows"){$OCArgs += "-setBaseClockOffset:$($OCDevices.$i),$X,$($Core[$($OCDevices.$i)]) "}
   if($Platforms -eq "windows"){$OCArgs += "-setMemoryClockOffset:$($OCDevices.$i),$X,$($Mem[$($OCDevices.$i)]) "} 
 }
if($OCArgs -ne $null)
 {
  if($Platforms -eq "linux"){Start-Process "nvidia-settings" -ArgumentList "$OCArgs"}
 }
}
else{
 Write-Host "Default Settings Selected"
 $OCArgs = @()
 for($i=0; $i -lt $OCDevices.PSObject.Properties.Value.Count; $i++)
 {
  $PWLSelected = $DefaultPower[$($OCDevices.$i)]
  if($Platforms -eq "linux"){Start-Process "nvidia-smi" -ArgumentList "-i $($OCDevices.$i) -pl $PWLSelected " -Wait}
  elseif($Platforms -eq "windows"){$OCArgs += "-setPowerTarget:$($OCDevices.$i),$PWLSelected "}
 }
 for($i=0; $i -lt $OCDevices.PSObject.Properties.Value.Count; $i++)
  {
   $X = 3
   Switch($Card[$($OCDevices.$i)]){
   "1050"{$X = 2}
   "1050ti"{$X = 2}
   "P106-100"{$X = 2}
   "P106-090"{$X = 1}
   "P104-100"{$X = 1}
   "P102-100"{$X = 1}
   }
  if($Platforms -eq "linux"){$OCArgs += "-a [gpu:$($OCDevices.$i)]/GPUGraphicsClockOffset[$X]=$($DefaultCore[$($OCDevices.$i)]) "}
  if($Platforms -eq "linux"){$OCArgs += "-a [gpu:$($OCDevices.$i)]/GPUMemoryTransferRateOffset[$X]=$($DefaultMem[$($OCDevices.$i)]) "}
  if($Platforms -eq "windows"){$OCArgs += "-setBaseClockOffset:$($OCDevices.$i),$($X),$($DefaultCore[$($OCDevices.$i)]) "}
  if($Platforms -eq "windows"){$OCArgs += "-setMemoryClockOffset:$($OCDevices.$i),$($X),$($DefaultMem[$($OCDevices.$i)]) "}
  }
if($OCArgs -ne $null){if($Platforms -eq "linux"){Start-Process "nvidia-settings" -ArgumentList "$OCArgs"}}
}

if($Platforms -eq "windows" -and $OCArgs -ne $null){
Write-Host "Starting OC" 
$script = @()
$script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
$script += "Invoke-Expression `'.\nvidiaInspector.exe $OCArgs`'"
Set-Location ".\build\apps"
$script | Out-File "$OCType-oc-start.ps1"
$Command = start-process "CMD" -ArgumentList "/c ""powershell.exe -executionpolicy bypass -windowstyle minimized -command "".\$OCtype-oc-start.ps1""" -PassThru
Set-Location $Dir
}
if($Default -eq $true)
{
$OCMessage = "
Current OC Profile:

Algorithm is $Miner_Algo
Default: $Default
Cards: $($OCSettings.Cards.Cards)
Power Settings: $($OCSettings.Default.Power)
Core Settings: $($OCSettings.Default.Core)
Memory Settings: $($OCSettings.Default.Memory)
"
$OCMessage
}
else{
$OCMessage = "
Current OC Profile:

Algorithm is $Miner_Algo
Default: $Default
Cards: $($OCSettings.Cards)
Power Settings: $($OCSettings.$Miner_Algo.Power)
Core Settings: $($OCSettings.$Miner_Algo.Core)
Memory Settings: $($OCSettings.$Miner_Algo.Memory)
"
$OCMessage
 }
 $OCMessage | Out-File ".\build\txt\oc-settings.txt"

  }
 }
}