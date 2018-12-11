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

#$Platforms = "linux"
#$RejPercent = 50
#$WorkingDir = "/hive/custom/SWARM.1.6.3"
#Set-Location $WorkingDir

function Get-NvidiaStats {
  timeout -s9 10 ./build/apps/VII-smi | Tee-Object -Variable getstats | Out-Null
  Start-Sleep -S .25
  if($getstats)
  {
  $NVIDIAStats = @{}
  $NVIDIAStats.Add("temps",@{})
  $NVIDIAStats.Add("fans",@{})
  $NVIDIAStats.Add("power",@{})
  $Ntemps = $getstats | Select-String "temperature" | foreach{$_ -replace "GPU ",""} | foreach{$_ -replace " temperature",""} | ConvertFrom-StringData
  $Nfans = $getstats | Select-String "fan speed" | foreach{$_ -replace "GPU ",""} | foreach{$_ -replace " fan speed",""} | ConvertFrom-StringData
  $Npower = $getstats | Select-String "power" | foreach{$_ -replace "GPU ",""} | foreach{$_ -replace " power",""} | ConvertFrom-StringData
  $Ntemps.keys | foreach{$NVIDIAStats.temps.Add("$($_)","$($Ntemps.$_)")}
  $Nfans.keys | foreach{$NVIDIAStats.fans.Add("$($_)","$($Nfans.$_)")}
  $NPower.keys | foreach{$NVIDIAStats.power.Add("$($_)","$($NPower.$_ -replace "failed to get","75")")}
  }
  $NVIDIAStats
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
    $A = timeout -s9 5 gpu-stats
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
    $A = timeout -s9 5 gpu-stats
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
##Delay To Ensure File-Write
$GetMiners = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-Json
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json

$DevNVIDIA = $false
$DevAMD = $false
$StartTime = Get-Date

$GetMiners | Foreach {
  $NEW=0; 
  $NEW | Set-Content ".\build\txt\$($_.Type)-hash.txt";
  $Name = $($_.Name)
  if($_.Type -like "*NVIDIA*"){$DevNVIDIA = $true};
  if($_.Type -like "*AMD*"){$DevAMD = $true}
  }

##Set-OC
Write-Host "Starting Tuning"
Start-OC -Platforms $Platforms -Dir $WorkingDir

Start-Sleep -S 10
$CPUOnly = $true
$GetMiners | Foreach {
  if($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*"){$CPUOnly = $false; "GPU" | Set-Content ".\build\txt\miner.txt"}
}
if($CPUOnly -eq $true){"CPU" | Set-Content ".\build\txt\miner.txt"}

$BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$BackgroundTimer.Restart()
$RestartTimer = New-Object -TypeName System.Diagnostics.Stopwatch

While($True)
{
  $RestartTimer.Restart()

if($Platforms -eq "windows" -and $HiveId -ne $null)
{
   $cpu1 = Get-WmiObject win32_processor | select LoadPercentage
   $cpu5 = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select Average
   $ramfree = $(Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
   $ramtotal = Get-Content ".\build\txt\ram.txt"
} 
$HashRates = @()
$Fans = @()
$Temps = @()
$Power = @()
$GPUHashrates = [PSCustomObject]@{}
$CPUHashrates = [PSCustomObject]@{}
$GPUFans = [PSCustomObject]@{}
$GPUTemps = [PSCustomObject]@{}
$GPUPower = [PSCustomObject]@{}
$RAW = 0
$KHS = 0
$REJ = 0
$ACC = 0
for($i=0; $i -lt $GCount.CPU.PSObject.Properties.Value.Count; $i++){$CPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.CPU.$i)" -Value 0;}
if($DevAMD -eq $true){for($i=0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++){$GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUFans | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $GPUPower | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0}}
if($DevNVIDIA -eq $true){for($i=0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++){$GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUFans | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $GPUPower | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0}}

if($Platforms -eq "windows")
{
$nvidiastat = ".\build\txt\nvidiahive.txt"
$amdstat = ".\build\txt\amdhive.txt"
$CheckTimer = New-Object -TypeName System.Diagnostics.Stopwatch
if(Test-Path $nvidiastat){Remove-Item $nvidiastat}
if(Test-Path $amdstat){Remove-Item $amdstat}

if($DevNVIDIA -eq $true)
{
if($nvidiaout){Clear-Variable nvidiaout}
invoke-expression ".\build\apps\nvidia-smi.exe --query-gpu=power.draw,fan.speed,temperature.gpu --format=csv" | Tee-Object -Variable nvidiaout | Out-Null
$ninfo = $nvidiaout | ConvertFrom-Csv
$NVIDIAFans = $ninfo.'fan.speed [%]' | foreach {$_ -replace ("\%","")}
$NVIDIATemps = $ninfo.'temperature.gpu'
$NVIDIAPower = $ninfo.'power.draw [W]' | foreach {$_ -replace ("\[Not Supported\]","75")} | foreach {$_ -replace (" W","")}
}
if($DevAMD -eq $true)
{
  if($amdout){Clear-Variable amdout}
  Invoke-Expression ".\build\apps\overdriveVII.exe -y -f -t" | Tee-Object -Variable amdout | Out-Null
  $amdinfo = $amdout | ConvertFrom-StringData
  $ainfo = @{}
  $ainfo.Add("Fans",@())
  $ainfo.Add("Temps",@())
  $ainfo.Add("Watts",@())
  $fancheck = 0
  $tempcheck = 0
  $wattcheck = 0
  $amdinfo.keys | foreach {if($_ -like "*Fan*"){$ainfo.Fans += $amdinfo.$_ ; $fancheck++}}
  $amdinfo.keys | foreach {if($_ -like "*Temp*"){$ainfo.Temps += $amdinfo.$_ ; $tempcheck++}}
  $amdinfo.keys | foreach {if($_ -like "*Watts*"){if($amdinfo.$_ -ne "0"){$ainfo.Watts += $amdinfo.$_}else{$ainfo.Watts += "75"}; $wattcheck++}}
  $AMDFans = $ainfo.Fans
  $AMDTemps = $ainfo.Temps
  $AMDPower = $ainfo.Watts
}
}

$GetMiners | Foreach {
$MinerAlgo = $($_.Algo)
$MinerName = $($_.MinerName)
$Name = $_.Name
$Server = "localhost"
$Interval = 15
$Port = $($_.Port)
$MinerType = $($_.Type)
$MinerAPI = $($_.API)
if($_.Type -like "*NVIDIA*"){$TypeS = "NVIDIA"}
elseif($_.Type -like "*AMD*"){$TypeS = "AMD"}
elseif($_.Type -like "*CPU*"){$TypeS = "CPU"}
if($_.Type -ne "CPU")
 {
  if($_.Devices -eq $null){$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}
  else{$Devices = Get-DeviceString -TypeDevices $_.Devices}
 }
elseif($_.Type -eq "CPU"){$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}
$HashPath = ".\logs\$($_.Type).log"

if($Platforms -eq "windows" -and $HiveId -ne $null)
 {
  if($_.Type -like "*NVIDIA*")
   {
    $TypeS = "NVIDIA"
    if($_.Devices -eq $null){$Devices = Get-DeviceString -TypeCount $GCount.NVIDIA.PSObject.Properties.Value.Count}
    else{$Devices = Get-DeviceString -TypeDevices $_.Devices}
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUPower.$($GCount.$TypeS.$GPU) = if($NVIDIAPower.Count -gt 1){$NVIDIAPower[$GPU]}else{$NVIDIAPower}}
   }
  if($_.Type -like "*AMD*")
  {
    $TypeS = "AMD"
    if($_.Devices -eq $null){$Devices = Get-DeviceString -TypeCount $GCount.AMD.PSObject.Properties.Value.Count}
    else{$Devices = Get-DeviceString -TypeDevices $_.Devices}
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUPower.$($GCount.$TypeS.$GPU) = if($AmdPower.Count -gt 1){$AMdPower[$GPU]}else{$AMdPower}}
  }
 }

   switch($MinerAPI)
    {
    'claymore'
      {
      $HS = "khs"
      Write-Host "Miner $MinerType is claymore api"
      Write-Host "Miner Port is $Port"
      Write-Host "Miner Devices is $Devices"
      $Request = $Null
      $Request = Get-HTTP -Port $Port
      if($Request)
       {
        $Data = $Request.Content.Substring($Request.Content.IndexOf("{"), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{") + 1) | ConvertFrom-Json
        $RAW = 0
        $RAW += $Data.result[2] -split ";" | Select -First 1 | foreach {[Double]$_*1000}
        $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
        $Process = Get-Process | Where Name -clike "*$($MinerType)*"
        Write-Host "Current Running instances: $($Process.Name)"
        $KHS += $Data.result[2] -split ";" | Select -First 1 | foreach {[Double]$_}
        $Hash = $Data.result[3] -split ";"
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){$Hash}else{$Hash[$i]})}
        $Hash = $Hash | % {iex $_}
        $MinerACC = $Data.result[2] -split ";" | Select -skip 1 -first 1
        $MinerREJ = $Data.result[2] -split ";" | Select -skip 2 -first 1
        $ACC += $Data.result[2] -split ";" | Select -skip 1 -first 1
        $REJ += $Data.result[2] -split ";" | Select -skip 2 -first 1
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
       else{Write-Host "$MinerAPI API Failed- Coult Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
      }
   'ethminer'
    {
      $HS = "hs"
      Write-Host "Miner $MinerType is ethminer api"
      Write-Host "Miner Port is $Port"
      Write-Host "Miner Devices is $Devices"
      $Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat1"} | ConvertTo-Json -Compress
      $Client = $Null
      $Client = Get-TCP -Server $Server -Port $port -Message $Message
      if($Client)
      {
        $Data = $Client | ConvertFrom-Json
        $RAW = 0
        $RAW += $Data.result[2] -split ";" | Select -First 1 | foreach {[Double]$_*1000}
        $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
        $Process = Get-Process | Where Name -clike "*$($MinerType)*"
        Write-Host "Current Running instances: $($Process.Name)"
        $KHS += $Data.result[2] -split ";" | Select -First 1 | foreach {[Double]$_}
        $Hash = $Data.result[3] -split ";"
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){$Hash}else{$Hash[$i]})}
        $Hash = $Hash | % {iex $_}
        $MinerACC = $Data.result[2] -split ";" | Select -skip 1 -first 1
        $MinerREJ = $Data.result[2] -split ";" | Select -skip 2 -first 1
        $ACC += $Data.result[2] -split ";" | Select -skip 1 -first 1
        $REJ += $Data.result[2] -split ";" | Select -skip 2 -first 1
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
      else{Write-Host "$MinerAPI API Failed- Coult Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
    }
   'excavator'
   {
   $HS = "khs"
   Write-Host "Miner $MinerType is excavator api"
   Write-Host "Miner Port is $Port"
   Write-Host "Miner Devices is $Devices"
   $Message = @{id=1; method = "algorithm.list"; params=@()} | ConvertTo-Json -Compress
   $GetSummary = $null
   $GetSummary = Get-TCP -Server $Server -Port $port -Message $Message
   if($GetSummary)
    {
    $Summary = $GetSummary | ConvertFrom-Json
    $RAW = $Summary.algorithms.speed
    $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
    $Process = Get-Process | Where Name -clike "*$($MinerType)*"
    Write-Host "Current Running instances: $($Process.Name)"
    $KHS += [Double]$Summary.algorithms.speed/1000
    }
    else{Write-Host "API Summary Failed- Could Not Total Hashrate Or No Accepted Shares" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
    $Message = @{id=1; method = "worker.list"; params=@()} | ConvertTo-Json -Compress
    $GetThreads = $Null
    $GetThreads = Get-TCP -Server $Server -Port $port -Message $Message
    if($GetThreads)
    {
    $Threads = $GetThreads | ConvertFrom-Json
    $Hash = $Threads.workers.algorithms.speed
    if($Hash){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){[Double]$Hash/1000}else{[Double]$Hash[$i]/1000})}}
    $ACC += $Summary.algorithms.accepted_shares
    $REJ += $Summary.algorithms.rejected_shares
    $MinerACC = 0
    $MinerREJ = 0
    $MinerACC += $Summary.algorithms.accepted_shares
    $MinerREJ += $Summary.algorithms.rejected_shares
    $UPTIME = $Summary.algorithms.uptime
    $ALGO = $Summary.algorithms.name
    if($Plaforms -eq "linux"){$MinerStats = Get-NVIDIAStats}
    if($MinerStats)
    {
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $NVIDIAStats.fans.$_}
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $NVIDIAStats.temps.$_}
    }
    }
    else{Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red}
   }
   'miniz'
   {
    $HS = "hs"
    Write-Host "Miner $MinerType is miniz api"
    Write-Host "Miner Port is $Port"
    Write-Host "Miner Devices is $Devices"
    $Request = $Null
    $Request = Invoke-Webrequest "http://$($server):$port" -UseBasicParsing -TimeoutSec 10
    if($Request)
    {
    $Data = $Request -split " "
    $Hash = $Data | Select-String "Sol/s" | Select-STring "data-label" | foreach {$_ -split "</td>" | Select -First 1} | foreach{$_ -split ">" | Select -Last 1}
    $RAW = 0
    $RAW = $Hash | Select -Last 1
    $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
    $KHS += [Double]$RAW/1000
    $Shares = $Data | Select-String "Shares" | Select -Last 1 | foreach{$_ -split "</td>" | Select -First 1} | Foreach{$_ -split ">" | Select -Last 1}
    $ACC += $Shares -split "/" | Select -first 1
    $REJ += $Shares -split "/" | Select -first 1
    $MinerACC = 0
    $MinerREJ = 0
    $MinerACC = $Shares -split "/" | Select -first 1
    $MinerREJ = $Shares -split "/" | Select -first 1
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){$Hash}else{$Hash[$i]})}
    if($Plaforms -eq "linux"){$MinerStats = Get-NVIDIAStats}
    if($MinerStats)
    {
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $NVIDIAStats.fans.$_}
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $NVIDIAStats.temps.$_}
    }
    if($Platforms -eq "windows"){$MinerFans = $NVIDIAFans; for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
    if($Platforms -eq "windows"){$MinerTemps = $NVIDIATemps; for($i=0; $i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$i]})}}
    $ALGO = $MinerAlgo
    $UPTIME = [math]::Round(((Get-Date)-$StartTime).TotalSeconds)
    }
    else{Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
   }

   'ewbf'
      {
       $HS = "hs"
       Write-Host "Miner $MinerType is ewbf api"
       Write-Host "Miner Port is $Port"
       Write-Host "Miner Devices is $Devices"  
       $Message = @{id = 1; method = "getstat"} | ConvertTo-Json -Compress
       $Client = $Null
       $Client = New-Object System.Net.Sockets.TcpClient $server, $port
       if($Client)
        { 
         $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
         $Reader = New-Object System.IO.StreamReader $Client.GetStream()
         $client.SendTimeout = 10000
         $client.ReceiveTimeout = 10000
         $Writer.AutoFlush = $true
         $Writer.WriteLine($Message)
         $Request = $Reader.ReadLine()
         $Data = $Request | ConvertFrom-Json
         $Data = $Data.result
         $RAW = 0
         $Data.speed_sps | foreach {$RAW += [Double]$_}
         $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
         Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
         $Process = Get-Process | Where Name -clike "*$($MinerType)*"
         Write-Host "Current Running instances: $($Process.Name)"
         for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Data.speed_sps.Count -eq 1){$Data.speed_sps}else{$Data.speed_sps[$i]})}
         $Data.accepted_shares | Foreach {$MinerACC += $_}
         $Data.rejected_shares | Foreach {$MinerREJ += $_}
         $Data.accepted_shares | Foreach {$ACC += $_}
         $Data.rejected_shares | Foreach {$REJ += $_}
         $Data.speed_sps | foreach {$KHS += [Double]$_}
         $UPTIME = ((Get-Date) - [DateTime]$Data.start_time[0]).seconds
         for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($Data.temperature.Count -eq 1){$Data.temperature}else{$Data.temperature[$i]})}
         $ALGO = $MinerAlgo
         if($Plaforms -eq "linux"){$MinerStats = Get-NVIDIAStats}
         if($MinerStats){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $NVIDIAStats.fans.$_}         }
         elseif($Platforms -eq "windows"){$MinerFans = $NVIDIAFans; for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
        }
        else{Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
      }
    'ccminer'
      {
       $HS = "khs"
       Write-Host "Miner $MinerType is ccminer api"
       Write-Host "Miner Port is $Port"
       Write-Host "Miner Devices is $Devices"
       $GetSummary = $Null
       $GetSummary = Get-TCP -Server $Server -Port $port -Message "summary"
       if($GetSummary)
       {
        $Multiplier = 1000
        $GetKHS = $GetSummary -split ";" | ConvertFrom-StringData
        $RAW = if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) {[Double]$GetKHS.KHS * $Multiplier}
        $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        $KHS += if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) {[Double]$GetKHS.KHS}
        Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
        $Process = Get-Process | Where Name -clike "*$($MinerType)*"
        Write-Host "Current Running instances: $($Process.Name)"
      }
       else{Write-Host "API Summary Failed- Could Not Total Hashrate Or No Accepted Shares" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
       $GetThreads = $Null
       $GetThreads = Get-TCP -Server $Server -Port $port -Message "threads"
       if($GetThreads)
        {
         $Data = $GetThreads -split "\|"
         $Hash = $Data -split ";" | Select-String "KHS" | foreach {$_ -replace ("KHS=","")}
         for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){$Hash}else{$Hash[$i]})}
         $Mfan = $Data -split ";" | Select-String "FAN" | foreach {$_ -replace ("FAN=","")}
         if($MFan){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MFan.Count -eq 1){$MFan}else{$MFan[$i]})}}
         elseif($Plaforms -eq "linux"){$MinerStats = Get-NVIDIAStats}
         if($MinerStats){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $NVIDIAStats.fans.$_}         }
         $MTemp = $Data -split ";" | Select-String "TEMP" | foreach {$_ -replace ("TEMP=","")}
         if($MTemp){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MTemp.Count -eq 1){$MTemp}else{$MTemp[$i]})}}
         elseif($MinerStats){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $NVIDIAStats.temps.$_}}
         $MinerACC = 0
         $MinerREJ = 0
         $MinerACC += $GetSummary -split ";" | Select-String "ACC=" | foreach{$_ -replace ("ACC=","")}
         $MinerREJ += $GetSummary -split ";" | Select-String "REJ=" | foreach{$_ -replace ("REJ=","")}
         $ACC += $GetSummary -split ";" | Select-String "ACC=" | foreach{$_ -replace ("ACC=","")}
         $REJ += $GetSummary -split ";" | Select-String "REJ=" | foreach{$_ -replace ("REJ=","")}
         $UPTIME = $GetSummary -split ";" | Select-String "UPTIME=" | foreach{$_ -replace ("UPTIME=","")}
         $ALGO = $GetSummary -split ";" | Select-String "ALGO=" | foreach{$_ -replace ("ALGO=","")}
        }
        else{Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red}
      }
    'trex'
     {
      $HS = "khs"
      Write-Host "Miner $MinerType is trex api"
      Write-Host "Miner Port is $Port"  
      Write-Host "Miner Devices is $Devices"
      $Request = $Null
      $Request = Get-HTTP -Port $Port -Message "/summary"
      if($Request)
       {
        $Data = $Request.Content | ConvertFrom-Json
        $RAW = if([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0){[Double]$Data.hashrate_minute}
        $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
        $Process = Get-Process | Where Name -clike "*$($MinerType)*"
        Write-Host "Current Running instances: $($Process.Name)"
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Data.gpus.hashrate_minute.Count -eq 1){[Double]$Data.gpus.hashrate_minute / 1000}else{[Double]$Data.gpus.hashrate_minute[$i] / 1000})}
        $MinerACC = 0
        $MinerREJ = 0
        $Data.accepted_count | Foreach {$MinerACC += $_}
        $Data.rejected_count | Foreach {$MinerREJ += $_}
        $Data.accepted_count | Foreach {$ACC += $_}
        $Data.rejected_count | Foreach {$REJ += $_}
        $KHS = if([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0){[Double]$Data.hashrate_minute/1000}
        $UPTIME = $Data.uptime
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($Data.gpus.temperature.Count -eq 1){$Data.gpus.temperature}else{$Data.gpus.temperature[$i]})}
        for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) =  $(if($Data.gpus.fan_speed.Count -eq 1){$Data.gpus.fan_speed}else{$Data.gpus.fan_speed[$i]})}
        $ALGO = $Data.Algorithm
       }
       else{Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
      }
    'dstm'
      {
        $HS = "hs"
        Write-Host "Miner $MinerType is dstm api"
        Write-Host "Miner Port is $Port"
        Write-Host "Miner Devices is $Devices"
        $GetSummary = $Null
        $GetSummary = Get-TCP -Server $Server -Port $port -Message "summary"
        if($GetSummary)
         {
        $Data = $GetSummary | ConvertFrom-Json
        $Data = $Data.result
        $RAW = 0
        $Data.sol_ps | foreach {$RAW += [Double]$_}
        $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
        Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
        $Process = Get-Process | Where Name -clike "*$($MinerType)*"
        Write-Host "Current Running instances: $($Process.Name)"
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
        if($Plaforms -eq "linux"){$MinerStats = Get-NVIDIAStats}
        if($MinerStats){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $NVIDIAStats.fans.$_}}
        elseif($Platforms -eq "windows"){$MinerFans = $NVIDIAFans; for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
        }
         else{Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
      }
  'sgminer-gm'
    {
      $HS = "khs"
      Write-Host "Miner $MinerType is sgminer api"
      Write-Host "Miner Port is $Port"
      Write-Host "Miner Devices is $Devices"  
      $Message = @{command="summary+devs"; parameter=""} | ConvertTo-Json -Compress
      $Request = $null
      $Request = Get-TCP -Server $Server -Port $port -Message $Message
      if($Request)
      {
      if($Platforms -eq "windows" -and $Minername -ne "teamredminer.exe"){$Request = $Request.Substring($Request.IndexOf("{"), $Request.LastIndexOf("}") - $Request.IndexOf("{") + 1) -replace " ", "_"}
      $Data = $Request | ConvertFrom-Json
      $summary = $Data.summary.summary
      $threads = $Data.devs.devs
      if($summary.'KHS 5s' -or $summary.'KHS_5s'){if($summary.'KHS 5s'){$Sum = $summary.'KHS 5s'}else{$Sum = $summary.'KHS_5s'}}
      else{if($summary.'KHS 30s'){$Sum = $summary.'KHS 30s'}else{$Sum = $summary.'KHS_30s'}}
      if($threads.'KHS 5s' -or $threads.'KHS_5s'){if($threads.'KHS 5s'){$thread = $threads.'KHS 5s'}else{$thread = $threads.'KHS_5s'}}
      else{if($threads.'KHS 30s'){$thread = $threads.'KHS 30s'}else{$thread = $threads.'KHS_30s'}}
      $RAW=0
      $RAW += [Double]$Sum*1000
      $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
      Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
      $Process = Get-Process | Where Name -clike "*$($MinerType)*"
      Write-Host "Current Running instances: $($Process.Name)"
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
      if($Platforms -eq "linux"){$MinerFans = Get-AMDFans}else{$MinerFans = $AMDFans}
      if($Platforms -eq "linux"){$MinerTemps = Get-AMDTemps}else{$MinerTemps = $AMDTemps}
      if($Platforms -eq "linux"){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
      else{for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$i]})}}
      if($Platforms -eq "linux"){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$($GCount.$TypeS.$GPU)]})}}
      else{for($i=0; $i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$i]})}}
        }
     else{Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
    }
   'cpuminer'
    {
     Write-Host "Miner $MinerType is cpuminer api"
     Write-Host "Miner Port is $Port"
     Write-Host "Miner Devices is $Devices"
     $GetCPUSUmmary = $Null
     $GetCPUSummary = Get-TCP -Server $Server -Port $Port -Message "summary"
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
      for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $CPUHashrates.$($GCount.$TypeS.$GPU) = $(if($J.Count -eq 1){$J}else{$J[$i]})}
      $J |Foreach {$CPUKHS += $_}
      $CPUHS = "khs"
     }
     else{
      $CPUKHS = 0
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
     else{Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red}
    }
   'lyclminer'
    {          
      $HS = "khs"
      Write-Host "Miner $MinerType is lyclminer (logging) api"
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
          Write-Host "Miner $Name was clocked at $([Double]$TotalRaw/1000)" -foreground Yellow
          $Process = Get-Process | Where Name -clike "*$($MinerType)*"
          Write-Host "Current Running instances: $($Process.Name)"
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
          if($Platforms -eq "linux"){$MinerFans = Get-AMDFans}else{$MinerFans = $AMDFans}
          if($Platforms -eq "linux"){$MinerTemps = Get-AMDTemps}else{$MinerTemps = $AMDTemps}
          if($Platforms -eq "linux"){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
          else{for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$i]})}}
          if($Platforms -eq "linux"){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$($GCount.$TypeS.$GPU)]})}}
          else{for($i=0; $i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$i]})}}
                      }
'xmrstak'
   {
    Write-Host "Miner $MinerType is xmrstak api"
    Write-Host "Miner Devices is $Devices"
    $HS = "hs"
    $Message="/api.json"
    $Request = $Null
    $Request = Get-HTTP -Port $Port -Message $Message
    if($Request)
    {
    $Data = $Request.Content | ConvertFrom-Json
    $Hash = $Data.Hashrate.threads
    $RAW = $Data.hashrate.total[0]
    $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
    $Process = Get-Process | Where Name -clike "*$($MinerType)*"
    Write-Host "Current Running instances: $($Process.Name)"
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){[Double]$($Hash[0] | Select -first 1)}else{[Double]$($Hash[$i] | Select -First 1)})}
    $MinerACC = 0
    $MinerREJ = 0
    $MinerACC += $Data.results.shares_good
    $MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
    $ACC += $Data.results.shares_good
    $REJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
    $UPTIME = $Data.connection.uptime
    $ALGO = $MinerAlgo
    $KHS = [Double]$Data.hashrate.total[0]
    if($Platforms -eq "linux"){$MinerFans = Get-AMDFans}else{$MinerFans = $AMDFans}
    if($Platforms -eq "linux"){$MinerTemps = Get-AMDTemps}else{$MinerTemps = $AMDTemps}
    if($Platforms -eq "linux"){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
    else{for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$i]})}}
    if($Platforms -eq "linux"){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$($GCount.$TypeS.$GPU)]})}}
    else{for($i=0; $i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$i]})}}
  }
    else{Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
   }
   'xmrstak-opt'
   {
    Write-Host "Miner $MinerType is xmrstak api"
    Write-Host "Miner Devices is $Devices"
    $CPUHS = "hs"
    $Message ="/api.json"
    $Request = $Null
    $Request = Get-HTTP -Port $Port -Message $Message
    if($Request)
    {
    $Data = $Request.Content | ConvertFrom-Json
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
    Write-Host "Miner $MinerType is wildrig api"
    Write-Host "Miner Devices is $Devices"    
    $HS = "khs"
    $Message = '/api.json'
    $Request = $Null
    $Request = Get-HTTP -Port $Port -Message $Message
    if($Request)
    {
    $Data = $Request.Content | ConvertFrom-Json
    $RAW = $Data.hashrate.total[0]
    $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    Write-Host "Miner $Name was clocked at $([Double]$RAW/1000)" -foreground Yellow
    $Process = Get-Process | Where Name -clike "*$($MinerType)*"
    Write-Host "Current Running instances: $($Process.Name)"
    $Hash = $Data.hashrate.threads
    for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUHashrates.$($GCount.$TypeS.$GPU) = $(if($Hash.Count -eq 1){[Double]$($Hash[0] | Select -first 1) / 1000}else{[Double]$($Hash[$i] | Select -First 1)})}
    $MinerACC = 0
    $MinerREJ = 0
    $MinerACC += $Data.results.shares_good
    $MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good 
    $ACC += $Data.results.shares_good
    $REJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
    $UPTIME = $Data.connection.uptime
    $ALGO = $MinerAlgo
    $KHS = [Double]$Data.hashrate.total[0]/1000
    if($Platforms -eq "linux"){$MinerFans = Get-AMDFans}else{$MinerFans = $AMDFans}
    if($Platforms -eq "linux"){$MinerTemps = Get-AMDTemps}else{$MinerTemps = $AMDTemps}
    if($Platforms -eq "linux"){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$($GCount.$TypeS.$GPU)]})}}
    else{for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUFans.$($GCount.$TypeS.$GPU) = $(if($MinerFans.Count -eq 1){$MinerFans}else{$MinerFans[$i]})}}
    if($Platforms -eq "linux"){for($i=0;$i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$($GCount.$TypeS.$GPU)]})}}
    else{for($i=0; $i -lt $Devices.Count; $i++){$GPU = $Devices[$i]; $GPUTemps.$($GCount.$TypeS.$GPU) = $(if($MinerTemps.Count -eq 1){$MinerTemps}else{$MinerTemps[$i]})}}
   }
    else{Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $RAW = 0; $RAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
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
Write-Host " $Fans" -ForegroundColor Cyan -NoNewline
Write-Host " $Temps" -ForegroundColor Magenta -NoNewline
if($Platforms -eq "windows"){Write-Host " $Power"  -ForegroundColor DarkCyan -NoNewline}
Write-Host " UPTIME=$UPTIME" -ForegroundColor White

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

if($Platforms -eq "windows" -and $HiveOS -eq "Yes")
{
$cpu = @(0,$($cpu1.LoadPercentage),$($cpu5.Average))
$mem = @($($ramfree),$($ramtotal-$ramfree))
$HashRates = $HashRates | foreach {$_ -replace ("GPU=","")}
$HashRates = $HashRates | foreach {$_ -replace ("$($_)","$($_)")}
$Power = $Power | foreach {$_ -replace ("POWER=","")}
$Power = $Power | foreach {$_ -replace ("$($_)","$($_)")}
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
    #try{
      $hiveresponse = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($SwarmResponse | ConvertTo-Json -Depth 1) -ContentType 'application/json'
      if($SwarmResponse.params.payload -eq "rebooting"){Restart-Computer}
      $SwarmResponse | ConvertTo-Json -Compress
      if($SwarmResponse.params.data -eq "Rig config changed")
      {
        $MinerFile =".\build\pid\miner_pid.txt"
        if(Test-Path $MinerFile){$MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue}
        if($MinerId)
         {
          Stop-Process $MinerId
          Start-Sleep -S 3
          Start-Process ".\SWARM.bat"
          Start-Sleep -S 3
          $ID = ".\build\pid\background_pid.txt"
          $BackGroundID = Get-Process -id (Get-Content "$ID" -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue
          Stop-Process $BackGroundID | Out-Null
         }
       }
     }
    #}
   # catch{Write-Host "Failed To Execute Command"}
   }
  }

if($BackgroundTimer.Elapsed.TotalSeconds -gt 120){Clear-Content ".\build\bash\hivestats.sh"; $BackgroundTimer.Restart()}

if($RestartTimer.Elapsed.TotalSeconds -le 10)
{
 do{
    Start-Sleep -S 1
   }while($RestartTimer.Elapsed.TotalSeconds -le 10)
}
#Start-Sleep -S 5
#Start-MinerWatchdog -PlatformMiners $Platforms
#Start-Sleep -S 5
#{"method":"stats","jsonrpc":"2.0","id":0,"params":{"rig_id":"","passwd":"","miner":"custom","meta":{"custom":{"coin":"RVN"}},"miner_stats":{"hs":[0,0,0,0,0,0,0,0,0,0,0,0,0],"hs_units":"khs","temp":[56,58,54,0,0,0,59,0,0,57,44,0,0],"fan":[80,80,80,0,0,0,80,0,0,80,80,0,0],"uptime":"6\r,","ar":["0\r","0\r"],"algo":"tribus\r"},"total_khs":"0\r","temp":["0","62","63","61","49","47","46","64","54","45","64","54","51","44"],"fan":["0","80","80","80","80","80","80","80","80","80","80","80","80","80"],"power":["0","143","137","150","0","0","0","147","0","0","143","151","0","0"],"df":"196G","mem":[7681,1669],"cpuavg":[5.29,4.33,4.61]}}
}
