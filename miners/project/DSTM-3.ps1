##Miner Path Information
if ($nvidia.dstm.path3) {$Path = "$($nvidia.dstm.path3)"}
else {$Path = "None"}
if ($nvidia.dstm.uri) {$Uri = "$($nvidia.dstm.uri)"}
else {$Uri = "None"}
if ($nvidia.dstm.minername) {$MinerName = "$($nvidia.dstm.minername)"}
else {$MinerName = "None"}
if ($Platform -eq "linux") {$Build = "Tar"}
elseif ($Platform -eq "windows") {$Build = "Zip"}

$ConfigType = "NVIDIA3"

##Log Directory
$Log = Join-Path $dir "logs\$ConfigType.log"

##Parse -GPUDevices
if ($NVIDIADevices3 -ne "none") {
    $GPUDevices3 = $NVIDIADevices3
    $GPUDevices3 = $GPUDevices3 -replace ',', ' '
    $Devices = $GPUDevices3
}
else {$Devices = "none"}

##Get Configuration File
$GetConfig = "$dir\config\miners\dstm.json"
try {$Config = Get-Content $GetConfig | ConvertFrom-Json}
catch {Write-Warning "Warning: No config found at $GetConfig"}

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | foreach {$Prestart += "$($_)"}

if($Coins -eq $true){$Pools = $CoinPools}else{$Pools = $AlgoPools}

##Build Miner Settings
if ($CoinAlgo -eq $null) {
    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $Pools | Where Algorithm -eq $MinerAlgo | foreach {
            if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
                if ($Config.$ConfigType.difficulty.$($_.Algorithm)) {$Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))"}else {$Diff = ""}
                [PSCustomObject]@{
                    Delay      = $Config.$ConfigType.delay
                    Symbol     = "$($_.Symbol)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    DeviceCall = "dstm"
                    Arguments  = "--server $($_.Host) --port $($_.Port) --user $($_.User3) --pass $($_.Pass3)$($Diff) --telemetry=0.0.0.0:43002 $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
                    Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) {$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price)}else {0}
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") {$Watts.$($_.Algorithm)."$($ConfigType)_Watts"}elseif ($Watts.default."$($ConfigType)_Watts") {$Watts.default."$($ConfigType)_Watts"}else {0}}
                    ocpower    = if ($Config.$ConfigType.oc.$($_.Algorithm).power) {$Config.$ConfigType.oc.$($_.Algorithm).power}else {$OC."default_$($ConfigType)".Power}
                    occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) {$Config.$ConfigType.oc.$($_.Algorithm).core}else {$OC."default_$($ConfigType)".core}
                    ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) {$Config.$ConfigType.oc.$($_.Algorithm).memory}else {$OC."default_$($ConfigType)".memory}
                    ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) {$Config.$ConfigType.oc.$($_.Algorithm).fans}else {$OC."default_$($ConfigType)".fans}
                    FullName   = "$($_.Mining)"
                    API        = "dstm"
                    Port       = 43002
                    MinerPool  = "$($_.Name)"
                    URI        = $Uri
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                    Log        = $Log 
                }            }
        }
    }
}
