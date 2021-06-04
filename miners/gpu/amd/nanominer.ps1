. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;
$(vars).AMDTypes | ForEach-Object {

    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""

    ##Miner Path Information
    if ($(vars).amd.nanominer.$ConfigType) { $Path = "$($(vars).amd.nanominer.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).amd.nanominer.uri) { $Uri = "$($(vars).amd.nanominer.uri)" }
    else { $Uri = "None" }
    if ($(vars).amd.nanominer.minername) { $MinerName = "$($(vars).amd.nanominer.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "nanominer-$Num"; $Port = "3800$Num"

    Switch ($Num) {
        1 { $Get_Devices = $(vars).AMDDevices1; $Rig = $(arg).Rigname1 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    if ($Get_Devices -ne "none") {
        $GPUDevices1 = $Get_Devices
    }
    else {
        $(vars).GCount.AMD.PSObject.Properties.Name | ForEach-Object {
            $ArgTweak += "0,";
            $ArgDevices += "$($(vars).GCount.AMD.$_),"
        }
        $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1);
        $ArgTweak = $ArgTweak.Substring(0, $ArgTweak.Length - 1);
    }

    ##Get Configuration File
    ##This is located in config\miners
    $MinerConfig = $Global:config.miners.nanominer

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = "/usr/local/swarm/lib64"
    $Miner_Dir = Join-Path ($(vars).dir) ((Split-Path $Path).replace(".", ""))

    ##Prestart actions before miner launch
    ##This can be edit in miner.json
    $Prestart = @()
    if ($IsLinux) { $Prestart += "export LD_PRELOAD=/usr/local/swarm/lib64/libcurl.so.3" }
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir`:$Miner_Dir"
    if ($IsLinux) { $Prestart += "export DISPLAY=:0" }
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($(vars).Coins) { $Pools = $(vars).CoinPools } else { $Pools = $(vars).AlgoPools }

    if ($(vars).Bancount -lt 1) { $(vars).Bancount = 5 }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if (
            $MinerAlgo -in $(vars).Algorithm -and
            $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and
            $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and
            $Name -notin $(vars).BanHammer
        ) {
            $StatAlgo = $MinerAlgo -replace "`_", "`-"
            $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate"
            if ($(arg).Rej_Factor -eq "Yes" -and $Stat.Rejections -gt 0 -and $Stat.Rejection_Periods -ge 3) { $HashStat = $Stat.Hour * (1 - ($Stat.Rejections * 0.01)) }
            else { $HashStat = $Stat.Hour }
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                [PSCustomObject]@{
                    MName             = $Name
                    Coin              = $(vars).Coins
                    Delay             = $MinerConfig.$ConfigType.delay
                    Fees              = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                    Symbol            = "$($_.Symbol)"
                    MinerName         = $MinerName
                    Prestart          = $PreStart
                    Type              = $ConfigType
                    Path              = $Path
                    Devices           = $Devices
                    Stratum           = "$($_.Protocol)://$($_.Pool_Host):$($_.Port)"
                    Version           = "$($(vars).amd.nanominer.version)"
                    DeviceCall        = "nanominer"
                    ## Use Host because there is already an object set
                    Host              = @{
                        algorithm = "$($($MinerConfig.$ConfigType.naming.$($_.Algorithm)))"
                        wallet    = "$($_.$User)";
                        password  = "$($_.$Pass)$($Diff)";
                        pool      = "$($_.Pool_Host):$($_.Port)";
                        port      = $Port;
                        devices   = $ArgDevices;
                        memTweak  = $ArgTweak;
                    }
                    Arguments         = "`[$($($MinerConfig.$ConfigType.naming.$($_.Algorithm)))`] wallet=$($_.$User) rigPassword=$($_.$Pass)$($Diff) pool1=$($_.Pool_Host):$($_.Port) webport=$Port logPath=$Log"
                    HashRates         = [Decimal]$Stat.Hour
                    HashRate_Adjusted = [Decimal]$Hashstat
                    Quote             = $_.Price
                    Rejections        = $Stat.Rejections
                    Power             = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 }
                    MinerPool         = "$($_.Name)"
                    Port              = $Port
                    Worker            = $Rig
                    API               = "Nanominer"
                    Wallet            = "$($_.$User)"
                    URI               = $Uri
                    Server            = "localhost"
                    Algo              = "$($_.Algorithm)"
                    Log               = "miner_generated"
                }
            }
        }
    }
}
