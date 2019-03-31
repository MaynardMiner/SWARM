##Miner Path Information
if ($amd.wildrig.path1) {$Path = "$($amd.wildrig.path1)"}
else {$Path = "None"}
if ($amd.wildrig.uri) {$Uri = "$($amd.wildrig.uri)"}
else {$Uri = "None"}
if ($amd.wildrig.minername) {$MinerName = "$($amd.wildrig.minername)"}
else {$MinerName = "None"}
if ($Platform -eq "linux") {$Build = "Tar"}
elseif ($Platform -eq "windows") {$Build = "Zip"}

$ConfigType = "AMD1"

##Log Directory
$Log = Join-Path $dir "logs\$ConfigType.log"

##Get Configuration File
$GetConfig = "$dir\config\miners\wildrig.json"
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
                    Devices    = "none"
                    DeviceCall = "wildrig"
                    Arguments  = "--opencl-platform=$AMDPlatform --api-port 60050 --algo $($Config.$ConfigType.naming.$($_.Algorithm)) --url stratum+tcp://$($_.Host):$($_.Port) --user $($_.User1) --pass $($_.Pass1)$($Diff) $($Config.$ConfigType.commands.$($Config.$ConfigType.naming.$($_.Algorithm)))"
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
                    Port       = 60050
                    API        = "wildrig"
                    URI        = $Uri
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                    Log        = $Log
                }            
            }
        }
    }
}
