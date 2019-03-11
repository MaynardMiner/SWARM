##Miner Path Information
if ($amd.teamredminer.path1) {$Path = "$($amd.teamredminer.path1)"}
else {$Path = "None"}
if ($amd.teamredminer.uri) {$Uri = "$($amd.teamredminer.uri)"}
else {$Uri = "None"}
if ($amd.teamredminer.minername) {$MinerName = "$($amd.teamredminer.minername)"}
else {$MinerName = "None"}
if ($Platform -eq "linux") {$Build = "Tar"}
elseif ($Platform -eq "windows") {$Build = "Zip"}

$ConfigType = "AMD1"

##Parse -GPUDevices
if ($AMDDevices1 -ne "none") {$Devices = $AMDDevices1}

##Get Configuration File
$GetConfig = "$dir\config\miners\teamredminer.json"
try {$Config = Get-Content $GetConfig | ConvertFrom-Json}
catch {Write-Warning "Warning: No config found at $GetConfig"}

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | foreach {$Prestart += "$($_)"}

if ($CoinAlgo -eq $null) {
    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $AlgoPools | Where Symbol -eq $MinerAlgo | foreach {
            if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
                if ($Config.$ConfigType.difficulty.$($_.Algorithm)) {$Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))"}else {$Diff = ""}
                [PSCustomObject]@{
                    Delay      = $Config.$ConfigType.delay
                    Symbol     = "$($_.Algorithm)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    DeviceCall = "tdxminer"
                    Arguments  = "--platform $AMDPlatform -a $($Config.$ConfigType.naming.$($_.Algorithm)) --api_listen=0.0.0.0:4028 -o stratum+tcp://$($_.Host):$($_.Port) -u $($_.User1) -p $($_.Pass1)$($DIff) $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
                    Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) {$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price)}else {0}
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") {$Watts.$($_.Algorithm)."$($ConfigType)_Watts"}elseif ($Watts.default."$($ConfigType)_Watts") {$Watts.default."$($ConfigType)_Watts"}else {0}}
                    ocdpm      = if ($Config.$ConfigType.oc.$($_.Algorithm).dpm) {$Config.$ConfigType.oc.$($_.Algorithm).dpm}else {$OC."default_$($ConfigType)".dpm}
                    ocv        = if ($Config.$ConfigType.oc.$($_.Algorithm).v) {$Config.$ConfigType.oc.$($_.Algorithm).v}else {$OC."default_$($ConfigType)".v}
                    occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) {$Config.$ConfigType.oc.$($_.Algorithm).core}else {$OC."default_$($ConfigType)".core}
                    ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).mem) {$Config.$ConfigType.oc.$($_.Algorithm).mem}else {$OC."default_$($ConfigType)".memory}
                    ocmdpm     = if ($Config.$ConfigType.oc.$($_.Algorithm).mdpm) {$Config.$ConfigType.oc.$($_.Algorithm).mdpm}else {$OC."default_$($ConfigType)".mdpm}
                    ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) {$Config.$ConfigType.oc.$($_.Algorithm).fans}else {$OC."default_$($ConfigType)".fans}
                    MinerPool  = "$($_.Name)"
                    FullName   = "$($_.Mining)"
                    Port       = 4028 
                    API        = "sgminer-gm"
                    URI        = $Uri
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                }
            }
        }
    }
}
