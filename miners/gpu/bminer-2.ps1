##Miner Path Information
if ($nvidia.bminer.path2) { $Path = "$($nvidia.bminer.path2)" }
else { $Path = "None" }
if ($nvidia.bminer.uri) { $Uri = "$($nvidia.bminer.uri)" }
else { $Uri = "None" }
if ($nvidia.bminer.MinerName) { $MinerName = "$($nvidia.bminer.MinerName)" }
else { $MinerName = "None" }
if ($Platform -eq "linux") { $Build = "Tar" }
elseif ($Platform -eq "windows") { $Build = "Zip" }

$ConfigType = "NVIDIA2"
$User = "User2"

##Log Directory
$Log = Join-Path $dir "logs\$ConfigType.log"

##Log Directory
$Log = Join-Path $dir "logs\$ConfigType.log"

##Parse -GPUDevices
if ($NVIDIADevices2 -ne "none") { $Devices = $NVIDIADevices2 }
else { $Devices = "none" }

##Get Configuration File
$GetConfig = "$dir\config\miners\bminer.json"
try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
catch { Write-Warning "Warning: No config found at $GetConfig" }

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

##Build Miner Settings
$Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $MinerAlgo = $_
    $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
        if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
            Switch ($_.Name) {
                "nicehash" { $Pass2 = "" }
                default { $Pass2 = ".$($($_.Pass2) -replace ",","%2C")" }
            }
            if ($_.Worker) { $Pass2 = ".$($_.Worker)" }
            if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = "%2Cd=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
            [PSCustomObject]@{
                Delay      = $Config.$ConfigType.delay
                Symbol     = "$($_.Symbol)"
                MinerName  = $MinerName
                Prestart   = $PreStart
                Type       = $ConfigType
                Path       = $Path
                Devices    = $Devices
                DeviceCall = "bminer"
                Arguments  = "-uri $($Config.$ConfigType.naming.$($_.Algorithm))://$($_.User2)$Pass2$Diff@$($_.Host):$($_.Port) -logfile `'$Log`' -api 127.0.0.1:44001"
                HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) }
                Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) { $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price) }else { 0 }
                PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                ocpower    = if ($Config.$ConfigType.oc.$($_.Algorithm).power) { $Config.$ConfigType.oc.$($_.Algorithm).power }else { $OC."default_$($ConfigType)".Power }
                occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) { $Config.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) { $Config.$ConfigType.oc.$($_.Algorithm).memory }else { $OC."default_$($ConfigType)".memory }
                ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) { $Config.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                MinerPool  = "$($_.Name)"
                FullName   = "$($_.Mining)"
                Port       = 44001
                API        = "bminer"
                Wrap       = $false
                Wallet     = "$($_.$User)"
                URI        = $Uri
                Server    = "localhost"
                BUILD      = $Build
                Algo       = "$($_.Algorithm)"
                Log        = "miner_generated"
            }
        }
    }
}

