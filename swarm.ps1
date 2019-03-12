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
    [Parameter(Mandatory = $false)]
    [String]$Wallet = "Yes", ##Miner Can Load Pools
    [Parameter(Mandatory = $false)]
    [String]$Wallet1, ##Group 1 Wallet
    [Parameter(Mandatory = $false)]
    [String]$Wallet2, ##Group 2 Wallet
    [Parameter(Mandatory = $false)]
    [String]$Wallet3, ##Group 3 Wallet
    [Parameter(Mandatory = $false)]
    [String]$Nicehash_Wallet1, ##Group 1 Nicehash Wallet
    [Parameter(Mandatory = $false)]
    [String]$Nicehash_Wallet2, ##Group 2 Nicehash Wallet
    [Parameter(Mandatory = $false)]
    [String]$Nicehash_Wallet3, ##Group 3 Nicehash Wallet
    [Parameter(Mandatory = $false)]
    [String]$AltWallet1, ##Group 3 Nicehash Wallet
    [Parameter(Mandatory = $false)]
    [String]$AltWallet2, ##Group 3 Nicehash Wallet
    [Parameter(Mandatory = $false)]
    [String]$AltWallet3, ##Group 3 Nicehash Wallet
    [Parameter(Mandatory = $false)]
    [String]$RigName1 = "SWARM1", ##ID=Rigname (Yiimp Pool) Group 1
    [Parameter(Mandatory = $false)]
    [String]$RigName2 = "SWARM2", ##ID=Rigname (Yiimp Pool) Group 2
    [Parameter(Mandatory = $false)]
    [String]$RigName3 = "SWARM3", ##ID=Rigname (Yiimp Pool) Group 3
    [Parameter(Mandatory = $false)]
    [Int]$API_ID = 0, ##Future Implentation
    [Parameter(Mandatory = $false)]
    [String]$API_Key = "", ##Future Implementation
    [Parameter(Mandatory = $false)]
    [Int]$Timeout = 24, ##Hours Before Mine Clears All Hashrates/Profit 0 files
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 300, #seconds before reading hash rate from miners
    [Parameter(Mandatory = $false)] 
    [Int]$StatsInterval = 1, #seconds of current active to gather hashrate if not gathered yet 
    [Parameter(Mandatory = $false)]
    [String]$Location = "US", #europe/us/asia
    [Parameter(Mandatory = $false)]
    [Array]$Type = ("NVIDIA1"), #AMD/NVIDIA/CPU
    [Parameter(Mandatory = $false)]
    [array]$GPUDevices1, ##Group 1 all miners
    [Parameter(Mandatory = $false)] 
    [array]$GPUDevices2, ##Group 2 all miners
    [Parameter(Mandatory = $false)]
    [array]$GPUDevices3, ##Group 3 all miners
    [Parameter(Mandatory = $false)]
    [Array]$PoolName = ("nlpool", "blockmasters", "ahashpool"), 
    [Parameter(Mandatory = $false)]
    [Array]$Currency = ("USD"), #i.e. GBP,EUR,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [String]$Passwordcurrency1 = "BTC", #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [String]$Passwordcurrency2 = "BTC", #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [string]$Passwordcurrency3 = "BTC", #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [String]$AltPassword1 = '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [String]$AltPassword2 = '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [String]$AltPassword3 = '', #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [Int]$Donate = .5, #Percent per Day
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080 
    [Parameter(Mandatory = $false)]
    [String]$CoinExchange = "LTC",
    [Parameter(Mandatory = $false)]
    [string]$Auto_Coin = "No",
    [Parameter(Mandatory = $false)]
    [Int]$Nicehash_Fee = "2",
    [Parameter(Mandatory = $false)]
    [Int]$Benchmark = 190,
    [Parameter(Mandatory = $false)]
    [array]$No_Algo1 = "",
    [Parameter(Mandatory = $false)]
    [array]$No_Algo2 = "",    
    [Parameter(Mandatory = $false)]
    [array]$No_Algo3 = "",
    [Parameter(Mandatory = $false)]
    [String]$Favor_Coins = "Yes",
    [Parameter(Mandatory = $false)]
    [double]$Threshold = 0.02,
    [Parameter(Mandatory = $false)]
    [string]$Platform = "linux",
    [Parameter(Mandatory = $false)]
    [int]$CPUThreads = 1,
    [Parameter(Mandatory = $false)]
    [string]$Stat_Coin = "Live",
    [Parameter(Mandatory = $false)]
    [string]$Stat_Algo = "Live",
    [Parameter(Mandatory = $false)]
    [string]$CPUOnly = "No",
    [Parameter(Mandatory = $false)]
    [string]$HiveOS = "Yes",
    [Parameter(Mandatory = $false)]
    [string]$Update = "No",
    [Parameter(Mandatory = $false)]
    [string]$Cuda = "10",
    [Parameter(Mandatory = $false)]
    [string]$Power = "Yes",
    [Parameter(Mandatory = $false)]
    [string]$WattOMeter = "No",
    [Parameter(Mandatory = $false)]
    [string]$Farm_Hash,
    [Parameter(Mandatory = $false)]
    [Double]$Rejections = 75,
    [Parameter(Mandatory = $false)]
    [string]$PoolBans = "Yes",
    [Parameter(Mandatory = $false)]
    [Int]$PoolBanCount = 2,
    [Parameter(Mandatory = $false)]
    [Int]$AlgoBanCount = 3,
    [Parameter(Mandatory = $false)]
    [Int]$MinerBanCount = 6,    
    [Parameter(Mandatory = $false)]
    [String]$Lite = "No",
    [Parameter(Mandatory = $false)]
    [String]$AMDPlatform,
    [Parameter(Mandatory = $false)]
    [String]$Conserve = "No",
    [Parameter(Mandatory = $false)]
    [Double]$Switch_Threshold = 1,
    [Parameter(Mandatory = $false)]
    [String]$SWARM_Mode = "No",
    [Parameter(Mandatory = $false)]
    [String]$API = "Yes",
    [Parameter(Mandatory = $false)]
    [String]$CLPlatform = "",
    [Parameter(Mandatory = $false)]
    [int]$Port = 4099,
    [Parameter(Mandatory = $false)]
    [String]$Remote = "No",
    [Parameter(Mandatory = $false)]
    [String]$APIPassword = "No",
    [Parameter(Mandatory = $false)]
    [String]$Startup = "Yes",
    [Parameter(Mandatory = $false)]
    [String]$ETH,
    [Parameter(Mandatory = $false)]
    [String]$Worker,
    [Parameter(Mandatory = $false)]
    [array]$No_Miner,
    [Parameter(Mandatory = $false)]
    [string]$HiveAPIkey,
    [Parameter(Mandatory = $false)]
    [array]$Algorithm,
    [Parameter(Mandatory = $false)]
    [array]$Coin
)


## Set Current Path
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

if(Test-Path "C:\"){$Platform = "windows"}
else{$Platform = "linux"}

Write-Host "OS = $Platform"

## Load Codebase
. .\build\powershell\killall.ps1;
. .\build\powershell\startlog.ps1;
. .\build\powershell\remoteupdate.ps1;
. .\build\powershell\datafiles.ps1;
. .\build\powershell\statcommand.ps1;
. .\build\powershell\poolcommand.ps1;
. .\build\powershell\minercommand.ps1;
. .\build\powershell\launchcode.ps1;
. .\build\powershell\datefiles.ps1;
. .\build\powershell\watchdog.ps1;
. .\build\powershell\download.ps1;
. .\build\powershell\hashrates.ps1;
. .\build\powershell\naming.ps1;
. .\build\powershell\childitems.ps1;
. .\build\powershell\powerup.ps1;
. .\build\powershell\peekaboo.ps1;
. .\build\powershell\checkbackground.ps1;
. .\build\powershell\maker.ps1;
. .\build\powershell\intensity.ps1;
. .\build\powershell\poolbans.ps1;
. .\build\powershell\cl.ps1;
. .\build\powershell\newsort.ps1;
. .\build\powershell\screen.ps1;
. .\build\powershell\commandweb.ps1;
. .\build\powershell\response.ps1;
. .\build\powershell\api.ps1;
. .\build\powershell\config_file.ps1;
if ($Type -like "*ASIC*") {. .\build\powershell\icserver.ps1; . .\build\powershell\poolmanager.ps1}
if ($Platform -eq "linux") {. .\build\powershell\sexyunixlogo.ps1; . .\build\powershell\gpu-count-unix.ps1}
if ($Platform -eq "windows") {. .\build\powershell\hiveoc.ps1; . .\build\powershell\sexywinlogo.ps1; . .\build\powershell\bus.ps1; }

##filepath dir
$dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$env:Path += ";$dir\build\cmd"
$Workingdir = (Split-Path $script:MyInvocation.MyCommand.Path)
$build = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build")
$pwsh = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\powershell")
$bash = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\linux")
$windows = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\windows")
$data = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\data")
$txt = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\txt")
$swarmstamp = "SWARMISBESTMINEREVER"
if (-not (Test-Path ".\build\txt")) {New-Item -Name "txt" -ItemType "Directory" -Path ".\build" | Out-Null}
$Platform | Set-Content ".\build\txt\os.txt"

## Initiate Update Check
if ($Platform -eq "Windows") {$GetUpdates = "Yes"}
else {$GetUpdates = $Update}
start-update -Update $Getupdates -Dir $dir -Platforms $Platform

##Load Previous Times & PID Data
## Close Previous Running Agent- Agent is left running to send stats online, even if SWARM crashes
if ($Platform -eq "windows") {
    $dir | Set-Content ".\build\cmd\dir.txt"
    $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
    if($oldpath -notlike "*;$dir\build\cmd*")
     {
      Write-Host "
Setting Path Variable For Commands: May require reboot to use.
" -ForegroundColor Yellow
      $newpath = "$oldpath;$dir\build\cmd"
      Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
     }
    $newpath = "$oldpath;$dir\build\cmd"
    Write-Host "Stopping Previous Agent"
    $ID = ".\build\pid\background_pid.txt"
    if (Test-Path $ID) {$Agent = Get-Content $ID}
    if ($Agent) {$BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue}
    if ($BackGroundID.name -eq "powershell") {Stop-Process $BackGroundID | Out-Null}
    $ID = ".\build\pid\pill_pid.txt"
    if (Test-Path $ID) {$Agent = Get-Content $ID}
    if ($Agent) {$BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue}
    if ($BackGroundID.name -eq "powershell") {Stop-Process $BackGroundID | Out-Null}
}

##Start Date Collection
Get-DateFiles
Start-Sleep -S 1
$PID | Out-File ".\build\pid\miner_pid.txt"

## Change console icon and title
if ($Platform -eq "windows") {
    $host.ui.RawUI.WindowTitle = "SWARM";
    Start-Process "powershell" -ArgumentList "-command .\build\powershell\icon.ps1 `".\build\apps\SWARM.ico`"" -NoNewWindow
}

## Get Child Items
Get-ChildItem . -Recurse -Force | Out-Null

## Crash Reporting
if ($Platform -eq "windows") {Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime | % {$Boot = [math]::Round(((Get-Date) - $_.LastBootUpTime).TotalSeconds)}}
elseif ($Platform -eq "linux") {$Boot = Get-Content "/proc/uptime" | % {$_ -split " " | Select -First 1}};
if ([Double]$Boot -lt 600) {
    if ((Test-Path ".\build\txt") -and (Test-Path ".\logs")) {
        Write-Warning "SWARM was started in 600 seconds of last boot. Generating a crash report to logs directory";
        $Report = "crash_report_$(Get-Date)";
        $Report = $Report | % {$_ -replace ":", "_"} | % {$_ -replace "\/", "-"} | % {$_ -replace " ", "_"};
        New-Item -Path ".\logs" -Name $Report -ItemType "Directory" | Out-Null;
        Get-ChildItem ".\build\txt" | Copy-Item -Destination ".\logs\$Report";
        $TypeLogs = @("NVIDIA1", "AMD1", "NVIDIA2", "NVIDIA3", "CPU", "ASIC")
        $TypeLogs | % {$TypeLog = ".\logs\$($_).log"; if (Test-Path $TypeLog) {Copy-Item -Path $TypeLog -Destination ".\logs\$Report" | Out-Null}}
        $ActiveLog = Get-ChildItem "logs"; $ActiveLog = $ActiveLog.Name | Select-String "active"
        if ($ActiveLog) {if (test-path ".\logs\$ActiveLog") {Copy-Item -Path ".\logs\$ActiveLog" -Destination ".\logs\$Report" | Out-Null}}
        Start-Sleep -S 3
    }
}

##Clear Old Agent Stats
$FileClear = @()
$FileClear += ".\build\txt\minerstats.txt"
$FileClear += ".\build\txt\hivestats.txt"
$FileClear += ".\build\txt\mineractive.txt"
$FileClear += ".\build\bash\hivecpu.sh"
$FileClear += ".\build\txt\profittable.txt"
$FileClear += ".\build\txt\bestminers.txt"
$FileClear | % {if (Test-Path $_) {Remove-Item $_ -Force}}

## Debug Mode- Allow you to run with last known arguments or arguments.json.
$Debug = $false

## Convert Arguments Into Hash Table
if ($Debug -ne $true) {
    $CurrentParams = @{}
    $CurrentParams.Add("Wallet", $Wallet)
    $CurrentParams.Add("Wallet1", $Wallet1)
    $CurrentParams.Add("Wallet2", $Wallet2)
    $CurrentParams.Add("Wallet3", $Wallet3)
    $CurrentParams.Add("Nicehash_Wallet1", $Nicehash_Wallet1)
    $CurrentParams.Add("Nicehash_Wallet2", $Nicehash_Wallet2)
    $CurrentParams.Add("Nicehash_Wallet3", $Nicehash_Wallet3)
    $CurrentParams.Add("AltWallet1", $AltWallet1)
    $CurrentParams.Add("AltWallet2", $AltWallet2)
    $CurrentParams.Add("AltWallet3", $AltWallet3)
    $CurrentParams.Add("Passwordcurrency1", $Passwordcurrency1)
    $CurrentParams.Add("Passwordcurrency2", $Passwordcurrency2)
    $CurrentParams.Add("Passwordcurrency3", $Passwordcurrency3)
    $CurrentParams.Add("AltPassword1", $AltPassword1)
    $CurrentParams.Add("AltPassword2", $AltPassword2)
    $CurrentParams.Add("AltPassword3", $AltPassword3)
    $CurrentParams.Add("Rigname1", $RigName1)
    $CurrentParams.Add("Rigname2", $RigName2)
    $CurrentParams.Add("Rigname3", $RigName3)
    $CurrentParams.Add("API_ID", $API_ID)
    $CurrentParams.Add("API_Key", $API_Key)
    $CurrentParams.Add("Timeout", $Timeout)
    $CurrentParams.Add("Interval", $Interval)
    $CurrentParams.Add("StatsInterval", $StatsInterval)
    $CurrentParams.Add("Location", $Location)
    $CurrentParams.Add("Type", $Type)
    $CurrentParams.Add("GPUDevices1", $GPUDevices1)
    $CurrentParams.Add("GPUDevices2", $GPUDevices2)
    $CurrentParams.Add("GPUDevices3", $GPUDevices3)
    $CurrentParams.Add("Poolname", $PoolName)
    $CurrentParams.Add("Currency", $Currency)
    $CurrentParams.Add("Donate", $Donate)
    $CurrentParams.Add("Proxy", $Proxy)
    $CurrentParams.Add("CoinExchange", $CoinExchange)
    $CurrentParams.Add("Auto_Coin", $Auto_Coin)
    $CurrentParams.Add("Nicehash_Fee", $Nicehash_Fee)
    $CurrentParams.Add("Benchmark", $Benchmark)
    $CurrentParams.Add("No_Algo1", $No_Algo1)
    $CurrentParams.Add("No_Algo2", $No_Algo2)
    $CurrentParams.Add("No_Algo3", $No_Algo3)
    $CurrentParams.Add("Favor_Coins", $Favor_Coins)
    $CurrentParams.Add("Threshold", $Threshold)
    $CurrentParams.Add("Platform", $Platform)
    $CurrentParams.Add("CPUThreads", $CPUThreads)
    $CurrentParams.Add("Stat_Coin", $Stat_Coin)
    $CurrentParams.Add("Stat_Algo", $Stat_Algo)
    $CurrentParams.Add("CPUOnly", $CPUOnly)
    $CurrentParams.Add("HiveOS", $HiveOS)
    $CurrentParams.Add("Update", $Update)
    $CurrentParams.Add("Cuda", $Cuda)
    $CurrentParams.Add("WattOMeter", $WattOMeter)
    $CurrentParams.Add("Farm_Hash", $Farm_Hash)
    $CurrentParams.Add("Rejections", $Rejections)
    $CurrentParams.Add("PoolBans", $PoolBans)
    $CurrentParams.Add("PoolBanCount", $PoolBanCount)
    $CurrentParams.Add("AlgoBanCount", $AlgoBanCount)
    $CurrentParams.Add("MinerBanCount", $MinerBanCount)
    $CurrentParams.Add("Conserve", $Conserve)
    $CurrentParams.Add("SWARM_Mode", $SWARM_Mode)
    $CurrentParams.Add("Switch_Threshold", $Switch_Threshold)
    $CurrentParams.Add("Lite", $Lite)
    $CurrentParams.Add("API", $API)
    $CurrentParams.ADD("CLPlatform", $CLPlatform)
    $CurrentParams.ADD("Port", $Port)
    $CurrentParams.ADD("Remote", $Remote)
    $CurrentParams.ADD("APIPassword", $APIPassword)
    $CurrentParams.ADD("Startup", $Startup)
    $CurrentParams.ADD("ETH", $ETH)
    $CurrentParams.ADD("Worker", $Worker)
    $CurrentParams.ADD("No_Miner", $No_Miner)
    $CurrentParams.ADD("HiveAPIkey", $HiveAPIkey)
    $CurrentParams.ADD("Algorithm", $Algorithm)
    $CurrentParams.ADD("Coin", $Coin)

    ## Save to Config Folder
    $StartParams = $CurrentParams | ConvertTo-Json 
    $StartParams | Set-Content ".\config\parameters\arguments.json"

    ## Duplicate Hashtable Compressed To Pass In Pipeline
    $StartingParams = $CurrentParams | ConvertTo-Json -Compress
}

## Check For Remote Arugments Change Arguments To Remote Arguments
if ((Test-Path ".\config\parameters\newarguments.json") -or $Debug -eq $true) {
    $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
    Write-Host "Detected New Arguments- Changing Parameters" -ForegroundColor Cyan
    Write-Host "These arguments can be found/modified in config < parameters < newarguments.json" -ForegroundColor Cyan
    if ($Debug -eq $True) {$NewParams = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json}
    else {$NewParams = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json}

    ## Bug Fix: Adding New Defaults to flight sheet:
    $Defaults = Get-Content ".\config\parameters\default.json" | ConvertFrom-Json
    $Defaults | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {if ($NewParams -notmatch $_) {$NewParams | Add-Member "$($_)" $Defaults.$_}}

    Start-Sleep -S 2

    ## Save to Config Folder
    $NewParams | Convertto-Json | Set-Content ".\config\parameters\arguments.json"
    $StartParams = $NewParams
    ## Duplicate Hashtable Compressed To Pass In Pipeline
    $StartingParams = $NewParams | ConvertTo-Json -Compress

    ## Pull From File This is linux Powershell Bug / Weird Parsing. This Corrects it.
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
    $GPUDevices1 = $SWARMParams.GPUDevices1 -replace "`'", ""
    $GPUDevices2 = $SWARMParams.GPUDevices2 -replace "`'", ""
    $GPUDevices3 = $SWARMParams.GPUDevices3 -replace "`'", ""
    $PoolName = $SWARMParams.PoolName
    $Currency = $SWARMParams.Currency
    $Passwordcurrency1 = $SWARMParams.Passwordcurrency1
    $Passwordcurrency2 = $SWARMParams.Passwordcurrency1
    $Passwordcurrency3 = $SWARMParams.Passwordcurrency3
    $AltPassword1 = $SWARMParams.AltPassword1
    $AltPassword2 = $SWARMParams.AltPassword2
    $AltPassword3 = $SWARMParams.AltPassword3
    $Donate = $SWARMParams.Donate
    $Proxy = $SWARMParams.Proxy -replace "`'", ""
    $CoinExchange = $SWARMParams.CoinExchange
    $Auto_Coin = $SWARMParams.Auto_Coin
    $Nicehash_Fee = $SWARMParams.Nicehash_Fee
    $Benchmark = $SWARMParams.Benchmark
    $No_Algo1 = $SWARMParams.No_Algo1
    $No_Algo2 = $SWARMParams.No_Algo2
    $No_Algo3 = $SWARMParams.No_Algo3
    $Favor_Coins = $SWARMParams.Favor_Coins
    $Threshold = $SWARMParams.Threshold
    $Platform = $SWARMParams.platform
    $CPUThreads = $SWARMParams.CPUThreads
    $Stat_Coin = $SWARMParams.Stat_Coin
    $Stat_Algo = $SWARMParams.Stat_Algo
    $CPUOnly = $SWARMParams.CPUOnly
    $HiveOS = $SWARMParams.HiveOS
    $Update = $SWARMParams.Update
    $Cuda = $SWARMParams.Cuda
    $WattOMeter = $SWARMParams.WattOMeter
    $Farm_Hash = $SWARMParams.Farm_Hash
    $Rejections = $SWARMParams.Rejections
    $PoolBans = $SWARMParams.PoolBans
    $PoolBanCount = $SWARMParams.PoolBanCount
    $AlgoBanCount = $SWARMParams.AlgoBanCount
    $Lite = $SWARMParams.Lite
    $Conserve = $SWARMParams.Conserve
    $Switch_Threshold = $SWARMParams.Switch_Threshold
    $SWARM_Mode = $SWARMParams.SWARM_Mode
    $CLPlatform = $SWARMParams.CLPlatform
    $API = $SWARMParams.API
    $Port = $SWARMParams.Port
    $Remote = $SWARMParams.Remote
    $APIPassword = $SWARMParams.APIPassword
    $Startup = $SWARMParams.Startup
    $ETH = $SWARMParams.ETH
    $Worker = $SWARMParams.Worker
    $No_Miner = $SWARMParams.No_Miner
    $HiveAPIkey = $SWARMParams.HiveAPIkey
    $SWARMAlgorithm = $SWARMParams.Algorithm
    $Coin = $SWARMParams.Coin
}

## Windows Start Up
if ($Platform -eq "windows") { 
    ## Pull Saved Worker Info (If recorded From Remote Command)
    if (test-Path ".\buid\txt\hivekeys.txt") {$HiveKeys = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json}

    ## Set New Arguments or First Run
    if ($HiveKeys) {$HiveID = $HiveKeys.HiveID; $HivePassword = $HiveKeys.HivePassword; $HiveWorker = $HiveKeys.HiveWorker; $HiveMirror = $HiveKeys.HiveMirror; }
    else {$HiveID = $null; $HivePassword = $null; $HiveWorker = $null; $HiveMirror = "https://api.hiveos.farm"}
}

## Wallet Information

$Wallets = @()
$Walletlist = @{}
if (Test-Path ".\wallet\keys") {$Oldkeys = Get-ChildItem ".\wallet\keys"}
if ($Oldkeys) {Remove-Item ".\wallet\keys\*" -Force}

##Build Hash Table
if ($AltWallet1) {$Walletlist.Add("AltWallet1", $AltWallet1)};
if ($AltWallet2) {$Walletlist.Add("AltWallet2", $AltWallet2)};
if ($AltWallet3) {$Walletlist.Add("AltWallet3", $AltWallet3)};
if ($Wallet1) {$Walletlist.Add("Wallet1", $Wallet1)};
if ($Wallet2) {$Walletlist.Add("Wallet2", $Wallet2)};
if ($Wallet3) {$Walletlist.Add("Wallet3", $Wallet3)};
if ($NiceHash_Wallet1) {$Walletlist.Add("NiceHash_Wallet1", $NiceHash_Wallet1)};
if ($NiceHash_Wallet2) {$Walletlist.Add("NiceHash_Wallet2", $NiceHash_Wallet2)};
if ($NiceHash_Wallet3) {$Walletlist.Add("NiceHash_Wallet3", $NiceHash_Wallet3)};
if (-Not (Test-Path ".\wallet\wallets")) {new-item -Path ".\wallet" -Name "wallets" -ItemType "directory" | Out-Null}
##Record To File
$WalletList | ConvertTO-Json | Set-Content ".\wallet\wallets\wallets.txt"

## Build Array with non-duplicate wallets, to prevent excessive calls to pool
if ($Wallet1) {$Wallets += [PSCustomObject]@{Wallet = "Wallet1"; address = $Wallet1; Symbol = $PasswordCurrency1; Response = ""; Unsold = ""; Current = ""}
}
if ($Wallet2 -and $Wallet2 -ne $Wallet1) {$Wallets += [PSCustomObject]@{Wallet = "Wallet2"; address = $Wallet2; Symbol = $PasswordCurrency2; Response = ""; Unsold = ""; Current = ""}
}
if ($Wallet3 -and $Wallet3 -ne $Wallet2 -and $Wallet3 -ne $Wallet1) {$Wallets += [PSCustomObject]@{Wallet = "Wallet3"; address = $Wallet3; Symbol = $PasswordCurrency3; Response = ""; Unsold = ""; Current = ""}
}
if ($AltWallet1) {$Wallets += [PSCustomObject]@{Wallet = "AltWallet1"; address = $AltWallet1; Symbol = $AltPassword1; Response = ""; Unsold = ""; Current = ""}
}
if ($AltWallet2 -and $AltWallet2 -ne $ALtWallet1) {$Wallets += [PSCustomObject]@{Wallet = "AltWallet2"; address = $AltWallet2; Symbol = $AltPassword2; Response = ""; Unsold = ""; Current = ""}
}
if ($AltWallet3 -and $AltWallet3 -ne $AltWallet2 -and $AltWallet3 -ne $AltWallet1) {$Wallets += [PSCustomObject]@{Wallet = "AltWallet3"; address = $AltWallet3; Symbol = $AltPassword3; Response = ""; Unsold = ""; Current = ""}
}
if ($Nicehash_Wallet1) {$Wallets += [PSCustomObject]@{Wallet = "Nicehash_Wallet1"; address = $Nicehash_Wallet1; Symbol = "NHBTC"; Response = ""; Unsold = ""; Current = ""}
}
if ($Nicehash_Wallet2 -and $Nicehash_Wallet2 -ne $Nicehash_Wallet1) {$Wallets += [PSCustomObject]@{Wallet = "Nicehash_Wallet2"; address = $Nicehash_Wallet2; Symbol = "NHBTC"; Response = ""; Unsold = ""; Current = ""}
}
if ($Nicehash_Wallet3 -and $Nicehash_Wallet3 -ne $Nicehash_Wallet2 -and $Nicehash_Wallet3 -ne $Nicehash_Wallet1) {$Wallets += [PSCustomObject]@{Wallet = "Nicehash_Wallet3"; address = $Nicehash_Wallet3; Symbol = "NHBTC"; Response = ""; Unsold = ""; Current = ""}
}
if (-Not (Test-Path ".\wallet\keys")) {new-item -Path ".\wallet" -Name "keys" -ItemType "directory" | Out-Null}

## Save Array To File
$Wallets | % { $_ | ConvertTo-Json | Set-Content ".\wallet\keys\$($_.Wallet).txt"}

## Version
if (-Not (Test-Path ".\build\txt")) {New-Item -Name "txt" -Path ".\build" -ItemType "directory" | Out-Null}
$Version = Get-Content ".\h-manifest.conf" | ConvertFrom-StringData
$Version.CUSTOM_NAME | Set-Content ".\build\txt\version.txt"
$Version = $Version.CUSTOM_VERSION

## lower case (Linux file path)
if ($Platform -eq "Windows") {$Platform = "windows"}

## upper case (Linux file path)
$Type | foreach {
    if ($_ -eq "amd1") {$_ = "AMD1"}
    if ($_ -eq "nvidia1") {$_ = "NVIDIA1"}
    if ($_ -eq "nvidia2") {$_ = "NVIDIA2"}
    if ($_ -eq "nvidia2") {$_ = "NVIDIA3"}
    if ($_ -eq "cpu") {$_ = "CPU"}
}

## create debug/command folder
if (-not (Test-Path ".\build\txt")) {New-Item -Path ".\build" -Name "txt" -ItemType "directory" | Out-Null}

## Time Sych For All SWARM Users
Write-Host "Sycronizing Time Through Nist" -ForegroundColor Yellow
$Sync = Get-Nist
try {Set-Date $Sync -ErrorAction Stop}catch {Write-Host "Failed to syncronize time- Are you root/administrator?" -ForegroundColor red; Start-Sleep -S 5}

##Start The Log
$dir | set-content ".\build\bash\dir.sh";
$Log = 1;
start-log -Platforms $Platform -HiveOS $HiveOS -Number $Log;

##HiveOS Confirmation
Write-Host "HiveOS = $HiveOS"
#Startings Settings (Non User Arguments):
$BenchmarkMode = "No"
$Instance = 1
$DecayStart = Get-Date
$DecayPeriod = 60 #seconds
$DecayBase = 1 - 0.1 #decimal percentage
$Deviation = $Donate
$WalletDonate = "1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i"
$NicehashDonate = "3JfBiUZZV17DTjAFCnZb97UpBgtLPLLDop"
$UserDonate = "MaynardVII"
$WorkerDonate = "Rig1"
$PoolNumber = 1
$ActiveMinerPrograms = @()
$Naming = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
$Priorities = Get-Content ".\config\pools\pool-priority.json" | ConvertFrom-Json
$DonationMode = $false
$Warnings = @()

## Linux Initialize
if ($Platform -eq "linux") {
    ## HiveOS Only Items
    if ($HiveOS -eq "Yes") {

        ## Clear trash for usb stick
        Start-Process ".\build\bash\libc.sh" -wait
        Start-Process ".\build\bash\libv.sh" -wait    
        Write-Host "Clearing Trash Folder"
        invoke-expression "rm -rf .local/share/Trash/files/*"

        ##Data and Hive Configs
        Write-Host "Getting Data" -ForegroundColor Yellow
        Get-Data -CmdDir $dir
        $config = get-content "/hive-config/rig.conf" | ConvertFrom-StringData
        $HivePassword = $config.RIG_PASSWD -replace "`"", ""
        $HiveWorker = $config.WORKER_NAME -replace "`"", ""
        $HiveMirror = $config.HIVE_HOST_URL -replace "`"", ""
        $HiveID = $config.RIG_ID
        $FarmID = $config.FARM_ID
    }

    Start-Process ".\build\bash\screentitle.sh" -Wait
  
    ## Kill Previous Screens
    start-killscript

    ## Set Cuda for commands
    $cuda | Set-Content ".\build\txt\cuda.txt"

    ## Start SWARM watchdog (for automatic shutdown)
    start-watchdog

    ## Get Total GPU Count
    $GPU_Count = Get-GPUCount

    ## Let User Know What Platform commands will work for- Will always be Group 1.
    $Type | Foreach {
        if ($_ -eq "NVIDIA1") {
            "NVIDIA1" | Out-File ".\build\txt\minertype.txt" -Force
            Write-Host "Group 1 is NVIDIA- Commands and Stats will work for NVIDIA1" -foreground yellow
            Start-Sleep -S 3
        }
        if ($_ -eq "AMD1") {
            "AMD1" | Out-File ".\build\txt\minertype.txt" -Force
            Write-Host "Group 1 is AMD- Commands and Stats will work for AMD1" -foreground yellow
            Start-Sleep -S 3
        }
        if ($_ -eq "CPU") {
            if ($GPU_Count -eq 0) {
                "CPU" | Out-File ".\build\txt\minertype.txt" -Force
                Write-Host "Group 1 is CPU- Commands and Stats will work for CPU" -foreground yellow
                Start-Sleep -S 3
            }
        }
    }

    ## Aaaaannnd...Que that sexy loading screen
    Get-SexyUnixLogo
}

##Windows Initialize
if ($Platform -eq "windows") {
    ## Add Swarm to Startup
    if ($Startup) {
        $CurrentUser = $env:UserName
        $Startup_Path = "C:\Users\$CurrentUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
        $Bat_Startup = Join-Path $Startup_Path "SWARM.bat"
        switch ($Startup) {
            "Yes" {
                Write-Host "Attempting to add current SWARM.bat to startup" -ForegroundColor Magenta
                Write-Host "If you do not wish SWARM to start on startup, use -Startup No argument"
                Write-Host "Startup FilePath: $Startup_Path"
                $bat = "CMD /r powershell -ExecutionPolicy Bypass -command `"Set-Location $dir; Start-Process `"SWARM.bat`"`""
                $Bat_Startup = Join-Path $Startup_Path "SWARM.bat"
                $bat | Set-Content $Bat_Startup
            }
            "No" {
                Write-Host "Startup No Was Specified. Removing From Startup" -ForegroundColor Magenta
                if (Test-Path $Bat_Startup) {Remove-Item $Bat_Startup -Force}
            }    
        }
    }

    ## Windows Bug- Set Cudas to match PCI Bus Order
    [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", "User")

    ##Set Cuda For Commands
    $Cuda = "10"
    $Cuda | Set-Content ".\build\txt\cuda.txt"

    ##Fan Start For Users not using HiveOS
    Start-Fans

    ##Detect if drivers are installed, not generic- Close if not. Print message on screen
    if ($Type -like "*NVIDIA*" -and -not (Test-Path "C:\Program Files\NVIDIA Corporation\NVSMI\nvml.dll")) {
        Write-Host "nvml.dll is missing" -ForegroundColor Red
        Start-Sleep -S 3
        Write-Host "To Fix:" -ForegroundColor Blue
        Write-Host "Update Windows, Purge Old NVIDIA Drivers, And Install Latest Drivers" -ForegroundColor Blue
        Start-Sleep -S 3
        Write-Host "Closing Miner"
        Start-Sleep -S 1
        exit
    }

    ## Fetch Ram Size, Write It To File (For Commands)
    $TotalMemory = (systeminfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
    $TotalMemory = $TotalMemory -replace (",", "")
    $TotalMemory = $TotalMemory -replace ("MB", "")
    $TotalMemory | Set-Content ".\build\txt\ram.txt"

    ## GPU Bus Hash Table
    $GetBusData = Get-BusFunctionID | ConvertTo-Json -Compress

    ## Get Total GPU HashTable
    $GPU_Count = Get-GPUCount $GetBusData

    ## Say Hello To Hive
    if ($HiveOS -eq "Yes") {
        ##Note For AMD Users:
        if ($Type -like "*AMD*") {
            Write-Host "
AMD USERS: PLEASE READ .\config\oc\new_sample.json FOR INSTRUCTIONS ON OVERCLOCKING IN HIVE OS!
" -ForegroundColor Cyan
            Start-Sleep -S 1
        }
        ## Initiate Contact
        $hiveresponse = Start-Peekaboo -HiveID $HiveID -HiveMirror $HiveMirror -HiveWorker $HiveWoker -HivePassword $HivePassword -Version $Version -GPUData $GetBusData; 
        if ($hiveresponse.result) {
            ## If Hive Responds with config: Set new config interactively
            $hiveresponse.result | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                $Action = $_
                if ($Action -eq "config") {
                    $config = [string]$hiveresponse.result.config | ConvertFrom-StringData
                    $HiveWorker = $config.WORKER_NAME -replace "`"", ""
                    $Pass = $config.RIG_PASSWD -replace "`"", ""
                    $mirror = $config.HIVE_HOST_URL -replace "`"", ""
                    $farmID = $config.FARM_ID
                    $HiveID = $config.RIG_ID
                    $NewHiveKeys = @{}
                    $NewHiveKeys.Add("HiveWorker", "$Hiveworker")
                    $NewHiveKeys.Add("HivePassword", "$Pass")
                    $NewHiveKeys.Add("HiveID", "$HiveID")
                    $NewHiveKeys.Add("HiveMirror", "$mirror")
                    $NewHiveKeys.Add("FarmID", "$farmID")
                    if (Test-Path ".\build\txt\hivekeys.txt") {$OldHiveKeys = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json}
                    ## If password was changed- Let Hive know message was recieved
                    if ($OldHiveKeys) {
                        if ("$($NewHiveKeys.HivePassword)" -ne "$($OldHiveKeys.HivePassword)") {
                            $method = "message"
                            $messagetype = "warning"
                            $data = "Password change received, wait for next message..."
                            $DoResponse = Add-HiveResponse -Method $method -MessageType $messagetype -Data $data -HiveID $HiveID -HivePassword $HivePassword -CommandID $command.result.id
                            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1 -Compress
                            $SendResponse = Invoke-RestMethod "$mirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                            $SendResponse
                            $DoResponse = @{method = "password_change_received"; params = @{rig_id = $HiveID; passwd = $HivePassword}; jsonrpc = "2.0"; id = "0"}
                            $DoResponse = $DoResponse | ConvertTo-JSon -Depth 1 -Compress
                            $Send2Response = Invoke-RestMethod "$mirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                        }
                    }

                    ## Set Arguments/New Parameters
                    $NewHiveKeys | ConvertTo-Json | Set-Content ".\build\txt\hivekeys.txt"
                    $HiveID = $NewHiveKeys.HiveID
                    $farmID = $NewHiveKeys.FarmID
                    $HivePassword = $NewHiveKeys.HivePassword
                    $HiveWorker = $NewHiveKeys.HiveWorker
                    $HiveMirror = $NewHiveKeys.HiveMirror
                }

                ##If Hive Sent OC Start SWARM OC
                if ($Action -eq "nvidia_oc") {
                    $WorkingDir = $dir
                    $NewOC = $hiveresponse.result.nvidia_oc | ConvertTo-Json -Compress
                    $NewOC | Start-NVIDIAOC 
                }
                if ($Action -eq "amd_oc") {
                    $WorkingDir = $dir
                    $NewOC = $hiveresponse.result.amd_oc | ConvertTo-Json -Compress
                    $NewOC | Start-AMDOC 
                }
            }

            ## Print Data to output, so it can be recorded in transcript
            $hiveresponse.result.config

        }
        else {
            Write-Host "failed to contact HiveOS- Do you have an account? Did you use your farm hash?"
        }

        ## Aaaaannnnd...Que that sexy logo. Go Time.
        Get-SexyWinLogo
    }
}

## Determine AMD platform
if ($Type -like "*AMD*") {
    if ($CLPlatform -ne "") {$AMDPlatform = $CLPlatform}
    else {
        [string]$AMDPlatform = get-AMDPlatform -Platforms $Platform
        Write-Host "AMD OpenCL Platform is $AMDPlatform"
    }
}


#Timers
if ($Timeout) {$TimeoutTime = [Double]$Timeout * 3600}
else {$TimeoutTime = 10000000000}
$TimeoutTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$TimeoutTimer.Start()
$logtimer = New-Object -TypeName System.Diagnostics.Stopwatch
$logtimer.Start()

##Remove Exclusion
try {if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) {Start-Process powershell -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -WindowStyle Minimized}}catch {}
##Proxy
if ($Proxy -eq "" -or $Proxy -eq '') {$PSDefaultParameterValues.Remove("*:Proxy")}
else {$PSDefaultParameterValues["*:Proxy"] = $Proxy}
##RecordPID

##GPU-Count- Parse the hashtable between devices.
if (Test-Path ".\build\txt\nvidiapower.txt") {Remove-Item ".\build\txt\nvidiapower.txt" -Force}
if (Test-path ".\build\txt\amdpower.txt") {Remove-Item ".\build\txt\amdpower.txt" -Force}
if ($GPU_Count -ne 0) {$GPUCount = @(); for ($i = 0; $i -lt $GPU_Count; $i++) {[string]$GPUCount += "$i,"}}
if ($CPUThreads -ne 0) {$CPUCount = @(); for ($i = 0; $i -lt $CPUThreads; $i++) {[string]$CPUCount += "$i,"}}
if ($GPU_Count -eq 0) {$Device_Count = $CPUThreads}
else {$Device_Count = $GPU_Count}
Write-Host "Device Count = $Device_Count" -foregroundcolor green
Start-Sleep -S 2
if ($GPUCount -ne $null) {$LogGPUS = $GPUCount.Substring(0, $GPUCount.Length - 1)}
if ($GPUDevices1){$GPUDevices1 | % {$NVIDIADevices1 += "$($_),"}}
if ($GPUDevices2){$GPUDevices2 | % {$NVIDIADevices2 += "$($_),"}}
if ($GPUDevices3){$GPUDevices3 | % {$NVIDIADevices3 += "$($_),"}}
if ($GPUDevices1){$GPUDevices1 | % {$AMDDevices1 += "$($_),"}}
if ($NVIDIADevices1){$NVIDIADevices1 = $NVIDIADevices1.Substring(0,$NVIDIADevices1.Length-1)}
if ($NVIDIADevices2){$NVIDIADevices2 = $NVIDIADevices2.Substring(0,$NVIDIADevices2.Length-1)}
if ($NVIDIADevices3){$NVIDIADevices3 = $NVIDIADevices3.Substring(0,$NVIDIADevices3.Length-1)}
if ($AMDDevices1){$AMDDevices1 = $AMDDevices1.Substring(0,$AMDDevices1.Length-1)}
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json

##Reset-Old Stats And Their Time
if (Test-Path "stats") {Get-ChildItemContent "stats" | ForEach {$Stat = Set-Stat $_.Name $_.Content.Week}}

#Get Miner Config Files
if ($Type -like "*CPU*") {$cpu = get-minerfiles -Types "CPU" -Platforms $Platform}
if ($Type -like "*NVIDIA*") {$nvidia = get-minerfiles -Types "NVIDIA" -Platforms $Platform -Cudas $Cuda}
if ($Type -like "*AMD*") {$amd = get-minerfiles -Types "AMD" -Platforms $Platform}

##Start New Agent
Write-Host "Starting New Background Agent" -ForegroundColor Cyan
if ($Platform -eq "windows") {Start-Background -WorkingDir $pwsh -Dir $dir -Platforms $Platform -HiveID $HiveID -HiveMirror $HiveMirror -HiveOS $HiveOS -HivePassword $HivePassword -RejPercent $Rejections -Remote $Remote -Port $Port -APIPassword $APIPassword -API $API}
elseif ($Platform -eq "linux") {Start-Process ".\build\bash\background.sh" -ArgumentList "background $dir $Platform $HiveOS $Rejections $Remote $Port $APIPassword $API" -Wait}

While ($true) {

    ##Manage Pool Bans
    Start-PoolBans $StartingParams $swarmstamp

    ##Parameters (change again interactively if needed)
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
    $GPUDevices1 = $SWARMParams.GPUDevices1 -replace "`'", ""
    $GPUDevices2 = $SWARMParams.GPUDevices2 -replace "`'", ""
    $GPUDevices3 = $SWARMParams.GPUDevices3 -replace "`'", ""
    $PoolName = $SWARMParams.PoolName
    $Currency = $SWARMParams.Currency
    $Passwordcurrency1 = $SWARMParams.Passwordcurrency1
    $Passwordcurrency2 = $SWARMParams.Passwordcurrency1
    $Passwordcurrency3 = $SWARMParams.Passwordcurrency3
    $AltPassword1 = $SWARMParams.AltPassword1
    $AltPassword2 = $SWARMParams.AltPassword2
    $AltPassword3 = $SWARMParams.AltPassword3
    $Donate = $SWARMParams.Donate
    $Proxy = $SWARMParams.Proxy -replace "`'", ""
    $CoinExchange = $SWARMParams.CoinExchange
    $Auto_Coin = $SWARMParams.Auto_Coin
    $Nicehash_Fee = $SWARMParams.Nicehash_Fee
    $Benchmark = $SWARMParams.Benchmark
    $No_Algo1 = $SWARMParams.No_Algo1
    $No_Algo2 = $SWARMParams.No_Algo2
    $No_Algo3 = $SWARMParams.No_Algo3
    $Favor_Coins = $SWARMParams.Favor_Coins
    $Threshold = $SWARMParams.Threshold
    $Platform = $SWARMParams.platform
    $CPUThreads = $SWARMParams.CPUThreads
    $Stat_Coin = $SWARMParams.Stat_Coin
    $Stat_Algo = $SWARMParams.Stat_Algo
    $CPUOnly = $SWARMParams.CPUOnly
    $HiveOS = $SWARMParams.HiveOS
    $Update = $SWARMParams.Update
    $Cuda = $SWARMParams.Cuda
    $WattOMeter = $SWARMParams.WattOMeter
    $Farm_Hash = $SWARMParams.Farm_Hash
    $Rejections = $SWARMParams.Rejections
    $PoolBans = $SWARMParams.PoolBans
    $PoolBanCount = $SWARMParams.PoolBanCount
    $AlgoBanCount = $SWARMParams.AlgoBanCount
    $Lite = $SWARMParams.Lite
    $Conserve = $SWARMParams.Conserve
    $Switch_Threshold = $SWARMParams.Switch_Threshold
    $SWARM_Mode = $SWARMParams.SWARM_Mode
    $API = $SWARMParams.API
    $CLPlatform = $SWARMParams.CLPlatform
    $Port = $SWARMParams.Port
    $Remote = $SWARMParams.Remote
    $APIPassword = $SWARMParams.APIPassword
    $Startup = $SWARMParams.Startup
    $Worker = $SWARMParams.Worker
    $No_Miner = $SWARMParams.No_Miner        
    $HiveAPIkey = $SWARMParams.HiveAPIkey
    $SWARMAlgorithm = $SWARMParams.Algorithm
    $Coin = $SWARMParams.Coin

    #Get-Algorithms
    $Algorithm = @()
    $Pool_Json = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-jSon
    if($Coin){$Passwordcurrency1 = $Coin; $Passwordcurrency2 = $Coin; $Passwordcurrency3 = $Coin}
    if($SWARMAlgorithm){$SWARMALgorithm | %{$Algorithm += $_}}
    else{$Algorithm = $Pool_Json.PSObject.Properties.Name}
    $Bad_Pools = Get-BadPools
    $Bad_Miners = Get-BadMiners    

    if ($SWARMParams.Rigname1 -eq "Donate") {$Donating = $True}
    else {$Donating = $False}
    if ($Donating -eq $True) 
     {
      $Passwordcurrency1 = "BTC"; 
      $Passwordcurrency2 = "BTC"; 
      $Passwordcurrency3 = "BTC"
      $DonateTime = Get-Date; 
      $DonateText = "Miner has donated on $DonateTime"; 
      $DonateText | Set-Content ".\build\txt\donate.txt"
     }

    if ($Type -notlike "*ASIC*") {
        ## Main Loop Begins
        ## SWARM begins with pulling files that might have been changed from previous loop.

        ##Save Watt Calcs
        if ($Watts) {$Watts | ConvertTo-Json | Out-File ".\config\power\power.json"}
        ##OC-Settings
        $OC = Get-Content ".\config\oc\oc-settings.json" | ConvertFrom-Json
        ##Reset Coins
        $CoinAlgo = $null  
        ##Get Watt Configuration
        $WattHour = $(Get-Date | Select hour).Hour
        $Watts = get-content ".\config\power\power.json" | ConvertFrom-Json

        ##Check Time Parameters
        $MinerWatch = New-Object -TypeName System.Diagnostics.Stopwatch
        $DecayExponent = [int](((Get-Date) - $DecayStart).TotalSeconds / $DecayPeriod)
 
        ##Get Price Data
        try {
            $R = [string]$Currency
            Write-Host "SWARM Is Building The Database. Auto-Coin Switching: $Auto_Coin" -foreground "yellow"
            $Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=BTC" -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
            $Currency | Where-Object {$Rates.$_} | ForEach-Object {$Rates | Add-Member $_ ([Double]$Rates.$_) -Force}
            $WattCurr = (1 / $Rates.$Currency)
            $WattEx = [Double](($WattCurr * $Watts.KWh.$WattHour))
        }
        catch {
            Write-Host -Level Warn "Coinbase Unreachable. "
            Write-Host -ForegroundColor Yellow "Last Refresh: $(Get-Date)"
            Write-host "Trying To Contact Cryptonator.." -foregroundcolor "Yellow"
            $Rates = [PSCustomObject]@{}
            $Currency | ForEach {$Rates | Add-Member $_ (Invoke-WebRequest "https://api.cryptonator.com/api/ticker/btc-$_" -UseBasicParsing | ConvertFrom-Json).ticker.price}
        }


        ##Load File Stats, Begin Clearing Bans And Bad Stats Per Timout Setting. Restart Loop if Done
        if ($TimeoutTimer.Elapsed.TotalSeconds -lt $TimeoutTime -or $Timeout -eq 0) {$Stats = Get-Stats -Timeouts "No"}
        else {
            $Stats = Get-Stats -Timeouts "Yes"
            $TimeoutTimer.Restart()
            continue
        }

        ##Get Algorithm Pools
        Write-Host "Checking Algo Pools" -Foregroundcolor yellow;
        $AllAlgoPools = Get-Pools -PoolType "Algo" -Stats $Stats
        ##Get Custom Pools
        Write-Host "Adding Custom Pools" -ForegroundColor Yellow;
        $AllCustomPools = Get-Pools -PoolType "Custom" -Stats $Stats

        ## Select the best 3 of each algorithm
        $Top_3_Algo = $AllAlgoPools.Symbol | Select-Object -Unique | ForEach-Object {$AllAlgoPools | Where Symbol -EQ $_ | Sort-Object Price -Descending | Select -First 3};
        $Top_3_Custom = $AllCustomPools.Symbol | Select-Object -Unique | ForEach-Object {$AllCustomPools | Where Symbol -EQ $_ | Sort-Object Price -Descending | Select -First 3};

        ## Combine Stats From Algo and Custom
        [System.Collections.ArrayList]$AlgoPools = if($Top_3_Algo){$Top_3_Algo | ForEach-Object {$_}}
        if($Top_3_Custom){$Top_3_Custom | ForEach-Object {$AlgoPools.Add($_)} | Out-Null;}
        $Top_3_Algo = $Null;
        $Top_3_Custom = $Null;

        if($AlgoPools.Count -eq 0) {
          $HiveMessage = "No Pools Found! Check Arguments/Net Connection"
          $HiveWarning = @{result = @{command = "timeout"}}
          if ($HiveOS -eq "Yes") {try {$SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror}catch {Write-Warning "Failed To Notify HiveOS"}}
          Write-Host $HiveMessage
          start-sleep $Interval; 
          continue  
        }

        ##Get Algorithms again, in case custom changed it.
        $Algorithm = Get-Algolist -Devices $Type -No_Algo $No_Algo;

        Write-Host "Checking Algo Miners"
        ##Load Only Needed Algorithm Miners
        [System.Collections.ArrayList]$AlgoMiners = Get-Miners -Platforms $Platform -MinerType $Type -Stats $Stats -Pools $AlgoPools;

        if($ALgoMiners.Count -eq 0) {
            $HiveMessage = "No Miners Found! Check Arguments / Configuration"
            $HiveWarning = @{result = @{command = "timeout"}}
            if ($HiveOS -eq "Yes") {try {$SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror}catch {Write-Warning "Failed To Notify HiveOS"}}
            Write-Host $HiveMessage
            start-sleep $Interval; 
            continue    
        }

        ##Download Miners, If Miner fails three times- A ban is created against miner, and it should stop downloading.
        ##This works by every time it fails to download, it writes miner name to the download block list. If it counts
        ##The name more than three times- It skips over miner. It also interactively rebuilds the AlgoMiners Array into
        ##A new array with the miner removed. I know, complicated, right?
        $DownloadNote = @()
        $Download = $false
        $BadAlgoMiners = @()

        if ($Lite -eq "No") {
            $AlgoMiners | ForEach {
                $AlgoMiner = $_
                if (Test-Path ".\timeout\download_block\download_block.txt") {$DLTimeout = Get-Content ".\timeout\download_block\download_block.txt"}
                $DLName = $DLTimeout | Select-String "$($AlgoMiner.Name)"
                if ((Test-Path $AlgoMiner.Path) -eq $false) {
                    if ($DLName.Count -lt 3) {
                        Expand-WebRequest -URI $AlgoMiner.URI -BuildPath $AlgoMiner.BUILD -Path (Split-Path $AlgoMiner.Path) -MineName (Split-Path $AlgoMiner.Path -Leaf) -MineType $AlgoMiner.Type
                        $Download = $true
                        if (-not (Test-Path $ALgoMiner.Path)) {
                            if (-not (Test-Path ".\timeout\download_block")) {New-Item -Name "download_block" -Path ".\timeout" -ItemType "directory" | OUt-Null}
                            "$($Algominer.Name)" | Out-File ".\timeout\download_block\download_block.txt" -Append
                        }
                    }
                    else {
                        $DLWarning = "$($AlgoMiner.Name) download failed too many times- Blocking"; 
                        if ($DownloadNote -notcontains $DLWarning) {$DownloadNote += $DLWarning}
                        $BadAlgoMiners += $_
                    }       

                }
            }

            $BadAlgoMiners | %{$AlgoMiners.Remove($_)} | Out-Null;
            $BadAlgoMiners = $Null
            $DLTimeout = $null
            $DlName = $Null
            ## Print Warnings
            if ($DownloadNote) {$DownloadNote | % {Write-Host "$($_)" -ForegroundColor Red}}
            $DownloadNote = $null
        }

        ## Linux Bug- Restart Loop if miners were downloaded. If not, miners were skipped over
        if ($Download -eq $true) {continue}

        ## All miners had pool quote printed for their respective algorithm. This adjusts them with the Threshold increase.
        ## This is done here, so it distributes it to all miners of that particular algorithm, not the just active miner.
        $BestActiveMiners | % {$AlgoMiners | Where Algo -EQ $_.Algo | Where Type -EQ $_.Type | % {
                if ($_.Quote -NE $Null) {
                    if ($Switch_Threshold) {
                        $_.Quote = [Double]$_.Quote * (1 + ($Switch_Threshold / 100)); 
                    }
                }
            }
        }

        ## Sort Miners- There are currently up to three for each algorithm. This process sorts them down to best 1.
        ## If Miner has no hashrate- The quote returned was zero, so it needs to be benchmarked. This rebuilds a new
        ## Miner array, favoring miners that need to benchmarked first, then miners that had the highest quote. It
        ## Is done this way, as sorting via [double] would occasionally glitch. This is more if/else, and less likely
        ## To fail.
        $CutMiners = Start-MinerReduction -Stats $Stats -Pools $AlgoPools -SortMiners $AlgoMiners -WattCalc $WattEx -Type $Type
        ##Remove The Extra Miners
        $CutMiners | %{$AlgoMiners.Remove($_)} | Out-Null;
        $CutMiners = $Null

        ## Print on screen user is screwed if the process failed.
        if ($AlgoMiners.Count -eq 0) {
            $HiveMessage = "No Miners Found! Check Arguments/Net Connection"
            $HiveWarning = @{result = @{command = "timeout"}}
            if ($HiveOS -eq "Yes") {try {$SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror}catch {Write-Warning "Failed To Notify HiveOS"}}
            Write-Host $HiveMessage
            start-sleep $Interval; 
            continue
        }

        ##This starts to refine each miner hashtable, applying watt calculations, and other factors to each miner. ##TODO
        start-minersorting -Command "Algo" -Stats $Stats -Pools $AlgoPools -SortMiners $AlgoMiners -WattCalc $WattEx

        ##Now that we have narrowed down to our best miners - we adjust them for switching threshold.
        $BestActiveMiners | % { $AlgoMiners | Where Path -EQ $_.path | Where Arguments -EQ $_.Arguments | % {
            if ($_.Profit -ne $NULL) {
                if ($Switch_Threshold) {
                    Write-Host "Switching_Threshold changes $($_.Name) $($_.Algo) base factored price from $(($_.Profit * $Rates.$Currency).ToString("N2"))" -NoNewline; 
                    if ($_.Profit -GT 0) {$_.Profit = [Double]$_.Profit * (1 + ($Switch_Threshold / 100))}
                    else {$_.Profit = [Double]$_.Profit * (1 + ($Switch_Threshold / -100))};  
                    Write-Host " to $(($_.Profit * $Rates.$Currency).ToString("N2"))"
                }
            }
          }
        }


        ##Okay so now we have all the new applied values to each profit, and adjustments. Now we need to find best miners to use.
        ##First we rule out miners that are above threshold
        $BadAlgoMiners = @()
        if ($Threshold -ne 0) {$AlgoMiners | Foreach {if ($_.Profit -gt $Threshold) {$BadAlgoMiners += $_}}}
        $BadAlgoMiners | %{$AlgoMiners.Remove($_)}
        $BadAlgoMiners = $Null

        ##Now we need to eliminate all algominers except best ones
        $BestAlgoMiners_Combo = Get-BestMiners
        $AlgoPools = $null

        ##Final Array Build- If user specified to shut miner off if there were negative figures:
        ##Array is rebuilt to remove miner that had negative profit, but it needs to NOT remove
        ##Miners that had no profit. (Benchmarking).
        if ($Conserve -eq "Yes") {
            $BestMiners_Combo = @()
            $Type | Foreach {
                $SelType = $_
                $ConserveArray = @()
                $ConserveArray += $BestAlgoMiners_Combo | Where Type -EQ $SelType | Where Profit -EQ $NULL
                $ConserveArray += $BestAlgoMiners_Combo | Where Type -EQ $SelType | Where Profit -GT 0
            }
            $BestMiners_Combo += $ConserveArray
        }
        else {$BestMiners_Combo = $BestAlgoMiners_Combo}
        $ConserveArray = $null

        ##Write On Screen Best Choice  
        $BestMiners_Selected = $BestMiners_Combo.Symbol
        $BestPool_Selected = $BestMiners_Combo.MinerPool 
        Write-Host "Most Ideal Choice Is $($BestMiners_Selected) on $($BestPool_Selected)" -foregroundcolor green          

        ##Build Simple Stats Table For Screen/Command
        $ProfitTable = @()
        $AlgoMiners | foreach {
            $ProfitTable += [PSCustomObject]@{
                Power         = [Decimal]$($_.Power * 24) / 1000 * $WattEX
                Pool_Estimate = $_.Pool_Estimate
                Type          = $_.Type
                Miner         = $_.Name
                Name          = $($_.Symbol)
                Arguments     = $($_.Arguments)
                HashRates     = $_.HashRates.$($_.Symbol)
                Profits       = $_.Profit
                Algo          = $_.Algo
                Fullname      = $_.FullName
                MinerPool     = $_.MinerPool
            }
        }

        $AlgoMiners = $Null

        ## This Set API table for LITE mode.
        $ProfitTable | ConvertTo-Json -Depth 4 | Set-Content ".\build\txt\profittable.txt"

        ##Clear Old Logs
        if (-not $ActiveMinerPrograms) {$Type | foreach {if (Test-Path ".\logs\$($_).log") {remove-item ".\logs\$($_).log" -Force}}}

        ##Add new miners to Active Miner Array, if they were not there already.
        ##This also does a little weird parsing for CPU only mining,
        ##And some parsing for logs.
        $BestMiners_Combo | ForEach {
            if (-not ($ActiveMinerPrograms | Where Path -eq $_.Path | Where Arguments -eq $_.Arguments )) {
                if ($_.Type -eq "CPU") {$LogType = $LogCPUS}
                if ($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*") {
                    if ($_.Devices -eq $null) {$LogType = $LogGPUS}
                    else {$LogType = $_.Devices}
                }
                $ActiveMinerPrograms += [PSCustomObject]@{
                    Delay          = $_.Delay
                    Name           = $_.Name
                    Type           = $_.Type
                    Devices        = $_.Devices
                    ArgDevices     = $_.ArgDevices
                    DeviceCall     = $_.DeviceCall
                    MinerName      = $_.MinerName
                    Path           = $_.Path
                    Arguments      = $_.Arguments
                    API            = $_.API
                    Port           = $_.Port
                    Coins          = $_.Symbol
                    Active         = [TimeSpan]0
                    Activated      = 0
                    Status         = "Idle"
                    HashRate       = 0
                    Benchmarked    = 0
                    WasBenchmarked = $false
                    XProcess       = $null
                    MinerPool      = $_.MinerPool
                    Algo           = $_.Algo
                    FullName       = $_.FullName
                    Instance       = $null
                    InstanceName   = $null
                    Username       = $_.Username
                    Connection     = $_.Connection
                    Password       = $_.Password
                    BestMiner      = $false
                    JsonFile       = $_.Config
                    LogGPUS        = $LogType
                    FirstBad       = $null
                    Prestart       = $_.Prestart
                    ocpl           = $_.ocpl
                    ocdpm          = $_.ocdpm
                    ocv            = $_.ocv
                    occore         = $_.occore
                    ocmem          = $_.ocmem
                    ocmdpm         = $_.ocmdpm
                    ocpower        = $_.ocpower
                    ocfans         = $_.ocfans
                    ethpill        = $_.ethpill
                    pilldelay      = $_.pilldelay
                    Host           = $_.Host
                    User           = $_.User
                    CommandFile    = $_.CommandFile
                    Profit         = 0
                    Power          = 0
                    Fiat_Day       = 0
                }
            }
        }

        $Restart = $false
        $NoMiners = $false
        $ConserveMessage = @()

        #Determine Which Miner Should Be Active
        $BestActiveMiners = @()
        $ActiveMinerPrograms | foreach {
            if ($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments) {$_.BestMiner = $true; $BestActiveMiners += $_}
            else {$_.BestMiner = $false}
        }

        $BestActiveMiners | Foreach {
            $SelectedMiner = $BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments
            $_.Profit = if ($SelectedMiner.Profit) {$SelectedMiner.Profit -as [decimal]}else {"bench"}
            $_.Power = $([Decimal]$($SelectedMiner.Power * 24) / 1000 * $WattEX)
            $_.Fiat_Day = if ($SelectedMiner.Profit) {($SelectedMiner.Profit * $Rates.$Currency).ToString("N2")}else {"bench"}
        }

        ##Stop Linux Miners That Are Negaitve (Print Message)
        $Type | foreach {
            $TypeSel = $_
            if (-not $BestMiners_Combo | Where Type -eq $TypeSel) {    
                $ConseverMessage += "Stopping $($_) due to conserve mode being specified"
                if ($Platform -eq "linux") {
                    $ActiveMinerPrograms | ForEach {
                        if ($_.BestMiner -eq $false) {
                            if ($_.XProcess = $null) {$_.Status = "Failed"}
                            else {
                                $_.Status = "Idle"
                                $MinerInfo = ".\build\pid\$($_.Name)_$($_.Type)_$($_.Coins)_info.txt"
                                if (Test-path $MinerInfo) {
                                    $MI = Get-Content $MinerInfo | ConvertFrom-Json
                                    $PIDTime = [DateTime]$MI.start_date
                                    $_.Active += (Get-Date) - $PIDTime
                                    Write-Host "Stopping Miner: $($_.Name) on $($_Type) screen" -ForegroundColor Yellow
                                    Start-Process "start-stop-daemon" -ArgumentList "--stop --name $($MI.miner_exec) --pidfile $($MI.pid_path) --retry 5" -Wait
                                }
                            }
                        }
                    }
                }
            }
        }

        ## This section pulls relavant statics that users require, and then outputs them to screen or file, to be pulled on command.
        if ($ConserveMessage) {$ConserveMessage | % {Write-Host "$_" -ForegroundColor Red}}
        $Y = [string]$CoinExchange
        $H = [string]$Currency
        $J = [string]'BTC'
        $BTCExchangeRate = Invoke-WebRequest "https://min-api.cryptocompare.com/data/pricemulti?fsyms=$Y&tsyms=$J" -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty $Y | Select-Object -ExpandProperty $J
        $MSFile = ".\build\txt\minerstats.txt"
        if (Test-Path $MSFIle) {Clear-Content ".\build\txt\minerstats.txt" -Force}
        $type | foreach {if (Test-Path ".\build\txt\$($_)-hash.txt") {Clear-Content ".\build\txt\$($_)-hash.txt" -Force}}
        $GetStatusAlgoBans = ".\timeout\algo_block\algo_block.txt"
        $GetStatusPoolBans = ".\timeout\pool_block\pool_block.txt"
        $GetStatusMinerBans = ".\timeout\miner_block\miner_block.txt"
        $GetStatusDownloadBans = ".\timeout\download_block\download_block.txt"
        if (Test-Path $GetStatusDownloadBans) {$StatusDownloadBans = Get-Content $GetStatusDownloadBans}
        else {$StatusDownloadBans = $null}
        $GetDLBans = @();
        if ($StatusDownloadBans) {$StatusDownloadBans | % {if ($GetDLBans -notcontains $_) {$GetDlBans += $_}}}
        if (Test-Path $GetStatusAlgoBans) {$StatusAlgoBans = Get-Content $GetStatusAlgoBans | ConvertFrom-Json}
        else {$StatusAlgoBans = $null}
        if (Test-Path $GetStatusPoolBans) {$StatusPoolBans = Get-Content $GetStatusPoolBans | ConvertFrom-Json}
        else {$StatusPoolBans = $null}
        if (Test-Path $GetStatusMinerBans) {$StatusMinerBans = Get-Content $GetStatusMinerBans | ConvertFrom-Json}
        else {$StatusMinerBans = $null}
        $StatusDate = Get-Date
        $StatusDate | Out-File ".\build\txt\mineractive.txt"
        $StatusDate | Out-File ".\build\txt\minerstats.txt"
        Get-MinerStatus | Out-File ".\build\txt\minerstats.txt" -Append
        $mcolor = "93"
        $me = [char]27
        $MiningStatus = "$me[${mcolor}mCurrently Mining $($BestMiners_Combo.Algo) Algorithm${me}[0m"
        $MiningStatus | Out-File ".\build\txt\minerstats.txt" -Append
        $BanMessage = @()
        $mcolor = "91"
        $me = [char]27
        if ($StatusAlgoBans) {$StatusAlgoBans | foreach {$BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from all pools${me}[0m"}}
        if ($StatusPoolBans) {$StatusPoolBans | foreach {$BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from $($_.MinerPool)${me}[0m"}}
        if ($StatusMinerBans) {$StatusMinerBans | foreach {$BanMessage += "$me[${mcolor}m$($_.Name) is banned${me}[0m"}}
        if ($GetDLBans) {$GetDLBans | foreach {$BanMessage += "$me[${mcolor}m$($_) failed to download${me}[0m"}}
        if ($ConserveMessage) {$ConserveMessage | foreach {$BanMessage += "$me[${mcolor}m$($_)${me}[0m"}}
        $BanMessage | Out-File ".\build\txt\minerstats.txt" -Append
        $BestActiveMiners | ConvertTo-Json | Out-File ".\build\txt\bestminers.txt"
        $Current_BestMiners = $BestActiveMiners | ConvertTo-Json -Compress
        $StatusLite = Get-StatusLite
        $StatusDate | Out-File ".\build\txt\minerstatslite.txt"
        $StatusLite | OUt-File ".\build\txt\minerstatslite.txt" -Append
        $MiningStatus | Out-File ".\build\txt\minerstatslite.txt" -Append
        $BanMessage | Out-File ".\build\txt\minerstatslite.txt" -Append

        ## Simple hash table for clearing ports. Used Later
        $PreviousMinerPorts = @{AMD1 = ""; NVIDIA1 = ""; NVIDIA2 = ""; NVIDIA3 = ""; CPU = ""}


        ## Records miner run times, and closes them. Starts New Miner instances and records
        ## there tracing information.
        $ActiveMinerPrograms | ForEach {
            if ($_.BestMiner -eq $false) {
                if ($Platform -eq "windows") {
                    if ($_.XProcess -eq $null) {$_.Status = "Failed"}
                    elseif ($_.XProcess.HasExited -eq $false) {
                        $_.Active += (Get-Date) - $_.XProcess.StartTime
                        $_.XProcess.CloseMainWindow() | Out-Null
                        $_.Status = "Idle"
                    }
                }
                elseif ($Platform -eq "linux") {
                    if ($_.XProcess = $null) {$_.Status = "Failed"}
                    else {
                        $PreviousMinerPorts.$($_.Type) = "($_.Port)"
                        $_.Status = "Idle"
                        $PIDDate = ".\build\pid\$($_.Name)_$($_.Type)_$($_.Coins)_date.txt"
                        if (Test-path $PIDDate) {
                            else {
                                $_.Status = "Idle"
                                $MinerInfo = ".\build\pid\$($_.Name)_$($_.Type)_$($_.Coins)_info.txt"
                                if (Test-path $MinerInfo) {
                                    $MI = Get-Content $MinerInfo | ConvertFrom-Json
                                    $PIDTime = [DateTime]$MI.start_date
                                    $_.Active += (Get-Date) - $PIDTime
                                    Write-Host "Stopping Miner: $($_.Name) on $($_Type) screen" -ForegroundColor Yellow
                                    Start-Process "start-stop-daemon" -ArgumentList "--stop --name $($MI.miner_exec) --pidfile $($MI.pid_path) --retry 5" -Wait
                                }
                            }                        
                        }
                    }
                }
            }
            elseif ($null -eq $_.XProcess -or $_.XProcess.HasExited -and $Lite -eq "No") {
                if ($TimeDeviation -ne 0) {
                    $Restart = $true
                    $_.Activated++
                    $_.InstanceName = "$($_.Type)-$($Instance)"
                    $Current = $_ | ConvertTo-Json -Compress
                    $PreviousPorts = $PreviousMinerPorts | ConvertTo-Json -Compress
                    $_.Xprocess = Start-LaunchCode -PP $PreviousPorts -Platforms $Platform -MinerRound $Current_BestMiners -NewMiner $Current
                    $Instance++
                }
                if ($Restart -eq $true) {
                    if ($_.XProcess -eq $null -or $_.Xprocess.HasExited -eq $true) {
                        $_.Status = "Failed"
                        $NoMiners = $true
                        Write-Host "$($_.MinerName) Failed To Launch" -ForegroundColor Darkred
                    }
                    else {
                        $_.Status = "Running"
                        Write-Host "Process Id is $($_.XProcess.ID)"
                        Write-Host "$($_.MinerName) Is Running!" -ForegroundColor Green
                    } 
                }
            }
        }


        ##Outputs the correct notification of miner launches.
        ##Restarts Timer for Interval.
        $MinerWatch.Restart()
        if ($Restart -eq $true -and $NoMiners -eq $true) {Invoke-MinerWarning}
        if ($Platform -eq "linux" -and $Restart -eq $true -and $NoMiners -eq $false) {Invoke-MinerSuccess1}
        if ($Platform -eq "windows" -and $Restart -eq $true -and $NoMiners -eq $false) {Invoke-MinerSuccess1}
        if ($Restart -eq $false) {Invoke-NoChange}


        ##Check For Miner that are benchmarking, sets flag to $true and notfies user.
        $BenchmarkMode = $false
        $SWARM_IT = $false
        $SwitchTime = $null
        $MinerInterval = $null
        $ModeCheck = 0
        $BestActiveMiners | Foreach {if (-not (Test-Path ".\stats\$($_.Name)_$($_.Algo)_hashrate.txt")) {$BenchmarkMode = $true; }}

        #Set Interval
        if ($BenchmarkMode -eq $true) {
            Write-Host "SWARM is Benchmarking Miners." -Foreground Yellow;
            Print-Benchmarking
            $MinerInterval = $Benchmark
        }
        else {
            if ($SWARM_Mode -eq "Yes") {
                $SWARM_IT = $true
                Write-Host "SWARM MODE ACTIVATED!" -ForegroundColor Green;
                $SwitchTime = Get-Date
                Write-Host "SWARM Mode Start Time is $SwitchTime" -ForegroundColor Cyan;
                $MinerInterval = 10000000;
            }
            else {$MinerInterval = $Interval}
        }

        ## Load mini logo
        if ($Platform -eq "linux") {Get-Logo}

        #Clear Logs If There Are 12
        if ($Log -eq 12) {
            Remove-Item ".\logs\*miner*" -Force
            $Log = 0
        } 

        #Start Another Log If An Hour Has Passed
        if ($LogTimer.Elapsed.TotalSeconds -ge 3600) {
            Stop-Transcript
            Start-Sleep -S 3
            if (Test-Path ".\logs\*active*") {
                Set-Location ".\logs"
                $OldActiveFile = Get-ChildItem "*active*"
                $OldActiveFile | Foreach {
                    $RenameActive = $_ -replace ("-active", "")
                    if (Test-Path $RenameActive) {Remove-Item $RenameActive -Force}
                    Rename-Item $_ -NewName $RenameActive -force
                }
                Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
            }
            $Log++
            Start-Transcript ".\logs\miner$($Log)-active.log"
            $LogTimer.Restart()
        }

        ##Write Details Of Active Miner And Stats To File
        Get-MinerActive | Out-File ".\build\txt\mineractive.txt" -Append

        ##Remove Old Jobs From Memory
        Get-Job -State Completed | Remove-Job
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        [GC]::Collect()

        ##Miner Loop Linux
        if ($Platform -eq "linux") {
            Do {
                Set-Countdown
                Get-MinerHashRate
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval - 20)) {break}
                Set-Countdown
                Get-MinerHashRate
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval - 20)) {break}
                Set-Countdown
                Restart-Miner
                Write-Host "

      Type 'stats' in another terminal to view miner statistics- This IS a remote command!
      https://github.com/MaynardMiner/Swarm/wiki/HiveOS-management >> Right Click 'Open URL In Browser'

  " -foreground Magenta
                Get-MinerHashRate
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval - 20)) {break}
                Set-Countdown
                Get-MinerHashRate
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval - 20)) {break}
                Set-Countdown
                Restart-Miner
                Get-MinerHashRate
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval - 20)) {break}
                Set-Countdown
                Write-Host "

      Type 'active' in another terminal to view active/previous miners- this IS a remote command!
      https://github.com/MaynardMiner/Swarm/wiki/HiveOS-management >> Right Click 'Open URL In Browser'

  " -foreground Magenta
                Get-MinerHashRate
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval - 20)) {break}
                $RestartData = Restart-Database
                if ($RestartData -eq "Yes") {break}

            }While ($MinerWatch.Elapsed.TotalSeconds -lt ($MinerInterval - 20))
        }
        else {
            ##Miner Loop Windows:
            Clear-Host
            Get-Logo
            Get-Date | Out-Host
            Get-MinerActive | Out-Host
            Get-MinerStatus | Out-Host
            Get-VM | Out-Host
            if ($SWARM_IT) {
                if ($SwitchTime) {
                    Write-Host "SWARM MODE ACTIVATED!" -ForegroundColor Green;
                    Write-Host "SWARM Mode Start Time is $SwitchTime" -ForegroundColor Cyan;
                }
            }
            if ($BenchmarkMode -eq $true) {Write-Host "Swarm Is Benchmarking Miners" -ForegroundColor Yellow}
            $BanMessage
            Do {
                Restart-Miner
                if ($MinerWatch.Elapsed.TotalSeconds -ge ($MinerInterval - 20)) {break}
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
                if ($SWARM_IT) {$ModeCheck = Invoke-SWARMMode $SwitchTime}
                if ($ModeCheck -gt 0) {break}
                Start-Sleep -s 5
            }While ($MinerWatch.Elapsed.TotalSeconds -lt ($MinerInterval - 20))
        }


        ## Start WattOMeter function
        if ($Platform -eq "linux" -or $Platform -eq "windows") {
            if ($WattOMeter -eq "Yes") {
                Print-WattOMeter
                if ($Type -like "*NVIDIA*") {Get-Power -PwrType "NVIDIA" -Platforms $Platform}
                if ($Type -like "*AMD*") {Get-Power -PwrType "AMD" -Platforms $Platform}
                Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
            }
        }

        ##Benchmarking/Timeout.    
        $BestActiveMiners | foreach {
            $MinerPoolBan = $false
            $MinerAlgoBan = $false
            $MinerBan = $false
            $Strike = $false
            if ($_.BestMiner -eq $true) {
                if ($null -eq $_.XProcess -or $_.XProcess.HasExited) {
                    $_.Status = "Failed"
                    $_.WasBenchMarked = $False
                    $Strike = $true
                    Write-Host "Cannot Benchmark- Miner is not running" -ForegroundColor Red
                }
                else { 
                    if ($TimeDeviation -ne 0) {
                        $_.HashRate = 0
                        $_.WasBenchmarked = $False
                        $WasActive = [math]::Round(((Get-Date) - $_.XProcess.StartTime).TotalSeconds)
                        if ($WasActive -ge $StatsInterval) {
                            Write-Host "$($_.Name) $($_.Coins) Was Active for $WasActive Seconds"
                            Write-Host "Attempting to record hashrate for $($_.Name) $($_.Coins)" -foregroundcolor "Cyan"
                            for ($i = 0; $i -lt 4; $i++) {
                                $Miner_HashRates = Get-HashRate -Type $_.Type
                                $_.HashRate = $Miner_HashRates
                                if ($_.WasBenchmarked -eq $False) {
                                    $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($_.Algo)_hashrate.txt"
                                    $PowerFilePath = Join-Path ".\stats" "$($_.Name)_$($_.Algo)_power.txt"
                                    $NewHashrateFilePath = Join-Path ".\backup" "$($_.Name)_$($_.Algo)_hashrate.txt"
                                    $NewPowerFilePath = Join-Path ".\backup" "$($_.Name)_$($_.Algo)_power.txt"
                                    if (-not (Test-Path "backup")) {New-Item "backup" -ItemType "directory" | Out-Null}
                                    Write-Host "$($_.Name) $($_.Coins) Starting Bench"
                                    if ($null -eq $Miner_HashRates -or $Miner_HashRates -eq 0) {
                                        $Strike = $true
                                        Write-Host "Stat Attempt Yielded 0" -Foregroundcolor Red
                                        Start-Sleep -S .25
                                        $GPUPower = 0
                                        if ($WattOMeter -eq "yes" -and $_.Type -ne "CPU") {
                                            if ($Watts.$($_.Algo)) {
                                                $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                            }
                                            else {
                                                $WattTypes = @{NVIDIA1_Watts = ""; NVIDIA2_Watts = ""; NVIDIA3_Watts = ""; AMD1_Watts = ""; CPU_Watts = ""}
                                                $Watts | Add-Member "$($_.Algo)" $WattTypes
                                                $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                            }
                                        }
                                    }
                                    else {
                                        if ($WattOMeter -eq "yes" -and $_.Type -ne "CPU") {try {$GPUPower = Set-Power -MinerDevices $($_.Devices) -Command "stat" -PwrType $($_.Type)}catch {Write-Host "WattOMeter Failed" $GPUPower = 0}}
                                        else {$GPUPower = 1}
                                        if ($WattOMeter -eq "yes" -and $_.Type -ne "CPU") {
                                            if ($Watts.$($_.Algo)) {
                                                $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                            }
                                            else {
                                                $WattTypes = @{NVIDIA1_Watts = ""; NVIDIA2_Watts = ""; NVIDIA3_Watts = ""; AMD1_Watts = ""; CPU_Watts = ""}
                                                $Watts | Add-Member "$($_.Algo)" $WattTypes
                                                $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                            }
                                        }
                                        $Stat = Set-Stat -Name "$($_.Name)_$($_.Algo)_hashrate" -Value $Miner_HashRates
                                        Start-Sleep -s 1
                                        $GetLiveStat = Get-Stat "$($_.Name)_$($_.Algo)_hashrate"
                                        $StatCheck = "$($GetLiveStat.Live)"
                                        $ScreenCheck = "$($StatCheck | ConvertTo-Hash)"
                                        if ($ScreenCheck -eq "0.00 PH" -or $null -eq $StatCheck) {
                                            $Strike = $true
                                            $_.WasBenchmarked = $False
                                            Write-Host "Stat Failed Write To File" -Foregroundcolor Red
                                        }
                                        else {
                                            Write-Host "Recorded Hashrate For $($_.Name) $($_.Coins) Is $($ScreenCheck)" -foregroundcolor "magenta"
                                            if ($WattOmeter -eq "Yes") {Write-Host "Watt-O-Meter scored $($_.Name) $($_.Coins) at $($GPUPower) Watts" -ForegroundColor magenta}
                                            if (-not (Test-Path $NewHashrateFilePath)) {
                                                Copy-Item $HashrateFilePath -Destination $NewHashrateFilePath -force
                                                Write-Host "$($_.Name) $($_.Coins) Was Benchmarked And Backed Up" -foregroundcolor yellow
                                            }
                                            $_.WasBenchmarked = $True
                                            Get-Intensity $_.Type $_.Coins $_.Path
                                            Write-Host "Stat Written
" -foregroundcolor green
                                            $Strike = $false
                                        } 
                                    }
                                }
                            }
                            ##Check For High Rejections
                            $RejectCheck = Join-Path ".\timeout\warnings" "$($_.Name)_$($_.Algo)_rejection.txt"
                            if (Test-Path $RejectCheck) {
                                Write-Host "Rejections Are Too High" -ForegroundColor DarkRed
                                $_.WasBenchmarked = $false
                                $Strike = $true
                            }
                        }
                    }
                }

                if ($Strike -ne $true) {
                    if ($Warnings."$($_.Name)" -ne $null) {$Warnings."$($_.Name)" | foreach {try {$_.bad = 0}catch {}}}
                    if ($Warnings."$($_.Name)_$($_.Algo)" -ne $null) {$Warnings."$($_.Name)_$($_.Algo)" | foreach {try {$_.bad = 0}catch {}}}
                    if ($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" -ne $null) {$Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach {try {$_.bad = 0}catch {}}}
                }
		 
                ## Strike-Out System. Will not work with Lite Mode
                if ($LITE -eq "No") {
                    if ($Strike -eq $true) {
                        if ($_.WasBenchmarked -eq $False) {
                            if (-not (Test-Path ".\timeout")) {New-Item "timeout" -ItemType "directory" | Out-Null}
                            if (-not (Test-Path ".\timeout\pool_block")) {New-Item -Path ".\timeout" -Name "pool_block" -ItemType "directory" | Out-Null}
                            if (-not (Test-Path ".\timeout\algo_block")) {New-Item -Path ".\timeout" -Name "algo_block" -ItemType "directory" | Out-Null}
                            if (-not (Test-Path ".\timeout\miner_block")) {New-Item -Path ".\timeout" -Name "miner_block" -ItemType "directory" | Out-Null}
                            if (-not (Test-Path ".\timeout\warnings")) {New-Item -Path ".\timeout" -Name "warnings" -ItemType "directory" | Out-Null}
                            Start-Sleep -S .25
                            $TimeoutFile = Join-Path ".\timeout\warnings" "$($_.Name)_$($_.Algo)_TIMEOUT.txt"
                            $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($_.Algo)_hashrate.txt"
                            if (-not (Test-Path $TimeoutFile)) {"$($_.Name) $($_.Coins) Hashrate Check Timed Out" | Set-Content ".\timeout\warnings\$($_.Name)_$($_.Algo)_TIMEOUT.txt" -Force}
                            if ($Warnings."$($_.Name)" -eq $null) {$Warnings += [PSCustomObject]@{"$($_.Name)" = [PSCustomObject]@{bad = 0}}
                            }
                            if ($Warnings."$($_.Name)_$($_.Algo)" -eq $null) {$Warnings += [PSCustomObject]@{"$($_.Name)_$($_.Algo)" = [PSCustomObject]@{bad = 0}}
                            }
                            if ($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" -eq $null) {$Warnings += [PSCustomObject]@{"$($_.Name)_$($_.Algo)_$($_.MinerPool)" = [PSCustomObject]@{bad = 0}}
                            }
                            $Warnings."$($_.Name)" | foreach {try {$_.bad++}catch {}}
                            $Warnings."$($_.Name)_$($_.Algo)" | foreach {try {$_.bad++}catch {}}
                            $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach {try {$_.bad++}catch {}}
                            if ($Warnings."$($_.Name)".bad -ge $MinerBanCount) {$MinerBan = $true}
                            if ($Warnings."$($_.Name)_$($_.Algo)".bad -ge $AlgoBanCount) {$MinerAlgoBan = $true}
                            if ($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)".bad -ge $PoolBanCount) {$MinerPoolBan = $true}
                            ##Strike One
                            if ($MinerPoolBan -eq $false -and $MinerAlgoBan -eq $false -and $MinerBan -eq $false) {
                                Write-Host "First Strike: There was issue with benchmarking.
" -ForegroundColor DarkRed;
                            }
                            ##Strike Two
                            if ($MinerPoolBan -eq $true) {
                                $minerjson = $_ | ConvertTo-Json -Compress
                                $reason = Get-MinerTimeout $minerjson
                                $HiveMessage = "Ban: $($_.Name)/$($_.Algo) From $($_.MinerPool)- $reason "
                                Write-Host "Strike Two: Benchmarking Has Failed - $HiveMessage
" -ForegroundColor DarkRed
                                $NewPoolBlock = @()
                                if (Test-Path ".\timeout\pool_block\pool_block.txt") {$GetPoolBlock = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json}
                                Start-Sleep -S 1
                                if ($GetPoolBlock) {$GetPoolBlock | foreach {$NewPoolBlock += $_}}
                                $NewPoolBlock += $_
                                $NewPoolBlock | ConvertTo-Json | Set-Content ".\timeout\pool_block\pool_block.txt"
                                $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach {try {$_.bad = 0}catch {}}
                                $HiveWarning = @{result = @{command = "timeout"}}
                                if ($HiveOS -eq "Yes") {try {$SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror}catch {Write-Warning "Failed To Notify HiveOS"}}
                                Start-Sleep -S 1
                            }
                            ##Strike Three: He's Outta Here
                            if ($MinerAlgoBan -eq $true) {
                                $minerjson = $_ | ConvertTo-Json -Compress
                                $reason = Get-MinerTimeout $minerjson
                                $HiveMessage = "Ban: $($_.Name)/$($_.Algo) from all pools- $reason "
                                Write-Host "Strike three: $HiveMessage
" -ForegroundColor DarkRed
                                $NewAlgoBlock = @()
                                if (test-path $HashRateFilePath) {remove-item $HashRateFilePath -Force}
                                if (Test-Path ".\timeout\algo_block\algo_block.txt") {$GetAlgoBlock = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json}
                                Start-Sleep -S 1
                                if ($GetAlgoBlock) {$GetAlgoBlock | foreach {$NewAlgoBlock += $_}}
                                $NewAlgoBlock += $_
                                $NewAlgoBlock | ConvertTo-Json | Set-Content ".\timeout\algo_block\algo_block.txt"
                                $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach {try {$_.bad = 0}catch {}}
                                $Warnings."$($_.Name)_$($_.Algo)" | foreach {try {$_.bad = 0}catch {}}
                                $HiveWarning = @{result = @{command = "timeout"}}
                                if ($HiveOS -eq "Yes") {try {$SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror}catch {Write-Warning "Failed To Notify HiveOS"} }
                                Start-Sleep -S 1
                            }
                            ##Strike Four: Miner is Finished
                            if ($MinerBan -eq $true) {
                                $HiveMessage = "$($_.Name) sucks, shutting it down."
                                Write-Host "$HiveMessage
" -ForegroundColor DarkRed
                                $NewMinerBlock = @()
                                if (test-path $HashRateFilePath) {remove-item $HashRateFilePath -Force}
                                if (Test-Path ".\timeout\miner_block\miner_block.txt") {$GetMinerBlock = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json}
                                Start-Sleep -S 1
                                if ($GetMinerBlock) {$GetMinerBlock | foreach {$NewMinerBlock += $_}}
                                $NewMinerBlock += $_
                                $NewMinerBlock | ConvertTo-Json | Set-Content ".\timeout\miner_block\miner_block.txt"
                                $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)"| foreach {try {$_.bad = 0}catch {}}
                                $Warnings."$($_.Name)_$($_.Algo)" | foreach {try {$_.bad = 0}catch {}}
                                $Warnings."$($_.Name)" | foreach {try {$_.bad = 0}catch {}}
                                $HiveWarning = @{result = @{command = "timeout"}}
                                if ($HiveOS -eq "Yes") {try {$SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror}catch {Write-Warning "Failed To Notify HiveOS"}}
                                Start-Sleep -S 1
                            }
                        }
                    }
                }
            }
        }
    }
    else {Start-ASIC}
}

Stop-Transcript
Exit
