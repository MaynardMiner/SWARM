<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

param(
[Parameter(Mandatory=$false)]
[String]$WorkingDir,
[Parameter(Mandatory=$false)]
[String]$Platforms,
[Parameter(Mandatory=$false)]
[String]$HiveId,
[Parameter(Mandatory=$false)]
[String]$HivePassword,
[Parameter(Mandatory=$false)]
[String]$HiveMirror,
[Parameter(Mandatory=$false)]
[String]$HiveOS,
[Parameter(Mandatory=$false)]
[Double]$RejPercent
)

$Platforms = "linux"
$HiveOS = "Yes"

##Icon for windows
if($Platforms -eq "windows")
 {
  Set-Location $WorkingDir; Invoke-Expression ".\build\powershell\icon.ps1 `"$WorkingDir\build\apps\comb.ico`""
  $Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black')
  $Host.UI.RawUI.ForegroundColor = 'White'
  $Host.PrivateData.ErrorForegroundColor = 'Red'
  $Host.PrivateData.ErrorBackgroundColor = $bckgrnd
  $Host.PrivateData.WarningForegroundColor = 'Magenta'
  $Host.PrivateData.WarningBackgroundColor = $bckgrnd
  $Host.PrivateData.DebugForegroundColor = 'Yellow'
  $Host.PrivateData.DebugBackgroundColor = $bckgrnd
  $Host.PrivateData.VerboseForegroundColor = 'Green'
  $Host.PrivateData.VerboseBackgroundColor = $bckgrnd
  $Host.PrivateData.ProgressForegroundColor = 'Cyan'
  $Host.PrivateData.ProgressBackgroundColor = $bckgrnd
  Clear-Host  
 }

## Codebase for Further Functions
. .\build\powershell\hashrates.ps1
. .\build\powershell\commandweb.ps1
. .\build\powershell\response.ps1
. .\build\powershell\hiveoc.ps1
. .\build\powershell\octune.ps1
. .\build\powershell\statcommand.ps1

## Simplified functions (To Shorten)
function Get-GPUs {$GPU = $Devices[$i]; $GCount.$TypeS.$GPU};

function Write-MinerData1 {
  Write-Host "Miner $MinerType is $MinerAPI api"
  Write-Host "Miner Port is $Port"
  Write-Host "Miner Devices is $Devices"
  Write-Host "Miner is Mining $MinerAlgo"
}

function Write-MinerData2 {
  $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
  Write-Host "Miner $Name was clocked at $([Double]$RAW)" -foreground Yellow
  if($Platforms -eq "linux"){$Process = Get-Process | Where Name -clike "*$($MinerType)*"}
  Write-Host "Current Running instances: $($Process.Name)
"
}
function Set-Array{
  param(
  [Parameter(Position=0, Mandatory=$true)]
  [Object]$ParseRates,
  [Parameter(Position=1, Mandatory=$true)]
  [int]$i,
  [Parameter(Position=2, Mandatory=$false)]
  [string]$factor
  )
  try{
  $Parsed = $ParseRates | %{iex $_}
  switch($factor)
   {
    "hs"{$factor = 1}
    "khs"{$factor = 1000}
    default{$factor = 1}
   }
  if($ParseRates.Count -eq 1){[Double]$Parse = $Parsed}
  elseif($ParseRates.Count -gt 1){[Double]$Parse = $Parsed[$i]}
  $Parse/$factor
  }catch
   {
    $Parse = 0
    $Parse
   }
  }

function Set-APIFailure {
  Write-Host "API Summary Failed- Could Not Total Hashrate Or No Accepted Shares" -Foreground Red; 
  $RAW | Set-Content ".\build\txt\$MinerType-hash.txt";
}
  

## NVIDIA HWMON
function Set-NvidiaStats {

  if($Platforms -eq "linux")
  {
  timeout -s9 10 ./build/apps/VII-smi | Tee-Object -Variable getstats | Out-Null
  if($getstats)
   {
    $nvidiai = $getstats | ConvertFrom-StringData
    $nvinfo = @{}
    $nvinfo.Add("Fans",@())
    $nvinfo.Add("Temps",@())
    $nvinfo.Add("Watts",@())
    $nvidiai.keys | foreach {if($_ -like "*fan*"){$nvinfo.Fans += $nvidiai.$_}}
    $nvidiai.keys | foreach {if($_ -like "*temperature*"){$nvinfo.Temps += $nvidiai.$_}}
    $nvidiai.keys | foreach {if($_ -like "*power*"){if($nvidiai.$_ -eq "failed to get"){$nvinfo.Watts += "75"}else{$nvinfo.Watts += $nvidiai.$_}}}
   }
  }

  elseif($Platforms -eq "windows")
  {
    invoke-expression ".\build\apps\nvidia-smi.exe --query-gpu=power.draw,fan.speed,temperature.gpu --format=csv" | Tee-Object -Variable nvidiaout | Out-Null
    if($nvidiaout){$ninfo = $nvidiaout | ConvertFrom-Csv
    $NVIDIAFans = $ninfo.'fan.speed [%]' | foreach {$_ -replace ("\%","")}
    $NVIDIATemps = $ninfo.'temperature.gpu'
    $NVIDIAPower = $ninfo.'power.draw [W]' | foreach {$_ -replace ("\[Not Supported\]","75")} | foreach {$_ -replace (" W","")}        
    $NVIDIAStats = @{}
    $NVIDIAStats.Add("Fans",$NVIDIAFans)
    $NVIDIAStats.Add("Temps",$NVIDIATemps)
    $NVIDIAStats.Add("Power",$NVIDIAPower)
    $nvinfo = $NVIDIAStats  
    }
  }
  $nvinfo
}

## AMD HWMON
function Set-AMDStats {

if($Platforms -eq "windows")
{
Invoke-Expression ".\build\apps\odvii.exe s" | Tee-Object -Variable amdout | Out-Null
 if($amdout)
  {
   $AMDStats = @{}
   $amdinfo = $amdout | ConvertFrom-StringData
   $ainfo = @{}
   $aerrors = @{}
   $aerrors.Add("Errors",@())
   $ainfo.Add("Fans",@())
   $ainfo.Add("Temps",@())
   $ainfo.Add("Watts",@())
   $amdinfo.keys | foreach {if($_ -like "*Fan*"){$ainfo.Fans += $amdinfo.$_}}
   $amdinfo.keys | foreach {if($_ -like "*Temp*"){$ainfo.Temps += $amdinfo.$_}}
   $amdinfo.keys | foreach {if($_ -like "*Watts*"){$ainfo.Watts += $amdinfo.$_}}
   $amdinfo.keys | foreach {if($_ -like "*Errors*"){$aerrors.Errors += $amdinfo.$_}}
   $AMDFans = $ainfo.Fans
   $AMDTemps = $ainfo.Temps
   $AMDPower = $ainfo.Watts
   if($aerrors.Errors)
   {
    Write-Host "Warning Errors Detected From Drivers:" -ForegroundColor Red
    $aerrors.Errors | %{Write-host "$($_)" -ForegroundColor Red}
    Write-Host "Drivers/Settings May Be Set Incorrectly/Not Compatible
" -ForegroundColor Red
   }
  }
}

elseif($Platforms -eq "linux" -and $HiveOS -eq "Yes")
{
  $AMDStats = @{}
  timeout -s9 5 gpu-stats | Tee-Object -Variable amdout | Out-Null
  if($amdout){$Stat = $amdout | ConvertFrom-Json}
  $AMDFans = $Stat.fan
  $AMDTemps = $Stat.temp
}

elseif($Platforms -eq "linux" -and $HiveOS -eq "No")
{
  $AMDStats = @{}
  timeout -s9 10 rocm-smi -f | Tee-Object -Variable AMDFans | Out-Null
  $AMDFans = $AMDFans | Select-String "%" | foreach {$_ -split "\(" | Select -Skip 1 -first 1} | foreach {$_ -split "\)" | Select -first 1}
  timeout -s9 10 rocm-smi -t | Tee-Object -Variable AMDTemps | Out-Null
  $AMDTemps = $AMDTemps | Select-String -CaseSensitive "Temperature" | foreach {$_ -split ":" | Select -skip 2 -First 1} | foreach {$_ -replace (" ","")} | foreach{$_ -replace ("c","")}
}

$AMDStats.Add("Fans",$AMDFans)
$AMDStats.Add("Temps",$AMDTemps)
$AMDStats.Add("Power",$AMDPower)

$AMDStats

}

##Get Active Miners And Devices
$GetMiners = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-Json
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json

##Set Starting Date & Device Flags
$DevNVIDIA = $false
$DevAMD = $false
$StartTime = Get-Date

## Determine Which GPU's to stat
$GetMiners | Foreach {
$NEW=0; 
$NEW | Set-Content ".\build\txt\$($_.Type)-hash.txt";
$Name = $($_.Name)
if($_.Type -like "*NVIDIA*"){$DevNVIDIA = $true; Write-Host "NVIDIA Detected"};
if($_.Type -like "*AMD*"){$DevAMD = $true; "AMD Detected"}
}

## Set-OC
Write-Host "Starting Tuning"
Start-OC -Platforms $Platforms -Dir $WorkingDir

## ADD Delay for OC and Miners To Start Up
Start-Sleep -S 10

## Determine if CPU in only used
$CPUOnly = $true
$GetMiners | Foreach {if($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*"){$CPUOnly = $false; "GPU" | Set-Content ".\build\txt\miner.txt"}}
if($CPUOnly -eq $true){"CPU" | Set-Content ".\build\txt\miner.txt"}

## Build Initial Hash Tables For Stats
$GPUHashrates = [PSCustomObject]@{}
$CPUHashrates = [PSCustomObject]@{}
$GPUFans = [PSCustomObject]@{}
$GPUTemps = [PSCustomObject]@{}
$GPUPower = [PSCustomObject]@{}
for($i=0; $i -lt $GCount.CPU.PSObject.Properties.Value.Count; $i++){$CPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.CPU.$i)" -Value 0;}
if($DevAMD -eq $true){for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUFans | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUPower | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0}}
if($DevNVIDIA -eq $true){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUFans | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUPower | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0}}

##Timers
$BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$BackgroundTimer.Restart()
$RestartTimer = New-Object -TypeName System.Diagnostics.Stopwatch

While($True)
{

## Timer For When To Restart Loop
$RestartTimer.Restart()

## Reset All Stats, Rebuild Tables
$ALGO = @(); $HashRates = @(); $Fans = @(); $Temps = @(); $Power = @(); $RAW = 0; $KHS = 0; $REJ = 0; $ACC = 0;
$GPUHashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{$GPUHashRates.$_ = 0};
$CPUHashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{$CPUHashRates.$_ = 0};
$GPUFans | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{$GPUFans.$_ = 0};
$GPUTemps | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{$GPUTemps.$_ = 0};
$GPUPower | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | %{$GPUPower.$_ = 0};

## Windows-To-Hive Stats
if($Platforms -eq "windows")
{
  ## Rig Metrics
  if($HiveOS -eq "Yes")
  {
  $ramtotal = Get-Content ".\build\txt\ram.txt"
  $cpu = $(Get-WmiObject Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength
  $LoadAverage = Set-Stat -Name "load-average" -Value $cpu
  $LoadAverages = @("$([Math]::Round($LoadAverage.Minute,2))","$([Math]::Round($LoadAverage.Minute_5,2))","$([Math]::Round($LoadAverage.Minute_10,2))")
  $ramfree = $(Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
  }
  if($DevNVIDIA -eq $true){$NVIDIAStats = Set-NvidiaStats}
  if($DevAMD -eq $true){$AMDStats = Set-AMDStats}
}

## Linux-To-Hive Stats
if($Platforms -eq "linux")
{
  if($DevNVIDIA -eq $true){$NVIDIAStats = Set-NvidiaStats}
  if($DevAMD -eq $true){$AMDStats = Set-AMDStats}
}

## Start API Calls For Each Miner
$GetMiners | Foreach {

## Miner Information
$MinerAlgo = "$($_.Algo)"
$MinerName = "$($_.MinerName)"
$Name = "$($_.Name)"
$Server = "localhost"
$Port = $($_.Port)
$MinerType = "$($_.Type)"
$MinerAPI = "$($_.API)"
$HashPath = ".\logs\$($_.Type).log"

## Set Object For Type (So It doesn't need to be repeated)
if($MinerType -like "*NVIDIA*"){$TypeS = "NVIDIA"}
elseif($MinerType -like "*AMD*"){$TypeS = "AMD"}
elseif($MinerType -like "*CPU*"){$TypeS = "CPU"}

## Determine Devices
if($_.Type -ne "CPU")
{
 if($_.Devices -eq $null){$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}
 else{$Devices = Get-DeviceString -TypeDevices $_.Devices}
}
elseif($_.Type -eq "CPU"){$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}


## First Power For Windows
if($Platforms -eq "windows" -and $HiveOS -eq "Yes")
 {
   if($TypeS -eq "NVIDIA"){$StatPower = $NVIDIAStats.Power}
   if($TypeS -eq "AMD"){$StatPower = $AMDStats.Power}
   if($StatPower -ne "" -or $StatPower -ne $null){for($i=0;$i -lt $Devices.Count; $i++){$GPUPower.$(Get-GPUS) = Set-Array $StatPower $i}}
 }


## Now Fans & Temps
if($MinerType -Like "*NVIDIA*")
{
  for($i=0;$i -lt $Devices.Count; $i++){try{$GPUFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $i}catch{Write-Host "Failed To Parse GPU Array" -foregroundcolor red; break}}
  for($i=0;$i -lt $Devices.Count; $i++){try{$GPUTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $i}catch{Write-Host "Failed To Parse GPU Array" -foregroundcolor red; break}}
}
if($MinerType -Like "*AMD*")
{
  for($i=0;$i -lt $Devices.Count; $i++){try{$GPUFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $i}catch{Write-Host "Failed To Parse GPU Array" -foregroundcolor red; break}}
  for($i=0;$i -lt $Devices.Count; $i++){try{$GPUTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $i}catch{Write-Host "Failed To Parse GPU Array" -foregroundcolor red}; break}
}

## Set Initial Output
$HS = "khs"
$RAW = 0
$MinerACC = 0
$MinerREJ = 0
Write-MinerData1

## Start Calling Miners

switch($MinerAPI)
{

  'claymore'
  {
   if($MinerName = "PhoenixMiner"){$Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat2"} | ConvertTo-Json -Compress}
   else{$Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat2"} | ConvertTo-Json -Compress}
   $Request = $null; $Request = Get-TCP -Server $Server -Port $Port -Message $Message 
    if($Request)
    {
     try{$Data = $Null; $Data = $Request | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
     $RAW += $Data.result[2] -split ";" | Select -First 1 | %{[Double]$_*1000};
     Write-MinerData2;
     $KHS += $Data.result[2] -split ";" | Select -First 1 | %{[Double]$_};
     $Hash = $Null; $Hash = $Data.result[3] -split ";";
     try{for($i=0;$i -lt $Devices.Count; $i++){$GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i $HS}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
     $MinerACC = $Data.result[2] -split ";" | Select -skip 1 -first 1
     $MinerREJ = $Data.result[2] -split ";" | Select -skip 2 -first 1
     $ACC += $Data.result[2] -split ";" | Select -skip 1 -first 1
     $REJ += $Data.result[2] -split ";" | Select -skip 2 -first 1
     $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
     $A = $Data.result[6] -split ";"
     $ALGO += "$MinerAlgo"
    }
    else{Set-APIFailure; break}
   }

  'excavator'
  {
   $HS = "khs"
   $RAW = 0
   Write-MinerData1
   $Message = $null; $Message = @{id=1; method = "algorithm.list"; params=@()} | ConvertTo-Json -Compress
   $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
   if($Request)
    {
    try{$Data = $Null; $Data = $Request | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
    $RAW = $Summary.algorithms.speed
    Write-MinerData2;
    $KHS += [Double]$Summary.algorithms.speed/1000
    }
    else{Set-APIFailure; break}
    $Message = @{id=1; method = "worker.list"; params=@()} | ConvertTo-Json -Compress
    $GetThreads = $Null; $GetThreads = Get-TCP -Server $Server -Port $port -Message $Message
    if($GetThreads)
    {
    $Threads = $GetThreads | ConvertFrom-Json
    $Hash = $Null; $Hash = $Threads.workers.algorithms.speed
    try{for($i=0;$i -lt $Devices.Count; $i++){$GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i $HS}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
    $ACC += $Summary.algorithms.accepted_shares
    $REJ += $Summary.algorithms.rejected_shares
    $MinerACC += $Summary.algorithms.accepted_shares
    $MinerREJ += $Summary.algorithms.rejected_shares
    $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
    $ALGO += "$($Summary.algorithms.name)"
    }
    else{Write-Host "API Threads Failed"; break}
  }

  'miniz'
  {
   $HS = "hs"
   try{$Request = $Null; $Request = Invoke-Webrequest "http://$($server):$port" -UseBasicParsing -TimeoutSec 10}catch{}
   if($Request)
   {
    $Data =$null; $Data = $Request.Content -split " "
    $Hash = $Null; $Hash = $Data | Select-String "Sol/s" | Select-STring "data-label" | foreach {$_ -split "</td>" | Select -First 1} | foreach{$_ -split ">" | Select -Last 1}
    $RAW = $Hash | Select -Last 1
    Write-MinerData2;
    $KHS += [Double]$RAW/1000
    $Shares = $Data | Select-String "Shares" | Select -Last 1 | foreach{$_ -split "</td>" | Select -First 1} | Foreach{$_ -split ">" | Select -Last 1}
    $ACC += $Shares -split "/" | Select -first 1
    $REJ += $Shares -split "/" | Select -Last 1
    $MinerACC = $Shares -split "/" | Select -first 1
    $MinerREJ = $Shares -split "/" | Select -Last 1
    try{for($i=0;$i -lt $Devices.Count; $i++){$GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i $HS}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
    $ALGO += "$MinerAlgo"
    $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
   }
   else{Set-APIFailure; break}
  }

  'ewbf'
  {
   $HS = "hs"
   $Message = $null; $Message = @{id = 1; method = "getstat"} | ConvertTo-Json -Compress
   $Request = $Null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
   if($Request)
    { 
     try{$Data = $Null; $Data = $Request | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
     $Data = $Data.result
     $Data.speed_sps | foreach {$RAW += [Double]$_}
     $Hash = $Null; $Hash = $Data.speed_sps
     Write-MinerData2;
     try{for($i=0;$i -lt $Devices.Count; $i++){$GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i $HS}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
     $Data.accepted_shares | Foreach {$MinerACC += $_}
     $Data.rejected_shares | Foreach {$MinerREJ += $_}
     $Data.accepted_shares | Foreach {$ACC += $_}
     $Data.rejected_shares | Foreach {$REJ += $_}
     $Data.speed_sps | foreach {$KHS += [Double]$_}
     $UPTIME = ((Get-Date) - [DateTime]$Data.start_time[0]).seconds
    }
    else{Set-APIFailure; break}
  }

 'ccminer'
  {
   $HS = "khs"
   $Request = $Null; $Request = Get-TCP -Server $Server -Port $port -Message "summary"
   if($Request)
    {
     $Multiplier = 1000
     try{$GetKHS = $Request -split ";" | ConvertFrom-StringData}catch{Write-Warning "Failed To Get Summary"}
     $RAW = if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) {[Double]$GetKHS.KHS * $Multiplier}
     Write-MinerData2;
     $KHS += if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) {[Double]$GetKHS.KHS}
    }
    else{Set-APIFailure; break}
    $GetThreads = $Null; $GetThreads = Get-TCP -Server $Server -Port $port -Message "threads"
    if($GetThreads)
     {
      $Data = $null; $Data = $GetThreads -split "\|"
      $Hash = $Null; $Hash = $Data -split ";" | Select-String "KHS" | foreach {$_ -replace ("KHS=","")}
      try{for($i=0;$i -lt $Devices.Count; $i++){$GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
      $MinerACC += $GetSummary -split ";" | Select-String "ACC=" | foreach{$_ -replace ("ACC=","")}
      $MinerREJ += $GetSummary -split ";" | Select-String "REJ=" | foreach{$_ -replace ("REJ=","")}
      $ACC += $GetSummary -split ";" | Select-String "ACC=" | foreach{$_ -replace ("ACC=","")}
      $REJ += $GetSummary -split ";" | Select-String "REJ=" | foreach{$_ -replace ("REJ=","")}
      $ALGO += "$MinerAlgo"
      $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
     }
     else{Write-Host "API Threads Failed"; break}
  }

  'bminer'
  {
   if($MinerAlgo -eq "daggerhashimoto"){$HS = "khs"}
   elseif($MinerAlgo -eq "zhash"){$HS = "hs"}
   $Request = $Null; $Request = Get-HTTP -Port $Port -Message "/api/status"
   if($Request)
    {
     try{$Data = $Null; $Data = $Request.Content | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
     for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $RAW += [Double]$Data.Miners.$GPU.solver.solution_rate}
     Write-MinerData2;
     $Hash = $Null; $Hash = $Data.Miners
     if($HS -eq "hs"){$HashFactor = 1}
     if($HS -eq "khs"){$Hashfactor = 1000}
     try{for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$(Get-Gpus) = [Double]$Hash.$GPU.solver.solution_rate/$HashFactor}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
     $Data.stratum.accepted_shares | Foreach {$MinerACC += $_}
     $Data.stratum.rejected_shares | Foreach {$MinerREJ += $_}
     $Data.stratum.accepted_shares | Foreach {$ACC += $_}
     $Data.stratum.rejected_shares | Foreach {$REJ += $_}
     for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $KHS += [Double]$Data.Miners.$GPU.solver.solution_rate/$HashFactor}
     $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
     $ALGO += "$MinerAlgo"
    }
    else{Set-APIFailure; break}
  }

  'trex'
  {
   $HS = "khs"
   $Request = $Null; $Request = Get-HTTP -Port $Port -Message "/summary"
   if($Request)
    {
     try{$Data = $Null; $Data = $Request.Content | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
     $RAW = if([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0){[Double]$Data.hashrate_minute}
     Write-MinerData2;
     $Hash = $Null; $Hash = $Data.gpus.hashrate_minute
     try{for($i=0;$i -lt $Devices.Count; $i++){$GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i $HS}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
     $Data.accepted_count | Foreach {$MinerACC += $_}
     $Data.rejected_count | Foreach {$MinerREJ += $_}
     $Data.accepted_count | Foreach {$ACC += $_}
     $Data.rejected_count | Foreach {$REJ += $_}
     $KHS = if([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0){[Double]$Data.hashrate_minute/1000}
     $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
     $ALGO += "$($Data.Algorithm)"
    }
    else{Set-APIFailure; break}
  }
  
 'dstm'
 {
  $HS = "hs"
  $Request = $Null; $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message "summary"
  if($Request)
   {
    try{$Data = $Null; $Data = $Request | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
    $Data = $Data.result
    $Data.sol_ps | foreach {$RAW += [Double]$_}
    Write-MinerData2;
    $Hash = $Null; $Hash = $Data.sol_ps
    try{for($i=0;$i -lt $Devices.Count; $i++){$GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i $HS}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
    $Data.rejected_shares | Foreach {$MinerREJ += $_}
    $Data.accepted_shares | Foreach {$MinerACC += $_}  
    $Data.rejected_shares | Foreach {$REJ += $_}
    $Data.accepted_shares | Foreach {$ACC += $_}
    $Data.sol_ps | foreach {$KHS += [Double]$_}
    $ALGO += "$MinerAlgo"
    $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
   }
   else{Set-APIFailure; break}
 }

 'sgminer-gm'
 {
  $HS = "hs"
  $Message = $null; $Message = @{command="summary+devs"; parameter=""} | ConvertTo-Json -Compress
  $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
  if($Request)
   {
    $Tryother = $false
    try{$Data = $Null; $Data = $Request | ConvertFrom-Json}catch{$Tryother = $true}
    if($Tryother -eq $true)
     {
        try{
          $Request = $Request.Substring($Request.IndexOf("{"), $Request.LastIndexOf("}") - $Request.IndexOf("{") + 1) -replace " ", "_"
          $Data = $Request | ConvertFrom-Json
          }catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
     }
    $summary = $Data.summary.summary
    $threads = $Data.devs.devs
    $Hash = $Null; $Sum = $Null;
    if($summary."KHS_5s"){$Sum = $summary."KHS_5s"}else{$Sum = $summary.'KHS_30s'}
    if($threads."KHS_5s"){$Hash = $threads."KHS_5s"}else{$Hash = $threads."KHS_30s"}
    $RAW += [Double]$Sum*1000
    $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    Write-MinerData2;
    $KHS += $Sum
    try{for($i=0;$i -lt $Devices.Count; $i++){$GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
    $summary.Rejected | Foreach {$MinerREJ += $_}
    $summary.Accepted | Foreach {$MinerACC += $_}    
    $summary.Rejected | Foreach {$REJ += $_}
    $summary.Accepted | Foreach {$ACC += $_}
    $ALGO += "$MinerALgo"
    $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
   }
   else{Set-APIFailure; break}
 }

'cpuminer'
 {
  $GetCPUSUmmary = $Null; $GetCPUSummary = Get-TCP -Server $Server -Port $Port -Message "summary"
  if($GetCPUSummary)
   {
    $CPUSUM = $GetCPUSummary -split ";" | Select-String "KHS=" | foreach {$_ -replace ("KHS=","")}
    $CPURAW = [double]$CPUSUM*1000
    $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"
   }
  else{Write-Host "API Summary Failed- Could Not Total Hashrate" -Foreground Red; $CPURAW = 0; $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
  $GetCPUThreads = $Null
  $GetCPUThreads = Get-TCP -Server $Server -Port $Port -Message "threads"
  if($GetCPUThreads)
   {
    $Data = $GetCPUThreads -split "\|"
    $kilo = $false
    $KHash = $Data | Select-String "kH/s"
    if($KHash){$Hash = $Data -split ";" | Select-String "kH/s"; $kilo = $true}
    else{$Hash = $Data -split ";" | Select-String "H/s"; $kilo = $false}
    $Hash = $Hash | foreach {$_ -split "=" | Select -Last 1 }
    $J = $Hash | % {iex $_}
    $CPUHash = @()
    if($kilo -eq $true)
    {
     $CPUKHS = 0
     if($Hash){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $CPUHashrates.$($GCount.$TypeS.$GPU) = $(if($J.Count -eq 1){$J}else{$J[$i]})}}
     $J |Foreach {$CPUKHS += $_}
     $CPUHS = "khs"
    }
    else
    {
     $CPUKHS = 0
     if($Hash){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $CPUHashrates.$($GCount.$TypeS.$GPU) = $(if($J.Count -eq 1){$J/1000}else{$J[$i]/1000})}}
     $J |Foreach {$CPUKHS += $_}
     $CPUHS = "hs"
    }
    $CPUHashrates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$CPUHash += "CPU=$($CPUHashRates.$_)"}
    $CPUACC = $GetCPUSummary -split ";" | Select-String "ACC=" | foreach{$_ -replace ("ACC=","")}
    $CPUREJ = $GetCPUSummary -split ";" | Select-String "REJ=" | foreach{$_ -replace ("REJ=","")}
    $CPUUPTIME = $GetCPUSummary -split ";" | Select-String "UPTIME=" | foreach{$_ -replace ("UPTIME=","")}
    $CPUALGO = $GetCPUSummary -split ";" | Select-String "ALGO=" | foreach{$_ -replace ("ALGO=","")}
    $CPUTEMP = $GetCPUSummary -split ";" | Select-String "TEMP=" | foreach{$_ -replace ("TEMP=","")}
    $CPUFAN = $GetCPUSummary -split ";" | Select-String "FAN=" | foreach{$_ -replace ("FAN=","")}
   }
  else{Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red}
  }

'xmrstak'
{
 $HS = "hs"
 Write-Host "Note: XMR-STAK API sucks. You can't match threads to GPU." -ForegroundColor Yellow
 $Message = $Null; $Message="/api.json"
 $Request = $Null; $Request = Get-HTTP -Port $Port -Message $Message
 if($Request)
  {
   try{$Data = $Null; $Data = $Request.Content | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
   $Hash = for($i=0; $i -lt $Data.hashrate.threads.count; $i++){$Data.Hashrate.threads[$i] | Select -First 1}
   $RAW = $Data.hashrate.total | Select -First 1
   Write-MinerData2;
   try{for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$(Get-Gpus) = $Hash[$GPU] | Select -First 1}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
   $MinerACC += $Data.results.shares_good
   $MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
   $ACC += $Data.results.shares_good
   $REJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
   $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
   $ALGO += "$MinerAlgo"
   $KHS = [Double]$Data.hashrate.total[0]
  }
  else{Set-APIFailure; break}
}

 'xmrstak-opt'
 {
  Write-Host "Miner $MinerType is xmrstak api"
  Write-Host "Miner Devices is $Devices"
  Write-Host "Note: XMR-STAK API sucks. You can't match threads to GPU." -ForegroundColor Yellow
  $CPUHS = "hs"
  $Message ="/api.json"
  $Request = $Null
  $Request = Get-HTTP -Port $Port -Message $Message
  if($Request)
   {
    try{$Data = $Null; $Data = $Request.Content | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
    $Hash = $Data.Hashrate.threads
    $CPURAW = [Double]$Data.hashrate.total[0]
    $CPUKHS = [Double]$Data.hashrate.total[0]
    $CPUSUM = [Double]$Data.hashrate.total[0]
    $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $CPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){[Double]$($Hash[0] | Select -first 1)}else{[Double]$($Hash[$i] | Select -First 1)})}
    $MinerACC = 0
    $MinerREJ = 0
    $MinerACC += $Data.results.shares_good
    $MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
    $CPUACC += $Data.results.shares_good
    $CPUREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
    $CPUUPTIME = $Data.connection.uptime
    $CPUALGO = $MinerAlgo
    }
    else{Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $CPURAW = 0; $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
  }

  'wildrig'
  {
   $HS = "khs"
   $Message = $Null; $Message = '/api.json'
   $Request = $Null; $Request = Get-HTTP -Port $Port -Message $Message
   if($Request)
    {
     try{$Data = $Null; $Data = $Request.Content | ConvertFrom-Json;}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
     $RAW = $Data.hashrate.total[0]
     Write-MinerData2;
     $Hash = $Data.hashrate.threads
     try{for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$(Get-Gpus) = $Hash[$GPU] | Select -First 1}}catch{Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
     $MinerACC += $Data.results.shares_good
     $MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good 
     $ACC += $Data.results.shares_good
     $REJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
     $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
     $ALGO += "$MinerAlgo"
     $KHS = [Double]$Data.hashrate.total[0]/1000
   }
   else{Set-APIFailure; break}
  }

}

##Check To See if High Rejections
if($BackgroundTimer.Elapsed.TotalSeconds -gt 60)
 {
  $Shares = [Double]$MinerACC + [double]$MinerREJ
  $RJPercent = $MinerREJ/$Shares*100
  if($RJPercent -gt $RejPercent)
  {
   Write-Host "Warning: Miner is reaching Rejection Limit- $($RJPercent.ToString("N2")) Percent Out of $Shares Shares" -foreground yellow
   if(-not (Test-Path ".\timeout")){New-Item "timeout" -ItemType Directory | Out-Null}
   if(-not (Test-Path ".\timeout\warnings")){New-Item ".\timeout\warnings" -ItemType Directory | Out-Null}
   "Bad Shares" | Out-File ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt"
  }
  else{if(Test-Path ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt"){Remove-Item ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt" -Force}}
 }
 
}

if($CPUOnly -eq $true)
{
$HIVE="
$($CPUHash -join "`n")
KHS=$({0:n2} -f $CPUKHS)
ACC=$CPUACC
REJ=$CPUREJ
ALGO=$CPUALGO
TEMP=$CPUTEMP
FAN=$CPUFAN
UPTIME=$CPUUPTIME
HSU=$CPUHS
"
$Hive
$Hive | Set-Content ".\build\bash\hivestats.sh"
}

else
{
  if($DEVNVIDIA -eq $True){if($GCount.NVIDIA.PSObject.Properties.Value.Count -gt 0){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$HashRates += 0; $Fans += 0; $Temps += 0}}}
  if($DevAMD -eq $True){if($GCount.AMD.PSObject.Properties.Value.Count -gt 0){for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$HashRates += 0; $Fans += 0; $Temps += 0}}}
  if($DEVNVIDIA -eq $True){for($i=0; $i -lt $GCount.NVIDIA.PSOBject.Properties.Value.Count; $i++){$HashRates[$($GCount.NVIDIA.$i)] = "GPU={0:f2}" -f $($GPUHashRates.$($GCount.NVIDIA.$i))}}
  if($DevAMD -eq $True){for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$HashRates[$($GCount.AMD.$i)] = "GPU={0:f2}" -f $($GPUHashRates.$($GCount.AMD.$i))}}
  if($DEVNVIDIA -eq $True){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$Fans[$($GCount.NVIDIA.$i)] = "FAN=$($GPUFans.$($GCount.NVIDIA.$i))"}}
  if($DevAMD -eq $True){for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$Fans[$($GCount.AMD.$i)] = "FAN=$($GPUFans.$($GCount.AMD.$i))"}}
  if($DEVNVIDIA -eq $True){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$Temps[$($GCount.NVIDIA.$i)] = "TEMP=$($GPUTemps.$($GCount.NVIDIA.$i))"}}
  if($DevAMD -eq $True){for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$Temps[$($GCount.AMD.$i)] = "TEMP=$($GPUTemps.$($GCount.AMD.$i))"}}
  if($Platforms -eq "windows" -and $HiveOS -eq "Yes")
  {
  if($DEVNVIDIA -eq $True){if($GCount.NVIDIA.PSObject.Properties.Value.Count -gt 0){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$Power += 0}}}
  if($DevAMD -eq $True){if($GCount.AMD.PSObject.Properties.Value.Count -gt 0){for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$Power += 0}}}
  if($DEVNVIDIA -eq $True){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$Power[$($GCount.NVIDIA.$i)] = "POWER=$($GPUPower.$($GCount.NVIDIA.$i))"}}
  if($DevAMD -eq $True){for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$Power[$($GCount.AMD.$i)] = "POWER=$($GPUPower.$($GCount.AMD.$i))"}}
  }  
  for($i=0; $i -lt $HashRates.count; $i++)
  {
   if($HashRates[$i] -eq 'GPU=0' -or $HashRates[$i] -eq 'GPU=' -or $HashRates[$i] -eq 'GPU=0.00')
    {
     if($HS -eq "khs"){$HashRates[$i] = 'GPU=0.001'; $KHS += 0.001}
     elseif($HS -eq "hs"){$HashRates[$i] = 'GPU=1'; $KHS += 1}
    }
   }

$KHS = '{0:f2}' -f $KHS
$ALGO = $ALGO | Select -First 1

$HIVE="
$($HashRates -join "`n")
KHS=$KHS
ACC=$ACC
REJ=$REJ
ALGO=$ALGO
$($Fans -join "`n")
$($Temps -join "`n")
UPTIME=$UPTIME
HSU=$HS
"

Write-Host "$HashRates" -ForegroundColor Green -NoNewline
Write-Host " KHS=$KHS" -ForegroundColor Yellow -NoNewline
Write-Host " ACC=$ACC" -ForegroundColor DarkGreen -NoNewline
Write-Host " REJ=$REJ" -ForegroundColor DarkRed -NoNewline
Write-Host " ALGO=$ALGO" -ForegroundColor Gray -NoNewline
Write-Host " $Fans" -ForegroundColor Cyan -NoNewline
Write-Host " $Temps" -ForegroundColor Magenta -NoNewline
if($Platforms -eq "windows"){Write-Host " $Power"  -ForegroundColor DarkCyan -NoNewline}
Write-Host " UPTIME=$UPTIME" -ForegroundColor White

if($CPUKHS -ne $null){Write-Host "CPU=$CPUSUM"}
$Hive | Set-Content ".\build\bash\hivestats.sh"
}

if($Platforms -eq "windows" -and $HiveOS -eq "Yes")
 {
  $Stats = Build-HiveResponse
  try{$response = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($Stats | ConvertTo-Json -Depth 4 -Compress) -ContentType 'application/json'}
  catch{Write-Warning "Failed To Contact HiveOS.Farm"; $response = $null}
  $response | ConvertTo-Json | Set-Content ".\build\txt\response.txt"
  if($response)
  {
   $SwarmResponse = Start-webcommand -command $response -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror
   if($SwarmResponse -ne $null)
    {
    if($SwarmResponse -eq "config")
     {
      Write-Warning "Config Command Initiated- Restarting SWARM"
      $MinerFile =".\build\pid\miner_pid.txt"
      if(Test-Path $MinerFile){$MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue}
      if($MinerId)
       {
        Stop-Process $MinerId
        Start-Sleep -S 3
       }
      Start-Process ".\SWARM.bat"
      Start-Sleep -S 3
      $ID = ".\build\pid\background_pid.txt"
      $BackGroundID = Get-Process -id (Get-Content "$ID" -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue
       Stop-Process $BackGroundID | Out-Null
     }
    if($SwarmResponse -eq "stats")
     {
      Write-Host "Hive Received Stats
"
     }
    if($SwarmResponse -eq "exec")
     {
      Write-Host "Sent Command To Hive"
     }
    }
  }
}

if($BackgroundTimer.Elapsed.TotalSeconds -gt 120){Clear-Content ".\build\bash\hivestats.sh"; $BackgroundTimer.Restart()}

if($RestartTimer.Elapsed.TotalSeconds -le 10)
{
 $GoToSleep = [math]::Round(10 - $RestartTimer.Elapsed.TotalSeconds)
 if($GoToSleep -gt 0){Start-Sleep -S $GoToSleep}
}

}
