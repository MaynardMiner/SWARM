##Miner Path Information
if ($amd.claymore_amd.path1) { $Path = "$($amd.claymore_amd.path1)" }
else { $Path = "None" }
if ($amd.claymore_amd.uri) { $Uri = "$($amd.claymore_amd.uri)" }
else { $Uri = "None" }
if ($amd.claymore_amd.minername) { $MinerName = "$($amd.claymore_amd.minername)" }
else { $MinerName = "None" }
if ($Platform -eq "linux") { $Build = "Tar" }
elseif ($Platform -eq "windows") { $Build = "Zip" }

$ConfigType = "AMD1"
$User = "User1"

##Log Directory
$Log = Join-Path $dir "logs\$ConfigType.log"

##Parse -GPUDevices
if ($AMDDevices1 -ne "none") {
    $ClayDevices1 = $AMDDevices1 -split ","
    $ClayDevices1 = Switch ($ClayDevices1) { "10" { "a" }; "11" { "b" }; "12" { "c" }; "13" { "d" }; "14" { "e" }; "15" { "f" }; "16" { "g" }; "17" { "h" }; "18" { "i" }; "19" { "j" }; "20" { "k" }; default { "$_" }; }
    $ClayDevices1 = $ClayDevices1 | ForEach-Object { $_ -replace ("$($_)", ",$($_)") }
    $ClayDevices1 = $ClayDevices1 -join ""
    $ClayDevices1 = $ClayDevices1.TrimStart(" ", ",")  
    $ClayDevices1 = $ClayDevices1 -replace (",", "")
    $Devices = $ClayDevices1
}
else { $Devices = "none" }

##Get Configuration File
$GetConfig = "$dir\config\miners\claymore_amd.json"
try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
catch { Write-Warning "Warning: No config found at $GetConfig" }

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

##Build Miner Settings
$Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $MinerAlgo = $_
    $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
        if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
            if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
            if ($_.Worker) { $MinerWorker = "-eworker $($_.Worker) " }
            else { $MinerWorker = "-epsw $($_.Pass1)$($Diff) " }
            [PSCustomObject]@{
                Delay      = $Config.$ConfigType.delay
                Symbol     = "$($_.Symbol)"
                MinerName  = $MinerName
                Prestart   = $PreStart
                Type       = $ConfigType
                Path       = $Path
                Devices    = $Devices
                DeviceCall = "claymore"
                Arguments  = "-platform 1 -mport 4333 -mode 1 -allcoins 1 -allpools 1 -epool $($_.Protocol)://$($_.Host):$($_.Port) -logfile `'$Log`' -ewal $($_.User1) $MinerWorker-wd 0 -gser 2 -dbg -1 -eres 1 $($Config.$ConfigType.commands.$($_.Algorithm))"
                HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) }
                Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) { $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price) }else { 0 }
                PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                ocdpm      = if ($Config.$ConfigType.oc.$($_.Algorithm).dpm) { $Config.$ConfigType.oc.$($_.Algorithm).dpm }else { $OC."default_$($ConfigType)".dpm }
                ocv        = if ($Config.$ConfigType.oc.$($_.Algorithm).v) { $Config.$ConfigType.oc.$($_.Algorithm).v }else { $OC."default_$($ConfigType)".v }
                occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) { $Config.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).mem) { $Config.$ConfigType.oc.$($_.Algorithm).mem }else { $OC."default_$($ConfigType)".memory }
                ocmdpm     = if ($Config.$ConfigType.oc.$($_.Algorithm).mdpm) { $Config.$ConfigType.oc.$($_.Algorithm).mdpm }else { $OC."default_$($ConfigType)".mdpm }
                ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) { $Config.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                FullName   = "$($_.Mining)"
                API        = "claymore"
                Port       = 4333
                MinerPool  = "$($_.Name)"
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
