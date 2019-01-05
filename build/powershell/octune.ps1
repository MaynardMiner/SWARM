
function Set-VegaOC{
  Param (
    [Parameter(Position=0)]
    [String]$Platform,
    [Parameter(Position=1)]
    [String]$OCAlgo
  )

    function Get-RegDevices {
    Set-Location "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    $Reg = $(Get-Item * -ErrorAction SilentlyContinue).Name
    $Reg = $Reg | %{$_ -split "\\" | Select -Last 1} | %{if($_ -like "*00*"){$_}}
    $RegNames= @{}
    $Reg | foreach{
    $DriverDesc = $(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($_)" -Name "DriverDesc").DriverDesc;
    if($DriverDesc -like "*Vega*")
     {$RegNames.Add("$($_)",$((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($_)" -Name "ProviderName").ProviderName))};    
    }
    Set-Location $WorkingDir; 
    $RegNames
  }
    function HX4 {
      param(
      [Parameter(Position=0, Mandatory=$true)]
      [Int]$IO
      )
      $HX4 = '{0:X4}' -f $IO
      @($HX4.Substring(0,2),$HX4.Substring(2,2))
    }
    function HX6 {
      param(
      [Parameter(Position=0, Mandatory=$true)]
      [int]$IO
      )
      $HX6 = $IO*100
      $HX6 = '{0:X6}' -f $HX6
      @($HX6.Substring(0,2),$HX6.Substring(2,2),$HX6.Substring(4,2))
    }
    function HX2 {
        param(
        [Parameter(Position=0, Mandatory=$true)]
        [int]$IO
        )
        $HX2 = $IO/100
        $HX2 = '{0:X2}' -f $HX2
        $HX2
      }  
    
    $PP = @{}
    $Core = @{}
    $Voltage = @{}
    $Clock = @{}

   $GetVegaOC = Get-Content ".\config\oc\vega-oc.json" | COnvertFrom-Json
   if($GetVegaOC.$OCAlgo.Core.Voltage.P7 -or $GetVegaOC.Default.Voltage.P7){$Vega= $true; $VegaP = $GetVegaOC.$OCAlgo;$VegaOC = $GetVegaOC.Default}

   if($Vega -eq $true)
   {
   $VegaP.Core.Voltage | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | foreach{if($VegaP.Core.Voltage.$_ -ne ""){$VegaOC.Core.Voltage.$_ = $VegaP.Core.Voltage.$_}}
   $VegaP.Core.Clocks | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | foreach{if($VegaP.Core.Clocks.$_ -ne ""){$VegaOC.Clock.Clocks.$_ = $VegaP.Core.Clocks.$_}}

   if($VegaP.Memory.Voltage.P4){$VegaOC.Memory.voltage.P4 = $VegaP.Memory.Voltage.P4}
   if($VegaP.Memory.Clocks.P4){$VegaOC.Memory.Clocks.P4 = $VegaP.Memory.Clocks.P4}

   $Voltage.ADD("P0",(HX4 $VegaOC.Core.Voltage.P0)); $Clock.Add("P0",(HX6 $VegaOC.Core.Clocks.P0))
   $Voltage.ADD("P1",(HX4 $VegaOC.Core.Voltage.P1)); $Clock.Add("P1",(HX6 $VegaOC.Core.Clocks.P1))
   $Voltage.ADD("P2",(HX4 $VegaOC.Core.Voltage.P2)); $Clock.Add("P2",(HX6 $VegaOC.Core.Clocks.P2))
   $Voltage.ADD("P3",(HX4 $VegaOC.Core.Voltage.P3)); $Clock.Add("P3",(HX6 $VegaOC.Core.Clocks.P3))
   $Voltage.ADD("P4",(HX4 $VegaOC.Core.Voltage.P4)); $Clock.Add("P4",(HX6 $VegaOC.Core.Clocks.P4))
   $Voltage.ADD("P5",(HX4 $VegaOC.Core.Voltage.P5)); $Clock.Add("P5",(HX6 $VegaOC.Core.Clocks.P5))
   $Voltage.ADD("P6",(HX4 $VegaOC.Core.Voltage.P6)); $Clock.Add("P6",(HX6 $VegaOC.Core.Clocks.P6))
   $Voltage.ADD("P7",(HX4 $VegaOC.Core.Voltage.P7)); $Clock.Add("P7",(HX6 $VegaOC.Core.Clocks.P7))
        $Core.Add("Voltage",$Voltage); $Core.Add("Clock",$Clock); $PP.Add("Core",$Core);

    $Mem = @{}
    $Voltage = @{}
    $Clock = @{}
    $Voltage.Add("P4",(HX4 $VegaOC.Memory.Voltage.P4)); $Clock.Add("P4",(HX6 $VegaOC.Memory.Clocks.P4))
        $Mem.Add("Voltage",$Voltage); $Mem.Add("Clock",$Clock); $PP.Add("Mem",$Mem);

    
    if($VegaP.Power_Limit_Max){$VegaOC.Power_Limit_Max = $VegaP.Power_Limit_Max}
    if($VegaP.Current_Limit){$VegaOC.Current_Limit = $VegaP.Current_Limit}
    if($VegaP.Wattage_Limit){$VegaOC.Wattage_Limit = $VegaP.Wattage_Limit}     
    if($VegaP.Acoustic_Limit){$VegaOC.Acoustic_Limit = $VegaP.Acoustic_Limit}     
    if($VegaP.Target_Temp){$VegaOC.Target_Temp = $VegaP.Target_Temp}     
    if($VegaP.Max_Temp){$VegaOC.Max_Temp = $VegaP.Max_Temp}     
    if($VegaP.Min_Fan){$VegaOC.Min_Fan = $VegaP.Min_Fan}     
    if($VegaP.Max_Fan){$VegaOC.Max_Fan = $VegaP.Max_Fan}     


    $PP.Add("Power_Limit_Max",(HX4 $VegaOC.Power_Limit_Max))
    $PP.Add("Current_Limit",(HX4 $VegaOC.Current_Limit))
    $PP.Add("Wattage_Limit",(HX4 $VegaOC.Wattage_Limit))
    $PP.Add("Acoustic_Limit",(HX4 $VegaOC.Acoustic_Limit))
    $PP.Add("Target_Temp",(HX4 $VegaOC.Target_Temp))
    $PP.Add("Max_Temp",(HX4 $VegaOC.Max_Temp))
    $PP.Add("Min_Fan",(HX2 $VegaOC.Min_Fan))
    $PP.Add("Max_Fan",(HX4 $VegaOC.Max_Fan))

$Power_Play = "B6,02,08,01,00,5C,00,E1,06,00,00,EE,2B,00,00,1B,00,48,00,00,00,80,A9,03,00,F0,49,02,00,$($PP.Power_Limit_Max[1]),$($PP.Power_Limit_Max[0]),08,00,00,00,00,00,00,00,00,00,00,00,00,00,00,02,01,5C,00,4F,02,46,02,94,00,9E,01,BE,00,28,01,7A,00,8C,00,BC,01,00,00,00,00,72,02,00,00,90,00,A8,02,6D,01,43,01,97,01,F0,49,02,00,71,02,02,02,00,00,00,00,00,00,08,00,00,00,00,00,00,00,05,00,07,00,03,00,05,00,00,00,00,00,00,00,01,08,$($PP.Core.Voltage.P0[1]),$($PP.Core.Voltage.P0[0]),$($PP.Core.Voltage.P1[1]),$($PP.Core.Voltage.P1[0]),$($PP.Core.Voltage.P2[1]),$($PP.Core.Voltage.P2[0]),$($PP.Core.Voltage.P3[1]),$($PP.Core.Voltage.P3[0]),$($PP.Core.Voltage.P4[1]),$($PP.Core.Voltage.P4[0]),$($PP.Core.Voltage.P5[1]),$($PP.Core.Voltage.P5[0]),$($PP.Core.Voltage.P6[1]),$($PP.Core.Voltage.P6[0]),$($PP.Core.Voltage.P7[1]),$($PP.Core.Voltage.P7[0]),01,FF,01,$($PP.Mem.Voltage.P4[1]),$($PP.Mem.Voltage.P4[0]),01,01,84,03,00,08,60,EA,00,00,00,40,19,01,00,01,80,38,01,00,02,DC,4A,01,00,03,90,5F,01,00,04,00,77,01,00,05,90,91,01,00,06,C0,D4,01,00,07,01,08,$($PP.Core.Clock.P0[2]),$($PP.Core.Clock.P0[1]),$($PP.Core.Clock.P0[0]),00,00,00,80,00,00,00,00,00,00,$($PP.Core.Clock.P1[2]),$($PP.Core.Clock.P1[1]),$($PP.Core.Clock.P1[0]),00,01,00,00,00,00,00,00,00,00,$($PP.Core.Clock.P2[2]),$($PP.Core.Clock.P2[1]),$($PP.Core.Clock.P2[0]),00,02,00,00,00,00,00,00,00,00,$($PP.Core.Clock.P3[2]),$($PP.Core.Clock.P3[1]),$($PP.Core.Clock.P3[0]),00,03,00,00,00,00,00,00,00,00,$($PP.Core.Clock.P4[2]),$($PP.Core.Clock.P4[1]),$($PP.Core.Clock.P4[0]),00,04,00,00,00,00,00,00,00,00,$($PP.Core.Clock.P5[2]),$($PP.Core.Clock.P5[1]),$($PP.Core.Clock.P5[0]),00,05,00,00,00,00,01,00,00,00,$($PP.Core.Clock.P6[2]),$($PP.Core.Clock.P6[1]),$($PP.Core.Clock.P6[0]),00,06,00,00,00,00,01,00,00,00,$($PP.Core.Clock.P7[2]),$($PP.Core.Clock.P7[1]),$($PP.Core.Clock.P7[0]),00,07,00,00,00,00,01,00,00,00,00,05,60,EA,00,00,00,40,19,01,00,00,80,38,01,00,00,DC,4A,01,00,00,90,5F,01,00,00,00,08,28,6E,00,00,00,2C,C9,00,00,01,F8,0B,01,00,02,80,38,01,00,03,90,5F,01,00,04,F4,91,01,00,05,D0,B0,01,00,06,C0,D4,01,00,07,00,6C,39,00,00,00,24,5E,00,00,01,FC,85,00,00,02,AC,BC,00,00,03,34,D0,00,00,04,68,6E,01,00,05,08,97,01,00,06,EC,A3,01,00,07,00,01,68,3C,01,00,00,01,04,3C,41,00,00,00,00,00,50,C3,00,00,00,00,00,80,38,01,00,02,00,00,$($PP.Mem.Clock.P4[2]),$($PP.Mem.Clock.P4[1]),$($PP.Mem.Clock.P4[0]),00,04,00,00,01,08,00,98,85,00,00,40,B5,00,00,60,EA,00,00,50,C3,00,00,01,80,BB,00,00,60,EA,00,00,94,0B,01,00,50,C3,00,00,02,00,E1,00,00,94,0B,01,00,40,19,01,00,50,C3,00,00,03,78,00,00,40,19,01,00,88,26,01,00,50,C3,00,00,04,40,19,01,00,80,38,01,00,80,38,01,00,50,C3,00,00,05,80,38,01,00,DC,4A,01,00,DC,4A,01,00,50,C3,00,00,06,00,77,01,00,00,77,01,00,90,5F,01,00,50,C3,00,00,07,90,91,01,00,90,91,01,00,00,77,01,00,50,C3,00,00,01,18,00,00,00,00,00,00,00,0B,E4,12,$($PP.Max_Fan[1]),$($PP.Max_Fan[0]),$($PP.Max_Fan[1]),$($PP.Max_Fan[0]),$($PP.Target_Temp[1]),$($PP.Target_Temp[0]),0A,00,54,03,C2,01,C2,01,C2,01,C2,01,C2,01,C2,01,90,01,00,00,00,00,00,02,$($PP.Min_Fan[0]),31,07,$($PP.Wattage_Limit[1]),$($PP.Wattage_Limit[0]),$($PP.Wattage_Limit[1]),$($PP.Wattage_Limit[0]),$($PP.Wattage_Limit[1]),$($PP.Wattage_Limit[0]),$($PP.Current_Limit[1]),$($PP.Current_Limit[0]),00,00,59,00,69,00,4A,00,4A,00,5F,00,73,00,73,00,64,00,40,00,90,92,97,60,96,00,90,$($PP.Max_Temp[1]),$($PP.Max_Temp[0]),00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,02,02,D4,30,00,00,02,10,60,EA,00,00,02,10"


if($Platform -eq "linux")
{
$PP_Table = Set-ItemProperty -PropertyType Binary -Value $Power_Play
}
if($Platform -eq "windows")
{
$hexified = $Power_PLay.Split(',') | % { "0x$_"}
$GetRegistry = (Get-RegDevices)
 $GetRegistry.Keys | foreach{
 $Regkey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($_)" -Name "PP_PhmSoftPowerPlayTable" -ErrorAction SilentlyContinue
 if($Regkey)
  {
   Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($_)" -Name "PP_PhmSoftPowerPlayTable" -Value ([byte[]]$hexified)
  }
  else{New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($_)" -Name "PP_PhmSoftPowerPlayTable" -PropertyType "Binary" -Value ([byte[]]$hexified) | Out-Null }
  }
  $MinerArray = Get-Content ".\build\txt\devicelist.txt" | COnvertFrom-Json
  $AMD = $MinerArray.AMD
  $AMD | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Foreach{
   $Commands += "-ac$($_) GPU_P7=$($VegaOC.Core.Clocks.P7);$($VegaOC.Core.Voltage.P7) GPU_P6=$($VegaOC.Core.Clocks.P6);$($VegaOC.Core.Voltage.P6) GPU_P5=$($VegaOC.Core.Clocks.P5);$($VegaOC.Core.Voltage.P5) GPU_P4=$($VegaOC.Core.Clocks.P4);$($VegaOC.Core.Voltage.P4) GPU_P3=$($VegaOC.Core.Clocks.P3);$($VegaOC.Core.Voltage.P3) GPU_P2=$($VegaOC.Core.Clocks.P2);$($VegaOC.Core.Voltage.P2) GPU_P1=$($VegaOC.Core.Clocks.P1);$($VegaOC.Core.Voltage.P1) GPU_P0=$($VegaOC.Core.Clocks.P0);$($VegaOC.Core.Voltage.P0) MEM_P3=$($VegaOC.Memory.Clocks.P4);$($VegaOC.Memory.Voltage.P4) Fan_Min=$($VegaOC.Min_Fan) Fan_Max=$($VegaOC.Max_Fan) Fan_Target=$($VegaOC.Target_Temp) "
   Start-Process ".\build\apps\OverdriveNtool.exe" -ArgumentList $Commands -NoNewWindow -Wait
  }
  $hexified | Set-Content ".\build\txt\reg.txt"
  }
 }
}


function Start-OC {
  param(
  [Parameter(Mandatory=$false)]
  [String]$Platforms,
  [Parameter(Mandatory=$false)]
  [String]$Dir
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

if($AMDOC = $true)
 {
  $VegaMiner = $OCMiners | Where Type -like "*AMD*"
  Set-VegaOC "windows" $VegaMiner.ALgo
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
   if($Platforms -eq "windows"){$NVIDIAOCArgs += "-setBaseClockOffset:$($GCount.NVIDIA.$GPU),0,$($Core[$i]) "}
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
   if($Platforms -eq "windows"){$NVIDIAOCArgs += "-setMemoryClockOffset:$($GCount.NVIDIA.$GPU),0,$($Mem[$i]) "} 
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
 $Fans = $_.ocfans -split ' '
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
      $VoltArgs = @()
      $DOAmdOC = $true
     for($i=0; $i -lt $OCDevices.Count; $i++)
     {
       $GPU = $OCDevices[$i]
      if($Platforms -eq "linux")
      {
        for($ia=0; $ia -lt 16; $ia++)
        {
        if($Voltage[$GPU]){$VoltArgs += "wolfamdctrl -i $($GCount.AMD.$GPU) --vddc-table-set $($Voltage[$GPU]) --volt-state $ia"}
        $VoltArgs += "sleep .1"
        }
       }
      }
      $AScript += $VoltArgs
      $AScreenPower += "$($_.Type) V is $($_.ocv) "
     }

     if($Fans)
     {
      for($i=0; $i -lt $OCDevices.Count; $i++)
      {
       $DOAmdOC = $true
       $GPU = $OCDevices[$i]
       if($Platforms -eq "linux")
       {
         $FanArgs = $null
         if($Fans[$GPU]){$Fanargs += " --set-fanspeed $($Fans[$i])"}
         $WolfArgs = "wolfamdctrl -i $($GCount.AMD.$GPU)$FanArgs"
         $AScript += $WolfArgs
         $AScript += "sleep .1"
       }
      }
      $AScreenFans += "$($.Type) V is $($.ocfans) "
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
$script | Out-File "NVIDIA-oc-start.ps1"
$Command = start-process "powershell.exe" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\NVIDIA-oc-start.ps1""" -PassThru
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
