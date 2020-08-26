. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;
$(vars).NVIDIATypes | ForEach-Object {
        
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($(vars).nvidia.bminer.$ConfigType) { $Path = "$($(vars).nvidia.bminer.$ConfigType)" } else { $Path = "None" }
    if ($(vars).nvidia.bminer.uri) { $Uri = "$($(vars).nvidia.bminer.uri)" } else { $Uri = "None" }
    if ($(vars).nvidia.bminer.MinerName) { $MinerName = "$($(vars).nvidia.bminer.MinerName)" } else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "bminer-$Num"; $Port = "4000$Num"

    Switch ($Num) {
        1 { $Get_Devices = $(vars).NVIDIADevices1; $Rig = $(arg).RigName1 }
        2 { $Get_Devices = $(vars).NVIDIADevices2; $Rig = $(arg).RigName2 }
        3 { $Get_Devices = $(vars).NVIDIADevices3; $Rig = $(arg).RigName3 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    ##This is located in config\miners
    $MinerConfig = $Global:config.miners.bminer

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = "/usr/local/swarm/lib64"
    $Miner_Dir = Join-Path ($(vars).dir) ((Split-Path $Path).replace(".", ""))

    ##Prestart actions before miner launch
    ##This can be edit in miner.json
    $Prestart = @()
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
                $Sel = $_.Algorithm
                $SelName = $_.Name
                Switch ($SelName) {
                    "nicehash" {
                        switch ($Sel) {
                            "ethash" { $Pass = ""; $Naming = "ethstratum"; $AddArgs = "" }
                            "cuckaroom" { $Pass = ""; $Naming = "cuckaroo29m"; $AddArgs = "-pers auto " }
                            "cuckaroo29-bfc" { $Pass = ""; $Naming = "bfc"; $AddArgs = "-pers auto " }
                            "cuckatoo31" { $Pass = ""; $Naming = "cuckatoo31"; $AddArgs = "-pers auto " }
                            "equihash_150/5" { $Pass = ""; $Naming = "beam"; $AddArgs = "" }
                            "equihash_144/5" { $Pass = ""; $Naming = "zhash"; $AddArgs = "" }
                            "beamv2" { $Pass = ""; $Naming = "beamhash2"; $AddArgs = "" }
                            "beamhashv3" { $Pass = ""; $Naming = "beamhash3"; $AddArgs = "" }
                            "eaglesong" { $Pass = ""; $Naming = "eaglesong"; $AddArgs = "" }
                            "kawpow" { $Pass = ""; $Naming = "raven"; $AddArgs = "" }
                            "cuckarooz29" { $Pass = ""; $Naming = "cuckaroo29z"; $AddArgs = "" }
                        }
                    }
                    "zergpool" {
                        switch ($Sel) {
                            "ethash" { $Pass = ""; $Naming = "ethproxy"; $AddArgs = "" }
                            "cuckaroom" { $Pass = ""; $Naming = "cuckaroo29m"; $AddArgs = "-pers auto " }
                            "cuckaroo29-bfc" { $Pass = ""; $Naming = "bfc"; $AddArgs = "-pers auto " }
                            "cuckatoo31" { $Pass = ""; $Naming = "cuckatoo31"; $AddArgs = "-pers auto " }
                            "equihash_150/5" { $Pass = ""; $Naming = "beam"; $AddArgs = "" }
                            "equihash_144/5" { $Pass = ""; $Naming = "zhash"; $AddArgs = "" }
                            "beamv2" { $Pass = ""; $Naming = "beamhash2"; $AddArgs = "" }
                            "beamhashv3" { $Pass = ""; $Naming = "beamhash3"; $AddArgs = "" }
                            "eaglesong" { $Pass = ""; $Naming = "eaglesong"; $AddArgs = "" }
                            "kawpow" { $Pass = ""; $Naming = "raven"; $AddArgs = "" }
                        }
                    }
                    "whalesburg" {
                        switch ($Sel) {
                            "ethash" { $Pass = ""; $Naming = "ethproxy+ssl"; $AddArgs = "" }
                        }
                    }
                    default {
                        switch ($Sel) {
                            "equihash_144/5" { $Pass = ".$($($_.$Pass) -replace ",","%2C")"; $Naming = "equihash1445"; $AddArgs = "-pers auto " }
                        }
                    }
                }
                if ($_.Worker) { $Pass = ".$($_.Worker)" }
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = "%2Cd=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                [PSCustomObject]@{
                    MName      = $Name
                    Coin       = $(vars).Coins
                    Delay      = $MinerConfig.$ConfigType.delay
                    Fees       = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                    Symbol     = "$($_.Symbol)"
                    MinerName  = $MinerName
                    Prestart   = $PreStart
                    Type       = $ConfigType
                    Path       = $Path
                    Devices    = $Devices
                    Stratum    = "$($_.Protocol)://$($_.Pool_Host):$($_.Port)" 
                    Version    = "$($(vars).nvidia.bminer.version)"
                    DeviceCall = "bminer"
                    Arguments  = "-uri $($Naming)://$($_.$User)$Pass$Diff@$($_.Pool_Host):$($_.Port) $AddArgs-logfile `'$Log`' -api 127.0.0.1:$Port $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = $Stat.Hour
                    HashRate_Adjusted = $Hashstat
                    Quote      = $_.Price
                    Rejections = $Stat.Rejections
                    Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                    MinerPool  = "$($_.Name)"
                    Port       = $Port
                    Worker     = $Rig
                    API        = "bminer"
                    Wallet     = "$($_.$User)"
                    URI        = $Uri
                    Server     = "localhost"                        
                    Algo       = "$($_.Algorithm)"
                    Log        = "miner_generated"
                }
            }
        }
    }
}