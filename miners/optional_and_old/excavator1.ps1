$NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($nvidia.excavator.$ConfigType) { $Path = "$($nvidia.excavator.$ConfigType)" }
    else { $Path = "None" }
    if ($nvidia.excavator.uri) { $Uri = "$($nvidia.excavator.uri)" }
    else { $Uri = "None" }
    if ($nvidia.excavator.MinerName) { $MinerName = "$($nvidia.excavator.MinerName)" }
    else { $MinerName = "None" }
    if ($Platform -eq "linux") { $Build = "Dpkg" }
    elseif ($Platform -eq "windows") { $Build = "Zip" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "excavator-$Num"; $Port = "5800$Num";

    Switch ($Num) {
        1 { $Get_Devices = $NVIDIADevices1 }
        2 { $Get_Devices = $NVIDIADevices2 }
        3 { $Get_Devices = $NVIDIADevices3 }
    }

    ##Log Directory
    $Log = Join-Path $dir "logs\$ConfigType.log"
    $CommandFile = Join-Path (Split-Path $Path) "command.json"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    $GetConfig = "$dir\config\miners\excavator.json"
    try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
    catch { Write-Warning "Warning: No config found at $GetConfig" }

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $dir "build\export"

    ##Prestart actions before miner launch
    $Prestart = @()
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $Config.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

    ##Build Miner Settings
    $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $MinerAlgo = $_
        $Stat = Get-Stat -Name "$($Name)_$($MinerAlgo)_hashrate"
        $AlgoPools | Where-Object Name -EQ "nicehash" | Where-Object Symbol -eq $MinerAlgo | ForEach-Object {
            if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
                if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }
                [PSCustomObject]@{
                    MName       = $Name
                    Delay       = $Config.$ConfigType.delay
                    Fees        = $Config.$ConfigType.fee.$($_.Algorithm)
                    Symbol      = "$($_.Algorithm)"
                    MinerName   = $MinerName
                    Prestart    = $PreStart
                    Type        = $ConfigType
                    Path        = $Path
                    Devices     = $Devices
                    NPool       = $($_.Excavator)
                    NUser       = $($_.$User)
                    NCommand    = if ($Config.$ConfigType.commands.$($_.Algorithm)) { $Config.$ConfigType.commands.$($_.Algorithm) | ConvertTo-Json -Compress }else { "" }
                    Commandfile = $CommandFile
                    DeviceCall  = "excavator"
                    Arguments   = "-a $($Config.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Host):$($_.Port) -b 0.0.0.0:$Port -u $($_.$User) -p $($_.$Pass)$($Diff) $($Config.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [PSCustomObject]@{$($_.Algorithm) = $Stat.Day }
                    Quote      = if ($Stat.Day) { $Stat.Day * ($_.Price) }else { 0 }
                    PowerX      = [PSCustomObject]@{ $($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                    ocpower     = if ($Config.$ConfigType.oc.$($_.Algorithm).power) { $Config.$ConfigType.oc.$($_.Algorithm).power }else { $OC."default_$($ConfigType)".Power }
                    occore      = if ($Config.$ConfigType.oc.$($_.Algorithm).core) { $Config.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                    ocmem       = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) { $Config.$ConfigType.oc.$($_.Algorithm).memory }else { $OC."default_$($ConfigType)".memory }
                    ocfans      = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) { $Config.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                    MinerPool   = "$($_.Name)"
                    FullName    = "$($_.Mining)"
                    Port        = $Port
                    API         = "excavator"
                    Wrap        = $false
                    URI         = $Uri
                    BUILD       = $Build
                    Algo        = "$($_.Algorithm)"
                    NewAlgo     = ''
                }
            }
        }
    }
}
