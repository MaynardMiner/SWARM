##Miner Path Information
if ($nvidia.ttminer.path1) {$Path = "$($nvidia.ttminer.path1)"}
else {$Path = "None"}
if ($nvidia.ttminer.uri) {$Uri = "$($nvidia.ttminer.uri)"}
else {$Uri = "None"}
if ($nvidia.ttminer.minername) {$MinerName = "$($nvidia.ttminer.minername)"}
else {$MinerName = "None"}
if ($Platform -eq "linux") {$Build = "Tar"}
elseif ($Platform -eq "windows") {$Build = "Zip"}

$ConfigType = "NVIDIA1"

##Parse -GPUDevices
if ($NVIDIADevices1 -ne '') {$Devices = $NVIDIADevices1}

##Get Configuration File
$GetConfig = "$dir\config\miners\ttminer.json"
try {$Config = Get-Content $GetConfig | ConvertFrom-Json}
catch {Write-Warning "Warning: No config found at $GetConfig"}

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
$Prestart = @()
if (Test-Path $BE) {$Prestart += "export LD_PRELOAD=libcurl-compat.so.3.0.0"}
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | foreach {$Prestart += "$($_)"}

##Build Miner Settings
if ($CoinAlgo -eq $null) {
    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $AlgoPools | Where Symbol -eq $MinerAlgo | foreach {
            if ($Algorithm -eq "$($_.Algorithm)") {
                [PSCustomObject]@{
                    Delay      = $Config.$ConfigType.delay
                    Symbol     = "$($_.Algorithm)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    DeviceCall = "claymore"
                    Arguments  = "-a $($Config.$ConfigType.naming.$($_.Algorithm)) --nvidia -o $($_.Protocol)://$($_.Host):$($_.Port) -b localhost:2068 -u $($_.User1) -p $($_.Pass1) $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
                    Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) {$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price)}else {0}
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") {$Watts.$($_.Algorithm)."$($ConfigType)_Watts"}elseif ($Watts.default."$($ConfigType)_Watts") {$Watts.default."$($ConfigType)_Watts"}else {0}}
                    ocpower    = if ($Config.$ConfigType.oc.$($_.Algorithm).power) {$Config.$ConfigType.oc.$($_.Algorithm).power}else {$OC."default_$($ConfigType)".Power}
                    occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) {$Config.$ConfigType.oc.$($_.Algorithm).core}else {$OC."default_$($ConfigType)".core}
                    ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) {$Config.$ConfigType.oc.$($_.Algorithm).memory}else {$OC."default_$($ConfigType)".memory}
                    MinerPool  = "$($_.Name)"
                    FullName   = "$($_.Mining)"
                    Port       = 2068
                    API        = "claymore"
                    URI        = $Uri
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                }
            }
        }
    }
}