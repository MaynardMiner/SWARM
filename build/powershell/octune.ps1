
function Start-OC {
  param(
  [Parameter(Mandatory=$false)]
  [String]$Platforms
  )

$Miners = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-Json
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
$OCSettings = Get-Content ".\config\oc\oc-settings.json" | ConvertFrom-Json

$nvidiaOC = $false
$AMDOC = $true

$Miners | foreach{
 if($_.Type -like "*NVIDIA*"){$nvidiaOC = $true}
 if($_.Type -like "*AMD*"){$AMDOC = $true}
}

$ETHPill = $false

##Check For Pill
$Miners | foreach {if($_.ethpill){$ETHPill = $true}}

##Stop previous Pill
if($Platforms -eq "linux"){Start-Process "./build/bash/killall.sh" -ArgumentList "pill"}

##Start New Pill
if($ETHPill -eq $true)
{
 $Miners | foreach {
 if($_.Type -like "*NVIDIA*")
  {
    if($_.ETHPill -eq "Yes")
    {
    if($_.Devices -eq $null){$OCPillDevices = Get-DeviceString -TypeCount $GCount.NVIDIA.PSObject.Properties.Value.Count}
    else{$OCPillDevices = Get-DeviceString -TypeDevices $_.Devices}
    $OCPillDevices | foreach {$PillDevices += "$($_),"}
    }
   }
  }
$PillDevices = $PillDevices.Substring(0,$PillDevices.Length-1)
$PillDevices = "--RevA $PillDevices"
if($Platforms -eq "linux")
 {
 if($_.PillDelay){$PillSleep = $_.PillDelay}
 else{$PillSleep = 1}
 $Pillconfig = "./build/apps/OhGodAnETHlargementPill-r2 $PillDevices"
 $Pillconfig | Set-Content ".\build\bash\pillconfig.sh"
 Start-Sleep -S .25
 Start-Process "./build/bash/pill.sh" -ArgumentList "$PillSleep" -Wait
 Start-Process "sync" -Wait
 }
}

$Card = $OCSettings.Cards -split ' '
$Card = $Card -split ","

#OC For Devices
$NVIDIAOCArgs = @()
$NVIDIAPowerArgs = @()
$DoAMDOC = $false
$DoNVIDIAOC = $false

$Miners | foreach {
##NVIDIA
if($_.Type -like "*NVIDIA*")
{
 if($_.Devices -eq $null){$OCDevices = Get-DeviceString -TypeCount $GCount.NVIDIA.PSObject.Properties.Value.Count}
 else{$OCDevices = Get-DeviceString -TypeDevices $_.Devices}
 Write-Host "$($_.Type) is mining with $($_.Name)"
 Write-Host "Platform is $Platforms"
 $Core = $_.occore -split ' '
 $Mem = $_.ocmem -split ' '
 $Power = $_.ocpower -split ' '
 $Core = $Core -split ","
 $Mem = $Mem -split ","
 $Power = $Power -split ","
 $ScreenMiners += "$($_.Type) is using $($_.Name) mining $($_.Algo) "
if($Card)
 {
  $NScript = @()
  $NScript += "`#`!/usr/bin/env bash"
  $NScript += "screen -S OC_NVIDIA -d -m"
  $NScript += "sleep .1"
  if($Mem -or $Core){$NScript += "screen -S OC_NVIDIA -X stuff $`"nvidia-settings"}

 if($Core)
  {
   $DONVIDIAOC = $true
   for($i=0; $i -lt $OCDevices.Count; $i++)
   {
   $GPU = $OCDevices[$i]
   $X = 3
   Switch($Card[$($GCount.NVIDIA.$i)]){
   "1050"{$X = 2}
   "1050ti"{$X = 2}
   "P106-100"{$X = 2}
   "P106-090"{$X = 1}
   "P104-100"{$X = 1}
   "P102-100"{$X = 1}
    }
   if($Platforms -eq "linux"){$NVIDIACore += " -a [gpu:$($GCount.NVIDIA.$GPU)]/GPUGraphicsClockOffset[$X]=$($Core[$GPU])"}
   if($Platforms -eq "windows"){$NVIDIAOCArgs += "-setBaseClockOffset:$($GCount.NVIDIA.$GPU),$X,$($Core[$GPU]) "}
   }
   $ScreenCore += "$($_.Type) Core is $($_.occore) "
  }
  
 if($Core){$NScript[3] = "$($NScript[3])$NVIDIACore"}

 if($Mem)
  {
    $DONVIDIAOC = $true
   for($i=0; $i -lt $OCDevices.Count; $i++)
   {
   $GPU = $OCDevices[$i]
   $X = 3
   Switch($Card[$($GCount.NVIDIA.$i)]){
   "1050"{$X = 2}
   "1050ti"{$X = 2}
   "P106-100"{$X = 2}
   "P106-090"{$X = 1}
   "P104-100"{$X = 1}
   "P102-100"{$X = 1}
    }
   if($Platforms -eq "linux"){$NVIDIAMem += " -a [gpu:$($GCount.NVIDIA.$GPU)]/GPUMemoryTransferRateOffset[$X]=$($Mem[$i])"}
   if($Platforms -eq "windows"){$NVIDIAOCArgs += "-setMemoryClockOffset:$($GCount.NVIDIA.$GPU),$X,$($Mem[$i]) "} 
   }
   $ScreenMem += "$($_.Type) Memory is $($_.ocmem) "
  }

  if($Mem){$NScript[3] = "$($NScript[3])$NVIDIAMem"}
  if($Mem -or $Core){$NScript[3] = "$($NScript[3])\n`""}
  $NScript += "sleep .1"

 if($Power)
  {
   $DONVIDIAOC = $true
   for($i=0; $i -lt $OCDevices.Count; $i++){
   $GPU = $OCDevices[$i]
   if($Platforms -eq "linux"){$NScript += "screen -S OC_NVIDIA -X stuff $`"nvidia-smi -i $($GCount.NVIDIA.$GPU) -pl $($Power[$i])\n`""; $NScript += "sleep .1"}
   elseif($Platforms -eq "windows"){$NVIDIAOCArgs += "-setPowerTarget:$($GCount.NVIDIA.$GPU),$($Power[$i]) "}
  }
  $ScreenPower += "$($_.Type) Power is $($_.ocpower) "
   }
  }
 }

 $NScript += "sleep .1"

if($_.Type -like "*AMD*")
{
 if($_.Devices -eq $null){$OCDevices = Get-DeviceString -TypeCount $GCount.AMD.PSObject.Properties.Value.Count}
 else{$OCDevices = Get-DeviceString -TypeDevices $_.Devices}
 Write-Host "$($_.Type) is mining with $($_.Name)"
 Write-Host "Platform is $Platforms"
 $CoreClock = $_.occore -split ' '
 $CoreState = $_.ocdpm -split ' '
 $MemClock = $_.ocmem -split ' '
 $MemState = $_.ocmdmp -split ' '
 $Voltage = $_.ocv -split ' '
 if($Card)
 {
  $Script = @()
  $Script += "`#`!/usr/bin/env bash"
  $Script += "screen -S OC_AMD -d -m"
  $Script += "sleep .1"

  if($MemClock -or $MemState)
   {
    $DOAmdOC = $true
    for($i=0; $i -lt $OCDevices.Count; $i++)
    {
     $GPU = $OCDevices[$i]
     if($Platforms -eq "linux")
     {
       $MEMArgs = $null
       $MEMArgs += "screen -S OC_AMD -X stuff $`"wolfamdctrl -i $($GCount.AMD.$GPU)"
       if($MemClock[$GPU]){$MEMArgs += " --mem-clock $($MemClock[$GPU])"}
       if($MemState[$GPU]){$MEMArgs += " --mem-state $($MemState[$GPU])"}
       $MEMArgs += "\n`""
       $Script += $MEMArgs
       $Script += "sleep .1"
     }
    }
   }

    if($CoreClock -or $CoreState)
    {
     for($i=0; $i -lt $OCDevices.Count; $i++)
     {
      $DOAmdOC = $true
      $GPU = $OCDevices[$i]
      if($Platforms -eq "linux")
      {
        $CoreArgs = $null
        $CoreArgs += "screen -S OC_AMD -X stuff $`"wolfamdctrl -i $($GCount.AMD.$GPU)"
        if($CoreClock[$GPU]){$CoreArgs += " --core-clock $($CoreClock[$GPU])"}
        if($CoreState[$GPU]){$CoreArgs += " --core-state $($CoreState[$GPU])"}
        $CoreArgs += "\n`""
        $Script += $CoreArgs
        $Script += "sleep .1"
      }
     }
    }
  
    if($Voltage)
    {
      $DOAmdOC = $true
     for($i=0; $i -lt $OCDevices.Count; $i++)
     {
       $GPU = $OCDevices[$i]
      if($Platforms -eq "linux")
      {
        for($i=1; $i -lt 16; $i++)
        {
        $VoltArgs = $null
        $VoltArgs += "screen -S OC_AMD -X stuff $`"wolfamdctrl -i $($GCount.AMD.$GPU)"
        if($Voltage[$GPU]){$VoltArgs += " --vddc-table-set $($Voltage[$GPU]) --volt-state $i"}
        $VoltArgs += "\n`""
        $Script += $VoltArgs
        $Script += "sleep .1"
        }
       }
      }
     }
    
   }

 }
}

if($NVIDIAOCArgs)
{
if($Platforms -eq "windows"){
Write-Host "Starting OC" 
$script = @()
$script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
$script += "Invoke-Expression `'.\nvidiaInspector.exe $NVIDIAOCArgs`'"
Set-Location ".\build\apps"
$script | Out-File "$($_.Type)-oc-start.ps1"
$Command = start-process "CMD" -ArgumentList "/c ""powershell.exe -executionpolicy bypass -windowstyle minimized -command "".\$($_.Type)-oc-start.ps1""" -PassThru
Set-Location $Dir
 }
}

if($DOAmdOC -eq $true -and $Platforms -eq "linux")
{
Start-Process "./build/bash/killall.sh" -ArgumentList "OC_AMD"
$Script | Out-File ".\build\bash\amdoc.sh"
Start-Sleep -S .25
Start-Process "chmod" -ArgumentList "+x build/bash/amdoc.sh" -Wait
Start-Process ".\build\bash\amdoc.sh"
}

if($DoNVIDIAOC -eq $true -and $Platforms -eq "linux")
{
 Start-Process "./build/bash/killall.sh" -ArgumentList "OC_NVIDIA"
 $NScript | Out-File ".\build\bash\nvidiaoc.sh"
 Start-Sleep -S .25
 Start-Process "chmod" -ArgumentList "+x build/bash/nvidiaoc.sh" -Wait
 Start-Process ".\build\bash\nvidiaoc.sh"
}



$OCMessage = "
Current OC Profile:
Miners: $ScreenMiners
Cards: $($OCSettings.Cards)
ETHPill: $ETHPill
Power: $ScreenPower
Core Settings: $ScreenCore
Memory Settings: $ScreenMem
"
$OCMessage
$OCMessage | Out-File ".\build\txt\oc-settings.txt"

}