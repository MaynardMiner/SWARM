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
    [String]$Wallet1,  ##Group 1 Wallet
    [Parameter(Mandatory=$false)]
    [String]$Wallet2, ##Group 2 Wallet
    [Parameter(Mandatory=$false)]
    [String]$Wallet3, ##Group 3 Wallet
    [Parameter(Mandatory=$false)]
    [String]$Nicehash_Wallet1,  ##Group 1 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$Nicehash_Wallet2,  ##Group 2 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$Nicehash_Wallet3,  ##Group 3 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$AltWallet1,  ##Group 3 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$AltWallet2,  ##Group 3 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$AltWallet3,  ##Group 3 Nicehash Wallet
    [Parameter(Mandatory=$false)]
    [String]$RigName1 = "SWARM1",  ##ID=Rigname (Yiimp Pool) Group 1
    [Parameter(Mandatory=$false)]
    [String]$RigName2 = "SWARM2",  ##ID=Rigname (Yiimp Pool) Group 2
    [Parameter(Mandatory=$false)]
    [String]$RigName3 = "SWARM3", ##ID=Rigname (Yiimp Pool) Group 3
    [Parameter(Mandatory=$false)]
    [Int]$API_ID = 0, ##Future Implentation
    [Parameter(Mandatory=$false)]
    [String]$API_Key = "", ##Future Implementation
    [Parameter(Mandatory=$false)]
    [Int]$Timeout = 24,  ##Hours Before Mine Clears All Hashrates/Profit 0 files
    [Parameter(Mandatory=$false)]
    [Int]$Interval = 300, #seconds before reading hash rate from miners
    [Parameter(Mandatory=$false)] 
    [Int]$StatsInterval = 1, #seconds of current active to gather hashrate if not gathered yet 
    [Parameter(Mandatory=$false)]
    [String]$Location = "US", #europe/us/asia
    [Parameter(Mandatory=$false)]
    [Array]$Type = ("NVIDIA1"), #AMD/NVIDIA/CPU
    [Parameter(Mandatory=$false)]
    [String]$GPUDevices1, ##Group 1 all miners
    [Parameter(Mandatory=$false)] 
    [String]$GPUDevices2, ##Group 2 all miners
    [Parameter(Mandatory=$false)]
    [String]$GPUDevices3, ##Group 3 all miners
    [Parameter(Mandatory=$false)]
    [Array]$PoolName = ("nlpool","blockmasters","ahashpool"), 
    [Parameter(Mandatory=$false)]
    [Array]$Currency = ("USD"), #i.e. GBP,EUR,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$Passwordcurrency1 = "BTC", #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$Passwordcurrency2 = "BTC", #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [string]$Passwordcurrency3 = "BTC", #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$AltPassword1 = '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$AltPassword2 =  '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [String]$AltPassword3 = '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [Int]$Donate = .5, #Percent per Day
    [Parameter(Mandatory=$false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080 
    [Parameter(Mandatory=$false)]
    [String]$CoinExchange = "LTC",
    [Parameter(Mandatory=$false)]
    [string]$Auto_Coin = "No",
    [Parameter(Mandatory=$false)]
    [Int]$Nicehash_Fee = "2",
    [Parameter(Mandatory=$false)]
    [Int]$Benchmark = 180,
    [Parameter(Mandatory=$false)]
    [array]$No_Algo = "",
    [Parameter(Mandatory=$false)]
    [String]$Favor_Coins = "Yes",
    [Parameter(Mandatory=$false)]
    [double]$Threshold = .02,
    [Parameter(Mandatory=$false)]
    [string]$Platform = "linux",
    [Parameter(Mandatory=$false)]
    [int]$CPUThreads = 1,
    [Parameter(Mandatory=$false)]
    [string]$Stat_Coin = "Live",
    [Parameter(Mandatory=$false)]
    [string]$Stat_Algo = "Live",
    [Parameter(Mandatory=$false)]
    [string]$CPUOnly = "No",
    [Parameter(Mandatory=$false)]
    [string]$HiveOS = "Yes",
    [Parameter(Mandatory=$false)]
    [string]$Update = "No",
    [Parameter(Mandatory=$false)]
    [string]$Cuda = "9.2",
    [Parameter(Mandatory=$false)]
    [string]$Power = "Yes",
    [Parameter(Mandatory=$false)]
    [string]$WattOMeter = "No",
    [Parameter(Mandatory=$false)]
    [string]$HiveID,
    [Parameter(Mandatory=$false)]
    [string]$HivePassword,
    [Parameter(Mandatory=$false)]
    [string]$Farm_Hash,
    [Parameter(Mandatory=$false)]
    [string]$HiveMirror,
    [Parameter(Mandatory=$false)]
    [Double]$Rejections = 75,
    [Parameter(Mandatory=$false)]
    [string]$PoolBans = "Yes",
    [Parameter(Mandatory=$false)]
    [Int]$PoolBanCount = 2,
    [Parameter(Mandatory=$false)]
    [Int]$AlgoBanCount = 3,
    [Parameter(Mandatory=$false)]
    [Int]$MinerBanCount = 4,    
    [Parameter(Mandatory=$false)]
    [String]$Lite = "No",
    [Parameter(Mandatory=$false)]
    [String]$AMDPlatform,
    [Parameter(Mandatory=$false)]
    [String]$Conserve = "No"
)

Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

$CurrentParams = @{}
$CurrentParams.Add("Wallet",$Wallet)
$CurrentParams.Add("Wallet1",$Wallet1)
$CurrentParams.Add("Wallet2",$Wallet2)
$CurrentParams.Add("Wallet3",$Wallet3)
$CurrentParams.Add("Nicehash_Wallet1",$Nicehash_Wallet1)
$CurrentParams.Add("Nicehash_Wallet2",$Nicehash_Wallet2)
$CurrentParams.Add("Nicehash_Wallet3",$Nicehash_Wallet3)
$CurrentParams.Add("AltWallet1",$AltWallet1)
$CurrentParams.Add("AltWallet2",$AltWallet2)
$CurrentParams.Add("AltWallet3",$AltWallet3)
$CurrentParams.Add("Passwordcurrency1",$Passwordcurrency1)
$CurrentParams.Add("Passwordcurrency2",$Passwordcurrency2)
$CurrentParams.Add("Passwordcurrency3",$Passwordcurrency3)
$CurrentParams.Add("AltPassword1",$AltPassword1)
$CurrentParams.Add("AltPassword2",$AltPassword2)
$CurrentParams.Add("AltPassword3",$AltPassword3)
$CurrentParams.Add("Rigname1",$RigName1)
$CurrentParams.Add("Rigname2",$RigName2)
$CurrentParams.Add("Rigname3",$RigName3)
$CurrentParams.Add("API_ID",$API_ID)
$CurrentParams.Add("API_Key",$API_Key)
$CurrentParams.Add("Timeout",$Timeout)
$CurrentParams.Add("Interval",$Interval)
$CurrentParams.Add("StatsInterval",$StatsInterval)
$CurrentParams.Add("Location",$Location)
$CurrentParams.Add("Type",$Type)
$CurrentParams.Add("GPUDevices1",$GPUDevices1)
$CurrentParams.Add("GPUDevices2",$GPUDevices2)
$CurrentParams.Add("GPUDevices3",$GPUDevices3)
$CurrentParams.Add("Poolname",$PoolName)
$CurrentParams.Add("Currency",$Currency)
$CurrentParams.Add("Donate",$Donate)
$CurrentParams.Add("Proxy",$Proxy)
$CurrentParams.Add("CoinExchange",$CoinExchange)
$CurrentParams.Add("Auto_Coin",$Auto_Coin)
$CurrentParams.Add("Nicehash_Fee",$Nicehash_Fee)
$CurrentParams.Add("Benchmark",$Benchmark)
$CurrentParams.Add("No_Algo",$No_Algo)
$CurrentParams.Add("Favor_Coins",$Favor_Coins)
$CurrentParams.Add("Threshold",$Threshold)
$CurrentParams.Add("Platform",$Platform)
$CurrentParams.Add("CPUThreads",$CPUThreads)
$CurrentParams.Add("Stat_Coin",$Stat_Coin)
$CurrentParams.Add("Stat_Algo",$Stat_Algo)
$CurrentParams.Add("CPUOnly",$CPUOnly)
$CurrentParams.Add("HiveOS",$HiveOS)
$CurrentParams.Add("Update",$Update)
$CurrentParams.Add("Cuda",$Cuda)
$CurrentParams.Add("WattOMeter",$WattOMeter)
$CurrentParams.Add("HiveId",$HiveId)
$CurrentParams.Add("Farm_Hash",$Farm_Hash)
$CurrentParams.Add("HivePassword",$HivePassword)
$CurrentParams.Add("HiveMirror",$HiveMirror)
$CurrentParams.Add("Rejections",$Rejections)
$CurrentParams.Add("PoolBans",$PoolBans)
$CurrentParams.Add("PoolBanCount",$PoolBanCount)
$CurrentParams.Add("AlgoBanCount",$AlgoBanCount)
$CurrentParams.Add("MinerBanCount",$MinerBanCount)
$CurrentParams.Add("Conserve",$Conserve)
if($Platform -eq "windows"){$CurrentParams.Add("AMDPlatform",$AMDPlatform)}
$CurrentParams.Add("Lite",$Lite)
$StartParams = $CurrentParams | ConvertTo-Json 
$StartingParams = $CurrentParams | ConvertTo-Json -Compress
$StartParams | Set-Content ".\config\parameters\arguments.json"
if(Test-Path ".\config\parameters\newarguments.json")
{
Write-Host "Detected New Arguments- Changing Parameters" -ForegroundColor Cyan
$NewParams = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
Start-Sleep -S 2
$NewParams | Convertto-Json | Set-Content ".\config\parameters\arguments.json"
$StartParams = $NewParams
$StartingParams = $NewParams | ConvertTo-Json -Compress
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
$Conserve = $SWARMParams.Conserve
if($Platform -eq "windows"){$AMDPlatform = $SWARMParams.AMDPlatform}
}

$Wallets = @()
$Walletlist = @{}
if(Test-Path ".\wallet\keys"){$Oldkeys = Get-ChildItem ".\wallet\keys"}
if($Oldkeys){Remove-Item ".\wallet\keys\*" -Force}

if($AltWallet1){$Walletlist.Add("AltWallet1",$AltWallet1)};
if($AltWallet2){$Walletlist.Add("AltWallet2",$AltWallet2)};
if($AltWallet3){$Walletlist.Add("AltWallet3",$AltWallet3)};
if($Wallet1){$Walletlist.Add("Wallet1",$Wallet1)};
if($Wallet2){$Walletlist.Add("Wallet2",$Wallet2)};
if($Wallet3){$Walletlist.Add("Wallet3",$Wallet3)};
if($NiceHash_Wallet1){$Walletlist.Add("NiceHash_Wallet1",$NiceHash_Wallet1)};
if($NiceHash_Wallet2){$Walletlist.Add("NiceHash_Wallet2",$NiceHash_Wallet2)};
if($NiceHash_Wallet3){$Walletlist.Add("NiceHash_Wallet3",$NiceHash_Wallet3)};
if(-Not (Test-Path ".\wallet\wallets")){new-item -Path ".\wallet" -Name "wallets" -ItemType "directory" | Out-Null}
$WalletList | ConvertTO-Json | Set-Content ".\wallet\wallets\wallets.txt"

if($Wallet1){$Wallets += [PSCustomObject]@{Wallet="Wallet1"; address=$Wallet1; Symbol=$PasswordCurrency1;Response="";Unsold="";Current=""}}
if($Wallet2 -and $Wallet2 -ne $Wallet1){$Wallets += [PSCustomObject]@{Wallet="Wallet2"; address=$Wallet2; Symbol=$PasswordCurrency2;Response="";Unsold="";Current=""}}
if($Wallet3 -and $Wallet3 -ne $Wallet2 -and $Wallet3 -ne $Wallet1){$Wallets += [PSCustomObject]@{Wallet="Wallet3"; address=$Wallet3; Symbol=$PasswordCurrency3;Response="";Unsold="";Current=""}}
if($AltWallet1){$Wallets += [PSCustomObject]@{Wallet="AltWallet1"; address=$AltWallet1; Symbol=$AltPassword1;Response="";Unsold="";Current=""}}
if($AltWallet2 -and $AltWallet2 -ne $ALtWallet1){$Wallets += [PSCustomObject]@{Wallet="AltWallet2"; address=$AltWallet2; Symbol=$AltPassword2;Response="";Unsold="";Current=""}}
if($AltWallet3 -and $AltWallet3 -ne $AltWallet2 -and $AltWallet3 -ne $AltWallet1){$Wallets += [PSCustomObject]@{Wallet="AltWallet3"; address=$AltWallet3; Symbol=$AltPassword3;Response="";Unsold="";Current=""}}
if($Nicehash_Wallet1){$Wallets += [PSCustomObject]@{Wallet="Nicehash_Wallet1"; address=$Nicehash_Wallet1; Symbol="NHBTC";Response="";Unsold="";Current=""}}
if($Nicehash_Wallet2 -and $Nicehash_Wallet2 -ne $Nicehash_Wallet1){$Wallets += [PSCustomObject]@{Wallet="Nicehash_Wallet2"; address=$Nicehash_Wallet2; Symbol="NHBTC";Response="";Unsold="";Current=""}}
if($Nicehash_Wallet3 -and $Nicehash_Wallet3 -ne $Nicehash_Wallet2 -and $Nicehash_Wallet3 -ne $Nicehash_Wallet1){$Wallets += [PSCustomObject]@{Wallet="Nicehash_Wallet3"; address=$Nicehash_Wallet3; Symbol="NHBTC";Response="";Unsold="";Current=""}}
if(-Not (Test-Path ".\wallet\keys")){new-item -Path ".\wallet" -Name "keys" -ItemType "directory" | Out-Null}
$Wallets | %{ $_ | ConvertTo-Json | Set-Content ".\wallet\keys\$($_.Wallet).txt"}


$Platform | Set-Content ".\build\txt\os.txt"

$Version = Split-Path ($script:MyInvocation.MyCommand.Path) -Parent
$Version = Split-Path $Version -Leaf
$Version = $Version -replace ".ps1",""
$Version = $Version -replace "SWARM.","v"

if($HiveOS -eq "Yes" -and $Platform -eq "linux"){Start-Process ".\build\bash\screentitle.sh" -Wait}
Get-ChildItem . -Recurse -Force | Out-Null 
if($Platform -eq "Windows"){$Platform = "windows"}
if($Platform -eq "Linux"){$Platform = "linux"}
$Type | foreach {
 if($_ -eq "amd1"){$_ = "AMD1"}
 if($_ -eq "nvidia1"){$_ = "NVIDIA1"}
 if($_ -eq "nvidia2"){$_ = "NVIDIA2"}
 if($_ -eq "nvidia2"){$_ = "NVIDIA3"}
 if($_ -eq "cpu"){$_ = "CPU"}
}
if(-not (Test-Path ".\build\txt")){New-Item -Path ".\build" -Name "txt" -ItemType "directory" | Out-Null}

. .\build\powershell\killall.ps1
. .\build\powershell\startlog.ps1
. .\build\powershell\remoteupdate.ps1
. .\build\powershell\datafiles.ps1
. .\build\powershell\algorithm.ps1
. .\build\powershell\statcommand.ps1
. .\build\powershell\poolcommand.ps1
. .\build\powershell\minercommand.ps1
. .\build\powershell\launchcode.ps1
. .\build\powershell\datefiles.ps1
. .\build\powershell\watchdog.ps1
. .\build\powershell\miners.ps1
. .\build\powershell\sorting.ps1
. .\build\powershell\download.ps1
. .\build\powershell\hashrates.ps1
. .\build\powershell\naming.ps1
. .\build\powershell\childitems.ps1
. .\build\powershell\powerup.ps1
. .\build\powershell\peekaboo.ps1
. .\build\powershell\checkbackground.ps1
. .\build\powershell\maker.ps1
. .\build\powershell\intensity.ps1
. .\build\powershell\poolbans.ps1
. .\build\powershell\cl.ps1
if($Type -like "*ASIC*"){. .\build\powershell\icserver.ps1; . .\build\powershell\poolmanager.ps1}
if($Platform -eq "linux"){. .\build\powershell\getbestunix.ps1; . .\build\powershell\sexyunixlogo.ps1; . .\build\powershell\gpu-count-unix.ps1}
if($Platform -eq "windows"){. .\build\powershell\getbestwin.ps1; . .\build\powershell\sexywinlogo.ps1; . .\build\powershell\bus.ps1;}

##Start The Log
$dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$dir | set-content ".\build\bash\dir.sh"
start-log -Platforms $Platform -HiveOS $HiveOS

##filepath dir
$build = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build")
$pwsh = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\powershell")
$bash = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\linux")
$windows = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\windows")
$data = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\data")
$txt = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\txt")
$swarmstamp = "SWARMISBESTMINEREVER"

if($Platform -eq "windows")
 {
  [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", "User")
  $Cuda = "10"
  Start-Fans
  if(-not (Test-Path "C:\Program Files\NVIDIA Corporation\NVSMI\nvml.dll"))
  {
    Write-Host "nvml.dll is missing" -ForegroundColor Red
    Start-Sleep -S 3
    Write-Host "To Fix:" -ForegroundColor Blue
    Write-Host "Copy `"\build\apps\nvml.dll`" to `"C:\Program Files\NVIDIA Corporation\NVSMI\`"" -ForegroundColor Blue
    Start-Sleep -S 3
    Write-Host "Closing Miner"
    Start-Sleep -S 1
    exit
  }
 }


if($Platform -eq "windows")
{
  $TotalMemory = (systeminfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
  $TotalMemory = $TotalMemory -replace (",","")
  $TotalMemory = $TotalMemory -replace ("MB","")
  $TotalMemory | Set-Content ".\build\txt\ram.txt"
}

##Start Kill-Script
if($Platform -eq "linux"){start-killscript}

##Version Information & Remote Update

if($platform -eq "linux")
{
$cuda | Out-file ".\build\txt\cuda.txt" -Force
start-update -Update $update
  if($HiveOS -eq "Yes"){
  Write-Host "Getting Data"
  Get-Data -CmdDir $dir
  if($Type -like "*AMD*"){
    [string]$AMDPlatform = get-AMDPlatform -Platforms $Platform
    Write-Host "AMD OpenCL Platform is $AMDPlatform"
    }
  }
}

Write-Host "HiveOS = $HiveOS"
#Startings Settings:
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
$ActiveMinerPrograms = @()
$Naming = Get-Content ".\config\naming\get-pool.json" | ConvertFrom-Json
$DonationMode = $false
if($Platform -eq "windows"){$GetBusData = $GetBusData = Get-BusFunctionID | ConvertTo-Json -Compress}
if($Platform -eq "windows" -and $HiveOS -eq "Yes")
{
Start-Peekaboo -HiveID $HiveID -HiveMirror $HiveMirror -HivePassword $HivePassword -GPUData $GetBusData; $hiveresponse
$newid = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
$HiveID = $newId.HiveID
$HivePassword = $NewId.HivePassword
$StartingParams = $newid | ConvertTo-Json -Compress
$newid = $null
}

#Timers
$TimeoutTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$TimeoutTimer.Start()
$logtimer = New-Object -TypeName System.Diagnostics.Stopwatch
$logtimer.Start()
if($Lite -Eq "Yes"){Start-Process ".\build\bash\apiserver.sh" -Wait}

##Load Previous Times & PID Data
Get-DateFiles

##Remove Exclusion
try{if((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)){Start-Process powershell -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath '$(Convert-Path .)'"}}catch{}

##Proxy
if($Proxy -eq ""){$PSDefaultParameterValues.Remove("*:Proxy")}
else{$PSDefaultParameterValues["*:Proxy"] = $Proxy}

##Check for lib & restart agent
if($Platform -eq "linux" -and $HiveOS -eq "Yes")
{
Start-Process ".\build\bash\libc.sh" -wait
Start-Process ".\build\bash\libv.sh" -wait
}

if($Platform -eq "linux")
 {
#Start Watchdog
start-watchdog
 }
$PID | Set-Content ".\build\pid\miner_pid.txt"

if(Test-Path ".\build\txt\nvidiapower.txt"){Remove-Item ".\build\txt\nvidiapower.txt" -Force}
if(Test-path ".\build\txt\amdpower.txt"){Remove-Item ".\build\txt\amdpower.txt" -Force}

##Threads
if($Platform -eq "linux"){$GPU_Count = Get-GPUCount -DeviceType $Type -Platforms $Platform -CPUThreads $CPUThreads}
elseif($Platform -eq "windows"){
$GPU_Count = Get-GPUCount $GetBusData
}
if($GPU_Count -ne 0){$GPUCount = @(); for($i=0; $i -lt $GPU_Count; $i++){[string]$GPUCount += "$i,"}}
if($CPUThreads -ne 0){$CPUCount = @(); for($i=0; $i -lt $CPUThreads; $i++){[string]$CPUCount += "$i,"}}
if($GPU_Count -eq 0){$Device_Count = $CPUThreads}
else{$Device_Count = $GPU_Count}
Write-Host "Device Count = $Device_Count" -foregroundcolor green
Start-Sleep -S 2
if($GPUCount -ne $null){$LogGPUS = $GPUCount.Substring(0,$GPUCount.Length-1)}
if($CPUCount -ne $null){$LogCPUS = $CPUCount.Substring(0,$CPUCount.Length-1)}
$NVIDIADevices1 = $GPUDevices1
$NVIDIADevices2 = $GPUDevices2
$NVIDIADevices3 = $GPUDevices3
$AMDDevices1 = $GPUDevices1

##GPU Count & Miner Type
if($Platform -eq "linux")
{
$Type | Foreach {
if($_ -eq "NVIDIA1"){
"NVIDIA1" | Out-File ".\build\bash\minertype.sh" -Force
Write-Host "Group 1 is NVIDIA- Commands and Stats will work for NVIDIA1" -foreground yellow
Start-Sleep -S 3
}
if($_ -eq "AMD1"){
"AMD1" | Out-File ".\build\bash\minertype.sh" -Force
Write-Host "Group 1 is AMD- Commands and Stats will work for AMD1" -foreground yellow
Start-Sleep -S 3
}
if($_ -eq "CPU"){
if($GPU_Count -eq 0){
"CPU" | Out-File ".\build\bash\minertype.sh" -Force
Write-Host "Group 1 is CPU- Commands and Stats will work for CPU" -foreground yellow
Start-Sleep -S 3
   }
  }
 }
}


##Reset-Old Stats
if(Test-Path "stats"){Get-ChildItemContent "stats" | ForEach {$Stat = Set-Stat $_.Name $_.Content.Week}}

##Logo
if($Platform -eq "windows"){Get-SexyWinLogo}
elseif($Platform -eq "linux"){Get-SexyUnixLogo}
 
#Get-Algorithms
$Algorithm = @()
$Warnings = @()
$NeedsToBeBench = $false
$Algorithm = Get-Algolist -Devices $Type -No_Algo $No_Algo

#Get-Update Files
if($Type -like "*CPU*"){$cpu = get-minerfiles -Types "CPU" -Platforms $Platform}
if($Type -like "*NVIDIA*"){$nvidia = get-minerfiles -Types "NVIDIA" -Platforms $Platform -Cudas $Cuda}
if($Type -like "*AMD*"){$amd = get-minerfiles -Types "AMD" -Platforms $Platform}

While($true)
{
##Manage Pool Bans
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
$Conserve = $SWARMParams.Conserve
if($Platform -eq "windows"){$AMDPlatform = $SWARMParams.AMDPlatform}

if($SWARMParams.Rigname1 -eq "Donate"){$Donating = $True}
else{$Donating = $False}
if($Donating -eq $True){$Test = Get-Date; $DonateTest = "Miner has donated on $Test"; $DonateTest | Set-Content ".\build\txt\donate.txt"}

if($Type -notlike "*ASIC*")
{
##Save Watt Calcs
if($Watts){$Watts | ConvertTo-Json | Out-File ".\config\power\power.json"}
##OC-Settings
$OC = Get-Content ".\config\oc\oc-settings.json" | ConvertFrom-Json
##Reset Coins
$CoinAlgo = $null  
##Get Watt Configuration
$Watts = get-content ".\config\power\power.json" | ConvertFrom-Json
##Check Time Parameters
$MinerWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$TimeoutTime = $Timeout*3600
$DecayExponent = [int](((Get-Date)-$DecayStart).TotalSeconds/$DecayPeriod)
 
##Get Price Data
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


##Load File Stats
if($TimeoutTimer.Elapsed.TotalSeconds -lt $TimeoutTime -or $Timeout -eq 0){$Stats = Get-Stats -Timeouts "No"}
else
{
 Get-Stats -Timeouts "Yes"
 $TimeoutTimer.Restart()
 continue
}

##GetPools
Write-Host "Checking Algo Pools" -Foregroundcolor yellow
$AllAlgoPools = Get-Pools -PoolType "Algo" -Stats $Stats
$AlgoPools = @()
$AlgoPools_Comparison = @()
$AllAlgoPools.Symbol | Select -Unique | ForEach {$AlgoPools += ($AllAlgoPools | Where Symbol -EQ $_ | Sort-Object Price -Descending | Select -First 3)}
$AllAlgoPools.Symbol | Select -Unique | ForEach {$AlgoPools_Comparison += ($AllAlgoPools | Where Symbol -EQ $_ | Sort-Object StablePrice -Descending | Select -First 3)}

##Load Only Needed Algorithm Miners
Write-Host "Checking Algo Miners"
$AlgoMiners = Get-Miners -Platforms $Platform -Stats $Stats -Pools $AlgoPools

##Re-Name Instance In Case Of Crashes
if($Lite -eq "No")
 {
$AlgoMiners | ForEach {
  $AlgoMiner = $_
  if(-not (Test-Path $AlgoMiner.path))
  {
   if(Test-Path (Split-Path $Algominer.Path))
   {
    Set-Location (Split-Path $AlgoMiner.Path)
    if(Test-Path "*$($_.Type)*")
    {
    $OldInstance = Get-ChildItem "*$($AlgoMiner.Type)-*"
    Rename-Item $OldInstance -NewName "$($AlgoMiner.MinerName)" -force
    }
    Set-Location $Dir
   }
  }
 }
}

##Download Miners
$Download = $false
if($Lite -eq "No")
{
$GetAlgoMiners = @()
$AlgoMiners | ForEach {
$AlgoMiner = $_
if(Test-Path ".\timeout\download_block\download_block.txt"){$DLTimeout = Get-Content ".\timeout\download_block\download_block.txt"}
$DLName = $DLTimeout | Select-String "$($AlgoMiner.Name)"
if($DLName.Count -lt 3)
 {
 if((Test-Path $AlgoMiner.Path) -eq $false)
  {
   Expand-WebRequest -URI $AlgoMiner.URI -BuildPath $AlgoMiner.BUILD -Path (Split-Path $AlgoMiner.Path) -MineName (Split-Path $AlgoMiner.Path -Leaf) -MineType $AlgoMiner.Type
   $Download = $true
   if(-not (Test-Path $ALgoMiner.Path))
    {
     if(-not (Test-Path ".\timeout\download_block")){New-Item -Name "download_block" -Path ".\timeout" -ItemType "directory"}
     "$($Algominer.Name)" | Add-Content ".\timeout\download_block\download_block.txt"
    }
  }
 else{$GetAlgoMiners += $AlgoMiner}
   }
 else{Write-Host "$($AlgoMiner.Name) download failed too many times- Blocking" -ForegroundColor Red}
  }
 $Algominers = $GetAlgoMiners
 $GetAlgoMiners = $Null
 $DLTimeout  = $null
 $DlName = $Null
 }
if($Download -eq $true){continue}

$NewAlgoMiners = @()
$Type | Foreach {
$GetType = $_; 
$AlgoMiners.Symbol | Select -Unique | foreach {
$zero = $AlgoMiners | Where Type -eq $GetType | Where Hashrates -match $_ | Where Quote -EQ 0; 
if($zero)
{
 $zerochoice = $zero | Sort-Object Quote -Descending | Select -First 1; 
 if(-not ($NewAlgoMiners | Where Name -EQ $zerochoice.Name | Where Arguments -EQ $zerochoice.Arguments))
  {
   $NewAlgoMiners += $zerochoice
  }
}
else
{
 $nonzero = $AlgoMiners | Where Type -eq $GetType | Where Hashrates -match $_ | Where Quote -NE 0; 
 $nonzerochoice = $nonzero | Sort-Object Quote -Descending | Select -First 1; 
 if(-not ($NewAlgoMiners | Where Name -EQ $nonzerochoice.Name | Where Arguments -EQ $nonzerochoice.Arguments))
   {
    $NewAlgoMiners += $nonzerochoice
   }
  }
 }
}
$AlgoMiners = $NewAlgoMiners
if($AlgoMiners.Count -eq 0){"No Miners!" | Out-Host; start-sleep $Interval; continue}

##Sort Algorithm Miners
start-minersorting -Command "Algo" -Stats $Stats -Pools $AlgoPools -Pools_Comparison $AlgoPools_Comparison -SortMiners $AlgoMiners -DBase $DecayBase -DExponent $DecayExponent -WattCalc $WattEx
$ActiveMinerPrograms | ForEach {$AlgoMiners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit}}
$GoodAlgoMiners = @()
$AlgoMiners | Foreach {if($_.Profit -lt $Threshold -or $_.Profit -eq $null){$GoodAlgoMiners += $_}}
$Miners = @()
$GoodAlgoMiners | foreach {$Miners += $_}
if($Platform -eq "windows"){$BestAlgoMiners_Combo = Get-BestWin -SortMiners $Miners}
elseif($Platform -eq "linux"){$BestAlgoMiners_Combo = Get-BestUnix -SortMiners $Miners}
if($Conserve = "Yes"){$BestMiners_Combo = $BestAlgoMiners_Combo | Where {$_.Profit -eq $null -or $_.Profit -gt 0}}
else{$BestMiners_Combo = $BestAlgoMiners_Combo}

##Define Wallet Estimates:


##check if Auto_Coin is working- Start Coin Sorting
#if($Auto_Coin -eq "Yes")
#{
##Determine Benchmark Mode
#$NeedsToBeBench = $false
#$BestAlgoMiners_Combo | foreach {if($_.Profit -eq $null){$NeedsToBeBench = $true; Write-Host "Coins Disabled - Benchmarking Required." -foreground yellow}}

#if($NeedsToBeBench -eq $false)
#{ 
#Get Specfic Coin Algorithms
#$CoinAlgo = $Algorithm
#Write-Host "CoinPools Are Active: Searching For Coins" -ForegroundColor Magenta

#Load Coin Pools
#$AllCoinPools = Get-Pools -PoolType "Coin" -Stats $Stats
#$CoinPools = [PSCustomObject]@{}
#$CoinPools_Comparison = [PSCustomObject]@{}
#$AllCoinPools.Symbol | Select -Unique | ForEach {$CoinPools | Add-Member $_ ($AllCoinPools | Where Symbol -EQ $_)}
#$AllCoinPools.Symbol | Select -Unique | ForEach {$CoinPools_Comparison | Add-Member $_ ($AllCoinPools | Where Symbol -EQ $_)}

#Load Coin Miners
#$CoinMiners = Get-Miners -Platforms $Platform -Stats $Stats -Pools $CoinPools
#if($CoinMiners -ne $null){start-minersorting -Command "Coin" -Stats $Stats -Pools $CoinPools -Pools_Comparison $CoinPools_Comparison -SortMiners $CoinMiners -DBase $DecayBase -DExponent $DecayExponent -WattCalc $WattEx}
#$Miners = @()
#if($BestAlgoMiners_Combo.MinerPool -like "*algo*")
#{
# if($Favor_Coins -eq "Yes"){Write-Host "User Specified To Favor Coins & Best Pool Is CoinPool: Factoring Only Coins";$Miners = $CoinMiners | Where Profit -lt $Threshold}
# else{$Miners = $CoinMiners | Where Profit -lt $Threshold;$BestAlgoMiners_Combo | foreach {$Miners += $_}}
#}
#else{$Miners = $CoinMiners | Where Profit -lt $Threshold; $BestAlgoMiners_Combo | foreach {$Miners += $_}}

#$ActiveMinerPrograms | ForEach {$Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit}}
#if($Platform -eq "windows"){$BestMiners_Combo = Get-BestWin -SortMiners $Miners}
#elseif($Platform -eq "linux"){$BestMiners_Combo = Get-BestUnix -SortMiners $Miners}

#if($Favor_Coins -eq "Yes")
#{
#$Miners = @()
#$NewCoinSymbol = @()
#$ProfitsArray = @()
#$NewCoinAlgo = @()

#$BestMiners_Combo | Foreach {$NewCoinSymbol += [PSCustomObject]@{"$($_.Type)" = "$($_.Symbol)"}}  
#$BestMiners_Combo | Foreach {$NewCoinAlgo += [PSCustomObject]@{"$($_.Type)" = "$($_.Algo)"}}  
#$BestMiners_Combo | Foreach {$ProfitsArray += [PSCustomObject]@{"$($_.Type)" = $($_.Profit)}}

#$Type | Foreach {
#$Selected = $_
#$TypeAlgoMiners = $GoodAlgoMiners | Where Type -eq $Selected
# $TypeAlgoMiners | Foreach{
#  if($NewCoinSymbol.$($_.Type) -ceq $($_.Symbol)){$Miners += $_}
#  else
#  {
#   if($NewCoinAlgo.$($_.Type) -cne $($_.Algo))
 #  {
  # if($ProfitsArray.$($_.Type) -gt $($_.Profit)){$Miners += $_}
  # }
  #}
 #}
#}
#$CoinMiners | foreach {$Miners += $_}
#}

 #else{$Miners = @(); $GoodAlgoMiners | foreach {$Miners += $_}; $CoinMiners | foreach {$Miners += $_}}
 #}
#}

##Write On Screen Best Choice  
$BestMiners_Selected = $BestMiners_Combo.Symbol
$BestPool_Selected = $BestMiners_Combo.MinerPool 
Write-Host "Most Ideal Choice Is $($BestMiners_Selected) on $($BestPool_Selected)" -foregroundcolor green          

 ##Build Stats Table
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
  oc_core = $_.occore
  oc_mem = $_.ocmem
  ocp_ower = $_.ocpower
  oc_v = $_.ocv
  oc_dpm = $_.ocdpm
  oc_mdpm = $_.ocmdpm
  oc_fans = $_.ocfans
 }
}
if(-not $ActiveMinerPrograms){$Type | foreach{if(Test-Path ".\logs\$($_).log"){remove-item ".\logs\$($_).log" -Force}}}
##Add Instance Settings To Miners For Tracking

$BestMiners_Combo | ForEach {
 if(-not ($ActiveMinerPrograms | Where Path -eq $_.Path | Where Arguments -eq $_.Arguments ))
  {
   if($_.Type -eq "CPU"){$LogType = $LogCPUS}
   if($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*")
    {
     if($_.Devices -eq $null){$LogType = $LogGPUS}
     else{$LogType = $_.Devices}
    }
  $ActiveMinerPrograms += [PSCustomObject]@{
   Delay = $_.Delay
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
   Active = [TimeSpan]0
   Activated = 0
   Status = "Idle"
   HashRate = 0
   Benchmarked = 0
   WasBenchmarked = $false
   XProcess = $null
   MinerPool = $_.MinerPool
   Algo = $_.Algo
   FullName = $_.FullName
   Instance = $null
   InstanceName = $null
   Username = $_.Username
   Connection = $_.Connection
   Password = $_.Password
   BestMiner = $false
   JsonFile = $_.Config
   LogGPUS = $LogType
   FirstBad = $null
   Prestart = $_.Prestart
   ocpl = $_.ocpl
   ocdpm = $_.ocdpm
   ocv = $_.ocv
   occore = $_.occore
   ocmem = $_.ocmem
   ocmdpm = $_.ocmdpm
   ocpower = $_.ocpower
   ocfans = $_.ocfans
   ethpill = $_.ethpill
   pilldelay = $_.pilldelay
   quote = 0
   NPool = $_.NPool
   NUser = $_.NUser
   CommandFile = $_.CommandFile
   }
  }
 }

$Restart = $false
$NoMiners = $false
$ConserveMessage = @()

#Determine Which Miner Should Be Active
$BestActiveMiners = @()
$ActiveMinerPrograms | foreach {
if($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments){$_.BestMiner = $true; $BestActiveMiners += $_}
else{$_.BestMiner = $false}
}

$Type | foreach{
  $TypeSel = $_
  if(-not $BestMiners_Combo | Where Type -eq $TypeSel)
   {    
    $ConseverMessage += "Stopping $($_) due to conserve mode being specified"
    if($Platform -eq "linux")
    {
     $ActiveMinerPrograms | ForEach {
        if($_.BestMiner -eq $false)
         {
          if($_.XProcess = $null){$_.Status = "Failed"}
          else
           {
            $_.Status = "Idle"
            $PIDDate = ".\build\pid\$($_.Name)_$($_.Coins)_$($_.InstanceName)_date.txt"
            if(Test-path $PIDDate)
             {
              $PIDDateFile = Get-Content $PIDDate | Out-String
              $PIDTime = [DateTime]$PIDDateFile
              $_.Active += (Get-Date)-$PIDTime
              Start-Process ".\build\bash\killall.sh" -ArgumentList "$($TypeSel)" -Wait
             }
             }
            }
           }
         }
        }
      }

if($ConserveMessage){$ConserveMessage | %{Write-Host "$_" -ForegroundColor Red}}
$Y = [string]$CoinExchange
$H = [string]$Currency
$J = [string]'BTC'
$BTCExchangeRate = Invoke-WebRequest "https://min-api.cryptocompare.com/data/pricemulti?fsyms=$Y&tsyms=$J" -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty $Y | Select-Object -ExpandProperty $J

function Get-MinerStatus {
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
$GetStatusDownloadBans = ".\timeout\download_block\download_block.txt"
if(Test-Path $GetStatusDownloadBans){$StatusDownloadBans = Get-Content $GetStatusDownloadBans}
else{$StatusDownloadBans = $null}
$GetDLBans = @();
if($StatusDownloadBans){$StatusDownloadBans | %{if($GetDLBans -notcontains $_){$GetDlBans+=$_}}}
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
if($GetDLBans){$GetDLBans | foreach {$BanMessage += "$me[${mcolor}m$($_) failed to download${me}[0m"}}
if($ConserveMessage){$ConserveMessage | foreach {$BanMessage += "$me[${mcolor}m$($_)${me}[0m"}}
$BanMessage | Out-File ".\build\bash\minerstats.sh" -Append
$BestActiveMiners | ConvertTo-Json | Out-File ".\build\txt\bestminers.txt"
$Current_BestMiners = $BestActiveMiners | ConvertTo-Json -Compress
$BackgroundDone = "No"

function Get-StatusLite {
  $ProfitTable | Sort-Object -Property Type,Profits -Descending | Format-Table -GroupBy Type (
    @{Label = "Miner"; Expression={$($_.Miner)}},
    @{Label = "Speed"; Expression={$($_.HashRates) | ForEach {if($null -ne $_){"$($_ | ConvertTo-Hash)/s"}else{"Bench"}}}; Align='center'},
    @{Label = "$Currency/Day"; Expression={$($_.Profits) | ForEach {if($null -ne $_){($_ * $Rates.$Currency).ToString("N2")}else{"Bench"}}}; Align='center'},
    @{Label = "   Pool"; Expression={$($_.MinerPool)}; Align='center'}
     )
  }

$StatusLite = Get-StatusLite
$StatusDate | Out-File ".\build\bash\minerstatslite.sh"
$StatusLite | OUt-File ".\build\bash\minerstatslite.sh" -Append
$MiningStatus | Out-File ".\build\bash\minerstatslite.sh" -Append
$BanMessage | Out-File ".\build\bash\minerstatslite.sh" -Append

$ActiveMinerPrograms | ForEach {
if($_.BestMiner -eq $false)
 {
  if($Platform -eq "windows")
   {
   if($_.XProcess -eq $null){$_.Status = "Failed"}
   elseif($_.XProcess.HasExited -eq $false)
    {
     $_.Active += (Get-Date)-$_.XProcess.StartTime
     $_.XProcess.CloseMainWindow() | Out-Null
     $_.Status = "Idle"
    }
   }
  elseif($Platform -eq "linux")
   {
    if($_.XProcess = $null){$_.Status = "Failed"}
    else
     {
      $_.Status = "Idle"
      $PIDDate = ".\build\pid\$($_.Name)_$($_.Coins)_$($_.InstanceName)_date.txt"
      if(Test-path $PIDDate)
       {
        $PIDDateFile = Get-Content $PIDDate | Out-String
        $PIDTime = [DateTime]$PIDDateFile
        $_.Active += (Get-Date)-$PIDTime   
       }
      }
     }
    }
 elseif($null -eq $_.XProcess -or $_.XProcess.HasExited -and $Lite -eq "No")
  {
   if($TimeDeviation -ne 0)
    {
     $Restart = $true
     $_.Activated++
     $_.InstanceName = "$($_.Type)-$($Instance)"
     $Current = $_ | ConvertTo-Json -Compress
     $_.Xprocess = Start-LaunchCode -Platforms $Platform -MinerRound $Current_BestMiners -NewMiner $Current -Background $BackgroundDone
     $BackgroundDone = "Yes"
     $_.Instance = ".\build\pid\$($_.Type)-$($Instance)"
     $PIDFile = "$($_.Name)_$($_.Coins)_$($_.InstanceName)_pid.txt"
     $Instance++
    }
    if($Restart -eq $true)
     {
     if($_.XProcess -eq $null -or $_.Xprocess.HasExited -eq $true)
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
     }
    }
   }

  $MinerWatch.Restart()

if($Restart -eq $true -and $NoMiners -eq $true)
{
##Notify User Of Failures
  Write-Host "
       
       
       
  There are miners that have failed! Check Your Settings And Arguments!
  Type `'mine`' in another terminal to see background miner, and its reason for failure.
  If miner is not your primary miner (AMD1 or NVIDIA1), type 'screen -r [Type]'
  https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration) >> Right Click 'Open URL In Browser'


  " -foreground Darkred
  Start-Sleep -s 20
}
#Notify User Of Delay
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
##Notify User No Miners Started
if($Restart -eq $false)
 {
  Write-Host "
        
        
  Most Profitable Miners Are Running


  " -foreground DarkCyan
  Start-Sleep -s 5
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
else{$MinerInterval = $Interval}

##Mem cleanup
$AlgoMiner = $Null
$AlgoMiners = $Null
$AlgoPools = $Null
$AlgoPools_Comparison = $Null
$AllAlgoPools = $Null
$BestAlgoMiners_Combo = $Null
$BestMiners_Combo = $Null
$BestPool_Selected = $Null
$GoodAlgoMiners = $null
$Name = $Null
$Miners = $Null
$NewAlgoMiners = $Null
$Nonzerochoice = $Null
$Stat = $Null
$GetSWARMParams = $null

if($Lite -eq "Yes"){
$UsePools = $false
$ProfitTable | foreach{if($_.Profits -ne $null){$UsePools = $true}}
if($UsePools -eq $false){$APITable = $ProfitTable | Sort-Object -Property Type,Profits -Descending}
else{$APITable = $ProfitTable | Sort-Object -Property Type,Pool_Estimate}
$APITable | ConvertTo-Json -Depth 4 | Set-Content ".\build\txt\profittable.txt"
Start-BackgroundCheck -Platforms $Platform
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
        Write-Host "                                                                                     sudo apt-get lambo" -foregroundcolor "Yellow"
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
}

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
     Start-Sleep -S .25
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
	 Write-Host " $MinerPrevious/s" -foreground yellow
 }
}

##Function To Adjust/Set Countdown On Screen
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

##Remove Old Jobs From Memory
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
}
else
{
  Clear-Host
  Get-MinerActive | Out-Host
  Get-MinerStatus | Out-Host
  Get-VM | Out-Host
  $BanMessage
Do{
   Restart-Miner
   if($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval-20)){break}
   Start-Sleep -s 30
}While($MinerWatch.Elapsed.TotalSeconds -lt ($MinerInterval-20))
}

if($Platform -eq "linux" -or $Platform -eq "windows")
{
if($WattOMeter -eq "Yes")
 {
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
Get-Power -PwrType $Type -Platforms $Platform
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
 }
}



##Benchmarking/Timeout      
$BestActiveMiners | foreach {
$MinerPoolBan = $false
$MinerAlgoBan = $false
$MinerBan = $false
$Strike = $false
if($_.BestMiner -eq $true)
 {
  if($null -eq $_.XProcess -or $_.XProcess.HasExited)
  {
   $_.Status = "Failed"
   $_.WasBenchMarked = $False
   $Strike = $true
   Write-Host "Cannot Benchmark- Miner is not running" -ForegroundColor Red
  }
  else
  { 
   if($TimeDeviation -ne 0)
   {
    $_.HashRate = 0
    $_.WasBenchmarked = $False
    $Miner_HashRates = Get-HashRate -Type $_.Type
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
        $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($_.Algo)_hashrate.txt"
        $PowerFilePath = Join-Path ".\stats" "$($_.Name)_$($_.Algo)_power.txt"
        $NewHashrateFilePath = Join-Path ".\backup" "$($_.Name)_$($_.Algo)_hashrate.txt"
        $NewPowerFilePath = Join-Path ".\backup" "$($_.Name)_$($_.Algo)_power.txt"
        if(-not (Test-Path "backup")){New-Item "backup" -ItemType "directory" | Out-Null}
        Write-Host "$($_.Name) $($_.Coins) Starting Bench"
        if($null -eq $Miner_HashRates -or $Miner_HashRates -eq 0)
        {
         $Strike = $true
         Write-Host "Stat Attempt Yielded 0" -Foregroundcolor Red
         Start-Sleep -S .25
         $GPUPower = 0
         if($WattOMeter -eq "yes" -and $_.Type -ne "CPU")
          {
          if($Watts.$($_.Algo))
           {
            $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
           }
           else
           {
            $WattTypes = @{NVIDIA1_Watts="";NVIDIA2_Watts="";NVIDIA3_Watts="";AMD1_Watts="";CPU_Watts=""}
            $Watts | Add-Member "$($_.Algo)" $WattTypes
            $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
           }
          }
         }
         else
          {
           if($WattOMeter -eq "yes" -and $_.Type -ne "CPU"){try{$GPUPower = Set-Power -MinerDevices $($_.Devices) -Command "stat" -PwrType $($_.Type)}catch{Write-Host "WattOMeter Failed" $GPUPower = 0}}
           else{$GPUPower = 1}
           if($WattOMeter -eq "yes" -and $_.Type -ne "CPU")
            {
             if($Watts.$($_.Algo))
              {
               $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
              }
             else
              {
               $WattTypes = @{NVIDIA1_Watts="";NVIDIA2_Watts="";NVIDIA3_Watts="";AMD1_Watts="";CPU_Watts=""}
               $Watts | Add-Member "$($_.Algo)" $WattTypes
               $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
              }
            }
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
             if($WattOmeter -eq "Yes"){Write-Host "Watt-O-Meter scored $($_.Name) $($_.Coins) at $($GPUPower) Watts" -ForegroundColor magenta}
             if(-not (Test-Path $NewHashrateFilePath))
              {
               Copy-Item $HashrateFilePath -Destination $NewHashrateFilePath -force
               Write-Host "$($_.Name) $($_.Coins) Was Benchmarked And Backed Up" -foregroundcolor yellow
              }
             $_.WasBenchmarked = $True
             $Current = $_ | ConvertTo-Json -Compress
             Get-Intensity $Current
	           Write-Host "Stat Written" -foregroundcolor green
             $Strike = $false
            } 
           }
          }
         }
      ##Check For High Rejections
      $RejectCheck = Join-Path ".\timeout\warnings" "$($_.Name)_$($_.Algo)_rejection.txt"
      if(Test-Path $RejectCheck)
       {
        Write-Host "Rejections Are Too High" -ForegroundColor DarkRed
        $_.WasBenchmarked = $false
        $Strike = $true
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
else{Start-ASIC}
}
  #Stop the log
  Stop-Transcript

