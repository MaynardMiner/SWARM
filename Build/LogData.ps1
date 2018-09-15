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
        [String]$DeviceCall,
        [Parameter(Mandatory=$false)]
        [String]$Type,
        [Parameter(Mandatory=$false)]
        [array]$GPUS,
        [Parameter(Mandatory=$false)]
        [String]$WorkingDir,
        [Parameter(Mandatory=$false)]
        [String]$Miner_Algo,
        [Parameter(Mandatory=$false)]
        [String]$API,
        [Parameter(Mandatory=$false)]
        [String]$Port
    )

Set-Location $WorkingDir

 . .\Build\Unix\IncludeCoin.ps1

##Apply OC Setings

if($Type -like "*NVIDIA*")
 {
$OCSettings = Get-Content ".\Config\OC-Nvidia.conf" | ConvertFrom-Json
$DefaultCore = $OCSettings.Default.Core -split ' '
$DefaultMem = $OCSettings.Default.Memory -split ' '
$DefaultPower = $OCSettings.Default.Power -split ' '
$Core = $OCSettings.$Miner_Algo.Core -split ' '
$Mem = $OCSettings.$Miner_Algo.Memory -split ' '
$Power = $OCSettings.$Miner_Algo.Power -split ' '
$Card = $OCSettings.Cards -split ' '
$Default = $true
if($Card -ne "")
 {
  if($Core -ne "")
   {
  $Default = $false
  $OCArgs = @()
  for($i=0; $i -lt $Power.Count; $i++)
  {
    $PWLSelected = $Power | Select -skip $i | Select -First 1
    Start-Process "nvidia-smi" -ArgumentList "-i $i -pl $PWLSelected" -Wait
  }
  for($i=0; $i -lt $Core.Count; $i++)
  {
    $X = 3
    Switch($Card | Select -skip $i | Select -First 1){
    "1050"{$X = 2}
    "1050ti"{$X = 2}
    "P106-100"{$X = 2}
    "P106-090"{$X = 1}
    "P104-100"{$X = 1}
    "P102-100"{$X = 1}
    }
    $OCArgs += " -a [gpu:$i]/GPUGraphicsClockOffset[$X]=$($Core | Select -skip $i | Select -First 1)"
    $OCArgs += " -a [gpu:$i]/GPUMemoryTransferRateOffset[$X]=$($Mem | Select -skip $i | Select -First 1)"
  }
 if($OCArgs -ne $null){Start-Process "nvidia-settings" -ArgumentList "$OCArgs"}
 }
 else{
  $OCArgs = @()
  for($i=0; $i -lt $DefaultPower.Count; $i++)
  {
    $PWLSelected = $DefaultPower | Select -skip $i | Select -First 1
    Start-Process "nvidia-smi" -ArgumentList "-i $i -pl $PWLSelected" -Wait
  }
  for($i=0; $i -lt $DefaultCore.Count; $i++)
  {
    $X = 3
    Switch($Card | Select -Skip $i | Select -First 1){
    "1050"{$X = 2}
    "1050ti"{$X = 2}
    "P106-100"{$X = 2}
    "P106-090"{$X = 1}
    "P104-100"{$X = 1}
    "P102-100"{$X = 1}
    }
    $OCArgs += " -a [gpu:$i]/GPUGraphicsClockOffset[$X]=$($DefaultCore | Select -Skip $i | Select -First 1)"
    $OCArgs += " -a [gpu:$i]/GPUMemoryTransferRateOffset[$X]=$($DefaultMem | Select -Skip $i | Select -First 1)"
  }
 if($OCArgs -ne $null){Start-Process "nvidia-settings" -ArgumentList "$OCArgs"}
  }
 }
}

if($Default -eq $true)
{
$OCMessage = "
Current OC Profile:
Algorithm is $Miner_Algo
Default: $Default
Cards: $($OCSettings.Cards)
Power Settings: $($OCSettings.Default.Power)
Core Settings: $($OCSettings.Default.Core)
Memory Settings: $($OCSettings.Default.Memory)
"
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
}

$OCMessage | Out-File ".\Build\OC-Settings.txt"

 While($true)
 {
 $MinerAlgo = "$($Miner_Algo)"
 $HashPath = Join-Path ".\Logs" "$($Type).log"

 switch($DeviceCall)
 {
  "trex"
     {
     if(Test-Path $HashPath)
       {
        Clear-Content ".\Build\Unix\Hive\hivestats.sh" -Force
        Clear-Content ".\Build\Unix\Hive\logstats.sh" -Force        
        $Miner_HashRates = Get-HashRate $API $Port
        $Convert = [string]$GPUS -replace (","," ")
        $GPU = $Convert -split ' '
        $HashArray = @()
        $Hash = @()
	      $A = $null
        $A = Get-Content $HashPath
        if($A)
         {
          for($i = 0; $i -lt $GPU.Count; $i++)
            {
             $Selected = $GPU | Select -skip $i | Select -First 1
             $B = $A | Select-String  "GPU #$($Selected):" | Select -Last 1
             if($B -ne $null)
              {
              if([regex]::match($B,"MH/s").success  -eq $true){$CHash = "MH/s"}
              else{$CHash = "kH/s"}
              $C = $B -replace (" ","") -split "-" -split "$CHash" | Select-String -SimpleMatch "."
              $C | foreach{$HashArray += $_}
              $Hash += $CHash
              }
           else
            {
             $Hash += "kH/s"
             $HashArray += 0.1
            }
           }
          }
       else{
       for($i = 0; $i -lt $GPU.Count; $i++)
         {
          $Hash += "Kh/s"
          $HashArray += 0.1
         }
        }
        $J = $HashArray | % {iex $_}
        $K = @()
        for($i = 0; $i -lt $Hash.Count; $i++)
          {
           $SelectedHash = $Hash | Select -skip $i | Select -First 1
           $SelectedPattern = $J | Select -skip $i | Select -First 1
           $SelectedPattern | foreach { if ($SelectedHash -eq "MH/s"){$K += "GPU=$($($_)*1000)"}else{$K += "GPU=$($_)"}}
          }
        $KK = $A | Select-String "ms" | Select-String " OK " | Select -Last 1
        $LL = $KK -split "]" | Select-String "/"
        $MM = $LL -split " -" | Select -First 1
        $NN = $MM -replace (" ", "     ")
        $OO = $NN -split ("     ") | Select -Last 1
        [string]$Accepted = $OO -Split "/" | Select -First 1
        [string]$GetRejected = $OO -Split "/" | Select -Last 1
        $Rejected = ($Accepted-$GetRejected)
        $KHS = $Miner_HashRates/1000

$Hive=
"$($K -join "`n")
RAW=$Miner_HashRates
KHS=$KHS
ACC=$Accepted
RJ=$Rejected
ALGO=$MinerAlgo"

$Hive

$Hive | Set-Content ".\Build\Unix\Hive\hivestats.sh"
$Hive | Set-Content ".\Build\Unix\Hive\logstats.sh"

       }
       Start-Sleep -S 5
    }
    "ccminer"
      {
       Write-Host "Logging not needed for this miner" -foregroundcolor yellow
       Start-Sleep -S 10
      }
    "cryptozeny"
      {
       if(Test-Path $HashPath)
        {
        Clear-Content ".\Build\Unix\Hive\hivestats.sh" -Force
        Clear-Content ".\Build\Unix\Hive\logstats.sh" -Force        
        $Miner_HashRates = Get-HashRate $API $Port
        $Convert = [string]$GPUS -replace (","," ")
        $GPU = $Convert -split ' '
        $HashArray = @()
        $Hash = @()
        $A = $null
        $TotalHash = 0
        $A = Get-Content $HashPath
        if($A)
        {
        for($i=0; $i -lt $GPU.Count; $i++)
         {
            $Hash = $A | Select-String "CPU #$($i)" | Select -Last 1
            $Hash = $Hash -replace (" ","")
            $Hash = $Hash -split ":" | Select-String -SimpleMatch "/s"
            $Hash = $Hash -split "/s" | Select -First 1
            $Hash = $Hash -replace ("h","")
            $Hash = $Hash -replace ("m","")
            $Hash = $Hash -replace ("mh","")
            $Hash = $Hash -replace ("kh","")
            $Hash = $Hash | % {iex $_}
            $Hash | foreach {$HashArray += $_}
            $Hash | foreach {$TotalHash += $_}
         }
        }
        else{
        for($i = 0; $i -lt $GPU.Count; $i++)
        {
         $HashArray += 0.1
        }
      }
        $J = $HashArray | % {iex $_}
        $K = @()
         for($i = 0; $i -lt $HashArray.Count; $i++)
           {
            $SelectedPattern = $J | Select -skip $i | Select -First 1
            $SelectedPattern | foreach {$K += "GPU=$(([math]::Round($($_)/1000,2)))"}}
      }
           $KHS = [math]::Round($TotalHash/1000,2)
           $Accepted = ($A | Select-String "Accepted").Count
           $Rejected = ($A | Select-String "Rejected").Count
$Hive=
"$($K -join "`n")
RAW=$TotalHash
KHS=$KHS
ACC=$Accepted
RJ=$Rejected
ALGO=$MinerAlgo"
$Hive

$Hive | Set-Content ".\Build\Unix\Hive\hivestats.sh"
$Hive | Set-Content ".\Build\Unix\Hive\logstats.sh"

Start-Sleep -S 5
      }
    "cpuminer-opt"
     {
      Write-Host "Logging not needed for this miner" -foregroundcolor yellow
      Start-Sleep -S 10
     }
    "claymore"
      {
       Write-Host "Logging not needed for this miner" -foregroundcolor yellow
       Start-Sleep -S 10
      }
    "dstm"
      {
       Write-Host "Logging not needed for this miner" -foregroundcolor yellow
       Start-Sleep -S 10
      }
    "ewbf"
      {
       Write-Host "Logging not needed for this miner" -foregroundcolor yellow
       Start-Sleep -S 10
      }
      "sgminer-gm"
      {
       Write-Host "Logging not needed for this miner" -foregroundcolor yellow
       Start-Sleep -S 10
      }
      "tdxminer"
      {
      if(Test-Path $HashPath)
       {
        Clear-Content ".\Build\Unix\Hive\hivestats.sh" -Force
        Clear-Content ".\Build\Unix\Hive\logstats.sh" -Force
        $Convert = [string]$GPUS -replace (","," ")
        $GPU = $Convert -split ' '
        $HashArray = @()
        $Hash = @()
	      $A = $null
        $A = Get-Content $HashPath
      if($A)
       {
        for($i = 0; $i -lt $GPU.Count; $i++)
        {
         $Selected = $GPU | Select -skip $i | Select -First 1
           $B = $A | Select-String "GPU $($Selected)" | Select-String "Stats" | Select -Last 1
           if($B -ne $null)
            {
             if([regex]::match($B,"Mh/s").success -eq $true){$CHash = "Mh/s"}
             else{$CHash = "Kh/s"}
             if([regex]::match($B,"Mh/s").success -eq $true){$Hash += "Mh/s"}
             else{$Hash += "Kh/s"}
             $D = $B -split ":" | Select-String "$CHash"
             $E = $D -replace (" ","")
             $F = $E -replace ("h/s\)","") | Select-String "$Chash"
             $G = $F -split "\(" | Select-String "$Chash"
             $H = $G -replace ("$Chash","")
             $H | foreach{$HashArray += $_}
            }
            else
            {
             $Hash += "Kh/s"
             $HashArray += 0.1
            }
          }
        else{
          for($i = 0; $i -lt $GPU.Count; $i++)
          {
            $Hash += "Kh/s"
            $HashArray += 0.1
          }
         }
        }
        $J = $HashArray | % {iex $_}
        $K = @()
        $TotalRaw = 0
        for($i = 0; $i -lt $Hash.Count; $i++)
          {
           $SelectedHash = $Hash | Select -skip $i | Select -First 1
           $SelectedPattern = $J | Select -skip $i | Select -First 1
           $SelectedPattern | foreach { if ($SelectedHash -eq "Mh/s"){$K += "GPU=$($($_)*1000)"}else{$K += "GPU=$($_)"}}
           $SelectedPattern | foreach { if ($SelectedHash -eq "Mh/s"){$TotalRaw += $_*1000000}else{$TotalRaw += ($_*1000)}}
          }
          $Accepted = ($A | Select-String "accepted").Count
          $Rejected = ($A | Select-String "rejected").Count
          $KHS = $TotalRaw/1000

$Hive=
"$($K -join "`n")
RAW=$TotalRaw
KHS=$KHS
ACC=$Accepted
RJ=$Rejected
ALGO=$MinerAlgo"

$Hive

$Hive | Set-Content ".\Build\Unix\Hive\hivestats.sh"
$Hive | Set-Content ".\Build\Unix\Hive\logstats.sh"
        }
Start-Sleep -S 5
      }
    "lyclminer"
     {
      if(Test-Path $HashPath)
       {
        Clear-Content ".\Build\Unix\Hive\hivestats.sh" -Force
        Clear-Content ".\Build\Unix\Hive\logstats.sh" -Force
      $Convert = [string]$GPUS -replace (","," ")
      $GPU = $Convert -split ' '
      $HashArray = @()
      $Hash = @()
      $A = $null
      $A = Get-Content $HashPath
      if($A)
      {
      for($i = 0; $i -lt $GPU.Count; $i++)
      {
       $Selected = $GPU | Select -skip $i | Select -First 1
       $B = $A | Select-String "Device #$($Selected)" | Select-String "/s" | Select -Last 1
        if($B -ne $Null)
         {
          $C = $B -replace (" ","")
          $D = $C -split "," | Select-String "/s"
          if($D -like "*/s*")
           {
            if([regex]::match($D,"MH/s").success -eq $true){$CHash = "MH/s"}
            else{$CHash = "KH/s"}
            if([regex]::match($D,"MH/s").success -eq $true){$Hash += "MH/s"}
            else{$Hash += "KH/s"}
           }
          $E = $D -split "$CHash" | Select -First 1
          $E | foreach{$HashArray += $_}
         }
         else{
          for($i = 0; $i -lt $GPU.Count; $i++)
          {
            $Hash += "Kh/s"
            $HashArray += 0.1
          }
         }
        }
       }
       else{
        for($i = 0; $i -lt $GPU.Count; $i++)
        {
          $Hash += "Kh/s"
          $HashArray += 0.1
        }
       }
      $J = $HashArray | % {iex $_}
      $K = @()
      $TotalRaw = 0
      for($i = 0; $i -lt $Hash.Count; $i++)
      {
       $SelectedHash = $Hash | Select -skip $i | Select -First 1
       $SelectedPattern = $J | Select -skip $i | Select -First 1
       $SelectedPattern | foreach { if ($SelectedHash -eq "MH/s"){$K += "GPU=$($($_)*1000)"}else{$K += "GPU=$($_)"}}
       $SelectedPattern | foreach { if ($SelectedHash -eq "MH/s"){$TotalRaw += ($_*1000000)}else{$TotalRaw += ($_*1000)}}
      }
      $AA = $A | Select-String "Accepted"  | Select -Last 1
      $BB = $AA -Split "d" | Select-String "/"
      $CC = $BB -replace (" ","")
      $DD = $CC -split "\)" | Select-String "%"
      $Shares = $DD -split "\(" | Select-String "/"
      [string]$Accepted = $Shares -Split "/" | Select -First 1
      [string]$GetRejected = $Shares -Split "/" | Select -Last 1
      $Rejected = ($Accepted-$GetRejected)
      $KHS = $TotalRaw/1000

$Hive=
"$($K -join "`n")
RAW=$TotalRaw
KHS=$KHS
ACC=$Accepted
RJ=$Rejected
ALGO=$MinerAlgo"
      
$Hive
      
$Hive | Set-Content ".\Build\Unix\Hive\hivestats.sh"
$Hive | Set-Content ".\Build\Unix\Hive\logstats.sh"
    }
Start-Sleep -S 5
    
    } 
   }
  }
