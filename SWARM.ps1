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
    [String]$Wallet = "Yes",  ##Miner Can Load Pools
    [Parameter(Mandatory=$false)]
    [String]$Wallet1 = '',  ##Group 1 Wallet
    [Parameter(Mandatory=$false)]
    [String]$Wallet2 = '', ##Group 2 Wallet
    [Parameter(Mandatory=$false)]
    [String]$Wallet3 = '', ##Group 3 Wallet
    [Parameter(Mandatory=$false)]
    [String]$CPUWallet = '', ##CPU Wallet
    [Parameter(Mandatory=$false)]
    [String]$ZergpoolWallet1 = '', ##Group 1 Zergpool Wallet
    [Parameter(Mandatory=$false)]
    [String]$ZergpoolWallet2 = '', ##Group 2 Zergpool Wallet
    [Parameter(Mandatory=$false)]
    [String]$ZergpoolWallet3 = '', ##Group 3 Zergpool Wallet
    [Parameter(Mandatory=$false)]
    [String]$blockmastersWallet1 = '',  ##Group 1 BlockMasters Wallet
    [Parameter(Mandatory=$false)]
    [String]$blockmastersWallet2 = '',  ##Group 2 BlockMasters Wallet
    [Parameter(Mandatory=$false)]
    [String]$blockmastersWallet3 = '',  ##Group 3 BlockMasters Wallet
    [Parameter(Mandatory=$false)]
    [String]$Nicehash_Wallet1 = '',  ##Group 1 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$Nicehash_Wallet2 = '',  ##Group 2 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$Nicehash_Wallet3 = '',  ##Group 3 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$UserName = "MaynardVII", ##MPH Username
    [Parameter(Mandatory=$false)]
    [String]$WorkerName = "Rig1",  ##MPH Workername
    [Parameter(Mandatory=$false)]
    [String]$RigName1 = "MMHash",  ##ID=Rigname (Yiimp Pool) Group 1
    [Parameter(Mandatory=$false)]
    [String]$RigName2 = "MMHash",  ##ID=Rigname (Yiimp Pool) Group 2
    [Parameter(Mandatory=$false)]
    [String]$RigName3 = "MMHash", ##ID=Rigname (Yiimp Pool) Group 3
    [Parameter(Mandatory=$false)]
    [Int]$API_ID = 0, ##Future Implentation
    [Parameter(Mandatory=$false)]
    [String]$API_Key = "", ##Future Implementation
    [Parameter(Mandatory=$false)]
    [Int]$Timeout = 0,  ##Hours Before Mine Clears All Hashrates/Profit 0 files
    [Parameter(Mandatory=$false)]
    [Int]$Interval = 180, #seconds before reading hash rate from miners
    [Parameter(Mandatory=$false)] 
    [Int]$StatsInterval = 1, #seconds of current active to gather hashrate if not gathered yet 
    [Parameter(Mandatory=$false)]
    [String]$Location = "US", #europe/us/asia
    [Parameter(Mandatory=$false)]
    [String]$MPHLocation = "US", #europe/us/asia 
    [Parameter(Mandatory=$false)]
    [Array]$Type = ("NVIDIA1"), #AMD/NVIDIA/CPU
    [Parameter(Mandatory=$false)]
    [String]$CCDevices1, ##Group 1 ccminer gpus
    [Parameter(Mandatory=$false)] 
    [String]$CCDevices2,  ##Group 2 ccminer gpus
    [Parameter(Mandatory=$false)]
    [String]$CCDevices3,  ##Group 3 ccminer gpus
    [Parameter(Mandatory=$false)]
    [String]$EWBFDevices1, ##Group 1 ewbf
    [Parameter(Mandatory=$false)] 
    [String]$EWBFDevices2, ##Group 2 ewbf
    [Parameter(Mandatory=$false)]
    [String]$EWBFDevices3, ##Group 3 ewbf
    [Parameter(Mandatory=$false)]
    [String]$GPUDevices1, ##Group 1 all miners
    [Parameter(Mandatory=$false)] 
    [String]$GPUDevices2, ##Group 2 all miners
    [Parameter(Mandatory=$false)]
    [String]$GPUDevices3, ##Group 3 all miners
    [Parameter(Mandatory=$false)]
    [String]$DSTMDevices1, 
    [Parameter(Mandatory=$false)] 
    [String]$DSTMDevices2,
    [Parameter(Mandatory=$false)]
    [String]$DSTMDevices3,
    [Parameter(Mandatory=$false)]
    [String]$ClayDevices1,
    [Parameter(Mandatory=$false)]
    [String]$ClayDevices2,
    [Parameter(Mandatory=$false)]
    [String]$ClayDevices3,
    [Parameter(Mandatory=$false)]
    [String]$RexDevices1,
    [Parameter(Mandatory=$false)]
    [String]$RexDevices2,
    [Parameter(Mandatory=$false)]
    [String]$RexDevices3,
    [Parameter(Mandatory=$false)]
    [String]$SGDevices1,
    [Parameter(Mandatory=$false)]
    [String]$SGDevices2,
    [Parameter(Mandatory=$false)]
    [String]$SGDevices3,
    [Parameter(Mandatory=$false)]
    [Array]$PoolName = ("zergpool_algo","zergpool_coin"), 
    [Parameter(Mandatory=$false)]
    [Array]$Currency = ("USD"), #i.e. GBP,EUR,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [Array]$Passwordcurrency = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [Array]$Passwordcurrency1 = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [Array]$Passwordcurrency2 = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [Array]$Passwordcurrency3 = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [Array]$CPUcurrency = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$Zergpoolpassword1 = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$Zergpoolpassword2 =  '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$Zergpoolpassword3 = '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$blockmasterspassword1 = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$blockmasterspassword2 =  '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$blockmasterspassword3 = '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [Int]$Donate = .5, #Percent per Day
    [Parameter(Mandatory=$false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080 
    [Parameter(Mandatory=$false)]
    [Int]$Delay = 1, #seconds before opening each miner
    [Parameter(Mandatory=$false)]
    [String]$CoinExchange = "LTC",
    [Parameter(Mandatory=$false)]
    [array]$Coin= $null,
    [Parameter(Mandatory=$false)]
    [array]$GPU_Group1= $null,
    [Parameter(Mandatory=$false)]
    [array]$GPU_Group2= $null,
    [Parameter(Mandatory=$false)]
    [array]$GPU_Group3= $null,
    [Parameter(Mandatory=$false)]
    [string]$Auto_Coin = "Yes",
    [Parameter(Mandatory=$false)]
    [string]$Auto_Algo = "Yes",
    [Parameter(Mandatory=$false)]
    [Int]$Nicehash_Fee,
    [Parameter(Mandatory=$false)]
    [Int]$Benchmark = 300,
    [Parameter(Mandatory=$false)]
    [Int]$GPU_Count = 13,
    [Parameter(Mandatory=$false)]
    [array]$No_Algo = $null,
    [Parameter(Mandatory=$false)]
    [String]$Favor_Coins = "Yes",
    [Parameter(Mandatory=$false)]
    [double]$Threshold = .01,
    [Parameter(Mandatory=$false)]
    [string]$Platform = "linux",
    [Parameter(Mandatory=$false)]
    [int]$CPUThreads = $null,
    [Parameter(Mandatory=$false)]
    [string]$StatLevel = "Live",
    [Parameter(Mandatory=$false)]
    [string]$CPUOnly = "No",
    [Parameter(Mandatory=$false)]
    [string]$HiveOS = "Yes",
    [Parameter(Mandatory=$false)]
    [string]$Update = "Yes",
    [Parameter(Mandatory=$false)]
    [string]$Cuda = "9.1"
)

#SetLocation & Load Script Files
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
Get-ChildItem . -Recurse | Out-Null 
. .\Build\Unix\IncludeCoin.ps1
. .\Build\Unix\Hive\HiveCmd.ps1

##Close Open Miner & Screens
$ActiveMinerPrograms = @()
$ProfitTable = @()
$OpenScreens = @()
$OpenScreens += "NVIDIA1"
$OpenScreens += "NVIDIA2"
$OpenScreens += "NVIDIA3"
$OpenScreens += "AMD1"
$OpenScreens += "AMD2"
$OpenScreens += "AMD3"
$OpenScreens += "CPU"
$OpenScreens += "ASIC"
$OpenScreens += "LogData"
$OpenScreens += "PIDInfo"
$OpenScreens | foreach {
Start-Process ".\Build\Unix\Hive\killall.sh" -ArgumentList "$($_)" -Wait
}

#Start the log
$Log = 1
if(-not (Test-Path "Logs")){
New-Item "Logs" -ItemType "directory" | Out-Null
Start-Sleep -S 1}
if(Test-Path ".\Logs\*Active*")
{
 Set-Location ".\Logs"
 $OldActiveFile = Get-ChildItem "*Active*"
 $OldActiveFile | Foreach {
  $RenameActive = $_ -replace ("-Active","")
  if(Test-Path $RenameActive){Remove-Item $RenameActive -Force}
  Rename-Item $_ -NewName $RenameActive -force
  }
 Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
}
Start-Transcript ".\Logs\miner$($Log)-Active.log" -Force
$LogTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$LogTimer.Start()

##Update
if($Update -eq "Yes")
 {
$PreviousVersions = @()
$PreviousVersions += "MM.Hash.1.3.6"
$PreviousVersions += "MM.Hash.1.3.7"
$PreviousVersions += "MM.Hash.1.3.8"
$PreviousVersions += "MM.Hash.1.3.8a"
$PreviousVersions += "MM.Hash.1.3.9"
$PreviousVersions += "MM.Hash.1.4.0b"
$PreviousVersions += "MM.Hash.1.0.4b"
$PreviousVersions += "MM.Hash.1.4.2b"
$PreviousVersions += "MM.Hash.1.4.3b"
$PreviousVersions += "MM.Hash.1.4.4b"
$PreviousVersions += "MM.Hash.1.4.6b"

$PreviousVersions | foreach {
  $PreviousPath = Join-Path "/hive/custom" "$_"
   if(Test-Path $PreviousPath)
    {
     Write-Host "Previous Version is $($PreviousPath)"
     Write-Host "Deleting Old Version"
     Start-Sleep -S 5
     $OldBackup = Join-Path $PreviousPath "Backup"
     $OldMiners = Join-Path $PreviousPath "Miners\unix"
     $OldTime = Join-Path $PreviousPath "Build\Data"
     if(Test-Path $OldBackup)
      {
      if(-not (Test-Path "Backup")){New-Item "Backup" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "Stats")){New-Item "Stats" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "Miners")){New-Item "Miners" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "Miners\unix")){New-Item "Miners\unix" -ItemType "directory"  | Out-Null }
      if(-not (Test-Path "Config")){New-Item "Config" -ItemType "directory"  | Out-Null }
      Get-ChildItem -Path "$($OldMiners)\*" -Include *.ps1 -Recurse | Copy-Item -Destination ".\Miners\unix" -force
      Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\Stats" -force
      Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\Backup" -force
      Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\Build\Data" -force
     }
    Remove-Item $PreviousPath -recurse -force
   }
  }
}

##Set Objects
$CmdDir = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "Build")
$Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
"$($CmdDir)" | Out-File ".\Build\dir.sh"
$BenchmarkMode = "No"
$Instance = 1
$InfoCheck1 = Get-Content ".\Build\Data\conversion.ifx" | Out-String
$VerifyCheck1 = Get-Content ".\Build\Data\verification.ifx" | Out-String
$InfoCheck2 = Get-Content ".\Build\Data\conversion2.ifx" | Out-String
$VerifyCheck2 = Get-Content ".\Build\Data\verification2.ifx" | Out-String
$InfoPass1 = $InfoCheck1
$InfoPass2 = $InfoCheck2
$VerifyPass1 = $VerifyCheck1
$VerifyPass2 = $VerifyCheck2 
$DecayStart = Get-Date
$DecayPeriod = 60 #seconds
$DecayBase = 1-0.1 #decimal percentage
$Deviation = $Donation
$WalletDonate = "1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i"
$NicehashDonate = "3JfBiUZZV17DTjAFCnZb97UpBgtLPLLDop"
$UserDonate = "MaynardVII"
$WorkerDonate = "Rig1"
$WalletSwitch = $Wallet
$WalletSwitch1 = $Wallet1
$WalletSwitch2 = $Wallet2
$WalletSwitch3 = $Wallet3
$CPUWalletSwitch = $CPUWallet
$ZergpoolWallet1Switch = $ZergpoolWallet1
$ZergpoolWallet2Switch = $ZergpoolWallet2
$ZergpoolWallet3Switch = $ZergpoolWallet3
$PasswordSwitch = $Passwordcurrency
$PasswordSwitch1 = $Passwordcurrency1
$PasswordSwitch2 = $Passwordcurrency2
$PasswordSwitch3 = $Passwordcurrency3
$CPUcurrencySwitch = $CPUcurrency
$Zergpoolpassword1Switch = $Zergpoolpassword1
$Zergpoolpassword2Switch = $Zergpoolpassword2
$Zergpoolpassword3Switch = $Zergpoolpassword3
$Nicehash_Wallet1Switch = $Nicehash_Wallet1
$Nicehash_Wallet2Switch = $Nicehash_Wallet2
$Nicehash_Wallet3Switch = $Nicehash_Wallet3
$UserSwitch = $UserName
$WorkerSwitch = $WorkerName
$RigSwitch = $RigName
$IntervalSwitch = $Interval
$TimeoutTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$TimeoutTimer.Start()

##Load Previous Times & PID Data
if($HiveOS -eq "Yes"){Get-Data -CmdDir $CmdDir}
Get-DateFiles -CmdDir $CmdDir

##Remove Exclusion
try{if((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)){Start-Process powershell -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath '$(Convert-Path .)'"}}catch{}

##Proxy
if($Proxy -eq ""){$PSDefaultParameterValues.Remove("*:Proxy")}
else{$PSDefaultParameterValues["*:Proxy"] = $Proxy}

##Check for libc 
if($HiveOS -eq "Yes"){Start-Process ".\Build\Unix\Hive\libc.sh" -wait}

##GPU Count & Miner Type
$Type | Foreach {
if($_ -eq "NVIDIA1"){
"NVIDIA1" | Out-File ".\Build\minertype.sh" -Force
Write-Host "Group 1 is NVIDIA- Commands and Stats will work for NVIDIA1" -foreground yellow
Start-Sleep -S 3
}
if($_ -eq "AMD1"){
"AMD1" | Out-File ".\Build\minertype.sh" -Force
Write-Host "Group 1 is AMD- Commands and Stats will work for AMD1" -foreground yellow
Start-Sleep -S 3
}
if($_ -eq "CPU"){
if($CPUOnly -eq "Yes"){
"CPU" | Out-File ".\Build\minertype.sh" -Force
Write-Host "Group 1 is CPU- Commands and Stats will work for CPU" -foreground yellow
Start-Sleep -S 3
  }
 }
}
$GPU_Count = Get-GPUCount -DeviceType $Type -CmdDir $CmdDir
Start-Sleep -S 2
if($CPUOnly -eq "Yes"){$GPU_Count = $CPUThreads}
$Count = @()
for($i=0; $i -lt $GPU_Count; $i++){[string]$Count += "$i,"}
Write-Host "Device Count = $GPU_Count" -foregroundcolor green
$LogGPUS = $Count.Substring(0,$Count.Length-1)

##Reset-Old Stats
if(Test-Path "Stats"){Get-ChildItemContent "Stats" | ForEach {$Stat = Set-Stat $_.Name $_.Content.Week}}
    
##Logo
Write-Host "
                                                                                     BEWARE OF THE
                                                                      ███████╗██╗    ██╗ █████╗ ██████╗ ███╗   ███╗
                                                                      ██╔════╝██║    ██║██╔══██╗██╔══██╗████╗ ████║
                                                                      ███████╗██║ █╗ ██║███████║██████╔╝██╔████╔██║
                                                                      ╚════██║██║███╗██║██╔══██║██╔══██╗██║╚██╔╝██║
                                                                      ███████║╚███╔███╔╝██║  ██║██║  ██║██║ ╚═╝ ██║
                                                                      ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝
                                                                             Parental Discretion Is Advised
                                                                                      v1.4.7b Unix       

                                                                      GitHub: https://Github.com/MaynardMiner/Swarm

                                                                                   SUDO APT-GET LAMBO
                                                                     .h+.                                      .+h.
                                                                     +MMd+.                                  .+dMM+ 
                                                                    +sNMMMMd+.                            .+hMMMMNs+
                                                                    .dMMMMMMMMh+.                       .+hNMMMMMMMd.
                                                                    .mMMMMMMMMMNy:.  -+:        :+-  .:yNMMMMMMMMMm.
                                                                     -mMMMMMMMMMMMms-  omhdmmdhmo  -smMMMMMMMMMMMm-
                                                                      -mMMMMMMMMMMMMMd+mMMMMMMMMm+dMMMMMMMMMMMMMm-
                                                                       \omNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmo/
                                                                                       MMMMMMMMMM
                                                                              -oooo+++//MMMMMMMM\\+++oooo-
                                                                             /          NMMMMMMM          \
                                                                                  -o++//NMMMMMMN\\++o-
                                                                                 /    +mMMMMMMMMm+    \
                                                                                     |.          .|
                                                                                     .MMMMMMMMMMMM.
                                                                                     .MMMMMMMMMMMM.
                                                                                      \.        ./
                                                                                        :MMMMMM:
                                                                                          :MMM:
                                                                                           \./
                                                                                            V
                                                                                            |                       -MaynardVII    

					                                    Hybrid Auto-Profit Switching Miner
						       BTC DONATION ADRRESS TO SUPPORT DEVELOPMENT: 1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i
				  	             This Software Is Open-Source. However, 1.40% Dev Fee Was Written In This Code
					                    It Can Take Awhile To Load At First Time Start-Up. Please Be Patient!
" -foregroundColor "darkyellow"
#Start Watchdog
Set-Location $CmdDir
$PID | Set-Content ".\PID\miner_PID.txt" -Force
Start-Process "screen" -ArgumentList "-S PIDInfo -d -m"
Start-Sleep -S 1
Start-Process ".\Unix\Hive\PIDInfo.sh" -ArgumentList "PIDInfo miner"
Set-Location $Dir
#Get-Algorithms
$Algorithm = @()
$Algorithm = Get-AlgorithmList -DeviceType $Type -No_Algo $No_Algo -CmdDir $Dir
#Get-Miner Files
$nvidia = [PSCustomObject]@{}
$amd = [PSCustomObject]@{}
$cpu = [PSCustomObject]@{}
if($Cuda -eq "9.1"){$miner_update_nvidia = Get-Content ".\Config\Update\nvidia9.1-linux.conf" | ConvertFrom-Json}
if($Cuda -eq "9.2"){$miner_update_nvidia = Get-Content ".\Config\Update\nvidia9.2-linux.conf" | ConvertFrom-Json}
$miner_update_amd = Get-Content ".\Config\Update\amd-linux.conf" | ConvertFrom-Json
$miner_update_cpu = Get-Content ".\Config\Update\cpu-linux.conf" | ConvertFrom-Json
$miner_update_nvidia | foreach {
$nvidia | Add-Member $_.Name $_
}
$miner_update_amd | foreach {
$amd | Add-Member $_.Name $_
}
$miner_update_cpu | foreach {
$cpu | Add-Member $_.Name $_
}

while($true)
{
$CoinAlgo = $null  
##Remove Coins
if(Test-Path ".\Stats\*_coin*"){Remove-Item ".\Stats\*_coin*" -force}

##Check Time Parameters
$MinerWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$TimeoutTime = [int]$Timeout*3600
$DecayExponent = [int](((Get-Date)-$DecayStart).TotalSeconds/$DecayPeriod)
$TimeDeviation = [int]($Deviation + 1.40)

$InfoCheck = Get-Content ".\Build\Data\Info.txt" | Out-String
$DonateCheck = Get-Content ".\Build\Data\System.txt" | Out-String
$LastRan = Get-Content ".\Build\Data\TimeTable.txt" | Out-String

if($TimeDeviation -ne 0)
 {
  $DonationTotal = (864*[int]$TimeDeviation)
  $DonationIntervals = ([int]$DonationTotal/288)
  $FinalDonation = (86400/[int]$DonationIntervals)

 if($LastRan -eq "")
  {
   Get-Date | Out-File ".\Build\Data\TimeTable.txt"
   Continue
  }

if($LastRan -ne "")
 {
 $RanDonate = [DateTime]$LastRan
 $LastRanDonated = [math]::Round(((Get-Date)-$RanDonate).TotalSeconds)
 if($LastRanDonated -ge 86400)
  {
  Clear-Content ".\Build\Data\TimeTable.txt" -Force
  Get-Date | Out-File ".\Build\Data\TimeTable.txt"
  Continue
  }
 }

if($LastRan -ne "")
 {
 $LastRanDonate = [DateTime]$LastRan
 $LastTimeActive = [math]::Round(((Get-Date)-$LastRanDonate).TotalSeconds)
  if($LastTimeActive -ge 1) 
   {
   if($DonateCheck -eq "")
    {
    Get-Date | Out-File ".\Build\Data\System.txt"
    Continue
    }
   $Donated = [DateTime]$DonateCheck
   $CurrentlyDonated = [math]::Round(((Get-Date)-$Donated).TotalSeconds)
   if($CurrentlyDonated -ge [int]$FinalDonation)
    {
        $Wallet = $InfoPass1
        $Wallet1 = $InfoPass1
        $Wallet2 = $InfoPass1
        $Wallet3 = $InfoPass1
        $CPUWallet = $InfoPass1
        $ZergpoolWallet1 = $InfoPass1
        $ZergpoolWallet2 = $InfoPass1
        $ZergpoolWallet3 = $InfoPass1
        $blockmastersWallet1 = $InfoPass1
        $blockmastersWallet2 = $InfoPass1
        $blockmastersWallet3 = $InfoPass1
        $Nicehash_Wallet1 = $VerifyPass1
        $Nicehash_Wallet2 = $VerifyPass1
        $Nicehash_Wallet3 = $VerifyPass1
        $UserName = $InfoPass2
        $WorkerName = $VerifyPass2
        $RigName = "DONATING!!!"
        $Interval = 288
        $Passwordcurrency = ("BTC")
        $Passwordcurrency1 = ("BTC")
        $Passwordcurrency2 = ("BTC")
        $Passwordcurrency3 = ("BTC")
        $CPUcurrency = ("BTC")
        $Zergpoolpassword1 = ("BTC")
        $Zergpoolpassword2 = ("BTC")
        $Zergpoolpassword3 = ("BTC")
        $blockmasterspassword1 = ("BTC")
        $blockmasterspassword2 = ("BTC")
        $blockmasterspassword3 = ("BTC")

     if(($InfoCheck) -eq "")
     {	
     Get-Date | Out-File ".\Build\Data\Info.txt"
     }
     Clear-Content ".\Build\Data\System.txt" -Force
     Get-Date | Out-File ".\Build\Data\System.txt"
     Start-Sleep -s 1
     Write-Host  "Entering Donation Mode" -foregroundColor "darkred"
     Continue
    }
  }

 if($InfoCheck -ne "")
  {
     $TimerCheck = [DateTime]$InfoCheck
     $LastTimerCheck = [math]::Round(((Get-Date)-$LastRanDonate).TotalSeconds)
     if(((Get-Date)-$TimerCheck).TotalSeconds -ge $Interval)
      {
        $Wallet = $WalletSwitch
        $Wallet1 = $WalletSwitch1
        $Wallet2 = $WalletSwitch2
	      $Wallet3 = $WalletSwitch3
        $ZergpoolWallet1 = $ZergpoolWallet1Switch
        $ZergpoolWallet2 = $ZergpoolWallet2Switch
        $ZergpoolWallet3 = $ZergpoolWallet3Switch
        $Nicehash_Wallet1 = $Nicehash_Wallet1Switch
        $Nicehash_Wallet2 = $Nicehash_Wallet2Switch
        $Nicehash_Wallet3 = $Nicehash_Wallet3Switch
        $CPUWallet = $CPUWalletSwitch
      	$UserName = $UserSwitch
	      $WorkerName = $WorkerSwitch
      	$RigName = $RigSwitch
        $Interval = $IntervalSwitch
        $Passwordcurrency = $PasswordSwitch
      	$Passwordcurrency1 = $PasswordSwitch1
        $Passwordcurrency2 = $PasswordSwitch2
        $Passwordcurrency3 = $PasswordSwitch3
        $Zergpoolpassword1 = $Zergpoolpassword1Switch
        $Zergpoolpassword2 = $Zergpoolpassword2Switch
        $Zergpoolpassword3 = $Zergpoolpassword3Switch
        $CPUcurrency = $CPUcurrencySwitch
	Clear-Content ".\Build\Data\Info.txt" -Force
	Write-Host "Leaving Donation Mode- Thank you For The Support!" -foregroundcolor "darkred"
	Continue
       }
     }
   }
  }
 
  ##Get Price Data
  try {
	$T = [string]$CoinExchange
	$R= [string]$Currency
	Write-Host "SWARM Is Building The Database. Auto-Coin Switching: $Auto_Coin" -foreground "yellow"   
  $Exchanged =  Invoke-RestMethod "https://min-api.cryptocompare.com/data/price?fsym=$T&tsyms=$R" -UseBasicParsing | Select-Object -ExpandProperty $R
	$Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=$R" -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
  $Currency | Where-Object {$Rates.$_} | ForEach-Object {$Rates | Add-Member $_ ([Double]$Rates.$_) -Force}
  }
  catch {
  Write-Host -Level Warn "Coinbase Unreachable. "
  Write-Host -ForegroundColor Yellow "Last Refresh: $(Get-Date)"
  Write-host "Trying To Contact Cryptonator.." -foregroundcolor "Yellow"
  $Rates = [PSCustomObject]@{}
  $Currency | ForEach {$Rates | Add-Member $_ (Invoke-WebRequest "https://api.cryptonator.com/api/ticker/btc-$_" -UseBasicParsing | ConvertFrom-Json).ticker.price}
   }
   
  ##Load File Stats
  if($TimeoutTimer.Elapsed.TotalSeconds -lt $TimeoutTime -or $Timeout -eq 0)
   {
    $Stats = $null
    $Stats = [PSCustomObject]@{}
    $AllStats = if(Test-Path "Stats"){Get-ChildItemContent "Stats" | ForEach {$Stats | Add-Member $_.Name $_.Content}}
    $AllStats | Out-Null
   }
  ##Timeout Reset
  else
   {
    $AllStats = if(Test-Path "./Stats"){Get-ChildItemContent "./Stats"}
    $AllStats | ForEach-Object{
    if($_.Content.Live -eq 0)
     {
      $Removed = Join-Path "./Stats" "$($_.Name).txt"
      $Change = $($_.Name) -replace "HashRate","TIMEOUT"
      if(Test-Path (Join-Path "./Timeout" "$($Change).txt")){Remove-Item (Join-Path "./Timeout" "$($Change).txt") -Force}
	    Remove-Item $Removed -Force
      Write-Host "$($_.Name) Hashrate and Timeout Notification was Removed"
     }
   }
   Write-Host "Cleared Timeouts" -ForegroundColor Red
   $TimeoutTimer.Restart()
   continue
   }

   ##Load Algo Pools
   Write-Host "Checking Algo Pools" -Foregroundcolor yellow
   $AllAlgoPools = if(Test-Path "AlgoPools"){Get-ChildItemContent "AlgoPools" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} |
   Where {$PoolName.Count -eq 0 -or (Compare-Object $PoolName $_.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}
   if($AllAlgoPools.Count -eq 0){"No Pools! Check Internet Connection."| Out-Host; start-sleep $Interval; continue}
   $AlgoPools = [PSCustomObject]@{}
   $AlgoPools_Comparison = $null
   $AlgoPools_Comparison = [PSCustomObject]@{}
   $AllAlgoPools.Symbol | Select -Unique | ForEach {$AlgoPools | Add-Member $_ ($AllAlgoPools | Where Symbol -EQ $_ | Sort-Object Price -Descending | Select -First 1)}
   $AllAlgoPools.Symbol | Select -Unique | ForEach {$AlgoPools_Comparison | Add-Member $_ ($AllAlgoPools | Where Symbol -EQ $_ | Sort-Object StablePrice -Descending | Select -First 1)}

   ##Load Only Needed Algorithm Miners
   Write-Host "Checking Algo Miners"
   $AlgoMiners = if(Test-Path "Miners\unix"){Get-ChildItemContent "Miners\unix" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} | 
   Where {$Platform.Count -eq 0 -or (Compare-Object $Platform $_.Platform -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} |
   Where {$Type.Count -eq 0 -or (Compare-Object $Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}


   ##Re-Name Instance In Case Of Crashes
   $AlgoMiners | ForEach {
    $AlgoMiner = $_
    if(Test-Path (Split-Path $Algominer.Path))
    {
     Set-Location (Split-Path $AlgoMiner.Path)
     if(Test-Path "*$($_.Type)*")
      {
       $OldInstance = Get-ChildItem "*$($AlgoMiner.Type)*"
       Rename-Item $OldInstance -NewName "$($AlgoMiner.MinerName)" -force
      }
     Set-Location $Dir
    }
  }

   ##Download Miners
   $AlgoMiners = $AlgoMiners | ForEach {
   $AlgoMiner = $_

    if((Test-Path $_.Path) -eq $false)
    {
    ##Download Miners
    if($AlgoMiner.BUILD -eq "Linux" -or $AlgoMiner.BUILD -eq "Linux-Clean" -or $AlgoMiner.BUILD -eq "Linux-Zip-Build")
     {
      Expand-WebRequest -URI $AlgoMiner.URI -BuildPath $AlgoMiner.BUILD -Path (Split-Path $AlgoMiner.Path) -MineName (Split-Path $AlgoMiner.Path -Leaf) -MineType $AlgoMiner.Type
     }
    if($AlgoMiner.BUILD -eq "Windows" -or "Linux-Zip" -or "Zip")
     {
     if((Split-Path $AlgoMiner.URI -Leaf) -eq (Split-Path $AlgoMiner.Path -Leaf))
      {
       New-Item (Split-Path $AlgoMiner.Path) -ItemType "Directory" | Out-Null
       Invoke-WebRequest $AlgoMiner.URI -OutFile $_.Path -UseBasicParsing
      }
     else
      {
       Expand-WebRequest -URI $AlgoMiner.URI -BuildPath $AlgoMiner.BUILD -Path (Split-Path $AlgoMiner.Path) -MineName (Split-Path $AlgoMiner.Path -Leaf) -MineType $AlgoMiner.Type
      }
     }
   }
 else
  {
   $AlgoMiner
  }
}

if($AlgoMiners.Count -eq 0){"No Miners!" | Out-Host; start-sleep $Interval; continue}

##Sort Alorithm Miners
$AlgoMiners | ForEach {
       $AlgoMiner = $_

       $AlgoMiner_HashRates = [PSCustomObject]@{}
       $AlgoMiner_Pools = [PSCustomObject]@{}
       $AlgoMiner_Pools_Comparison = [PSCustomObject]@{}
       $AlgoMiner_Profits = [PSCustomObject]@{}
       $AlgoMiner_Profits_Comparison = [PSCustomObject]@{}
       $AlgoMiner_Profits_Bias = [PSCustomObject]@{}

       $AlgoMiner_Types = $AlgoMiner.Type | Select -Unique
       $AlgoMiner_Indexes = $AlgoMiner.Index | Select -Unique

       $AlgoMiner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
       $AlgoMiner_HashRates | Add-Member $_ ([Double]$AlgoMiner.HashRates.$_)
       $AlgoMiner_Pools | Add-Member $_ ([PSCustomObject]$AlgoPools.$_)
       $AlgoMiner_Pools_Comparison | Add-Member $_ ([PSCustomObject]$AlgoPools_Comparison.$_)
       $AlgoMiner_Profits | Add-Member $_ ([Double]$AlgoMiner.HashRates.$_*$AlgoPools.$_.Price)
       $AlgoMiner_Profits_Comparison | Add-Member $_ ([Double]$AlgoMiner.HashRates.$_*$AlgoPools_Comparison.$_.Price)
       $AlgoMiner_Profits_Bias | Add-Member $_ ([Double]$AlgoMiner.HashRates.$_*$AlgoPools.$_.Price*(1-($AlgoPools.$_.MarginOfError*[Math]::Pow($DecayBase,$DecayExponent))))
       }

      
       
       $AlgoMiner_Profit = [Double]($AlgoMiner_Profits.PSObject.Properties.Value | Measure -Sum).Sum
       $AlgoMiner_Profit_Comparison = [Double]($AlgoMiner_Profits_Comparison.PSObject.Properties.Value | Measure -Sum).Sum
       $AlgoMiner_Profit_Bias = [Double]($AlgoMiner_Profits_Bias.PSObject.Properties.Value | Measure -Sum).Sum

       $AlgoMiner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
        if(-not [String]$AlgoMiner.HashRates.$_)
        {
               $AlgoMiner_HashRates.$_ = $null
               $AlgoMiner_Profits.$_ = $null
               $AlgoMiner_Profits_Comparison.$_ = $null
               $AlgoMiner_Profits_Bias.$_ = $null
               $AlgoMiner_Profit = $null
               $AlgoMiner_Profit_Comparison = $null
               $AlgoMiner_Profit_Bias = $null
           }
       }

       if($AlgoMiner_Types -eq $null){$AlgoMiner_Types = $AlgoMiners.Type | Select -Unique}
       if($AlgoMiner_Indexes -eq $null){$AlgoMiner_Indexes = $AlgoMiners.Index | Select -Unique}
       
       if($AlgoMiner_Types -eq $null){$AlgoMiner_Types = ""}
       if($AlgoMiner_Indexes -eq $null){$AlgoMiner_Indexes = 0}
       
       $AlgoMiner.HashRates = $AlgoMiner_HashRates

       $AlgoMiner | Add-Member Pools $AlgoMiner_Pools
       $AlgoMiner | Add-Member Profits $AlgoMiner_Profits
       $AlgoMiner | Add-Member Profits_Comparison $AlgoMiner_Profits_Comparison
       $AlgoMiner | Add-Member Profits_Bias $AlgoMiner_Profits_Bias
       $AlgoMiner | Add-Member Profit $AlgoMiner_Profit
       $AlgoMiner | Add-Member Profit_Comparison $AlgoMiner_Profit_Comparison
       $AlgoMiner | Add-Member Profit_Bias $AlgoMiner_Profit_Bias

       $AlgoMiner | Add-Member Type $AlgoMiner_Types -Force
       $AlgoMiner | Add-Member Index $AlgoMiner_Indexes -Force

       $AlgoMiner.Path = Convert-Path $AlgoMiner.Path
   }


   $AlgoMiners | ForEach {
       $AlgoMiner = $_
       $AlgoMiner_Devices = $AlgoMiner.Device | Select -Unique
       if($AlgoMiner_Devices -eq $null){$AlgoMiner_Devices = ($AlgoMiners | Where {(Compare-Object $AlgoMiner.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}).Device | Select -Unique}
       if($AlgoMiner_Devices -eq $null){$AlgoMiner_Devices = $AlgoMiner.Type}
       $AlgoMiner | Add-Member Device $AlgoMiner_Devices -Force
   }

   #Don't penalize active miners & sort by threshold
   $ActiveMinerPrograms | ForEach {$AlgoMiners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit}}
   $GoodAlgoMiners = @()
   $AlgoMiners | Where [Double]Profit -lt $Threshold | foreach {$GoodAlgoMiners += $_}

   #Get most profitable algo miner combination i.e. AMD+NVIDIA+CPU add algo miners to miners list
   $Miners = @()
   $GoodAlgoMiners | foreach {$Miners += $_}
   $BestAlgoMiners = $GoodAlgoMiners | Select Type,Index -Unique | ForEach {$AlgoMiner_GPU = $_; ($GoodAlgoMiners | Where {(Compare-Object $AlgoMiner_GPU.Type $_.Type | Measure).Count -eq 0 -and (Compare-Object $AlgoMiner_GPU.Index $_.Index | Measure).Count -eq 0} | Sort-Object -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Bias -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
   $BestDeviceAlgoMiners = $GoodAlgoMiners | Select Device -Unique | ForEach {$AlgoMiner_GPU = $_; ($GoodAlgoMiners | Where {(Compare-Object $AlgoMiner_GPU.Device $_.Device | Measure).Count -eq 0} | Sort-Object -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Bias -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
   $BestAlgoMiners_Comparison = $GoodAlgoMiners | Select Type,Index -Unique | ForEach {$AlgoMiner_GPU = $_; ($GoodAlgoMiners | Where {(Compare-Object $AlgoMiner_GPU.Type $_.Type | Measure).Count -eq 0 -and (Compare-Object $AlgoMiner_GPU.Index $_.Index | Measure).Count -eq 0} | Sort-Object -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Comparison -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
   $BestDeviceAlgoMiners_Comparison = $GoodAlgoMiners | Select Device -Unique | ForEach {$AlgoMiner_GPU = $_; ($GoodAlgoMiners | Where {(Compare-Object $AlgoMiner_GPU.Device $_.Device | Measure).Count -eq 0} | Sort-Object -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Comparison -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
   $AlgoMiners_Type_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($GoodAlgoMiners | Select Type -Unique) | Where{(Compare-Object ($_.Combination | Select -ExpandProperty Type -Unique) ($_.Combination | Select -ExpandProperty Type) | Measure).Count -eq 0})
   $AlgoMiners_Index_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($GoodAlgoMiners | Select Index -Unique) | Where{(Compare-Object ($_.Combination | Select -ExpandProperty Index -Unique) ($_.Combination | Select -ExpandProperty Index) | Measure).Count -eq 0})
   $AlgoMiners_Device_Combos = (Get-Combination ($GoodAlgoMiners | Select Device -Unique) | Where{(Compare-Object ($_.Combination | Select -ExpandProperty Device -Unique) ($_.Combination | Select -ExpandProperty Device) | Measure).Count -eq 0})
   $BestAlgoMiners_Combos = $AlgoMiners_Type_Combos | ForEach {$AlgoMiner_Type_Combo = $_.Combination; $AlgoMiners_Index_Combos | ForEach {$AlgoMiner_Index_Combo = $_.Combination; [PSCustomObject]@{Combination = $AlgoMiner_Type_Combo | ForEach {$AlgoMiner_Type_Count = $_.Type.Count; [Regex]$AlgoMiner_Type_Regex = ‘^(‘ + (($_.Type | ForEach {[Regex]::Escape($_)}) -join “|”) + ‘)$’; $AlgoMiner_Index_Combo | ForEach {$AlgoMiner_Index_Count = $_.Index.Count; [Regex]$AlgoMiner_Index_Regex = ‘^(‘ + (($_.Index | ForEach {[Regex]::Escape($_)}) –join “|”) + ‘)$’; $BestAlgoMiners | Where {([Array]$_.Type -notmatch $AlgoMiner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $AlgoMiner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $AlgoMiner_Type_Regex).Count -eq $AlgoMiner_Type_Count -and ([Array]$_.Index -match $AlgoMiner_Index_Regex).Count -eq $AlgoMiner_Index_Count}}}}}}
   $BestAlgoMiners_Combos += $AlgoMiners_Device_Combos | ForEach {$AlgoMiner_Device_Combo = $_.Combination; [PSCustomObject]@{Combination = $AlgoMiner_Device_Combo | ForEach {$AlgoMiner_Device_Count = $_.Device.Count; [Regex]$AlgoMiner_Device_Regex = ‘^(‘ + (($_.Device | ForEach {[Regex]::Escape($_)}) -join “|”) + ‘)$’; $BestDeviceAlgoMiners | Where {([Array]$_.Device -notmatch $AlgoMiner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $AlgoMiner_Device_Regex).Count -eq $AlgoMiner_Device_Count}}}}
   $BestAlgoMiners_Combos_Comparison = $AlgoMiners_Type_Combos | ForEach {$AlgoMiner_Type_Combo = $_.Combination; $AlgoMiners_Index_Combos | ForEach {$AlgoMiner_Index_Combo = $_.Combination; [PSCustomObject]@{Combination = $AlgoMiner_Type_Combo | ForEach {$AlgoMiner_Type_Count = $_.Type.Count; [Regex]$AlgoMiner_Type_Regex = ‘^(‘ + (($_.Type | ForEach {[Regex]::Escape($_)}) -join “|”) + ‘)$’; $AlgoMiner_Index_Combo | ForEach {$AlgoMiner_Index_Count = $_.Index.Count; [Regex]$AlgoMiner_Index_Regex = ‘^(‘ + (($_.Index | ForEach {[Regex]::Escape($_)}) –join “|”) + ‘)$’; $BestAlgoMiners_Comparison | Where {([Array]$_.Type -notmatch $AlgoMiner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $AlgoMiner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $AlgoMiner_Type_Regex).Count -eq $AlgoMiner_Type_Count -and ([Array]$_.Index -match $AlgoMiner_Index_Regex).Count -eq $AlgoMiner_Index_Count}}}}}}
   $BestAlgoMiners_Combos_Comparison += $AlgoMiners_Device_Combos | ForEach {$AlgoMiner_Device_Combo = $_.Combination; [PSCustomObject]@{Combination = $AlgoMiner_Device_Combo | ForEach {$AlgoMiner_Device_Count = $_.Device.Count; [Regex]$AlgoMiner_Device_Regex = ‘^(‘ + (($_.Device | ForEach {[Regex]::Escape($_)}) -join “|”) + ‘)$’; $BestDeviceAlgoMiners_Comparison | Where {([Array]$_.Device -notmatch $AlgoMiner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $AlgoMiner_Device_Regex).Count -eq $AlgoMiner_Device_Count}}}}
   $BestAlgoMiners_Combo = $BestAlgoMiners_Combos | Sort-Object -Descending {($_.Combination | Where Profit -EQ $null | Measure).Count},{($_.Combination | Measure Profit_Bias -Sum).Sum},{($_.Combination | Where Profit -NE 0 | Measure).Count} | Select -First 1 | Select -ExpandProperty Combination
   $BestAlgoMiners_Combo_Comparison = $BestAlgoMiners_Combos_Comparison | Sort-Object -Descending {($_.Combination | Where Profit -EQ $null | Measure).Count},{($_.Combination | Measure Profit_Comparison -Sum).Sum},{($_.Combination | Where Profit -NE 0 | Measure).Count} | Select -First 1 | Select -ExpandProperty Combination
   $BestMiners_Combo = $BestAlgoMiners_Combo

#check if Auto_Coin is working- Start Coin Sorting
if($Auto_Coin -eq "Yes")
 {
  $AddCoinMiners = @()
  $NeedsToBeBench = $false

#Check if Benchmarking/Disable Coins
$BestAlgoMiners_Combo | foreach {
 if($_.Profit -eq $null)
  {
   $NeedsToBeBench = $true
   Write-Host "Coins Disabled - Benchmarking Required." -foreground yellow
  }
  }

#Get Specific Coin Miners
if($NeedsToBeBench -eq $false){$BestAlgoMiners_Combo | foreach {if($_.MinerPool -like "*algo*"){$AddCoinMiners += $_}}}

#Get Specfic Coin Algorithms
if($AddCoinMiners -ne $null)
 {
  $CoinAlgo = @()
  $AddCoinMiners.Algo | foreach {$CoinAlgo += $_}

  Write-Host "Best Pool Is CoinPool: Searching For Coins For $($CoinAlgo) Algorithm" -ForegroundColor Magenta

#Load Coin Pools 
$AllCoinPools = if(Test-Path "CoinPools"){Get-ChildItemContent "CoinPools" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} |
Where {$PoolName.Count -eq 0 -or (Compare-Object $PoolName $_.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} |
Where {$CoinAlgo.Count -eq 0 -or (Compare-Object $CoinAlgo $_.Algorithm -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}
$CoinPools = [PSCustomObject]@{}
$CoinPools_Comparison = $null
$CoinPools_Comparison = [PSCustomObject]@{}
$AllCoinPools.Symbol | Select -Unique | ForEach {$CoinPools | Add-Member $_ ($AllCoinPools | Where Symbol -EQ $_ | Sort-Object Price -Descending | Select -Unique -First 1)}
$AllCoinPools.Symbol | Select -Unique | ForEach {$CoinPools_Comparison | Add-Member $_ ($AllCoinPools | Where Symbol -EQ $_ | Sort-Object StablePrice -Descending | Select -Unique -First 1)}

#Load Coin Miners
$CoinMiners = if(Test-Path "Miners\unix"){Get-ChildItemContent "Miners\unix" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} |
Where {$Platform.Count -eq 0 -or (Compare-Object $Platform $_.Platform -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} |
Where {$Type.Count -eq 0 -or (Compare-Object $Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} |
Where {$CoinAlgo.Count -eq 0 -or (Compare-Object $CoinAlgo $_.Selected.PSObject.Properties.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}
      
  }
}

##Sort Coin Miners
if($CoinMiners -ne $null)
 {
  $CoinMiners | ForEach {
  $CoinMiner = $_

  $CoinMiner_HashRates = [PSCustomObject]@{}
  $CoinMiner_Pools = [PSCustomObject]@{}
  $CoinMiner_Pools_Comparison = [PSCustomObject]@{}
  $CoinMiner_Profits = [PSCustomObject]@{}
  $CoinMiner_Profits_Comparison = [PSCustomObject]@{}
  $CoinMiner_Profits_Bias = [PSCustomObject]@{}
      
  $CoinMiner_Types = $CoinMiner.Type | Select -Unique
  $CoinMiner_Indexes = $CoinMiner.Index | Select -Unique
      
  $CoinMiner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
  $CoinMiner_HashRates | Add-Member $_ ([Double]$CoinMiner.HashRates.$_)
  $CoinMiner_Pools | Add-Member $_ ([PSCustomObject]$CoinPools.$_)
  $CoinMiner_Pools_Comparison | Add-Member $_ ([PSCustomObject]$CoinPools_Comparison.$_)
  $CoinMiner_Profits | Add-Member $_ ([Double]$CoinMiner.HashRates.$_*$CoinPools.$_.Price)
  $CoinMiner_Profits_Comparison | Add-Member $_ ([Double]$CoinMiner.HashRates.$_*$CoinPools_Comparison.$_.Price)
  $CoinMiner_Profits_Bias | Add-Member $_ ([Double]$CoinMiner.HashRates.$_*$CoinPools.$_.Price*(1-($CoinPools.$_.MarginOfError*[Math]::Pow($DecayBase,$DecayExponent))))
 }
                       
  $CoinMiner_Profit = [Double]($CoinMiner_Profits.PSObject.Properties.Value | Measure -Sum).Sum
  $CoinMiner_Profit_Comparison = [Double]($CoinMiner_Profits_Comparison.PSObject.Properties.Value | Measure -Sum).Sum
  $CoinMiner_Profit_Bias = [Double]($CoinMiner_Profits_Bias.PSObject.Properties.Value | Measure -Sum).Sum

  ##Not Needed- Added for future use
  $CoinMiner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
  if(-not [String]$CoinMiner.HashRates.$_)
   {
    $CoinMiner_HashRates.$CoinMinerAlgo = $null
    $CoinMiner_Profits.$CoinSymbol = $null
    $CoinMiner_Profits_Comparison.$CoinSymbol = $null
    $CoinMiner_Profits_Bias.$CoinSymbol = $null
    $CoinMiner_Profit = $null
    $CoinMiner_Profit_Comparison = $null
    $CoinMiner_Profit_Bias = $null
   }
  }
      
  if($CoinMiner_Types -eq $null){$CoinMiner_Types = $CoinMiners.Type | Select -Unique}
  if($CoinMiner_Indexes -eq $null){$CoinMiner_Indexes = $CoinMiners.Index | Select -Unique}
              
  if($CoinMiner_Types -eq $null){$CoinMiner_Types = ""}
  if($CoinMiner_Indexes -eq $null){$CoinMiner_Indexes = 0}
              
  $CoinMiner.HashRates = $CoinMiner_HashRates
              
  $CoinMiner | Add-Member Pools $CoinMiner_Pools
  $CoinMiner | Add-Member Profits $CoinMiner_Profits
  $CoinMiner | Add-Member Profits_Comparison $CoinMiner_Profits_Comparison
  $CoinMiner | Add-Member Profits_Bias $CoinMiner_Profits_Bias
  $CoinMiner | Add-Member Profit $CoinMiner_Profit
  $CoinMiner | Add-Member Profit_Comparison $CoinMiner_Profit_Comparison
  $CoinMiner | Add-Member Profit_Bias $CoinMiner_Profit_Bias

  $CoinMiner | Add-Member Type $CoinMiner_Types -Force
  $CoinMiner | Add-Member Index $CoinMiner_Indexes -Force
      
  $CoinMiner.Path = Convert-Path $CoinMiner.Path
 }

  $CoinMiners | ForEach {
  $CoinMiner = $_
  $CoinMiner_Devices = $CoinMiner.Device | Select -Unique
  if($CoinMiner_Devices -eq $null){$CoinMiner_Devices = ($CoinMiners | Where {(Compare-Object $CoinMiner.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}).Device | Select -Unique}
  if($CoinMiner_Devices -eq $null){$CoinMiner_Devices = $CoinMiner.Type}
  $CoinMiner | Add-Member Device $CoinMiner_Devices -Force
 }

   $NewCoinAlgo = @()
   $Miners = @()

   if($Favor_Coins -eq "Yes")
    {
     $CoinAlgo | foreach {
     if($BestAlgoMiners_Combo.MinerPool -like "*algo*")
      {
       $NewCoinAlgo += [PSCustomObject]@{
       $_ = "$($_)"
         }
        }
      }
     }

    $ProfitsArray = @()

      if($Favor_Coins -eq "Yes")
      {
      $CoinMiners | Where [Double]Profit -lt $Threshold | foreach {$Miners += $_}
      }
      else{
      $GoodAlgoMiners | foreach {$Miners += $_}
      $CoinMiners | Where [Double]Profit -lt $Threshold | foreach {$Miners += $_}
      }

      $ActiveMinerPrograms | ForEach {$Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit}}

       $BestMiners = $Miners | Select Type,Index -Unique | ForEach {$Miner_GPU = $_; ($Miners | Where {(Compare-Object $Miner_GPU.Type $_.Type | Measure).Count -eq 0 -and (Compare-Object $Miner_GPU.Index $_.Index | Measure).Count -eq 0} | Sort-Object -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Bias -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
       $BestDeviceMiners = $Miners | Select Device -Unique | ForEach {$Miner_GPU = $_; ($Miners | Where {(Compare-Object $Miner_GPU.Device $_.Device | Measure).Count -eq 0} | Sort-Object -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Bias -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
       $BestMiners_Comparison = $Miners | Select Type,Index -Unique | ForEach {$Miner_GPU = $_; ($Miners | Where {(Compare-Object $Miner_GPU.Type $_.Type | Measure).Count -eq 0 -and (Compare-Object $Miner_GPU.Index $_.Index | Measure).Count -eq 0} | Sort-Object -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Comparison -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
       $BestDeviceMiners_Comparison = $Miners | Select Device -Unique | ForEach {$Miner_GPU = $_; ($Miners | Where {(Compare-Object $Miner_GPU.Device $_.Device | Measure).Count -eq 0} | Sort-Object -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Comparison -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
       $Miners_Type_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($Miners | Select Type -Unique) | Where{(Compare-Object ($_.Combination | Select -ExpandProperty Type -Unique) ($_.Combination | Select -ExpandProperty Type) | Measure).Count -eq 0})
       $Miners_Index_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($Miners | Select Index -Unique) | Where{(Compare-Object ($_.Combination | Select -ExpandProperty Index -Unique) ($_.Combination | Select -ExpandProperty Index) | Measure).Count -eq 0})
       $Miners_Device_Combos = (Get-Combination ($Miners | Select Device -Unique) | Where{(Compare-Object ($_.Combination | Select -ExpandProperty Device -Unique) ($_.Combination | Select -ExpandProperty Device) | Measure).Count -eq 0})
       $BestMiners_Combos = $Miners_Type_Combos | ForEach {$Miner_Type_Combo = $_.Combination; $Miners_Index_Combos | ForEach {$Miner_Index_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Type_Combo | ForEach {$Miner_Type_Count = $_.Type.Count; [Regex]$Miner_Type_Regex = '^(' + (($_.Type | ForEach {[Regex]::Escape($_)}) -join "|") + ')$'; $Miner_Index_Combo | ForEach {$Miner_Index_Count = $_.Index.Count; [Regex]$Miner_Index_Regex = '^(' + (($_.Index | ForEach {[Regex]::Escape($_)}) -join "|") + ')$'; $BestMiners | Where {([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count}}}}}}
       $BestMiners_Combos += $Miners_Device_Combos | ForEach {$Miner_Device_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Device_Combo | ForEach {$Miner_Device_Count = $_.Device.Count; [Regex]$Miner_Device_Regex = '^(' + (($_.Device | ForEach {[Regex]::Escape($_)}) -join "|") + ')$'; $BestDeviceMiners | Where {([Array]$_.Device -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $Miner_Device_Regex).Count -eq $Miner_Device_Count}}}}
       $BestMiners_Combos_Comparison = $Miners_Type_Combos | ForEach {$Miner_Type_Combo = $_.Combination; $Miners_Index_Combos | ForEach {$Miner_Index_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Type_Combo | ForEach {$Miner_Type_Count = $_.Type.Count; [Regex]$Miner_Type_Regex = '^(' + (($_.Type | ForEach {[Regex]::Escape($_)}) -join "|") + ')$'; $Miner_Index_Combo | ForEach {$Miner_Index_Count = $_.Index.Count; [Regex]$Miner_Index_Regex = '^(' + (($_.Index | ForEach {[Regex]::Escape($_)}) -join "|") + ')$'; $BestMiners_Comparison | Where {([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count}}}}}}
       $BestMiners_Combos_Comparison += $Miners_Device_Combos | ForEach {$Miner_Device_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Device_Combo | ForEach {$Miner_Device_Count = $_.Device.Count; [Regex]$Miner_Device_Regex = '^(' + (($_.Device | ForEach {[Regex]::Escape($_)}) -join "|") + ')$'; $BestDeviceMiners_Comparison | Where {([Array]$_.Device -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $Miner_Device_Regex).Count -eq $Miner_Device_Count}}}}
       $BestMiners_Combo = $BestMiners_Combos | Sort-Object -Descending {($_.Combination | Where Profit -EQ $null | Measure).Count},{($_.Combination | Measure Profit_Bias -Sum).Sum},{($_.Combination | Where Profit -NE 0 | Measure).Count} | Select -First 1 | Select -ExpandProperty Combination
       $BestMiners_Combo_Comparison = $BestMiners_Combos_Comparison | Sort-Object -Descending {($_.Combination | Where Profit -EQ $null | Measure).Count},{($_.Combination | Measure Profit_Comparison -Sum).Sum},{($_.Combination | Where Profit -NE 0 | Measure).Count} | Select -First 1 | Select -ExpandProperty Combination

       if($Favor_Coins -eq "Yes")
        {
       $BestMiners_Combo | Foreach {
        $ProfitsArray += [PSCustomObject]@{
         Type = $_.Type
         Profits = $_.Profit 
        }
       }

       $GoodAlgoMiners | Foreach{
        if($NewCoinAlgo.$($_.Symbol) -ne "$($_.Symbol)")
         {
          if(($ProfitsArray | Where Type -EQ $_.Type).Profits -gt $_.Profit)
           {
            $Miners += $_
           }
           }
        }
       }
    }
  ##Write On Screen Best Choice  
  $BestMiners_Selected = $BestMiners_Combo.Symbol
  $BestPool_Selected = $BestMiners_Combo.MinerPool 
  Write-Host "Most Profitable Choice Is $($BestMiners_Selected) on $($BestPool_Selected)" -foregroundcolor green          

 ##Build Stats Table
 $ProfitTable = $null
 $ProfitTable = @()
 $Miners | foreach {
 $ProfitTable += [PSCustomObject]@{
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

 ##Add Instance Settings To Miners For Tracking
 $BestMiners_Combo | ForEach {
    if(-not ($ActiveMinerPrograms | Where Path -eq $_.Path | Where Arguments -eq $_.Arguments ))
     {
            $ActiveMinerPrograms += [PSCustomObject]@{
              Name = $_.Name
              Type = $_.Type
              Devices = $_.Devices
              DeviceCall = $_.DeviceCall
	            MinerName = $_.MinerName
              Path = $_.Path
              Arguments = $_.Arguments
              API = $_.API
              Port = $_.Port
              Coins = $_.Symbol
              New = $false
              Active = [TimeSpan]0
              Activated = 0
              Status = "Idle"
              HashRate = 0
              Benchmarked = 0
              Timeout = 0
              WasBenchmarked = $false
              XProcess = $null
              MinerPool = $_.MinerPool
	            Algo = $_.Algo
              Bad_Benchmark = 0
              FullName = $_.FullName
              Instance = $null
	            InstanceNumber = $null
              Username = $_.Username
              Connection = $_.Connection
              Password = $_.Password
              BestMiner = $null
          }
        }
      }
    
##Simple Switches For User Notification
$Restart = $false
$NoMiners = $false

#Determine Which Miner Should Be Active
$ActiveMinerPrograms | foreach {
if($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments){$_.BestMiner = $true}
else{$_.BestMiner = $false}
}

##Close & Launch Miners
$ActiveMinerPrograms | foreach {
  if($_.BestMiner -eq $false)
   {
    if($_.XProcess.HasExited){
     if($_.Status -eq "Running"){
     $_.Status = "Failed"
     }
    }
  else
   {
    $_.Status = "Idle"
    $PIDDate = "$($_.Instance)_Date.txt"
    if(Test-path $PIDDate)
     {
     $PIDDateFile = Get-Content $PIDDate | Out-String
     $PIDTime = [DateTime]$PIDDateFile
     $_.Active += (Get-Date)-$PIDTime   
     }
    }
   }
 else{
    if($TimeDeviation -ne 0)
     {
      $CurrentLog = ".\Logs\$($_.Type).log"
      if(Test-Path $CurrentLog){Clear-Content $CurrentLog -Force}
      if($null -eq $_.XProcess -or $_.XProcess.HasExited -ne $false)
       {
        $Restart = $true
        $DecayStart = Get-Date
        $_.New = $true
        $_.Activated++
        $CurrentLog = ".\Logs\$($_.Type).log"
        if(Test-Path $CurrentLog){Clear-Content $CurrentLog -Force}    
        $LogDir = Join-Path $Dir "Logs\$($_.Type).log"
        Rename-Item $_.Path -NewName "$($_.Type)-$($Instance)" -Force
        $MinerDir = Split-Path $_.Path
        if($null -eq $_.Devices){$GPUGrouping = $LogGPUS}
        else{$GPUGrouping = $_.Devices}
        if($CPUOnly -eq "Yes"){$GPUGrouping = $LogGPUS}
        $LaunchCodes = @{}
        $LaunchCodes.Add("Type",$_.Type)
        $LaunchCodes.Add("Logs",$LogDir)
        $LaunchCodes.Add("Name",$_.Name)
        $LaunchCodes.Add("MinerName",$_.MinerName)
        $LaunchCodes.Add("Path",$_.Path)
        $LaunchCodes.Add("Coins",$_.Coins)
        $LaunchCodes.Add("CmdDir",$CmdDir)
        $LaunchCodes.Add("MinerDir",$MinerDir)
        $LaunchCodes.Add("Delay",$Delay)
        $LaunchCodes.Add("Algos",$_.Algo)
        $LaunchCodes.Add("GPUGroup",$GPUGrouping)
        $LaunchCodes.Add("APIs",$_.API)
        $LaunchCodes.Add("Ports",$_.Port)
        $LaunchCodes.Add("MDir",$Dir)
        $LaunchCodes.Add("MinerInstance","$($_.Type)-$($Instance)")
        if($_.Arguments -ne "none"){$LaunchCodes.Add("Arguments","$($_.Arguments)")}
        if($null -ne $_.Connection){$LaunchCodes.Add("Connection","$($_.Connection)")}
        if($null -ne $_.Username){$LaunchCodes.Add("Username","$($_.Username)")}
        if($null -ne $_.Password){$LaunchCodes.Add("Password","$($_.Password)")}
        if($null -ne $_.DeviceCall){$LaunchCodes.Add("DeviceCall",$_.DeviceCall)}
        if($null -ne $_.Devices){$LaunchCodes.Add("Devices",$_.Devices)}

        Start-LaunchCode @LaunchCodes

      $_.Instance = ".\Build\PID\$($_.Name)_$($_.Coins)_$($_.Type)-$($Instance)"
      $_.InstanceNumber = $($Instance)
      $PIDFile = "$($_.Instance)_PID.txt"

      if(Test-Path $PIDFile)
        {
         $MinerContent = Get-Content $PIDFile
         $MinerProcess = Get-Process -Id $MinerContent -ErrorAction SilentlyContinue
         if($null -ne $MinerProcess){$_.XProcess = $MinerProcess}
        }
      }
      $Instance++
      if($Restart -eq $true){
       if($null -eq $_.XProcess -or $_.XProcess.HasExited){
        $_.Status = "Failed"
        $NoMiners = "Yes"
        Write-Host "$($_.MinerName) Failed To Launch" -ForegroundColor Darkred
       }
       else
       {
        $_.Status = "Running"
        Write-Host "$($_.MinerName) Is Running!" -ForegroundColor Green
       }
      }
     }
    }
   }
$MinerWatch.Restart()

##Notify User Of Failures
if($NoMiners -eq $true)
{
  Write-Host "
       
       
       
  There are miners that have failed! Check Your Settings And Arguments!
  https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration) >> Right Click 'Open URL In Browser'


  " -foreground Darkred
  Start-Sleep -s 20
}

#Notify User Of Delay
if($Restart -eq $true)
 {
   Write-Host "
                

Waiting 20 Seconds For Miners To Load & Restarting Background Tracking

Type 'mine' in another terminal to see miner working- This is NOT a remote command!

Type 'get-screen [MinerType]' to see last 100 lines of log- This IS a remote command!

https://github.com/MaynardMiner/SWARM/wiki/HiveOS-management >> Right Click 'Open URL In Browser'  


   " -foreground Magenta
   Start-Sleep -s 20
 }

 ##Notify User No Miners Started
 else
 {
   Write-Host "
        
        
   Most Profitable Miners Are Running


   " -foreground DarkCyan
   Start-Sleep -s 5
 }

 ##Get Active Miners For Display
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

##Get Details Of All Miners
function Get-MinerStatus {
       Write-Host "
                                                                           (                    (      *     
                                                                            )\ ) (  (      (     )\ ) (  `    
                                                                            (()/( )\))(   ' )\   (()/( )\))(   
                                                                             /(_)|(_)()\ |(((_)(  /(_)|(_)()\  
                                                                            (_)) _(())\_)()\ _ )\(_)) (_()((_) 
                                                                            / __|\ \((_)/ (_)_\(_) _ \|  \/  | 
                                                                            \__ \ \ \/\/ / / _ \ |   /| |\/| | 
                                                                            |___/  \_/\_/ /_/ \_\|_|_\|_|  |_| 
                                                                                                                                                     " -foregroundcolor "DarkRed"
        Write-Host "                                                                                     Sudo Apt-Get Lambo" -foregroundcolor "Yellow"
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        $Y = [string]$CoinExchange
	      $H = [string]$Currency
      	$J = [string]'BTC'
    $BTCExchangeRate = Invoke-WebRequest "https://min-api.cryptocompare.com/data/pricemulti?fsyms=$Y&tsyms=$J" -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty $Y | Select-Object -ExpandProperty $J
    $CurExchangeRate = Invoke-WebRequest "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$H" -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty $J | Select-Object -ExpandProperty $H
    Write-Host "1 $CoinExchange = " "$Exchanged"  "$Currency" -foregroundcolor "Yellow"
    $ProfitTable | Where {$_.Profits -ge 1E-5 -or $null -eq $_.Profits} | Sort-Object -Property Type,Profits -Descending | Format-Table -GroupBy Type (
        @{Label = "Miner"; Expression={$($_.Miner)}},
        @{Label = "Coin"; Expression={$($_.Name)}},
        @{Label = "Speed"; Expression={$($_.HashRates) | ForEach {if($null -ne $_){"$($_ | ConvertTo-Hash)/s"}else{"Bench"}}}; Align='center'},
        @{Label = "BTC/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){  $_.ToString("N5")}else{"Bench"}}}; Align='right'},
        @{Label = "$Y/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){  ($_ / $BTCExchangeRate).ToString("N5")}else{"Bench"}}}; Align='right'},
        @{Label = "$Currency/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){($_ / $BTCExchangeRate * $Exchanged).ToString("N3")}else{"Bench"}}}; Align='center'},
        @{Label = "Pool"; Expression={$($_.MinerPool)}; Align='center'}
            )
      }

#Check For Bechmark
$BenchmarkMode = $false
$ActiveMinerPrograms | Foreach {
if($null -eq (Get-Item ".\Stats\$($_.Name)_$($_.Algo)_HashRate.txt" -ErrorAction SilentlyContinue))
 {
  $BenchmarkMode = $true
 }
}

#Set Interval
if($BenchmarkMode -eq $true){$MinerInterval = $Benchmark}
else{$MinerInterval = $Interval}

#Clear Logs If There Are 12
if($Log -eq 12)
 {
  Remove-Item ".\Logs\*miner*"
  $Log = 0
}

#Start Another Log If An Hour Has Passed
if($LogTimer.Elapsed.TotalSeconds -ge 3600)
 {
  Stop-Transcript
  if(Test-Path ".\Logs\*Active*")
  {
   Set-Location ".\Logs"
   $OldActiveFile = Get-ChildItem "*Active*"
   $OldActiveFile | Foreach {
    $RenameActive = $_ -replace ("-Active","")
    if(Test-Path $RenameActive){Remove-Item $RenameActive -Force}
    Rename-Item $_ -NewName $RenameActive -force
    }
   Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
  }
  $Log++
  Start-Transcript ".\Logs\miner$($Log)-Active.log"
  $LogTimer.Restart()
 }
 
##Write Details Of Active Miner And Stats To File
$StatusDate = Get-Date
$StatusDate | Out-File ".\Build\Unix\Hive\mineractive.sh"
Get-MinerActive | Out-File ".\Build\Unix\Hive\mineractive.sh" -Append
Clear-Content ".\Build\Unix\Hive\minerstats.sh" -Force
$StatusDate | Out-File ".\Build\Unix\Hive\minerstats.sh"
Get-MinerStatus | Out-File ".\Build\Unix\Hive\minerstats.sh" -Append
$mcolor = "93"
$me = [char]27
$MiningStatus = "$me[${mcolor}mCurrently Mining $($BestMiners_Combo.Algo) Algorithm${me}[0m"
$MiningStatus | Out-File ".\Build\Unix\Hive\minerstats.sh" -Append
if($Favor_Coins -eq "Yes")
 {
  if($BenchmarkMode -eq $false)
   {
$Crazy = "No- You are not crazy. Algorithms are removed from this list so that coin is at the top. See github wik FAQ section as to why."
$CrazyLink = "https://github.com/MaynardMiner/Swarm/wiki/FAQ >> Right Click 'Open URL In Browser"
$Crazy | Out-File ".\Build\Unix\Hive\minerstats.sh" -Append
$CrazyLink | Out-File ".\Build\Unix\Hive\minerstats.sh" -Append
   }
 }

##Function To Check And See If Miners Are Running- Restart If Not
function Restart-Miner {

$ActiveMinerPrograms | Foreach {
  $Restart = $false
  if($_.BestMiner -eq $true)
   {
   if($_.XProcess -eq $null -or $_.XProcess.HasExited)
    {
    $Restart = $true
    $DecayStart = Get-Date
    $_.New = $true
    $_.Activated++
    $CurrentLog = ".\Logs\$($_.Type).log"
    if(Test-Path $CurrentLog){Clear-Content $CurrentLog -Force}
    $LogDir = Join-Path $Dir "Logs\$($_.Type).log"
    Rename-Item $_.Path -NewName "$($_.Type)-$($Instance)" -Force
    $MinerDir = Split-Path $_.Path
    if($null -eq $_.Devices){$GPUGrouping = $LogGPUS}
    else{$GPUGrouping = $_.Devices}
    $LaunchCodes = @{}
    $LaunchCodes.Add("Type",$_.Type)
    $LaunchCodes.Add("Logs",$LogDir)
    $LaunchCodes.Add("Name",$_.Name)
    $LaunchCodes.Add("MinerName",$_.MinerName)
    $LaunchCodes.Add("Path",$_.Path)
    $LaunchCodes.Add("Coins",$_.Coins)
    $LaunchCodes.Add("CmdDir",$CmdDir)
    $LaunchCodes.Add("MinerDir",$MinerDir)
    $LaunchCodes.Add("Delay",$Delay)
    $LaunchCodes.Add("Algos",$_.Algo)
    $LaunchCodes.Add("GPUGroup",$GPUGrouping)
    $LaunchCodes.Add("APIs",$_.API)
    $LaunchCodes.Add("Ports",$_.Port)
    $LaunchCodes.Add("MDir",$Dir)
    $LaunchCodes.Add("MinerInstance","$($_.Type)-$($Instance)")
    if($_.Arguments -ne "none"){$LaunchCodes.Add("Arguments","$($_.Arguments)")}
    if($null -ne $_.Connection){$LaunchCodes.Add("Connection","$($_.Connection)")}
    if($null -ne $_.Username){$LaunchCodes.Add("Username","$($_.Username)")}
    if($null -ne $_.Password){$LaunchCodes.Add("Password","$($_.Password)")}
    if($null -ne $_.DeviceCall){$LaunchCodes.Add("DeviceCall",$_.DeviceCall)}
    if($null -ne $_.Devices){$LaunchCodes.Add("Devices",$_.Devices)}

    Start-LaunchCode @LaunchCodes

    $_.Instance = ".\Build\PID\$($_.Name)_$($_.Coins)_$($_.Type)-$($Instance)"
    $_.InstanceNumber = $($Instance)
    $PIDFile = "$($_.Instance)_PID.txt"

    if(Test-Path $PIDFile)
     {
     $MinerContent = Get-Content $PIDFile
     $MinerProcess = Get-Process -Id $MinerContent -ErrorAction SilentlyContinue
     if($null -ne $MinerProcess){$_.XProcess = $MinerProcess}
     }
  
    $Instance++
    }
    if($Restart -eq $true)
     {
     if($null -eq $_.XProcess -or $_.XProcess.HasExited)
      {
      $_.Status = "Failed"
      Write-Host "$($_.MinerName) Failed To Launch" -ForegroundColor Darkred
      }
    else
     {
      $_.Status = "Running"
      Write-Host "$($_.MinerName) Is Running!" -ForegroundColor Green
     }

   Write-Host "
        
        
        
   Waiting 20 Seconds For Miners To Fully Load



   " 
   Start-Sleep -s 20
      }

    }
   }
  }

##Function To Display HashRate On Screen
function Get-MinerHashRate {
  
$ActiveMinerPrograms | Foreach {
  if($_.BestMiner -eq $true)
  {
   if($null -eq $_.Xprocess -or $_.XProcess.HasExited){$_.Status = "Failed"}
   $Miner_HashRates = Get-HashRate -API $_.API -Port $_.Port -CPUThreads $CPUThreads
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
	 Start-Sleep -S 2
	 Write-Host "$($_.Type) previous hashrates for $($_.Coins) is" -nonewline
	 Write-Host " $MinerPrevious/s" -foreground yellow
  }
 }
}

##Function To Adjust/Set Countdown On Screen
function Set-Countdown {
 
$Countdown = ([math]::Round(($MinerInterval-20) - $MinerWatch.Elapsed.TotalSeconds))
$CountMessage = "Time Left Until Database Starts: $($Countdown)" 
$GetActive = Get-Content ".\Build\Unix\Hive\mineractive.sh"
$ReplaceActive = $GetActive | Select -skipLast 1
$ReplaceActive += $CountMessage
$ReplaceActive | Set-Content ".\Build\Unix\Hive\mineractive.sh"      
Write-Host $CountMessage -foreground Gray

}

##Restart Database/Break Loop And Continue If No Hash Is Detected
function Restart-Database {
     
$Restart = "No"

$ActiveMinerPrograms | foreach {
  if($_.BestMiner -eq $true)
  {
   if($null -eq $_.XProcess -or $_.XProcess.HasExited)
   {
    $_.Status = "Failed"
    $Restart = "Yes"
   }
 else
  {
   $Miner_HashRates = Get-HashRate -API $_.API -Port $_.Port -CPUThreads $CPUThreads
   $ScreenHash = "$($Miner_HashRates | ConvertTo-Hash)"
   if($ScreenHash -eq "0.00PH")
    {
     $_.Status = "Failed"
     $Restart = "Yes"
    }
   }
  }
 }
$Restart
}

##Remove Old Jobs From Memory
Get-Job -State Completed | Remove-Job
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
[GC]::Collect()

##Miner Loop
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
  Restart-Miner
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
  Restart-Miner
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
  $RestartData = Restart-Database
  if($RestartData -eq "Yes"){break}

}While($MinerWatch.Elapsed.TotalSeconds -lt ($MinerInterval-20))
      
      
##Benchmarking/Timeout      
$ActiveMinerPrograms | foreach {
if($_.BestMiner -eq $true)
 {
 if($null -eq $_.XProcess -or $_.XProcess.HasExited)
  {
   $_.Status = "Failed"
   $_.WasBenchMarked = $False  
  }
  else
   { 
   if($TimeDeviation -ne 0)
    {
     $_.HashRate = 0
     $_.WasBenchmarked = $False
     $Miner_HashRates = Get-HashRate -API $_.API -Port $_.Port -CPUThreads $CPUThreads
     $_.Timeout = 0
     $_.HashRate = $Miner_HashRates
     $WasActive = [math]::Round(((Get-Date)-$_.XProcess.StartTime).TotalSeconds)
     if($WasActive -ge $StatsInterval)
      {
	     Write-Host "$($_.Name) $($_.Coins) Was Active for $WasActive Seconds"
	     Write-Host "Attempting to record hashrate for $($_.Name) $($_.Coins)" -foregroundcolor "Cyan"
       for($i=0; $i -lt 4; $i++)
        {
        if($_.WasBenchmarked -eq $False)
         {
         if(-not (Test-Path "Backup")){New-Item "Backup" -ItemType "directory" | Out-Null}
         Write-Host "$($_.Name) $($_.Coins) Starting Bench"
	       $HashRateFilePath = Join-Path ".\Stats" "$($_.Name)_$($_.Algo)_HashRate.txt"
         $NewHashrateFilePath = Join-Path ".\Backup" "$($_.Name)_$($_.Algo)_HashRate.txt"
         if($null -eq $Miner_HashRates -or $Miner_HashRates -eq 0)
          {
           $_.Timeout++
           Write-Host "Stat Attempt Yielded 0" -Foregroundcolor Red
           Start-Sleep -S .25
          }
         else
          {            
           $Stat = Set-Stat -Name "$($_.Name)_$($_.Algo)_HashRate" -Value $Miner_HashRates
           Start-Sleep -s 1
           $GetLiveStat = Get-Stat "$($_.Name)_$($_.Algo)_HashRate"
           $StatCheck = "$($GetLiveStat.Live)"
           $ScreenCheck = "$($StatCheck | ConvertTo-Hash)"
           if($ScreenCheck -eq "0.00 PH" -or $null -eq $StatCheck)
            {
             $_.Timeout++
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
             $_.New = $False
             $_.WasBenchmarked = $True
	           Write-Host "Stat Written" -foregroundcolor green
             $_.Timeout = 0
             $_.Bad_Benchmark = 0
            } 
           }
          }
         }
        }
       }
      }
		 

if($_.Timeout -gt 2 -or $null -eq $_.XProcess -or $_.XProcess.HasExited)
 {
  if($_.WasBenchmarked -eq $False)
   {
    if (-not (Test-Path ".\Timeout")) {New-Item "Timeout" -ItemType "directory" | Out-Null}
    $TimeoutFile = Join-Path ".\Timeout" "$($_.Name)_$($_.Algo)_TIMEOUT.txt"
    $HashRateFilePath = Join-Path ".\Stats" "$($_.Name)_$($_.Algo)_HashRate.txt"
    $_.Bad_Benchmark++
    if(-not (Test-Path $TimeoutFile)){"$($_.Name) $($_.Coins) Hashrate Check Timed Out $($_.Bad_Benchmark) Times" | Set-Content ".\Timeout\$($_.Name)_$($_.Algo)_TIMEOUT.txt" -Force}
    $_.WasBenchmarked = $True
    $_.New = $False
    $_.Timeout = 0
    Write-Host "$($_.Name) $($_.Coins) Hashrate Check Timed Out $($_.Bad_Benchmark) Times- It Was Noted In Timeout Folder" -foregroundcolor "darkred"
    if$($_.Bad_Benchmark -eq 3){$Stat = Set-Stat -Name "$($_.Name)_$($_.Algo)_HashRate" -Value 0}
    Write-Host "Benchmarking Has Failed - Setting Stat To 0. Delete Stat In Stats Folder To Reset" -ForegroundColor DarkRed
    }
   }
  }
 }
}
 
  #Stop the log
  Stop-Transcript
  Get-Date | Out-File ".\Build\Data\TimeTable.txt"
