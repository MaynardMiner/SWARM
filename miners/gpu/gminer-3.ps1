##Miner Path Information
if ($nvidia.gminer.path3) {$Path = "$($nvidia.gminer.path3)"}
else {$Path = "None"}
if ($nvidia.gminer.uri) {$Uri = "$($nvidia.gminer.uri)"}
else {$Uri = "None"}
if ($nvidia.gminer.minername) {$MinerName = "$($nvidia.gminer.minername)"}
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

##gminer apparently doesn't know how to tell the difference between
##cuda and amd devices, like every other miner that exists. So now I 
##have to spend an hour and parse devices
##to matching platforms.
if ($NVIDIADevices3 -ne "none") {
    $GPUDevices3 = $NVIDIADevices3
    $GPUEDevices3 = $GPUDevices3 -split ","
    $GPUEDevices3 | % {$ArgDevices += "$($GCount.NVIDIA.$_) " }
    $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1)
}
else {$GCount.NVIDIA.PSObject.Properties.Name | % { $ArgDevices += "$($GCount.NVIDIA.$_) "}; $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1)}
        
##Get Configuration File
$GetConfig = "$dir\config\miners\gminer.json"
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
                    ArgDevices = $ArgDevices
                    DeviceCall = "gminer"
                    Arguments  = "--api 42002 --server $($_.Host) --port $($_.Port) --user $($_.User3) --logfile `'$Log`' --pass $($_.Pass3)$Diff $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
                    Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) {$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price)}else {0}
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") {$Watts.$($_.Algorithm)."$($ConfigType)_Watts"}elseif ($Watts.default."$($ConfigType)_Watts") {$Watts.default."$($ConfigType)_Watts"}else {0}}
                    ocpower    = if ($Config.$ConfigType.oc.$($_.Algorithm).power) {$Config.$ConfigType.oc.$($_.Algorithm).power}else {$OC."default_$($ConfigType)".Power}
                    occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) {$Config.$ConfigType.oc.$($_.Algorithm).core}else {$OC."default_$($ConfigType)".core}
                    ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) {$Config.$ConfigType.oc.$($_.Algorithm).memory}else {$OC."default_$($ConfigType)".memory}
                    ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) {$Config.$ConfigType.oc.$($_.Algorithm).fans}else {$OC."default_$($ConfigType)".fans}
                    MinerPool  = "$($_.Name)"
                    FullName   = "$($_.Mining)"
                    API        = "gminer"
                    Port       = 42002
                    URI        = $Uri
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                    Log        = "miner_generated" 
                }            
            }
        }
    }
}