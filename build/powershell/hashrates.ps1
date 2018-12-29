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

function Start-Background {
  param(
    [Parameter(Mandatory=$false)]
    [String]$Dir,
    [Parameter(Mandatory=$false)]
    [String]$WorkingDir,
    [Parameter(Mandatory=$false)]
    [String]$Platforms,
    [Parameter(Mandatory=$false)]
    [String]$HiveId,
    [Parameter(Mandatory=$false)]
    [String]$HiveOS,
    [Parameter(Mandatory=$false)]
    [String]$HivePassword,
    [Parameter(Mandatory=$false)]
    [String]$HiveMirror,
    [Parameter(Mandatory=$false)]
    [String]$RejPercent
    )

    $BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
    $command = Start-Process "powershell" -WorkingDirectory $WorkingDir -ArgumentList "-noexit -executionpolicy bypass -windowstyle minimized -command `"&{`$host.ui.RawUI.WindowTitle = `'Background Agent`'; &.\Background.ps1 -WorkingDir `'$dir`' -Platforms `'$Platforms`' -HiveID `'$HiveID`' -HiveOS `'$HiveOS`' -HiveMirror $HiveMirror -HivePassword `'$HivePassword`' -RejPercent $RejPercent}`"" -PassThru -WindowStyle Minimized | foreach {$_.Id} > ".\build\pid\background_pid.txt"
    $BackgroundTimer.Restart()
    do
    {
    Start-Sleep -S 1
    Write-Host "Getting Process ID for Background Agent"
    $ProcessId = if(Test-Path ".\build\pid\background_pid.txt"){Get-Content ".\build\pid\background_pid.txt"}
    if($ProcessID -ne $null){$Process = Get-Process $ProcessId -ErrorAction SilentlyContinue}
    }until($ProcessId -ne $null -or ($BackgroundTimer.Elapsed.TotalSeconds) -ge 10)  
    $BackgroundTimer.Stop()
}

function Get-DeviceString {
    param(
    [Parameter(Mandatory=$false)]
    [String]$TypeDevices = "none",
    [Parameter(Mandatory=$false)]
    [String]$TypeCount
    )

   if($TypeDevices -ne "none")
   {
    $TypeDevices = $TypeDevices -replace (","," ")
    if($TypeDevices -match " "){$NewDevices = $TypeDevices -split " "}else{$NewDevices = $TypeDevices -split ""}
    $NewDevices = Switch($NewDevices){"a"{"10"};"b"{"11"};"c"{"12"};"e"{"13"};"f"{"14"};"g"{"15"};"h"{"16"};"i"{"17"};"j"{"18"};"k"{"19"};"l"{"20"};default{"$_"};}
    if($TypeDevices -match " "){$TypeGPU = $NewDevices}else{$TypeGPU = $NewDevices | ? {$_.trim() -ne ""}}
    $TypeGPU = $TypeGPU | % {iex $_}
   }
   else{
    $TypeGPU = @()
    $GetDevices = 0
    for($i=0; $i -lt $TypeCount; $i++){$TypeGPU += $GetDevices++}
   }

$TypeGPU
}




function Get-TCP {
     
  param(
      [Parameter(Mandatory = $false)]
      [String]$Server = "localhost", 
      [Parameter(Mandatory = $true)]
      [String]$Port, 
      [Parameter(Mandatory = $true)]
      [String]$Message, 
      [Parameter(Mandatory = $false)]
      [Int]$Timeout = 10 #seconds
  )

  try {
      $Client = New-Object System.Net.Sockets.TcpClient $Server, $Port
      $Stream = $Client.GetStream()
      $Writer = New-Object System.IO.StreamWriter $Stream
      $Reader = New-Object System.IO.StreamReader $Stream
      $client.SendTimeout = $Timeout * 1000
      $client.ReceiveTimeout = $Timeout * 1000
      $Writer.AutoFlush = $true

      $Writer.WriteLine($Message)
      $Response = $Reader.ReadLine()
  }
  catch { $Error.Remove($error[$Error.Count - 1])}
  finally {
      if ($Reader) {$Reader.Close()}
      if ($Writer) {$Writer.Close()}
      if ($Stream) {$Stream.Close()}
      if ($Client) {$Client.Close()}
  }

  $response
  
}

function Get-HTTP {
     
  param(
      [Parameter(Mandatory = $false)]
      [String]$Server = "localhost", 
      [Parameter(Mandatory = $true)]
      [String]$Port, 
      [Parameter(Mandatory = $false)]
      [String]$Message,
      [Parameter(Mandatory = $false)]
      [Int]$Timeout = 10 #seconds
  )

  try {
       $response = Invoke-WebRequest "http://$($Server):$($Port)$($Message)" -UseBasicParsing -TimeoutSec $timeout
      }
  catch {$Error.Remove($error[$Error.Count - 1])}
  $response
}


function Get-HashRate {
    param(
        [Parameter(Mandatory=$true)]
        [String]$Type,
        [Parameter(Mandatory=$false)]
        [String]$API,
        [Parameter(Mandatory=$false)]
        [Int]$Port
       )

    if($Type -eq "ASIC")
    {
      switch($API)
      {
        "cgminer"
        {
        $summary = "summary|0"
        $Master | foreach {try{$response = Get-TCP -Server "$($_)" -Port $Port -Message $summary -Timeout $timeout}catch{}}
        $response = $response -split "SUMMARY," | Select -Last 1
        $response = $response -split "," | ConvertFrom-StringData
        $Hash = [Double]$Response."MHS 5s"*1000000
        $Hash
        }
      }
    }
    else{
        $HashFile = Get-Content ".\build\txt\$Type-hash.txt"
        [Double]$HashFile 
        }
}

function Get-HiveStats {
   param (
        [Parameter(Mandatory=$false)]
        [Int]$Threads,
        [Parameter(Mandatory=$false)]
        [Int]$Devices,
        [Parameter(Mandatory=$false)]
        [Int]$DType,
        [Parameter(Mandatory=$false)]
        [Int]$Command,
        [Parameter(Mandatory=$false)]
        [Object]$Parameters = @{},
        [Parameter(Mandatory=$false)]
        [Bool]$Safe = $false
    )

    $Server = "localhost"

    try
    {
      switch($API)
        {
            "sgminer-gm"
            {
             $Message = @{command="summary+devs"; parameter=""} | ConvertTo-Json -Compress
             do
             {
              $Request = Get-TCP -Server $Server -Port $Port
              $Data = $Request.Substring($Request.IndexOf("{"),$Request.LastIndexOf("}")-$Request.IndexOf("{")+1) -replace " ","_" | ConvertFrom-Json
              $HashRate = if($Data.SUMMARY.HS_5s -ne $null){[Double]$Data.SUMMARY.HS_5s*[Math]::Pow($Multiplier,0)}
              elseif($Data.SUMMARY.KHS_5s -ne $null){[Double]$Data.SUMMARY.KHS_5s*[Math]::Pow($Multiplier,1)}
              elseif($Data.SUMMARY.MHS_5s -ne $null){[Double]$Data.SUMMARY.MHS_5s*[Math]::Pow($Multiplier,2)}
              elseif($Data.SUMMARY.GHS_5s -ne $null){[Double]$Data.SUMMARY.GHS_5s*[Math]::Pow($Multiplier,3)}
              elseif($Data.SUMMARY.THS_5s -ne $null){[Double]$Data.SUMMARY.THS_5s*[Math]::Pow($Multiplier,4)}
              elseif($Data.SUMMARY.PHS_5s -ne $null){[Double]$Data.SUMMARY.PHS_5s*[Math]::Pow($Multiplier,5)}
              if($HashRate -ne $null)
               {
                $HashRates += $HashRate
                if(-not $Safe){break}
               }
              $HashRate = if($Data.SUMMARY.HS_av -ne $null){[Double]$Data.SUMMARY.HS_av*[Math]::Pow($Multiplier,0)}
              elseif($Data.SUMMARY.KHS_av -ne $null){[Double]$Data.SUMMARY.KHS_av*[Math]::Pow($Multiplier,1)}
              elseif($Data.SUMMARY.MHS_av -ne $null){[Double]$Data.SUMMARY.MHS_av*[Math]::Pow($Multiplier,2)}
              elseif($Data.SUMMARY.GHS_av -ne $null){[Double]$Data.SUMMARY.GHS_av*[Math]::Pow($Multiplier,3)}
              elseif($Data.SUMMARY.THS_av -ne $null){[Double]$Data.SUMMARY.THS_av*[Math]::Pow($Multiplier,4)}
              elseif($Data.SUMMARY.PHS_av -ne $null){[Double]$Data.SUMMARY.PHS_av*[Math]::Pow($Multiplier,5)}
              if($HashRate -eq $null){$HashRates = @(); break}
              $HashRates += $HashRate
              if(-not $Safe){break}
              Start-sleep $Interval
             } while($HashRates.Count -lt 2)
            }
            "ccminer"
            {
              if($DType -eq "CPU"){$NewDevices = $Devices; $Threads = $null}
              elseif($Devices -ne $Null){$NewThreads = $Null; $NewDevices = $Devices}
              else{$NewThreads = $Threads; $NewDevices = $Null}
              $GetThreads = Get-TCP -Server $Server -Port $Port -Message "threads"
              $GetSummary = Get-TCP -Server $Server -Port $port -Message "summary"
              $Hashes = $GetThreads -split "="
              $Hashes = $GetThreads -split "\|" | Select-String "\."
              $ACC = $GetSummary -split ";" | Select-String "ACC" | foreach{$_ -replace ("ACC=","")}
              $REJ = $GetSummary -split ";" | Select-String "REJ" | foreach{$_ -replace ("REJ=","")}
              $KHS = $GetSummary -split ";" | Select-String "KHS" | foreach{$_ -replace ("KHS=","")}
              $UPTIME = $GetSummary -split ";" | Select-String "UPTIME" | foreach{$_ -replace ("UPTIME=","")}
              $ALGO = $GetSummary -split ";" | Select-String "UPTIME" | foreach{$_ -replace ("ALGO=","")}
              $Hash = @()
              $HashRates
              if($NewThreads -ne $null){for($i=0;$i -lt $NewThreads.Count; $i++){ $Selected = $Data | Skip $i | Select -First 1; $Hash += $Selected}}
              elseif($NewDevices -ne $null){for($i=0;$i -lt $NewDevices.Count; $i++){$GPU = $NewDevices[$i]; $Selected = $Data | Skip $GPU | Select -First 1;$Hash += $Selected}}
              $RAW = 0
              $Hash = $Hash | % {iex $_}
              $Hash | foreach {$RAW += $_}
              $Hash | foreach {$HashRates += "GPU=$_"}
              if(-not $Safe){break}
              Start-Sleep $Interval
            }
          "ewbf"
            {
             do
              {
                $Message = @{id = 1; method = "getstat"} | ConvertTo-Json -Compress
                $Client = New-Object System.Net.Sockets.TcpClient $server, $port
                $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
                $Reader = New-Object System.IO.StreamReader $Client.GetStream()
                $Writer.AutoFlush = $true
                $Writer.WriteLine($Message)
                $Request = $Reader.ReadLine()
                $Data = $Request | ConvertFrom-Json
                $HashRates += [Double]($HashRate | Measure-Object -Sum).Sum
                if(-not $Safe){break}
                Start-Sleep $Interval
               } while($HashRates.Count -lt 2)
            }
          "claymore"
            {
             do
             {
              $Request = Invoke-WebRequest "http://$($Server):$Port" -UseBasicParsing
              $Data = $Request.Content.Substring($Request.Content.IndexOf("{"),$Request.Content.LastIndexOf("}")-$Request.Content.IndexOf("{")+1) | ConvertFrom-Json
              $HashRate = $Data.result[2].Split(";")[0]
              if($HashRate -eq $null){$HashRates = @()}
              $HashRates += [Double]$HashRate*$Multiplier
              if(-not $Safe){break} 
              Start-Sleep $Interval
             } while($HashRates.Count -lt 2)
            }
          "dstm" 
            {
             $Message = "summary"
             do 
             {
              $Client = New-Object System.Net.Sockets.TcpClient $server, $port
              $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
              $Reader = New-Object System.IO.StreamReader $Client.GetStream()
              $Writer.AutoFlush = $true
              $Writer.WriteLine($Message)
              $Request = $Reader.ReadLine()
              $Data = $Request | ConvertFrom-Json
              $HashRate = [Double]($Data.result.sol_ps | Measure-Object -Sum).Sum
              if (-not $HashRate) {$HashRate = [Double]($Data.result.speed_sps | Measure-Object -Sum).Sum} #ewbf fix
              if ($HashRate -eq $null) {$HashRates = @(); break}
              $HashRates += [Double]$HashRate
              if (-not $Safe) {break}
              Start-Sleep $Interval
             } while ($HashRates.Count -lt 2)
            }
         "wrapper"
           {
            do
            {
             $HashRate = Get-Content ".\Wrapper_$Port.txt"
             if($HashRate -eq $null){$HashRates = @(); break}
             $HashRates += [Double]$HashRate
             if(-not $Safe){break}
             Start-Sleep $Interval
            } while($HashRates.Count -lt 2)
           }
         "tdxminer"
           {
            do
            {
             if(Test-Path ".\Build\Unix\Hive\logstats.sh")
              {
               $Data = Get-Content ".\Build\Unix\Hive\logstats.sh" | ConvertFrom-StringData
               $HashRate = $Data.RAW
               if($HashRate -eq $null){$HashRates = @(); break}
               $HashRates += [Double]$HashRate
               if(-not $Safe){break}
               Start-Sleep $Interval
              }
             } while($HashRates.Count -lt 2)
            Clear-Content ".\Build\Unix\Hive\logstats.sh"
           }
         "lyclminer"
           {
            do
            {
             if(Test-Path ".\Build\Unix\Hive\logstats.sh")
              {
               $Data = Get-Content ".\Build\Unix\Hive\logstats.sh" | ConvertFrom-StringData
               $HashRate = $Data.RAW
               if($HashRate -eq $null){$HashRates = @(); break}
               $HashRates += [Double]$HashRate
               if(-not $Safe){break}
               Start-Sleep $Interval
              }
            }while($HashRates.Count -lt 2)
            Clear-Content ".\Build\Unix\Hive\logstats.sh"
           }
         "cpulog"
           {
            $Hashrate = 0
            if(Test-Path ".\Logs\CPU.log")
            {
             $CPUlog = Get-Content ".\Logs\CPU.log" | Select-String "CPU"
             for($i=0; $i -lt $CPUThreads; $i++)
             {
              $Hash = $CPUlog | Select-String "CPU #$($i)" | Select -Last 1
              $Hash = $Hash -replace (" ","")
              $Hash = $Hash -split ":" | Select-String -SimpleMatch "/s"
              $Hash = $Hash -split "/s" | Select -First 1
              $Hash = $Hash -replace ("h","")
              $Hash = $Hash -replace ("m","")
              $Hash = $Hash -replace ("mh","")
              $Hash = $Hash -replace ("kh","")
              $Hash = $Hash | % {iex $_}
              $Hash | foreach{$HashRate += $_}
             }
            $HashRates += [Double]$HashRate
            }
            else{$HashRates = @(); break}
           }                 
         "lolminer"
           {
            do 
            {
             $Client = New-Object System.Net.Sockets.TcpClient $server, $port
             $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
             $Reader = New-Object System.IO.StreamReader $Client.GetStream()
             $Writer.AutoFlush = $true
             $Request = $Reader.ReadToEnd()
             $Data = $Request | ConvertFrom-Json
             $HashRate = [Double]$Data."TotalSpeed(10s)"
             if ($HashRate -eq $null) {$HashRates = @(); break}
             $HashRates += [Double]$HashRate
             if (-not $Safe) {break}
             Start-Sleep $Interval
            } while ($HashRates.Count -lt 2)
           }
        "xmrstak" 
          {
           do 
           {
            $Request="/api.json"
            $Reader = Invoke-WebRequest "http://$($server):$($port)$($Request)" -UseBasicParsing -TimeoutSec 2
            if ($Reader -ne "") {
            $Data = $Reader.Content | ConvertFrom-Json
            $HashRate = [Double]$Data.hashrate.total[0]
            }
            $HashRates += [Double]$HashRate
            if (-not $Safe) {break}
            Start-Sleep $Interval
           } while ($HashRates.Count -lt 2)  
          }
        "wildrig" 
          {
           do 
           {
            $Request="/api.json"
            $Reader = Invoke-WebRequest "http://$($server):$($port)$($Request)" -UseBasicParsing -TimeoutSec 2
            if ($Reader -ne "") {
            $Data = $Reader.Content | ConvertFrom-Json
            $HashRate = [Double]$Data.hashrate.total[0]
            }
            $HashRates += [Double]$HashRate
            if (-not $Safe) {break}
            Start-Sleep $Interval
           } while ($HashRates.Count -lt 2)
          }
        }
        #####
if($Command -eq "Send")
{
$FILE=
"$($Hashrates -join "`n")
KHS=$KHS
ACC=$ACC
REJ=$REJ
ALGO=$ALGO
UPTIME=$UPTIME
"
$FILE | Set-Content ".\Build\Unix\Hive\hivestats.sh"
$Hash
}         
}catch{}
}

filter ConvertTo-Hash {
    $Hash = $_
    switch([math]::truncate([math]::log($Hash,[Math]::Pow(1000,1))))
    {
        0 {"{0:n2}  H" -f ($Hash / [Math]::Pow(1000,0))}
        1 {"{0:n2} KH" -f ($Hash / [Math]::Pow(1000,1))}
        2 {"{0:n2} MH" -f ($Hash / [Math]::Pow(1000,2))}
        3 {"{0:n2} GH" -f ($Hash / [Math]::Pow(1000,3))}
        4 {"{0:n2} TH" -f ($Hash / [Math]::Pow(1000,4))}
        Default {"{0:n2} PH" -f ($Hash / [Math]::Pow(1000,5))}
    }
}

filter ConvertTo-LogHash {
    $Hash = $_
    switch([math]::truncate([math]::log($Hash,[Math]::Pow(1000,1))))
    {
        0 {"{0:n2}  `nhs" -f ($Hash / [Math]::Pow(1000,0))}
        1 {"{0:n2} `nkhs" -f ($Hash / [Math]::Pow(1000,1))}
        2 {"{0:n2} `nmhs" -f ($Hash / [Math]::Pow(1000,2))}
        3 {"{0:n2} `nghs" -f ($Hash / [Math]::Pow(1000,3))}
        4 {"{0:n2} `nths" -f ($Hash / [Math]::Pow(1000,4))}
        Default {"{0:n2} `n PH" -f ($Hash / [Math]::Pow(1000,5))}
    }
}