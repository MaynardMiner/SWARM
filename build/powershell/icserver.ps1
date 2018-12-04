function Start-ASIC{

$Config = Get-Content ".\config\asic\asic-list.json" | convertfrom-json

$BenchmarkMode = "No"
$Instance = 1
$DecayStart = Get-Date
$DecayPeriod = 60 #seconds
$DecayBase = 1-0.1 #decimal percentage
$Deviation = $Donate
$WalletDonate = "1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i"
$NicehashDonate = "3JfBiUZZV17DTjAFCnZb97UpBgtLPLLDop"
$UserDonate = "MaynardVII"
$WorkerDonate = "Rig1"
$PoolNumber = 1
$TimeDeviation = 1
$Algorithm = @()
$Config.Algorithm | foreach {$Algorithm += $_}
$Naming = [PSCustomObject]@{}
$Config.algorithm | foreach{$Naming | Add-Member $($_) $($_)}
$Miner = $Config.miner
$Master = $Config.master
$Slaves = @()
$Config.Slaves | foreach {$Slaves += $_}
$Port = $Config.port
$API = $Config.miner
$CoinAlgo = $null
$ActiveMinerPrograms = @()
$PID | Set-Content ".\build\pid\miner_pid.txt"
$swarmstamp = "SWARMISBESTMINEREVER"

While($True)
{
Start-PoolBans $StartingParams $swarmstamp 

##Parameters (if changed through command)
$GetSWARMParams = Get-Content ".\config\parameters\arguments.json"
$SWARMParams = $GetSWARMParams | ConvertFrom-Json
$Wallet = $SWARMParams.Wallet
$Wallet1 = $SWARMParams.Wallet1
$Wallet2 = $SWARMParams.Wallet2
$Wallet3 = $SWARMParams.Wallet3
$CPUWallet = $SWARMParams.CPUWallet
$Nicehash_Wallet1 = $SWARMParams.Nicehash_Wallet1
$Nicehash_Wallet2 = $SWARMParams.Nicehash_Wallet2
$Nicehash_Wallet3 = $SWARMParams.Nicehash_Wallet3
$AltWallet1 = $SWARMParams.AltWallet1
$AltWallet2 = $SWARMParams.AltWallet2
$AltWallet3 = $SWARMParams.AltWallet3
$RigName1 = $SWARMParams.RigName1
$RigName2 = $SWARMParams.RigName2
$RigName3 = $SWARMParams.RigName3
$API_ID = $SWARMParams.API_ID
$API_Key = $SWARMParams.API_Key
$Timeout = $SWARMParams.Timeout
$Interval = $SWARMParams.Interval
$StatsInterval = $SWARMParams.StatsInterval
$Location = $SWARMParams.Location
$Type = $SWARMParams.Type
$GPUDevices1 = $SWARMParams.GPUDevices1 -replace "\\'",""
$GPUDevices2 = $SWARMParams.GPUDevices2 -replace "\\'",""
$GPUDevices3 = $SWARMParams.GPUDevices3 -replace "\\'",""
$PoolName = $SWARMParams.PoolName
$Currency = $SWARMParams.Currency
$Passwordcurrency1 = $SWARMParams.Passwordcurrency1
$Passwordcurrency2 = $SWARMParams.Passwordcurrency1
$Passwordcurrency3 = $SWARMParams.Passwordcurrency3
$AltPassword1 = $SWARMParams.AltPassword1
$AltPassword2 =  $SWARMParams.AltPassword2
$AltPassword3 = $SWARMParams.AltPassword3
$Donate = $SWARMParams.Donate
$Proxy = $SWARMParams.Proxy -replace "\\'",""
$CoinExchange = $SWARMParams.CoinExchange
$Auto_Coin = $SWARMParams.Auto_Coin
$Nicehash_Fee = $SWARMParams.Nicehash_Fee
$Benchmark = $SWARMParams.Benchmark
$No_Algo = $SWARMParams.No_Algo
$Favor_Coins = $SWARMParams.Favor_Coins
$Threshold = $SWARMParams.Threshold
$Platform = $SWARMParams.platform
$CPUThreads = $SWARMParams.CPUThreads
$Stat_Coin = $SWARMParams.Stat_Coin
$Stat_Algo = $SWARMParams.Stat_Algo
$CPUOnly =  $SWARMParams.CPUOnly
$HiveOS = $SWARMParams.HiveOS
$Update = $SWARMParams.Update
$Cuda = $SWARMParams.Cuda
$WattOMeter = $SWARMParams.WattOMeter
$HiveID = $SWARMParams.HiveId
$Farm_Hash = $SWARMParams.Farm_Hash
$HivePassword = $SWARMParams.HivePassword
$HiveMirror = $SWARMParams.HiveMirror
$Rejections = $SWARMParams.Rejections
$PoolBans = $SWARMParams.PoolBans
$PoolBanCount = $SWARMParams.PoolBanCount
$AlgoBanCount = $SWARMParams.AlgoBanCount
$Lite = $SWARMParams.Lite

if($SWARMParams.Rigname1 -eq "Donate"){$Donating = $True}
else{$Donating = $False}
if($Donating -eq $True){$Test =Get -Date; $DonateTest = "Miner has donated on $Test"; $DonateTest | Set-Content ".\build\txt\donate.txt"}

$MinerWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$TimeoutTime = $Timeout*3600
$DecayExponent = [int](((Get-Date)-$DecayStart).TotalSeconds/$DecayPeriod)

$ActiveMinerPrograms | foreach {Write-Host "Current Active Miner Progams: $($_.MinerPool)"}

try {
    $R = [string]$Currency
    Write-Host "SWARM Is Building The Database. Auto-Coin Switching: $Auto_Coin" -foreground "yellow"
    $Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=BTC" -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
    $Currency | Where-Object {$Rates.$_} | ForEach-Object {$Rates | Add-Member $_ ([Double]$Rates.$_) -Force}
    $WattCurr = (1/$Rates.$Currency)
    $WattEx = [Double](($WattCurr*$Watts.KWh.KWh))
    }
    catch {
    Write-Host -Level Warn "Coinbase Unreachable. "
    Write-Host -ForegroundColor Yellow "Last Refresh: $(Get-Date)"
    Write-host "Trying To Contact Cryptonator.." -foregroundcolor "Yellow"
    $Rates = [PSCustomObject]@{}
    $Currency | ForEach {$Rates | Add-Member $_ (Invoke-WebRequest "https://api.cryptonator.com/api/ticker/btc-$_" -UseBasicParsing | ConvertFrom-Json).ticker.price}
    }

    if($TimeoutTimer.Elapsed.TotalSeconds -lt $TimeoutTime -or $Timeout -eq 0){$Stats = Get-Stats -Timeouts "No"}
    else
    {
     Get-Stats -Timeouts "Yes"
     $TimeoutTimer.Restart()
     continue
    }

    Write-Host "Checking Algo Pools" -Foregroundcolor yellow
    $AllAlgoPools = Get-Pools -PoolType "Algo" -Stats $Stats
    $AlgoPools = @()
    $AlgoPools_Comparison = @()
    $AllAlgoPools.Symbol | Select -Unique | ForEach {$AlgoPools += ($AllAlgoPools | Where Symbol -EQ $_ | Sort-Object Price -Descending | Select -First 3)}
    $AllAlgoPools.Symbol | Select -Unique | ForEach {$AlgoPools_Comparison += ($AllAlgoPools | Where Symbol -EQ $_ | Sort-Object StablePrice -Descending | Select -First 10)}

    $AlgoMiners = Get-Miners -Platforms $Platform -Stats $Stats -Pools $AlgoPools
    if($AlgoMiners.Count -eq 0){"No Miners!" | Out-Host; start-sleep $Interval; continue}
    
    start-minersorting -Command "Algo" -Stats $Stats -Pools $AlgoPools -Pools_Comparison $AlgoPools_Comparison -SortMiners $AlgoMiners -DBase $DecayBase -DExponent $DecayExponent -WattCalc $WattEx
    $ActiveMinerPrograms | ForEach {$AlgoMiners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit}}
    $GoodAlgoMiners = @()
    $AlgoMiners | Foreach {if($_.Profit -lt $Threshold -or $_.Profit -eq $null){$GoodAlgoMiners += $_}}
    $Miners = @()
    $GoodAlgoMiners | foreach {$Miners += $_}
    if($Platform -eq "windows"){$BestAlgoMiners_Combo = Get-BestWin -SortMiners $Miners}
    elseif($Platform -eq "linux"){$BestAlgoMiners_Combo = Get-BestUnix -SortMiners $Miners}
    $BestMiners_Combo = $BestAlgoMiners_Combo    

    $BestMiners_Selected = $BestMiners_Combo.Symbol
    $BestPool_Selected = $BestMiners_Combo.MinerPool 
    Write-Host "Most Ideal Choice Is $($BestMiners_Selected) on $($BestPool_Selected)" -foregroundcolor green          
    $ProfitTable = $null
    $ProfitTable = @()
    $Miners | foreach {
    $ProfitTable += [PSCustomObject]@{
     Power = [Decimal]$($_.Power*24)/1000*$WattEX
     Pool_Estimate = $_.Pool_Estimate
     Type = $_.Type
     Miner = $_.Name
     Name = $($_.Symbol)
     Arguments = $($_.Arguments)
     HashRates = $_.HashRates.$($_.Symbol)
     Profits = $_.Profit_Bias
     Algo = $_.Algo
     Fullname = $_.FullName
     MinerPool = $_.MinerPool
    }
   }

 $BestMiners_Combo | ForEach {
 if(-not ($ActiveMinerPrograms | Where Path -eq $_.Path | Where Arguments -eq $_.Arguments ))
  {
    Write-Host "Adding To $($_.MinerPool) to active programs"
    $ActiveMinerPrograms += [PSCustomObject]@{
        Name = $_.Name
        Type = $_.Type
        Devices = 0
        DeviceCall = $_.DeviceCall
        MinerName = $_.MinerName
        Path = $_.Path
        Arguments = $_.Arguments
        API = $_.API
        Port = $_.Port
        Coins = $_.Symbol
        Active = [TimeSpan]0
        Activated = 0
        Status = "Idle"
        HashRate = 0
        Benchmarked = 0
        WasBenchmarked = $false
        MinerPool = $_.MinerPool
        Algo = $_.Algo
        FullName = $_.FullName
        BestMiner = $false
        Quote = 0
        IsActive = $null
        StartDate = 0
       }
      }
     }

     $Restart = $false
     $NoMiners = $false

     $BestActiveMiners = @()
     $ActiveMinerPrograms | foreach {
     if($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments){$_.BestMiner = $true; $BestActiveMiners += $_}
     else{$_.BestMiner = $false}
     }

     function Get-MinerStatus {
        $Y = [string]$CoinExchange
        $H = [string]$Currency
        $J = [string]'BTC'
        $BTCExchangeRate = Invoke-WebRequest "https://min-api.cryptocompare.com/data/pricemulti?fsyms=$Y&tsyms=$J" -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty $Y | Select-Object -ExpandProperty $J
        $ProfitTable | Sort-Object -Property Type,Profits -Descending | Format-Table -GroupBy Type (
        @{Label = "Miner"; Expression={$($_.Miner)}},
        @{Label = "Coin"; Expression={$($_.Name)}},
        @{Label = "Speed"; Expression={$($_.HashRates) | ForEach {if($null -ne $_){"$($_ | ConvertTo-Hash)/s"}else{"Bench"}}}; Align='center'},
        @{Label = "Watt/Day"; Expression={$($_.Power) | ForEach {if($null -ne $_){($_ * $Rates.$Currency).ToString("N2")}else{"Bench"}}}; Align='center'},
        @{Label = "BTC/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){  $_.ToString("N5")}else{"Bench"}}}; Align='right'},
        @{Label = "$Y/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){  ($_ / $BTCExchangeRate).ToString("N5")}else{"Bench"}}}; Align='right'},
        @{Label = "$Currency/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){($_ * $Rates.$Currency).ToString("N2")}else{"Bench"}}}; Align='center'},
        @{Label = "   Pool"; Expression={$($_.MinerPool)}; Align='center'}
            )
      }
      
      Clear-Content ".\build\bash\minerstats.sh" -Force
      $type | foreach {if(Test-Path ".\build\txt\$($_)-hash.txt"){Clear-Content ".\build\txt\$($_)-hash.txt" -Force}}
      $GetStatusAlgoBans = ".\timeout\algo_block\algo_block.txt"
      $GetStatusPoolBans = ".\timeout\pool_block\pool_block.txt"
      $GetStatusMinerBans = ".\timeout\miner_block\miner_block.txt"
      if(Test-Path $GetStatusAlgoBans){$StatusAlgoBans = Get-Content $GetStatusAlgoBans | ConvertFrom-Json}
      else{$StatusAlgoBans = $null}
      if(Test-Path $GetStatusPoolBans){$StatusPoolBans = Get-Content $GetStatusPoolBans | ConvertFrom-Json}
      else{$StatusPoolBans = $null}
      if(Test-Path $GetStatusMinerBans){$StatusMinerBans = Get-Content $GetStatusMinerBans | ConvertFrom-Json}
      else{$StatusMinerBans = $null}
      $StatusDate = Get-Date
      $StatusDate | Out-File ".\build\bash\mineractive.sh"
      $StatusDate | Out-File ".\build\bash\minerstats.sh"
      Get-MinerStatus | Out-File ".\build\bash\minerstats.sh" -Append
      $mcolor = "93"
      $me = [char]27
      $MiningStatus = "$me[${mcolor}mCurrently Mining $($BestMiners_Combo.Algo) Algorithm${me}[0m"
      $MiningStatus | Out-File ".\build\bash\minerstats.sh" -Append
      $BanMessage = @()
      $mcolor = "91"
      $me = [char]27
      if($StatusAlgoBans){$StatusAlgoBans | foreach {$BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from all pools${me}[0m"}}
      if($StatusPoolBans){$StatusPoolBans | foreach {$BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from $($_.MinerPool)${me}[0m"}}
      if($StatusMinerBans){$StatusMinerBans | foreach {$BanMessage += "$me[${mcolor}m$($_.Name) is banned${me}[0m"}}
      $BanMessage | Out-File ".\build\bash\minerstats.sh" -Append

    $ActiveMinerPrograms | ForEach {
        if($_.BestMiner -eq $false)
         {
          if($_.IsActive -eq $true)
            {
             $_.Active += (Get-Date)-$_.StartDate
             $_.Status = "Idle"
             $_.IsActive = $false
            }
         }
      else
       {
        if($_.IsActive -eq $false -or $_.IsActive -eq $null)
         {
         $_.Activated++
         $Restart = $true
         $IPs = @()
         $Slaves | foreach {if($_ -ne $null){$IPs += $_}}
         $PoolConfig = $_
         $Master | foreach {
          Write-Host "Checking For Old Pools at $($_)"; 
          $WorkingPool = Remove-Pools -IPAddress "$($_)" -PoolPort $PoolConfig.Port -PoolTimeout 10
          Start-Sleep -S .1
          $addpool = "addpool|$($PoolConfig.Arguments)"
          $switchpool = "switchpool|$WorkingPool"
          Write-Host "Switching Pool For $($_)"
          $response1 = Get-TCP -Server "$($_)" -Port $PoolConfig.Port -Message $addpool -Timeout $timeout
          Start-Sleep -S .1
          $response2 = Get-TCP -Server "$($_)" -Port $PoolConfig.Port -Message $switchpool -Timeout $timeout
         }
        if($IPs)
        {
         $IPs | foreach {
          Write-Host "Checking For Old Pools at $($_)"; 
          $WorkingPool = Remove-Pools -IPAddress "$($_)" -PoolPort $PoolConfig.Port -PoolTimeout 10
          Start-Sleep -S .1
          $addpool = "addpool|$($PoolConfig.Arguments)"
          $switchpool = "switchpool|$WorkingPool"
          Write-Host "Switching Pool For $($_)"
          $response1 = Get-TCP -Server "$($_)" -Port $PoolConfig.Port -Message $addpool -Timeout $timeout
          Start-Sleep -S .1
          $response2 = Get-TCP -Server "$($_)" -Port $PoolConfig.Port -Message $switchpool -Timeout $timeout
         }
        }
         $_.StartDate = Get-Date
          if($response2)
          {
           $_.ISActive = $true
           $_.Status = "Running"
           $NoMiners = $false
           Write-Host "Switch was successful" -ForegroundColor Green
          }
          else
          {
           $_.ISActive = $false
           $NoMiners = $true
           $_.Status = "Failed"
           Write-Host "Switch Failed- Check Arguments" -ForegroundColor Red
          }
        }
      }
    }

   $MinerWatch.Restart()

    if($Platform -eq "linux" -and $Restart -eq $true -and $NoMiners -eq $false)
    {
      Write-Host "         
           
                                //\\  _______
                               //  \\//~//.--|
                               Y   /\\~~//_  |
                              _L  |_((_|___L_|
                             (/\)(____(_______)      
   Waiting 20 Seconds For Miners To Load & Restarting Background Tracking
   
   Type 'mine' in another terminal to see miner working- This is NOT a remote command!
   
   Type 'get-screen [MinerType]' to see last 100 lines of log- This IS a remote command!
   
   https://github.com/MaynardMiner/SWARM/wiki/HiveOS-management >> Right Click 'Open URL In Browser'  
   
      " -foreground Magenta
      Start-Sleep -s 20
    }
   if($Platform -eq "windows" -and $Restart -eq $true -and $NoMiners -eq $false)
    {
      Write-Host "         
            
                                 //\\  _______
                                //  \\//~//.--|
                                Y   /\\~~//_  |
                               _L  |_((_|___L_|
                              (/\)(____(_______)      
    Waiting 20 Seconds For Miners To Load & Restarting Background Tracking"
    Start-Sleep -s 20
   }

if($Restart -eq $false)
 {
  Write-Host "
        
        
  Most Profitable Miners Are Running


  " -foreground DarkCyan
  Start-Sleep -s 5
 }

 function Get-MinerActive {

  $ActiveMinerPrograms | Sort-Object -Descending Status,
  {if($null -eq $_.IsActive){[DateTime]0}else{$_.StartDate}
  } | Select -First (1+6+6) | Format-Table -Wrap -GroupBy Status (
  @{Label = "Speed"; Expression={$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align='right'},
  @{Label = "Active"; Expression={"{0:dd} Days {0:hh} Hours {0:mm} Minutes" -f $(if($null -eq $_.IsActive){$_.Active}else{if($_.IsActive -eq $false){($_.Active)}else{($_.Active+((Get-Date)-$_.StartDate))}})}},
  @{Label = "Launched"; Expression={Switch($_.Activated){0 {"Never"} 1 {"Once"} Default {"$_ Times"}}}},
  @{Label = "Command"; Expression={"$($_.MinerName) $($_.Devices) $($_.Arguments)"}}
)
}
function Get-Logo {
       Write-Host '
                                                                           (                    (      *     
                                                                            )\ ) (  (      (     )\ ) (  `    
                                                                            (()/( )\))(     )\   (()/( )\))(   
                                                                             /(_)|(_)()\ |(((_)(  /(_)|(_)()\  
                                                                            (_)) _(())\_)()\ _ )\(_)) (_()((_) 
                                                                            / __|\ \((_)/ (_)_\(_) _ \|  \/  | 
                                                                            \__ \ \ \/\/ / / _ \ |   /| |\/| | 
                                                                            |___/  \_/\_/ /_/ \_\|_|_\|_|  |_| 
                                                                                                                                                     ' -foregroundcolor "DarkRed"
        Write-Host "                                                                                     sudo apt-get lambo" -foregroundcolor "Yellow"
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
}


#Check For Bechmark
$BenchmarkMode = $false
$ActiveMinerPrograms | Foreach {
 if($Miners | Where Path -eq $_.Path | Where Arguments -eq $_.Arguments)
 {
  if(-not (Test-Path ".\stats\$($_.Name)_$($_.Algo)_hashrate.txt"))
  {
   $BenchmarkMode = $true
  }
 }
}

#Set Interval
if($BenchmarkMode -eq $true)
{
$MinerInterval = $Benchmark
$Message = 
"SWARM is now benchmarking miners. It will only be able to 
properly calculate stats once miners finish benchmarking.

Note: Only one miner per algorithm and platform will show on stats 
screen. While benchmarking, miner will choose a miner that needs to be
benched, leaving previously benchmarked miners to vanish from stats 
screen. They will return if benchmarks were higher than current miner.

This is normal behavior.

To see all miner benchmarks that have been performed use:
get benchmarks
command"
$Message | Out-File ".\build\bash\minerstats.sh" -Append
}
else{$MinerInterval = $Interval}

#Clear Logs If There Are 12
if($Log -eq 12)
 {
  Remove-Item ".\logs\*miner*" -Force
  $Log = 0
}

#Start Another Log If An Hour Has Passed
if($LogTimer.Elapsed.TotalSeconds -ge 3600)
 {
  Stop-Transcript
  if(Test-Path ".\logs\*active*")
  {
   Set-Location ".\logs"
   $OldActiveFile = Get-ChildItem "*active*"
   $OldActiveFile | Foreach {
    $RenameActive = $_ -replace ("-active","")
    if(Test-Path $RenameActive){Remove-Item $RenameActive -Force}
    Rename-Item $_ -NewName $RenameActive -force
    }
   Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
  }
  $Log++
  Start-Transcript ".\logs\miner$($Log)-active.log"
  $LogTimer.Restart()
 }

##Write Details Of Active Miner And Stats To File
Get-MinerActive | Out-File ".\build\bash\mineractive.sh" -Append

#if($Favor_Coins -eq "Yes")
 #{
  #if($BenchmarkMode -eq $false)
   #{
#$Crazy = "Favor Coins Was Specified. Algorithms may be removed from this list so that highest value coin is at the top. See github wik FAQ section as to why."
#$CrazyLink = "https://github.com/MaynardMiner/Swarm/wiki/FAQ >> Right Click 'Open URL In Browser"
#$Crazy | Out-File ".\build\bash\minerstats.sh" -Append
#$CrazyLink | Out-File ".\build\bash\minerstats.sh" -Append
   #}
  #}

  function Get-MinerHashRate {
    $BestActiveMiners | Foreach {
     $Miner_HashRates = Get-HashRate -Type $_.Type -API $_.API -Port $_.Port
     $GetDayStat = Get-Stat "$($_.Name)_$($_.Algo)_HashRate"
     $DayStat = "$($GetDayStat.Day)"
     $MinerPrevious = "$($DayStat | ConvertTo-Hash)"
     $ScreenHash = "$($Miner_HashRates | ConvertTo-Hash)"
     Write-Host "[$(Get-Date)]:" -foreground yellow -nonewline
     Write-Host " $($_.Type) is currently Running: " -ForegroundColor green -nonewline
     $MinerStatus
     Write-Host "$($_.Name) current hashrate for $($_.Coins) is" -nonewline
     Write-Host " $ScreenHash/s" -foreground green
     Write-Host "$($_.Type) is currently mining on $($_.MinerPool)" -foregroundcolor Cyan
     Start-Sleep -S 2
     Write-Host "$($_.Type) previous hashrates for $($_.Coins) is" -nonewline
     Write-Host " $MinerPrevious/s" -foreground yellow
   }
  }
  
  function Set-Countdown {
    $Countdown = ([math]::Round(($MinerInterval-20) - $MinerWatch.Elapsed.TotalSeconds))
    $CountMessage = "Time Left Until Database Starts: $($Countdown)"
    Write-Host $CountMessage -foreground Gray
    }
    
    function Restart-Database {
    $Restart = "No"
    $BestActiveMiners | foreach {
    if($null -eq $_.XProcess -or $_.XProcess.HasExited)
    {
     $_.Status = "Failed"
     $Restart = "Yes"
    }
    else
    {
     $Miner_HashRates = Get-HashRate -Type $_.Type
     $ScreenHash = "$($Miner_HashRates | ConvertTo-Hash)"
     if($ScreenHash -eq "0.00PH" -or $ScreenHash -eq '')
     {
     if($BenchmarkMode -eq $false)
      {
       $_.Status = "Failed"
       $Restart = "Yes"
        }
       }
      }
     }
    $Restart
    }
    
    Get-Job -State Completed | Remove-Job
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
    
    function Get-VM {
      ps powershell* | Select *memory* | ft -auto `
      @{Name='Virtual Memory Size (MB)';Expression={($_.VirtualMemorySize64)/1MB}; Align='center'}, `
      @{Name='Private Memory Size (MB)';Expression={(  $_.PrivateMemorySize64)/1MB}; Align='center'},
      @{Name='Memory Used This Session (MB)';Expression={([System.gc]::gettotalmemory("forcefullcollection") /1MB)}; Align='center'}
     }
    
    ##Miner Loop Linux
    if($Platform -eq "linux")
    {
    Do{
      Set-Countdown
      Get-MinerHashRate
      Start-Sleep -s 15
      if($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval-20)){break}
      Set-Countdown
      Get-MinerHashRate
      Start-Sleep -s 15
      if($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval-20)){break}
      Set-Countdown
      Write-Host "
    
          Type 'stats' in another terminal to view miner statistics- This IS a remote command!
          https://github.com/MaynardMiner/Swarm/wiki/HiveOS-management >> Right Click 'Open URL In Browser'
    
      " -foreground Magenta
      Get-MinerHashRate
      Start-Sleep -s 15
      if($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval-20)){break}
      Set-Countdown
      Get-MinerHashRate
      Start-Sleep -s 15
      if($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval-20)){break}
      Set-Countdown
      Get-MinerHashRate
      Start-Sleep -s 15
      if($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval-20)){break}
      Set-Countdown
      Write-Host "
    
          Type 'active' in another terminal to view active/previous miners- this IS a remote command!
          https://github.com/MaynardMiner/Swarm/wiki/HiveOS-management >> Right Click 'Open URL In Browser'
    
      " -foreground Magenta
      Get-MinerHashRate
      Start-Sleep -s 15
      if($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval-20)){break}    
    }While($MinerWatch.Elapsed.TotalSeconds -lt ($MinerInterval-20))
    }
    else
    {
      Clear-Host
      Get-MinerActive | Out-Host
      Get-MinerStatus | Out-Host
      Get-VM | Out-Host
    Do{
       if($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval-20)){break}
       Start-Sleep -s 30
    }While($MinerWatch.Elapsed.TotalSeconds -lt ($MinerInterval-20))
   }

   $BestActiveMiners | foreach {
    $MinerPoolBan = $false
    $MinerAlgoBan = $false
    $MinerBan = $false
    $Strike = $false
    if($_.BestMiner -eq $true)
    {
      if($TimeDeviation -ne 0)
      {
       $_.HashRate = 0
       $_.WasBenchmarked = $False
       $Miner_HashRates = Get-HashRate -Type $_.Type -API $_.API -Port $_.Port
       $_.HashRate = $Miner_HashRates
       $WasActive = [math]::Round(((Get-Date)-$_.StartDate).TotalSeconds)
       if($WasActive -ge $StatsInterval)
       {
        Write-Host "$($_.Name) $($_.Coins) Was Active for $WasActive Seconds"
        Write-Host "Attempting to record hashrate for $($_.Name) $($_.Coins)" -foregroundcolor "Cyan"
        for($i=0; $i -lt 4; $i++)
        {
         if($_.WasBenchmarked -eq $False)
          {
           $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($_.Algo)_hashrate.txt"
           $NewHashrateFilePath = Join-Path ".\backup" "$($_.Name)_$($_.Algo)_hashrate.txt"
           if(-not (Test-Path "backup")){New-Item "backup" -ItemType "directory" | Out-Null}
           Write-Host "$($_.Name) $($_.Coins) Starting Bench"
           if($null -eq $Miner_HashRates -or $Miner_HashRates -eq 0)
           {
            $Strike = $true
            Write-Host "Stat Attempt Yielded 0" -Foregroundcolor Red
            Start-Sleep -S .25
           }
           else
           {
             $Stat = Set-Stat -Name "$($_.Name)_$($_.Algo)_hashrate" -Value $Miner_HashRates
             Start-Sleep -s 1
             $GetLiveStat = Get-Stat "$($_.Name)_$($_.Algo)_hashrate"
             $StatCheck = "$($GetLiveStat.Live)"
             $ScreenCheck = "$($StatCheck | ConvertTo-Hash)"
             if($ScreenCheck -eq "0.00 PH" -or $null -eq $StatCheck)
              {
              $Strike = $true
              $_.WasBenchmarked = $False
              Write-Host "Stat Failed Write To File" -Foregroundcolor Red
             }
            else
             {
              Write-Host "Recorded Hashrate For $($_.Name) $($_.Coins) Is $($ScreenCheck)" -foregroundcolor "magenta"
              if(-not (Test-Path $NewHashrateFilePath))
               {
                Copy-Item $HashrateFilePath -Destination $NewHashrateFilePath -force
                Write-Host "$($_.Name) $($_.Coins) Was Benchmarked And Backed Up" -foregroundcolor yellow
               }
              $_.WasBenchmarked = $True
              Write-Host "Stat Written" -foregroundcolor green
              $Strike = $false
             } 
            }
           }
          }
         }
        }

     if($Strike -ne $true)
     {
      if($Warnings."$($_.Name)" -ne $null){$Warnings."$($_.Name)" | foreach{try{$_.bad=0}catch{}}}
      if($Warnings."$($_.Name)_$($_.Algo)" -ne $null){$Warnings."$($_.Name)_$($_.Algo)" | foreach{try{$_.bad=0}catch{}}}
      if($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" -ne $null){$Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach{try{$_.bad=0}catch{}}}
     }
        
   
   if($Strike -eq $true)
    {
     if($_.WasBenchmarked -eq $False)
      {
       if (-not (Test-Path ".\timeout")) {New-Item "timeout" -ItemType "directory" | Out-Null}
       if (-not (Test-Path ".\timeout\pool_block")) {New-Item -Path ".\timeout" -Name "pool_block" -ItemType "directory" | Out-Null}
       if (-not (Test-Path ".\timeout\algo_block")) {New-Item -Path ".\timeout" -Name "algo_block" -ItemType "directory" | Out-Null}
       if (-not (Test-Path ".\timeout\miner_block")) {New-Item -Path ".\timeout" -Name "miner_block" -ItemType "directory" | Out-Null}
       if (-not (Test-Path ".\timeout\warnings")) {New-Item -Path ".\timeout" -Name "warnings" -ItemType "directory" | Out-Null}
       Start-Sleep -S .25
       $TimeoutFile = Join-Path ".\timeout\warnings" "$($_.Name)_$($_.Algo)_TIMEOUT.txt"
       $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($_.Algo)_hashrate.txt"
       if(-not (Test-Path $TimeoutFile)){"$($_.Name) $($_.Coins) Hashrate Check Timed Out" | Set-Content ".\timeout\warnings\$($_.Name)_$($_.Algo)_TIMEOUT.txt" -Force}
       if($Warnings."$($_.Name)" -eq $null){$Warnings += [PSCustomObject]@{"$($_.Name)" = [PSCustomObject]@{bad = 0}}}
       if($Warnings."$($_.Name)_$($_.Algo)" -eq $null){$Warnings += [PSCustomObject]@{"$($_.Name)_$($_.Algo)" = [PSCustomObject]@{bad = 0}}}
       if($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" -eq $null){$Warnings += [PSCustomObject]@{"$($_.Name)_$($_.Algo)_$($_.MinerPool)" = [PSCustomObject]@{bad = 0}}}
       $Warnings."$($_.Name)" | foreach{try{$_.bad++}catch{}}
       $Warnings."$($_.Name)_$($_.Algo)" | foreach{try{$_.bad++}catch{}}
       $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach{try{$_.bad++}catch{}}
       if($Warnings."$($_.Name)".bad -ge $MinerBanCount){$MinerBan = $true}
       if($Warnings."$($_.Name)_$($_.Algo)".bad -ge $AlgoBanCount){$MinerAlgoBan = $true}
       if($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)".bad -ge $PoolBanCount){$MinerPoolBan = $true}
       ##Strike One
       if($MinerPoolBan -eq $false -and $MinerAlgoBan -eq $false -and $MinerBan -eq $false)
       {
        Write-Host "First Strike: There was issue with benchmarking." -ForegroundColor DarkRed
       }
       ##Strike Two
       if($MinerPoolBan -eq $true)
       {
        Write-Host "Strike Two: Benchmarking Has Failed - Prohibiting miner from pool" -ForegroundColor DarkRed
        $NewPoolBlock = @()
        if(Test-Path ".\timeout\pool_block\pool_block.txt"){$GetPoolBlock = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json}
        Start-Sleep -S 1
        if($GetPoolBlock){$GetPoolBlock | foreach{$NewPoolBlock += $_}}
        $NewPoolBlock += $_
        $NewPoolBlock | ConvertTo-Json | Set-Content ".\timeout\pool_block\pool_block.txt"
        $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach{try{$_.bad=0}catch{}}
       }
       ##Strike Three: He's Outta Here
        if($MinerAlgoBan -eq $true)
        {
         Write-Host "Strike three: $($_.Algo) is now banned on $($_.Name)" -ForegroundColor DarkRed
         $NewAlgoBlock = @()
         if(test-path $HashRateFilePath){remove-item $HashRateFilePath -Force}
         if(Test-Path ".\timeout\algo_block\algo_block.txt"){$GetAlgoBlock = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json}
         Start-Sleep -S 1
         if($GetAlgoBlock){$GetAlgoBlock | foreach{$NewAlgoBlock += $_}}
         $NewAlgoBlock += $_
         $NewAlgoBlock | ConvertTo-Json | Set-Content ".\timeout\algo_block\algo_block.txt"
         $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach{try{$_.bad=0}catch{}}
         $Warnings."$($_.Name)_$($_.Algo)" | foreach{try{$_.bad=0}catch{}}
         Start-Sleep -S 1
        }
       ##Strike Four: Miner is Finished
       if($MinerBan -eq $true)
       {
        Write-Host "This miner sucks, shutting it down." -ForegroundColor DarkRed
        $NewMinerBlock = @()
        if(test-path $HashRateFilePath){remove-item $HashRateFilePath -Force}
        if(Test-Path ".\timeout\miner_block\miner_block.txt"){$GetMinerBlock = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json}
        Start-Sleep -S 1
        if($GetMinerBlock){$GetMinerBlock | foreach{$NewMinerBlock += $_}}
        $NewMinerBlock += $_
        $NewMinerBlock | ConvertTo-Json | Set-Content ".\timeout\miner_block\miner_block.txt"
        $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach{try{$_.bad=0}catch{}}
        $Warnings."$($_.Name)_$($_.Algo)" | foreach{try{$_.bad=0}catch{}}
        $Warnings."$($_.Name)" | foreach{try{$_.bad=0}catch{}}
        Start-Sleep -S 1
        }
        }
       }
      }
     }
    }
   }