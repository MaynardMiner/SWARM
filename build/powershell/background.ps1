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

function Get-NvidiaTemps {
  if($HiveOS -eq "No")
   {
  timeout -s9 10 nvidia-smi --query-gpu=temperature.gpu --format=csv | Tee-Object ".\build\txt\gputemps.txt" | Out-Null
  Start-Sleep -S .25
  if(Test-path ".\build\txt\gputemps.txt"){$gettemps = Get-Content ".\build\txt\gputemps.txt" | ConvertFrom-Csv}
  $NVIDIATemps = $gettemps.'temperature.gpu'
  $NVIDIATemps
   }
   else{
    $A = timeout -s9 10 gpu-stats
    if($A){$Stat = $A | ConvertFrom-Json}
    $Stat.temp | Select -skip 1
    }  
}

function Get-NvidiaFans {
  if($HiveOS -eq "No")
  {
  timeout -s9 10 nvidia-smi --query-gpu=fan.speed --format=csv | Tee-Object ".\build\txt\gpufans.txt" | Out-Null
  Start-Sleep -S .25
  if(Test-path ".\build\txt\gpufans.txt"){$getfan = Get-Content ".\build\txt\gpufans.txt" | ConvertFrom-Csv}
  $NVIDIAFans = $getfan.'fan.speed [%]' | foreach {$_ -replace ("\%","")}
  $NVIDIAFans
  }
  else{
    $A = timeout -s9 10 gpu-stats
    if($A){$Stat = $A | ConvertFrom-Json}
    $Stat.fan | Select -skip 1
      }  
    }

function Get-AMDFans{
  if($HiveOS -eq "No")
  {
  timeout -s9 10 rocm-smi -f | Tee-Object ".\build\txt\gpufan.txt" | Out-Null
  Start-Sleep -S .25
  if(Test-path ".\build\txt\gpufan.txt"){$getfan = Get-Content ".\build\txt\gpufan.txt"}
  $AMDFans = $getfan | Select-String "%" | foreach {$_ -split "\(" | Select -Skip 1 -first 1} | foreach {$_ -split "\)" | Select -first 1}
  $AMDFans
  }
  else{
    $A = timeout -s9 10 gpu-stats
    if($A){$Stat = $A | ConvertFrom-Json}
    $Stat.fan | Select -skip 1
      }  
}

function Get-AMDTemps {
  if($HiveOS -eq "No")
  {
  timeout -s9 10 rocm-smi -t | Tee-Object ".\build\txt\gputemp.txt" | Out-Null
  if(Test-path ".\build\txt\gputemp.txt"){$gettemps = Get-Content ".\build\txt\gputemp.txt"}
  $AMDTemps = $gettemps | Select-String -CaseSensitive "Temperature" | foreach {$_ -split ":" | Select -skip 2 -First 1} | foreach {$_ -replace (" ","")} | foreach{$_ -replace ("c","")}
  $AMDTemps
  }
  else{
    $A = timeout -s9 10 gpu-stats
    if($A){$Stat = $A | ConvertFrom-Json}
    $Stat.temp | Select -skip 1
      }  
}

if($Platforms -eq "windows"){Set-Location $WorkingDir}

##Functions:
. .\build\powershell\hashrates.ps1
. .\build\powershell\octune.ps1
. .\build\powershell\commandweb.ps1
. .\build\powershell\powerup.ps1

##Data
$GetMiners = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-Json
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json

##Set-OC
$OC = $false
$GetMiners | foreach {
 if($_.Type -like "*NVIDIA*" -and $OC -eq $false)
 {
  Write-Host "Starting Tuning"
  Start-OC -Devices $_.Devices -OCType $($_.Type) -Miner_Algo $($_.Algo) -Platforms $Platforms -Dir $WorkingDir
  $OC = $true
 }
}

$CPUOnly = $true

$GetMiners | Foreach {
  if($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*"){$CPUOnly = $false; "GPU" | Set-Content ".\build\txt\miner.txt"}
}
if($CPUOnly -eq $true){"CPU" | Set-Content ".\build\txt\miner.txt"}

$BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$BackgroundTimer.Restart()

$GetMiners | Foreach {
$NEW=0 
$NEW | Set-Content ".\build\txt\$($_.Type)-hash.txt" 
}
$StartTime = Get-Date

While($True)
{
$GPUHashrates = [PSCustomObject]@{}
$CPUHashrates = [PSCustomObject]@{}
$GPUFans = [PSCustomObject]@{}
$GPUTemps = [PSCustomObject]@{}
$GPUPower = [PSCustomObject]@{}
$KHS = 0
$CPUKHS = 0
$REJ = 0
$ACC = 0
for($i=0; $i -lt $GCount.CPU.PSObject.Properties.Value.Count; $i++){$CPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.CPU.$i)" -Value 0;}
for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUFans | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUPower | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0}
for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUFans | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUPower | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0}


if($Platforms -eq "windows")
{
$CheckTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$CheckTimer.Restart()
if(Test-Path ".\build\txt\nvidiahive.txt"){Remove-Item ".\build\txt\nvidiahive.txt"}
Do{
invoke-expression ".\build\apps\nvidia-smi.exe --query-gpu=power.draw,fan.speed,temperature.gpu --format=csv > "".\build\txt\nvidiahive.txt"""
}while(((Test-Path ".\build\txt\nvidiahive.txt") -eq $false) -or $CheckTimer.Elapsed.Seconds -gt 10)
if(Test-Path ".\build\txt\nvidiahive.txt"){$info = Get-Content ".\build\txt\nvidiahive.txt" | ConvertFrom-Csv}
$CheckTimer.Stop()
$NVIDIAFans = $info.'fan.speed [%]' | foreach {$_ -replace ("\%","")}
$NVIDIATemps = $info.'temperature.gpu'
$NVIDIAPower = $info.'power.draw [W]' | foreach {$_ -replace ("\[Not Supported\]","75")} | foreach {$_ -replace (" W","")}
Write-Host "Power is $NVIDIAPower"
}

$GetMiners | Foreach {
if($Platforms -eq "windows" -and $HiveId -ne $null)
 {
  if($_.Type -like "*NVIDIA*")
   {
     $TypeS = "NVIDIA"
    if($_.Devices -eq $null){$Devices = Get-DeviceString -TypeCount $GCount.NVIDIA.PSObject.Properties.Value.Count}
    else{$Devices = Get-DeviceString -TypeDevices $_.Devices}
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUPower.$($GCount.$TypeS.$GPU) = $NVIDIAPower[$GPU]}
    $cpu1 = Get-WmiObject win32_processor | select LoadPercentage
    $cpu5 = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select Average
    $ramfree = $(Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
    $ramtotal = Get-Content ".\build\txt\ram.txt"
   }
 }

  $Server = "localhost"
  $Interval = 15
  $Port = $($_.Port)
  $MinerType = $($_.Type)
  $MinerAPI = $($_.API)
  if($_.Type -like "*NVIDIA*"){$TypeS = "NVIDIA"}
  elseif($_.Type -like "*AMD*"){$TypeS = "AMD"}
  elseif($_.Type -like "*CPU*"){$TypeS = "CPU"}
  $MinerAlgo = $($_.Algo)

  $Name = $($_.Name)
  if($_.Type -ne "CPU")
  {
  if($_.Devices -eq $null){$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}
  else{$Devices = Get-DeviceString -TypeDevices $_.Devices}
  }
  elseif($_.Type -eq "CPU"){$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}
  $HashPath = ".\logs\$($_.Type).log"
 try
  {
  switch($MinerAPI)
    {
    'claymore'
      {
      $HS = "khs"
      Write-Host "Miner $MinerType is claymore api"
      Write-Host "Miner Port is $Port"
      Write-Host "Miner Devices is $Devices"   
      try{$Request = Invoke-WebRequest "http://$($server):$($port)" -UseBasicParsing -TimeoutSec 10}catch{Write-Host "API TimedOut"}
      $Data = $Request.Content.Substring($Request.Content.IndexOf("{"), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{") + 1) | ConvertFrom-Json
      $Hash = $Data.result[3] -split ";"
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){$Hash}else{$Hash[$i]})}
      $RAW = 0
      $Hash = $Hash | % {iex $_}
      $Hash | foreach {$RAW += $_*1000}
      $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
      $MinerACC = 0
      $MinerREJ = 0
      $MinerACC += $Data.result[2] -split ";" | Select -skip 1 -first 1
      $MinerREJ += $Data.result[2] -split ";" | Select -skip 2 -first 1
      $ACC += $Data.result[2] -split ";" | Select -skip 1 -first 1
      $REJ += $Data.result[2] -split ";" | Select -skip 2 -first 1
      $KHS += $Data.result[2] -split ";" | Select -First 1 | foreach {[Double]$_}
      $UPTIME = $Data.result[1] | Select -first 1 | foreach {[Double]$_*60}
      $A = $Data.result[6] -split ";"
      $temp = $true
      for($i=0; $i -lt $A.count; $i++){if($temp -eq $true){$A[$i] = "$($A[$i])T"; $temp=$false; continue}if($temp -eq $false){$A[$i] = "$($A[$i])F"; $temp=$true; continue}} 
      $FanSelect = $A | Select-String "F" | foreach {$_ -replace "F"}
      $TempSelect = $A | Select-String "T"| foreach {$_ -replace "T"}
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($FanSelect.Count -eq 1){$FanSelect}else{$FanSelect[$i]})}
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($TempSelect.Count -eq 1){$TempSelect}else{$TempSelect[$i]})} 
      $ALGO = $MinerAlgo
      }
   'ewbf'
      {
      $HS = "hs"
       Write-Host "Miner $MinerType is ewbf api"
       Write-Host "Miner Port is $Port"
       Write-Host "Miner Devices is $Devices"  
       $Message = @{id = 1; method = "getstat"} | ConvertTo-Json -Compress
       try{$Client = New-Object System.Net.Sockets.TcpClient $server, $port}catch{Write-Host "API TimedOut"}
       $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
       $Reader = New-Object System.IO.StreamReader $Client.GetStream()
       $client.SendTimeout = 10000
       $client.ReceiveTimeout = 10000
       $Writer.AutoFlush = $true
       $Writer.WriteLine($Message)
       $Request = $Reader.ReadLine()
       $Data = $Request | ConvertFrom-Json
       $Data = $Data.result
       $Data.speed_sps | foreach {$RAW += [Double]$_}
       $RAW = 0
       $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
       for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Data.speed_sps.Count -eq 1){$Data.speed_sps}else{$Data.speed_sps[$i]})}
       $MinerACC = 0
       $MinerREJ = 0
       $Data.accepted_shares | Foreach {$MinerACC += $_}
       $Data.rejected_shares | Foreach {$MinerREJ += $_}
       $Data.accepted_shares | Foreach {$ACC += $_}
       $Data.rejected_shares | Foreach {$REJ += $_}
       $Data.speed_sps | foreach {$KHS += [Double]$_}
       $UPTIME = ((Get-Date) - [DateTime]$Data.start_time[0]).seconds
       for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($Data.temperature.Count -eq 1){$Data.temperature}else{$Data.temperature[$i]})}
       $ALGO = $MinerAlgo
       if($Platforms -eq "linux"){$MinerFans = Get-NVIDIAFans; for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
       elseif($Platforms -eq "windows"){$MinerFans = $NVIDIAFans; for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
      }
    'ccminer'
      {
        $HS = "khs"
        Write-Host "Miner $MinerType is ccminer api"
        Write-Host "Miner Port is $Port"
        Write-Host "Miner Devices is $Devices"
        try{$GetSummary = Get-TCP -Server $Server -Port $port -Message "summary"}catch{Write-Host "API summary TimedOut"}
        $GetKHS = $GetSummary -split ";" | Select-String -pattern '^KHS' | foreach {$_ -replace ("KHS=","")}
        $GetKHS = $GetKHS | % {iex $_}
        $RAW = 0
        $RAW += $GetKHS*1000
        $RAW | Set-Content ".\build\txt\$MinerType-hash.txt";
        $KHS += $GetKHS
        try{$GetThreads = Get-TCP -Server $Server -Port $port -Message "threads"}catch{Write-Host "API threads TimedOut"}
        $Data = $GetThreads -split "\|"
        $Hash = $Data -split ";" | Select-String "KHS" | foreach {$_ -replace ("KHS=","")}
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){$Hash}else{$Hash[$i]})}
        $Mfan = $Data -split ";" | Select-String "FAN" | foreach {$_ -replace ("FAN=","")}
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MFan.Count -eq 1){$MFan}else{$MFan[$i]})}
        $MTemp = $Data -split ";" | Select-String "TEMP" | foreach {$_ -replace ("TEMP=","")}
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MTemp.Count -eq 1){$MTemp}else{$MTemp[$i]})}
        $MinerACC = 0
        $MinerREJ = 0
        $MinerACC += $GetSummary -split ";" | Select-String "ACC=" | foreach{$_ -replace ("ACC=","")}
        $MinerREJ += $GetSummary -split ";" | Select-String "REJ=" | foreach{$_ -replace ("REJ=","")}
        $ACC += $GetSummary -split ";" | Select-String "ACC=" | foreach{$_ -replace ("ACC=","")}
        $REJ += $GetSummary -split ";" | Select-String "REJ=" | foreach{$_ -replace ("REJ=","")}
        $UPTIME = $GetSummary -split ";" | Select-String "UPTIME=" | foreach{$_ -replace ("UPTIME=","")}
        $ALGO = $GetSummary -split ";" | Select-String "ALGO=" | foreach{$_ -replace ("ALGO=","")}
      }
    'trex'
     {
      $HS = "khs"
      Write-Host "Miner $MinerType is trex api"
      Write-Host "Miner Port is $Port"  
      Write-Host "Miner Devices is $Devices"  
      try{$Request = Invoke-WebRequest "http://$($server):$($port)/summary" -UseBasicParsing -TimeoutSec 10
      $Data = $Request.Content | ConvertFrom-Json}catch{Write-Host "API TimedOut"}
      $RAW = 0
      $RAW = $Data.hashrate_minute
      $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Data.gpus.hashrate_minute.Count -eq 1){[Double]$Data.gpus.hashrate_minute / 1000}else{[Double]$Data.gpus.hashrate_minute[$i] / 1000})}
      $MinerACC = 0
      $MinerREJ = 0
      $Data.accepted_count | Foreach {$MinerACC += $_}
      $Data.rejected_count | Foreach {$MinerREJ += $_}
      $Data.accepted_count | Foreach {$ACC += $_}
      $Data.rejected_count | Foreach {$REJ += $_}
      $KHS += [Double]$Data.hashrate_minute/1000
      $UPTIME = $Data.uptime
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($Data.gpus.temperature.Count -eq 1){$Data.gpus.temperature}else{$Data.gpus.temperature[$i]})}
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) =  $(if($Data.gpus.fan_speed.Count -eq 1){$Data.gpus.fan_speed}else{$Data.gpus.fan_speed[$i]})}
      $ALGO = $Data.Algorithm
     }
    'dstm'
      {
        $HS = "hs"
        Write-Host "Miner $MinerType is dstm api"
        Write-Host "Miner Port is $Port"
        Write-Host "Miner Devices is $Devices"  
        try{$GetSummary = Get-TCP -Server $Server -Port $port -Message "summary"
        $Data = $GetSummary | ConvertFrom-Json}catch{Write-Host "API TimedOut"}
        $Data = $Data.result
        $RAW = 0
        $Data.sol_ps | foreach {$RAW += [Double]$_}
        $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Data.sol_ps.Count -eq 1){$Data.sol_ps}else{$Data.sol_ps[$i]})}
        $MinerACC = 0
        $MinerREJ = 0
        $Data.rejected_shares | Foreach {$MinerREJ += $_}
        $Data.accepted_shares | Foreach {$MinerACC += $_}  
        $Data.rejected_shares | Foreach {$REJ += $_}
        $Data.accepted_shares | Foreach {$ACC += $_}
        $Data.sol_ps | foreach {$KHS += [Double]$_}
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($Data.temperature.Count -eq 1){$Data.temperature}else{$Data.temperature[$i]})}
        $ALGO = $MinerAlgo
        $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
        if($Platforms -eq "linux"){$MinerFans = Get-NVIDIAFans; for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
        elseif($Platforms -eq "windows"){$MinerFans = $NVIDIAFans; for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
      }
  'sgminer-gm'
    {      
      $HS = "khs"
      Write-Host "Miner $MinerType is sgminer api"
      Write-Host "Miner Port is $Port"
      Write-Host "Miner Devices is $Devices"  
      $Message = @{command="summary+devs"; parameter=""} | ConvertTo-Json -Compress
      try{$Request = Get-TCP -Server $Server -Port $port -Message $Message | ConvertFrom-Json}catch{Write-Host "API TimedOut"}
      $summary = $Request.summary.summary
      $threads = $Request.devs.devs
      if($summary.'KHS 5s'){$Sum = $summary.'KHS 5s'}
      else{$Sum = $summary.'KHS 30s'}
      if($threads.'KHS 5s'){$Thread = $threads.'KHS 5s'}
      else{$thread = $threads.'KHS 30s'}
      $RAW = 0
      $RAW += [Double]$Sum*1000
      $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
      $KHS += $Sum
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($thread.Count -eq 1){$thread}else{$thread[$i]})}
      $MinerACC = 0
      $MinerREJ = 0
      $summary.Rejected | Foreach {$MinerREJ += $_}
      $summary.Accepted | Foreach {$MinerACC += $_}    
      $summary.Rejected | Foreach {$REJ += $_}
      $summary.Accepted | Foreach {$ACC += $_}
      $ALGO = $MinerALgo
      $UPTIME = $summary.Elapsed
      $MinerFans = Get-AMDFans
      $MinerTemps = Get-AMDTemps
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$($GCount.$TypeS.$GPU)]})}
    }
   'cpuminer'
    {
     Write-Host "Miner $MinerType is cpuminer api"
     Write-Host "Miner Port is $Port"
     Write-Host "Miner Devices is $Devices"
     try{$GetCPUSummary = Get-TCP -Server $Server -Port $Port -Message "summary"}catch{Write-Host "API Summary TimedOut"}
     $CPUSUM = $GetCPUSummary -split ";" | Select-String "KHS=" | foreach {$_ -replace ("KHS=","")}
     $CPURAW = 0
     $CPURAW += [double]$CPUSUM*1000
     $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt";
     try{$GetCPUThreads = Get-TCP -Server $Server -Port $Port -Message "threads"}catch{Write-Host "API Threads TimedOut"}
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
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $CPUHashrates.$($GCount.$TypeS.$GPU) = $(if($J.Count -eq 1){$J}else{$J[$i]})}
      $J |Foreach {$CPUKHS += $_}
      $CPUHS = "khs"
     }
     else{
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $CPUHashrates.$($GCount.$TypeS.$GPU) = $(if($J.Count -eq 1){$J/1000}else{$J[$i]/1000})}
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
   'lyclminer'
    {          
      $HS = "khs"
      Write-Host "Miner $MinerType is tdxminer (logging) api"
      Write-Host "Miner Devices is $Devices"
      $HashArray =@()
      $Hashed = @()
      $Hash = @()
      if(Test-Path $HashPath){$Hashes = Get-Content $HashPath}
     if($Hashes)
      {    
      for($i=0; $i -lt $Devices.Count; $i++)
      {
        $GPU = $Devices[$i];
        $Selected = $GPUHashrates.$($GCount.$TypeS.$GPU)
        $Hashes = $Hashes | Select-String "Device #$($Selected)" | Select-String "/s" | Select -Last 1
        if($Hashes -ne $Null)
        {
         $C = $Hashes -replace (" ","")
         $D = $C -split "," | Select-String "/s"
           if($D -like "*/s*")
            {
             if([regex]::match($D,"MH/s").success -eq $true){$CHash = "MH/s"}
             else{$CHash = "KH/s"}
             if([regex]::match($D,"MH/s").success -eq $true){$Hash += "MH/s"}
             else{$Hashed += "KH/s"}
            }
           $E = $D -split "$CHash" | Select -First 1
           $E | foreach{$HashArray += $_}
          }
          else{
              $Hashed += "Kh/s"
              $HashArray += 0.1
              }
           }
          }
         else{
          for($i = 0; $i -lt $Devices.Count; $i++)
          {
            $Hashed += "Kh/s"
            $HashArray += 0.1
          }
         }
          $J = $HashArray | % {iex $_}
          $K = @()
          $TotalRaw = 0
          for($i = 0; $i -lt $Hash.Count; $i++)
          {
           $SelectedHash = $Hashed | Select -skip $i | Select -First 1
           $SelectedPattern = $J | Select -skip $i | Select -First 1
           $SelectedPattern | foreach { if ($SelectedHash -eq "MH/s"){$K += $_*1000}else{$K += $_}}
           $SelectedPattern | foreach { if ($SelectedHash -eq "MH/s"){$TotalRaw += ($_*1000000)}else{$TotalRaw += ($_*1000)}}
          }        
          for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($K.Count -eq 1){$K}else{$K[$i]})}
          $KHS += [Double]$TotalRaw/1000
          $ALGO = $MinerAlgo
          $TotalRaw | Set-Content ".\build\txt\$MinerType-hash.txt"      
          $AA = $A | Select-String "Accepted"  | Select -Last 1
          $BB = $AA -Split "d" | Select-String "/"
          $CC = $BB -replace (" ","")
          $DD = $CC -split "\)" | Select-String "%"
          $Shares = $DD -split "\(" | Select-String "/"
          $MinerACC = 0
          $MinerREJ = 0    
          $ACC += $($Shares -Split "/" | Select -First 1)
          $MinerACC += $($Shares -Split "/" | Select -First 1)
          $GetRejected = $($Shares -Split "/" | Select -Last 1)
          $REJ += ($GetRejected-$MinerACC)
          $MinerREJ += ($GetRejected-$MinerACC)
          $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
          $MinerFans = Get-AMDFans
          $MinerTemps = Get-AMDTemps
          for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}
          for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$($GCount.$TypeS.$GPU)]})}    
        }
'xmrstak'
   {
    Write-Host "Miner $MinerType is xmrstak api"
    Write-Host "Miner Devices is $Devices"
    $HS = "hs"
    $Request="/api.json"
    try{$Reader = Invoke-WebRequest "http://$($server):$($port)$($Request)" -UseBasicParsing -TimeoutSec 10 | ConvertFrom-Json}catch{Write-Host "API TimedOut"}
    $Hash = $Reader.Hashrate.threads
    $RAW = 0
    $RAW = $Reader.hashrate.total[0]
    $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){[Double]$($Hash[0] | Select -first 1)}else{[Double]$($Hash[$i] | Select -First 1)})}
    $MinerACC = 0
    $MinerREJ = 0
    $MinerACC += $Reader.results.shares_good
    $MinerREJ += $Reader.results.shares_total - [Double]$Reader.results.shares_good 
    $ACC += $Reader.results.shares_good
    $REJ += - $Reader.results.shares_total - [Double]$Reader.results.shares_good
    $UPTIME = $Reader.connection.uptime
    $ALGO = $MinerAlgo
    $KHS = [Double]$Reader.hashrate.total[0]
    $MinerFans = Get-AMDFans
    $MinerTemps = Get-AMDTemps
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$($GCount.$TypeS.$GPU)]})}
   }
'wildrig'
  {
    Write-Host "Miner $MinerType is wildrig api"
    Write-Host "Miner Devices is $Devices"    
    $HS = "khs"
    $Request="/api.json"
    try{$Reader = Invoke-WebRequest "http://$($server):$($port)$($Request)" -UseBasicParsing -TimeoutSec 10 | ConvertFrom-Json}catch{Write-Host "API TimedOut"}
    $RAW = 0
    $RAW = $Reader.hashrate.total[0]
    $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    $Hash = $Reader.hashrate.threads
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){[Double]$($Hash[0] | Select -first 1) / 1000}else{[Double]$($Hash[$i] | Select -First 1)})}
    $MinerACC = 0
    $MinerREJ = 0
    $MinerACC += $Reader.results.shares_good
    $MinerREJ += $Reader.results.shares_total - $Reader.results.shares_good 
    $ACC += $Reader.results.shares_good
    $REJ += - $Reader.results.shares_total - $Reader.results.shares_good
    $UPTIME = $Reader.connection.uptime
    $ALGO = $MinerAlgo
    $KHS = [Double]$Reader.hashrate.total[0]/1000
    $MinerFans = Get-AMDFans
    $MinerTemps = Get-AMDTemps
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$($GCount.$TypeS.$GPU)]})}
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
   "Bad Shares" | Out-File ".\timeout\$($_.Name)_$($_.Algo)_rejection.txt"
  }
  else{if(Test-Path ".\timeout\$($_.Name)_$($_.Algo)_rejection.txt"){Remove-Item ".\timeout\$($_.Name)_$($_.Algo)_rejection.txt" -Force}}
 }

 }catch{Write-Host "Warning: There Was An Error Getting Stats" -foreground Red}
}

if($CPUOnly -eq $true)
{
$HIVE="
$($CPUHash -join "`n")
KHS=$CPUKHS
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
  $HashRates = @()
  $Fans = @()
  $Temps = @()
  if($GCount.NVIDIA.PSObject.Properties.Value.Count -gt 0){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$HashRates += 0; $Fans += 0; $Temps += 0}}
  if($GCount.AMD.PSObject.Properties.Value.Count -gt 0){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$HashRates += 0; $Fans += 0; $Temps += 0}}
  for($i=0; $i -lt $GPUHashrates.PSObject.Properties.Value.Count; $i++){$HashRates[$i] = "GPU=$($GPUHashRates.$i)"}
  for($i=0; $i -lt $GPUFans.PSObject.Properties.Value.Count; $i++){$Fans[$i] = "FAN=$($GPUFans.$i)"}
  for($i=0; $i -lt $GPUTemps.PSObject.Properties.Value.Count; $i++){$Temps[$i] = "TEMP=$($GPUTemps.$i)"}
  for($i=0; $i -lt $HashRates.count; $i++)
  {
   if($HashRates[$i] -eq 'GPU=0' -or $HashRates[$i] -eq 'GPU=' -or $HashRates[$i] -eq 'GPU=0.00')
    {
     if($HS -eq "khs"){$HashRates[$i] = 'GPU=0.001'; $KHS += 0.001}
     elseif($HS -eq "hs"){$HashRates[$i] = 'GPU=1'; $KHS += 1}
    }
   }

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

$Agent="$HashRates KHS=$KHS ACC=$ACC REJ=$REJ $Fans $Temps UPTIME=$UPTIME"

$Agent
if($CPUKHS -ne $null){Write-Host "CPU=$CPUSUM"}
$Hive | Set-Content ".\build\bash\hivestats.sh"
}


function Start-MinerWatchdog {
  param(
  [Parameter(Mandatory=$false)]
  [String]$PlatformMiners
  )

   if($PlatformMiners -eq "windows"){
   $MinerFile =".\build\pid\miner_pid.txt"
   if(Test-Path $MinerFile){$MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue}
    if($MinerId -eq $null -or $MinerId.HasExited)
     {
       $ID = ".\build\pid\background_pid.txt"
       $BackGroundID = Get-Process -id (Get-Content "$ID" -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue
       $BackGroundID.CloseMainWindow() | Out-Null
      }
    }
  }

if($Platforms -eq "windows" -and $HiveId -ne $null)
{
$cpu = @(0,$($cpu1.LoadPercentage),$($cpu5.Average))
$mem = @($($ramfree),$($ramtotal-$ramfree))
$Power = $NVIDIAPower
$HashRates = $HashRates | foreach {$_ -replace ("GPU=","")}
$HashRates = $HashRates | foreach {$_ -replace ("$($_)","$($_)")}
$Fans = $Fans | foreach {$_ -replace ("FAN=","")}
$Fans = $Fans | foreach {$_ -replace ("$($_)","$($_)")}
$Temps = $Temps | foreach {$_ -replace ("TEMP=","")}
$Temps = $Temps | foreach {$_ -replace ("$($_)","$($_)")}
$AR = @("$ACC","$REJ")
$TOTALKHS = [math]::Round($KHS,2)

$Stats = @{
  method = "stats"
  rig_id = $HiveID
  jsonrpc = "2.0"
  id= "0"
  params = @{
   rig_id = $HiveID
   passwd = $HivePassword
   miner = "custom"
   meta = @{
    custom = @{
    coin = "RVN"
    }
   }
   miner_stats = @{
   hs = @($HashRates)
   hs_units = $HS
   uptime = $UPTIME
   algo = $ALGO
   ar = @($AR)
   temp = @($Temps)
   fan = @($Fans)
    }
   total_khs = $TOTALKHS
   power = @($Power)
   mem = @($mem)
   cpuavg = @($cpu)
   df = "0"
  }
}

try{
$response = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($Stats | ConvertTo-Json -Depth 4 -Compress) -ContentType 'application/json'
if($response.result.command -eq "OK"){Write-Host "Hive Recieved Stats"}
}
catch{Write-Host "Failed To Contact HiveOS.Farm"}

$response.result.exec

if($response.result.command -ne "OK")
 {
  ##command exec
  $SwarmResponse = Start-webcommand $response
  if($SwarmResponse -ne $null)
   {
    Write-Host "Sending Command $($response.result.exec) To Hive"
    try{
      $hiveresponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($SwarmResponse | ConvertTo-Json -Depth 1) -ContentType 'application/json'
      if($SwarmResponse.params.payload -eq "rebooting"){Restart-Computer}
       }
    catch{Write-Host "Failed To Execute Command"}
   }
  }
 }

if($BackgroundTimer.Elapsed.TotalSeconds -gt 120){Clear-Content ".\build\bash\hivestats.sh"; $BackgroundTimer.Restart()}
Start-MinerWatchdog -PlatformMiners $Platforms
Start-Sleep -S 5
Start-MinerWatchdog -PlatformMiners $Platforms
Start-Sleep -S 5
#{"method":"stats","jsonrpc":"2.0","id":0,"params":{"rig_id":"","passwd":"","miner":"custom","meta":{"custom":{"coin":"RVN"}},"miner_stats":{"hs":[0,0,0,0,0,0,0,0,0,0,0,0,0],"hs_units":"khs","temp":[56,58,54,0,0,0,59,0,0,57,44,0,0],"fan":[80,80,80,0,0,0,80,0,0,80,80,0,0],"uptime":"6\r,","ar":["0\r","0\r"],"algo":"tribus\r"},"total_khs":"0\r","temp":["0","62","63","61","49","47","46","64","54","45","64","54","51","44"],"fan":["0","80","80","80","80","80","80","80","80","80","80","80","80","80"],"power":["0","143","137","150","0","0","0","147","0","0","143","151","0","0"],"df":"196G","mem":[7681,1669],"cpuavg":[5.29,4.33,4.61]}}
}