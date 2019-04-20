$AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""

    ##Miner Path Information
    if ($AMD.gminer.$ConfigType) { $Path = "$($AMD.gminer.$ConfigType)" }
    else { $Path = "None" }
    if ($AMD.gminer.uri) { $Uri = "$($AMD.gminer.uri)" }
    else { $Uri = "None" }
    if ($AMD.gminer.minername) { $MinerName = "$($AMD.gminer.minername)" }
    else { $MinerName = "None" }
    if ($Platform -eq "linux") { $Build = "Tar" }
    elseif ($Platform -eq "windows") { $Build = "Zip" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "gminer_amd-$Num"; $Port = "3300$Num"

    Switch ($Num) {
        1 { $Get_Devices = $AMDDevices1 }
    }
    
    ##Log Directory
    $Log = Join-Path $dir "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") {
        $GPUDevices1 = $Get_Devices
        $GPUDevices1 = $GPUDevices1 -replace ',', ' '
        $Devices = $GPUDevices1
    }
    else { $Devices = $Get_Devices }

    ##gminer apparently doesn't know how to tell the difference between
    ##cuda and amd devices, like every other miner that exists. So now I 
    ##have to spend an hour and parse devices
    ##to matching platforms.
    $ArgDevices = $Null
    if ($Get_Devices -ne "none") {
        $GPUDevices1 = $Get_Devices
        $GPUEDevices1 = $GPUDevices1 -split ","
        $GPUEDevices1 | ForEach-Object { $ArgDevices += "$($GCount.AMD.$_) " }
        $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1)
    }
    else { $GCount.AMD.PSObject.Properties.Name | ForEach-Object { $ArgDevices += "$($GCount.AMD.$_) " }; $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1) }

    ##Get Configuration File
    $GetConfig = "$dir\config\miners\gminer_amd.json"
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

    ##Build Miner Settings
    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
        $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
            if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
                if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }
                [PSCustomObject]@{
                    MName      = $Name
                    Coin       = $Coins
                    Delay      = $Config.$ConfigType.delay
                    Fees       = $Config.$ConfigType.fee.$($_.Algorithm)
                    Symbol     = "$($_.Symbol)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    ArgDevices = $ArgDevices
                    DeviceCall = "gminer"
                    Arguments  = "--api $Port --server $($_.Host) --port $($_.Port) --user $($_.$User) --logfile `'$Log`' --pass $($_.$Pass)$Diff $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                    Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                    PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                    ocdpm      = if ($Config.$ConfigType.oc.$($_.Algorithm).dpm) { $Config.$ConfigType.oc.$($_.Algorithm).dpm }else { $OC."default_$($ConfigType)".dpm }
                    ocv        = if ($Config.$ConfigType.oc.$($_.Algorithm).v) { $Config.$ConfigType.oc.$($_.Algorithm).v }else { $OC."default_$($ConfigType)".v }
                    occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) { $Config.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                    ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).mem) { $Config.$ConfigType.oc.$($_.Algorithm).mem }else { $OC."default_$($ConfigType)".memory }
                    ocmdpm     = if ($Config.$ConfigType.oc.$($_.Algorithm).mdpm) { $Config.$ConfigType.oc.$($_.Algorithm).mdpm }else { $OC."default_$($ConfigType)".mdpm }
                    ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) { $Config.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                    MinerPool  = "$($_.Name)"
                    FullName   = "$($_.Mining)"
                    API        = "gminer"
                    Port       = $Port
                    Wallet     = "$($_.$User)"
                    URI        = $Uri
                    Server     = "localhost"
                    BUILD      = $Build
                    Algo       = "$($_.Algorithm)"
                    Log        = "miner_generated" 
                }            
            }
        }
    }
}