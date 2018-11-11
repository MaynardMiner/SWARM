
function Start-OC {
  param(
  [Parameter(Mandatory=$false)]
  [String]$Platforms
  )

$OCMiners = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-Json
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
$OCSettings = Get-Content ".\config\oc\oc-settings.json" | ConvertFrom-Json

$nvidiaOC = $false
$AMDOC = $false

$OCMiners | foreach{
 if($_.Type -like "*NVIDIA*"){$nvidiaOC = $true}
 if($_.Type -like "*AMD*"){$AMDOC = $true}
}

$ETHPill = $false

##Check For Pill
$OCMiners | foreach {if($_.ethpill){$ETHPill = $true}}

##Stop previous Pill
if($Platforms -eq "linux"){Start-Process "./build/bash/killall.sh" -ArgumentList "pill"}

##Start New Pill
if($ETHPill -eq $true)
{
 $OCMiners | foreach {
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
$DoNVIDIAOC = $false
$DoAMDOC = $false
$NVIDIAOCArgs = @()
$NVIDIAPowerArgs = @()
$NScript = @()
$NScript += "`#`!/usr/bin/env bash"
$AScript = @()
$AScript += "`#`!/usr/bin/env bash"
$SettingsArgs = $false
$OCMiners | foreach {if($_.ocmem -or $_.occore){$SettingsArgs = $true}}
if($SettingsArgs -eq $true){$NScript += "nvidia-settings"}


$OCMiners | foreach {
##NVIDIA
if($_.Type -like "*NVIDIA*")
{
 if($_.Devices -eq $null){$OCDevices = Get-DeviceString -TypeCount $GCount.NVIDIA.PSObject.Properties.Value.Count}
 else{$OCDevices = Get-DeviceString -TypeDevices $_.Devices}
 $Core = $_.occore -split ' '
 $Mem = $_.ocmem -split ' '
 $Power = $_.ocpower -split ' '
 $Core = $Core -split ","
 $Mem = $Mem -split ","
 $Power = $Power -split ","
 $NScreenMiners = "$($_.MinerName) "

if($Card)
 {
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
   if($Platforms -eq "linux"){$NVIDIACORE += " -a [gpu:$($GCount.NVIDIA.$GPU)]/GPUGraphicsClockOffset[$X]=$($Core[$i])"}
   if($Platforms -eq "windows"){$NVIDIAOCArgs += "-setBaseClockOffset:$($GCount.NVIDIA.$GPU),$X,$($i) "}
   }
   $NScreenCore += "$($_.Type) Core is $($_.occore) "
  }
  

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
   if($Platforms -eq "linux"){$NVIDIAMEM += " -a [gpu:$($GCount.NVIDIA.$GPU)]/GPUMemoryTransferRateOffset[$X]=$($Mem[$i])"}
   if($Platforms -eq "windows"){$NVIDIAOCArgs += "-setMemoryClockOffset:$($GCount.NVIDIA.$GPU),$X,$($Mem[$i]) "} 
   }
   $NScreenMem += "$($_.Type) Memory is $($_.ocmem) "
  }

 if($Power)
  {
   $DONVIDIAOC = $true
   for($i=0; $i -lt $OCDevices.Count; $i++)
   {
   $GPU = $OCDevices[$i]
   if($Platforms -eq "linux"){$NScript += "nvidia-smi -i $($GCount.NVIDIA.$GPU) -pl $($Power[$i])"; $NScript += "sleep .1"}
   elseif($Platforms -eq "windows"){$NVIDIAOCArgs += "-setPowerTarget:$($GCount.NVIDIA.$GPU),$($Power[$i]) "}
   }
  $NScreenPower += "$($_.Type) Power is $($_.ocpower) "
   }
  }
 }

if($_.Type -like "*AMD*")
{
 if($_.Devices -eq $null){$OCDevices = Get-DeviceString -TypeCount $GCount.AMD.PSObject.Properties.Value.Count}
 else{$OCDevices = Get-DeviceString -TypeDevices $_.Devices}
 $CoreClock = $_.occore -split ' '
 $CoreState = $_.ocdpm -split ' '
 $MemClock = $_.ocmem -split ' '
 $MemState = $_.ocmdpm -split ' '
 $Voltage = $_.ocv -split ' '
 $AScreenMiners += "$($_.Minername) "
 if($Card)
 {

  if($MemClock -or $MemState)
   {
    $DOAmdOC = $true
    for($i=0; $i -lt $OCDevices.Count; $i++)
    {
     $GPU = $OCDevices[$i]
     if($Platforms -eq "linux")
     {
       $MEMArgs = $null
       if($MemClock[$GPU]){$MEMArgs += " --mem-clock $($MemClock[$i])"}
       if($MemState[$GPU]){$MEMArgs += " --mem-state $($MemState[$i])"}
       $WolfArgs = "wolfamdctrl -i $($GCount.AMD.$GPU)$MEMArgs"
       $AScript += "$WolfArgs"
       $AScript += "sleep .1"
     }
    }
    $AScreenCore += "$($_.Type) MEM is $($_.ocmem) "
    $AScreenDPM += "$($_.Type) MDPM is $($_.ocmdpm) "
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
        if($CoreClock[$GPU]){$CoreArgs += " --core-clock $($CoreClock[$i])"}
        if($CoreState[$GPU]){$CoreArgs += " --core-state $($CoreState[$i])"}
        $WolfArgs = "wolfamdctrl -i $($GCount.AMD.$GPU)$CoreArgs"
        $AScript += $WolfArgs
        $AScript += "sleep .1"
      }
     }
     $AScreenMem += "$($_.Type) CORE is $($_.occore) "
     $AScreenMDPM += "$($_.Type) DPM is $($_.ocdpm) "
    }
  
    if($Voltage)
    {
      $WolfArgs = @()
      $DOAmdOC = $true
     for($i=0; $i -lt $OCDevices.Count; $i++)
     {
       $GPU = $OCDevices[$i]
      if($Platforms -eq "linux")
      {
        for($i=1; $i -lt 16; $i++)
        {
        if($Voltage[$GPU]){$WolfArgs += "wolfamdctrl -i $($GCount.AMD.$GPU) --vddc-table-set $($Voltage[$GPU]) --volt-state $i"}
        $WolfArgs += "sleep .1"
        }
       }
      }
      $AScript += $WolfArgs
      $AScreenPower += "$($_.Type) V is $($_.ocv) "
     }
    
   }

 }
}

if($DoNVIDIAOC -eq $true -and $Platforms -eq "windows")
{
Write-Host "Starting OC" 
$script = @()
$script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
$script += "Invoke-Expression `'.\nvidiaInspector.exe $NVIDIAOCArgs`'"
Set-Location ".\build\apps"
$script | Out-File "$($_.Type)-oc-start.ps1"
$Command = start-process "CMD" -ArgumentList "/c ""powershell.exe -executionpolicy bypass -windowstyle minimized -command "".\$($_.Type)-oc-start.ps1""" -PassThru
Set-Location $Dir
}

if($DOAmdOC -eq $true -and $Platforms -eq "linux")
{
Start-Process "./build/bash/killall.sh" -ArgumentList "OC_AMD" -Wait
Start-Process "screen" -ArgumentList "-S OC_AMD -d -m" -Wait
Start-Sleep -S .25
$AScript | Out-File ".\build\bash\amdoc.sh"
Start-Sleep -S .25
Start-Process "chmod" -ArgumentList "+x build/bash/amdoc.sh" -Wait
if(Test-Path ".\build\bash\amdoc.sh"){Start-Process "screen" -ArgumentList "-S OC_AMD -X stuff ./build/bash/amdoc.sh`n"}
}

if($DoNVIDIAOC -eq $true -and $Platforms -eq "linux")
{
 if($Core){$NScript[1] = "$($NScript[1])$NVIDIACORE"}
 if($Mem){$NScript[1] = "$($NScript[1])$NVIDIAMEM"}
 Start-Process "./build/bash/killall.sh" -ArgumentList "OC_NVIDIA" -Wait
 Start-Process "screen" -ArgumentList "-S OC_NVIDIA -d -m"
 Start-Sleep -S .25
 $NScript | Out-File ".\build\bash\nvidiaoc.sh"
 Start-Sleep -S .25
 Start-Process "chmod" -ArgumentList "+x build/bash/nvidiaoc.sh" -Wait
 if(Test-Path ".\build\bash\nvidiaoc.sh"){Start-Process "screen" -ArgumentList "-S OC_NVIDIA -X stuff ./build/bash/nvidiaoc.sh`n"}
}

$OCMessage = @()
$OCMessage += "Cards: $($OCSettings.Cards)"

if($DoNVIDIAOC -eq $true)
{
$OCMessage += "Current NVIDIA OC Profile-"
$OCMessage += "NVIDIA Miner: $NScreenMiners"
$OCMessage += "ETHPill: $ETHPill"
$OCMessage += "Power: $NScreenPower"
$OCMessage += "Core Settings: $NScreenCore"
$OCMessage += "Memory Settings: $NScreenMem"
}
if($DoAMDOC -eq $true)
{
$OCMessage += "Current AMD OC Profile-"
$OCMessage += "AMD Miner: $AScreenMiners"
$OCMessage += "Power: $AScreenPower"
$OCMessage += "Core Settings: $AScreenCore"
$OCMessage += "DPM Settings: $AScreenDPM"
$OCMessage += "Memory Settings: $AScreenMem"
$OCMessage += "MDPM Settings: $AScreenMDPM"
}
$OCMessage
$OCMessage | Out-File ".\build\txt\oc-settings.txt"

}
