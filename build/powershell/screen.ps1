
function Get-MinerStatus {
    $ProfitTable | Sort-Object -Property Type,Profits -Descending | Format-Table -GroupBy Type (
    @{Label = "Miner"; Expression={$($_.Miner)}},
    @{Label = "Coin"; Expression={$($_.Name)}},
    @{Label = "Speed"; Expression={$($_.HashRates) | ForEach {if($null -ne $_){"$($_ | ConvertTo-Hash)/s"}else{"Bench"}}}; Align='center'},
    @{Label = "Watt/Day"; Expression={$($_.Power) | ForEach {if($null -ne $_){($_ * $Rates.$Currency).ToString("N2")}else{"Bench"}}}; Align='center'},
    @{Label = "BTC/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){  $_.ToString("N5")}else{"Bench"}}}; Align='right'},
    @{Label = "$Y/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){  ($_ / $BTCExchangeRate).ToString("N5")}else{"Bench"}}}; Align='right'},
    @{Label = "$Currency/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){($_ * $Rates.$Currency).ToString("N2")}else{"Bench"}}}; Align='center'},
    @{Label = "Pool"; Expression={$($_.MinerPool)}; Align='Right'}
        )
  }

  function Get-StatusLite {
    $ProfitTable | Sort-Object -Property Type,Profits -Descending | Format-Table -GroupBy Type (
      @{Label = "Miner"; Expression={$($_.Miner)}},
      @{Label = "Speed"; Expression={$($_.HashRates) | ForEach {if($null -ne $_){"$($_ | ConvertTo-Hash)/s"}else{"Bench"}}}; Align='center'},
      @{Label = "$Currency/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){($_ * $Rates.$Currency).ToString("N2")}else{"Bench"}}}; Align='center'},
      @{Label = "Pool"; Expression={$($_.MinerPool)}; Align='Right'}
       )
    }

function Invoke-MinerWarning{
##Notify User Of Failures
Write-Host "
       
       
       
There are miners that have failed! Check Your Settings And Arguments!
Type `'mine`' in another terminal to see background miner, and its reason for failure.
If miner is not your primary miner (AMD1 or NVIDIA1), type 'screen -r [Type]'
https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration) >> Right Click 'Open URL In Browser'


" -foreground Darkred
Start-Sleep -s 20
}

function Invoke-MinerSuccess1{
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

function Invoke-MinerSuccess2{
Write-Host "         
         
                        //\\  _______
                       //  \\//~//.--|
                       Y   /\\~~//_  |
                      _L  |_((_|___L_|
                     (/\)(____(_______)      
Waiting 20 Seconds For Miners To Load & Restarting Background Tracking"
Start-Sleep -s 20
}

function Invoke-NoChange{
Write-Host "
        
        
Most Profitable Miners Are Running


" -foreground DarkCyan
Start-Sleep -s 5
}

function Print-Benchmarking{
    $MinerInterval = $Benchmark
$Message = 
"

SWARM is now benchmarking miners. It will only be able to 
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


function Get-MinerActive {

    $ActiveMinerPrograms | Sort-Object -Descending Status,
    {if($null -eq $_.XProcess){[DateTime]0}else{$_.XProcess.StartTime}
    } | Select -First (1+6+6) | Format-Table -Wrap -GroupBy Status (
    @{Label = "Speed"; Expression={$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align='right'},
    @{Label = "Active"; Expression={"{0:dd} Days {0:hh} Hours {0:mm} Minutes" -f $(if($null -eq $_.XProcess){$_.Active}else{if($_.XProcess.HasExited){($_.Active)}else{($_.Active+((Get-Date)-$_.XProcess.StartTime))}})}},
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
     Write-Host "                                                                                  sudo apt-get lambo" -foregroundcolor "Yellow"
     Write-Host ""
     Write-Host ""
     Write-Host ""
     Write-Host ""
}

function Restart-Miner {
    $BestActiveMiners | Foreach {
    $Restart = $false
    if($_.XProcess -eq $null -or $_.XProcess.HasExited -and $Lite -eq "No")
     {
       if($TimeDeviation -ne 0)
       {
        $Restart = $true
        $BackgroundDone = "Yes"
        $_.Activated++
        $_.InstanceName = "$($_.Type)-$($Instance)"
        $Current = $_ | ConvertTo-Json -Compress
        $_.Xprocess = Start-LaunchCode -Platforms $Platform -MinerRound $Current_BestMiners -NewMiner $Current -Background $BackgroundDone
        $_.Instance = ".\build\pid\$($_.Type)-$($Instance)"
        $PIDFile = "$($_.Name)_$($_.Coins)_$($_.InstanceName)_pid.txt"
        $Instance++
       }
      
      if($Restart -eq $true)
      {
       if($null -eq $_.XProcess -or $_.XProcess.HasExited)
       {
       $_.Status = "Failed"
       $NoMiners = $true
       Write-Host "$($_.MinerName) Failed To Launch" -ForegroundColor Darkred
       }
       else
       {
       $_.Status = "Running"
       Write-Host "$($_.MinerName) Is Running!" -ForegroundColor Green
       }
      Write-Host "
           
                 //\\  _______
                //  \\//~//.--|
                Y   /\\~~//_  |
               _L  |_((_|___L_|
              (/\)(____(_______)        
           
     Waiting 20 Seconds For Miners To Fully Load
   
      " 
      Start-Sleep -s 20
       }
      }
     }
    }

    function Get-MinerHashRate {
        $BestActiveMiners | Foreach {
         if($null -eq $_.Xprocess -or $_.XProcess.HasExited){$_.Status = "Failed"}
         $Miner_HashRates = Get-HashRate -Type $_.Type
           $GetDayStat = Get-Stat "$($_.Name)_$($_.Algo)_HashRate"
         $DayStat = "$($GetDayStat.Day)"
         $MinerPrevious = "$($DayStat | ConvertTo-Hash)"
           $ScreenHash = "$($Miner_HashRates | ConvertTo-Hash)"
         Write-Host "[$(Get-Date)]:" -foreground yellow -nonewline
         Write-Host " $($_.Type) is currently" -foreground green -nonewline
         if($_.Status -eq "Running"){$MinerStatus = Write-Host " Running: " -ForegroundColor green -nonewline}
         if($_.Status -eq "Failed"){$MinerStatus = Write-Host " Not Running: " -ForegroundColor darkred -nonewline} 
         $MinerStatus
           Write-Host "$($_.Name) current hashrate for $($_.Coins) is" -nonewline
           Write-Host " $ScreenHash/s" -foreground green
         Write-Host "$($_.Type) is currently mining on $($_.MinerPool)" -foregroundcolor Cyan
           Write-Host "$($_.Type) previous hashrates for $($_.Coins) is" -nonewline
           Write-Host " $MinerPrevious/s
 " -foreground yellow
       }
      }

      function Set-Countdown {
        if($SWARM_Mode -eq "Yes" -and $BenchmarkMode -eq $false){$CountDown = Invoke-SWARMMode $SwitchTime; $CountDown = $Countdown*-1}
        else{$Countdown = ([math]::Round(($MinerInterval-20) - $MinerWatch.Elapsed.TotalSeconds))}
        if($SWARM_Mode -eq "Yes" -and $BenchmarkMode -eq $false){$CountMessage = "SWARM Mode Starts: $($Countdown) seconds"}
        else{$CountMessage = "Time Left Until Database Starts: $($Countdown) seconds"}
        Write-Host "$CountMessage 
"-foreground DarkMagenta
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

            function Get-VM {
                ps powershell* | Select *memory* | ft -auto `
                @{Name='Virtual Memory Size (MB)';Expression={($_.VirtualMemorySize64)/1MB}; Align='center'}, `
                @{Name='Private Memory Size (MB)';Expression={(  $_.PrivateMemorySize64)/1MB}; Align='center'},
                @{Name='Memory Used This Session (MB)';Expression={([System.gc]::gettotalmemory("forcefullcollection") /1MB)}; Align='center'}
               }

function Print-WattOMeter{
  Write-Host "

  Starting Watt-O-Meter
       __________
      |   ____   |
      |  /    \  |
      | | .''. | |
      | |   /  | |
      |==========|
      |   WATT   |
      |__________|
    
  " -foregroundcolor yellow
}