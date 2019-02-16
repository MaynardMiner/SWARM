##Miner Path Information
if ($cpu.stak_cpu.path1) {$Path = "$($cpu.stak_cpu.path1)"}
else {$Path = "None"}
if ($cpu.stak_cpu.uri) {$Uri = "$($cpu.stak_cpu.uri)"}
else {$Uri = "None"}
if ($cpu.stak_cpu.minername) {$MinerName = "$($cpu.stak_cpu.minername)"}
else {$MinerName = "None"}
if ($Platform -eq "linux") {$Build = "Tar"}
elseif ($Platform -eq "windows") {$Build = "Zip"}

$ConfigType = "CPU"

#Max threads must be specified- XMR-STAK has no -t option

##Get Configuration File
$GetConfig = "$dir\config\miners\stak_cpu.json"
try {$Config = Get-Content $GetConfig | ConvertFrom-Json}
catch {Write-Warning "Warning: No config found at $GetConfig"}

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | foreach {$Prestart += "$($_)"}

##Build Miner Settings
if ($CoinAlgo -eq $null) {
    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $AlgoPools | Where Symbol -eq $MinerAlgo | foreach {
            if ($Algorithm -eq "$($_.Algorithm)") {
                if ($Config.$ConfigType.difficulty.$($_.Algorithm)) {$Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))"}else {$Diff = ""}
                [PSCustomObject]@{
                    Delay      = $Config.$ConfigType.delay
                    Symbol     = "$($_.Algorithm)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    DeviceCall = "xmrstak-opt"
                    Arguments  = "--currency $($Config.$ConfigType.naming.$($_.Algorithm)) -i 60045 --url stratum+tcp://$($_.Host):$($_.Port) --user $($_.User1) --pass $($_.Pass1)$($Diff) --rigid SWARM --noAMD --noNVIDIA --use-nicehash $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
                    Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) {$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price)}else {0}
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") {$Watts.$($_.Algorithm)."$($ConfigType)_Watts"}elseif ($Watts.default."$($ConfigType)_Watts") {$Watts.default."$($ConfigType)_Watts"}else {0}}
                    MinerPool  = "$($_.Name)"
                    FullName   = "$($_.Mining)"
                    Port       = 60045
                    API        = "xmrstak-opt"
                    URI        = $Uri
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                }
            }
        }
    }
}