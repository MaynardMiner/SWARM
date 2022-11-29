. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;

## Bminer cannot run more than 1 application at a time. Trying to use for multiple
## device groups = failure. Therefor SWARM is programmed to run bminer in only 
## 1 device group {NVIDIA1}

$(vars).NVIDIATypes | Where-Object {$_ -eq "NVIDIA1"} | ForEach-Object {

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
    $Log = Join-Path $($(vars).dir) "logs\$Name.log"

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
            $MinerAlgo -in $MinerAlgos -and
            $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and
            $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and
            $Name -notin $(vars).BanHammer
        ) {
            $StatAlgo = $MinerAlgo -replace "`_", "`-"
            $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate"
            if ($(arg).Rej_Factor -eq "Yes" -and $Stat.Rejections -gt 0 -and $Stat.Rejection_Periods -ge 3) { $HashStat = $Stat.Hour * (1 - ($Stat.Rejections * 0.01)) }
            else { $HashStat = $Stat.Hour }
            $Pools | Where-Object Algorithm -eq $MinerAlgo |  ForEach-Object {
                $Sel = $_.Algorithm
                $SelName = $_.Name
                $GetPass = $_.$Pass;
                $GetUser = $_.$User;
                if ($_.Worker) { $GetPass = "$($_.Worker)" }
                $CanUse = $true;
                $Diff = ""
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { 
                    switch($_.Name) {
                        "zergpool" { $Diff = ",sd=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                        default { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                    }
                }
                $UserPass = $_.$User + ":" + [System.Web.HttpUtility]::UrlEncode($GetPass + $Diff);
                $PoolPort = $_.Port
                Switch ($SelName) {
                    "nicehash" {
                        switch ($Sel) {
                            "ethash" { $Naming = "ethstratum"; $AddArgs = " " }
                            "cuckaroom" { $Naming = "cuckaroo29m"; $AddArgs = " " }
                            "cuckaroo29-bfc" { $Naming = "bfc"; $AddArgs = " " }
                            "equihash_150/5" { $Naming = "beam"; $AddArgs = " -pers auto " }
                            "equihash_144/5" { $Naming = "zhash"; $AddArgs = " -pers auto " }
                            "beamv2" { $Naming = "beamhash2"; $AddArgs = " " }
                            "beamhashv3" { $Naming = "beamhash3"; $AddArgs = " " }
                            "eaglesong" { $Naming = "eaglesong"; $AddArgs = " " }
                            "kawpow" { $Naming = "raven"; $AddArgs = " " }
                            "cuckarooz29" { $Naming = "cuckaroo29z"; $AddArgs = " " }
                            "octopus" { $Naming = "conflux"; $AddArgs = " " }
                        }
                    }
                    "zergpool" {
                        switch ($Sel) {
                            "ethash" { $Naming = "ethproxy"; $AddArgs = " "; $UserPass = $GetUser + "." + ":" + [System.Web.HttpUtility]::UrlEncode($GetPass + $Diff) }
                            "equihash_144/5" { $Naming = "zhash"; $AddArgs = " -pers auto "; $CanUse = $false }
                            "equihash_150/5" { $Naming = "beam"; $AddArgs = " -pers auto " ; $CanUse = $false }
                            "eaglesong" { $Naming = "eaglesong"; $AddArgs = " "; $UserPass = $GetUser + "." + ":" + [System.Web.HttpUtility]::UrlEncode($GetPass + $Diff) }
                            "kawpow" { $Naming = "raven"; $AddArgs = " "; $UserPass = $GetUser + "." + ":" + [System.Web.HttpUtility]::UrlEncode($GetPass + $Diff) }
                        }
                    }
                    "whalesburg" {
                        switch ($Sel) {
                            "ethash" { $Naming = "ethproxy+ssl"; $AddArgs = " "; $PoolPort = "7777" }
                        }
                    }
                    "mph" {
                        switch ($Sel) {
                            "ethash" { $Naming = "ethstratum"; $AddArgs = " "; $UserPass = $GetUser + "." + ":" + [System.Web.HttpUtility]::UrlEncode($GetPass + $Diff) }
                            "equihash_144/5" { $Naming = "zhash"; $AddArgs = " -pers BgoldPoW "; $CanUse = $false }
                            "eaglesong" { $Naming = "eaglesong"; $AddArgs = " "; $UserPass = $GetUser + "." + ":" + [System.Web.HttpUtility]::UrlEncode($GetPass + $Diff) }
                            "kawpow" { $Naming = "raven"; $AddArgs = " "; $UserPass = $GetUser + "." + ":" + [System.Web.HttpUtility]::UrlEncode($GetPass + $Diff) }
                        }
                    }
                    "hashrent" {
                        switch($Sel) {
                            "ethash" {$Naming = "ethproxy"; $UserPass = $GetUser.replace("/","%2F") + "." + $GetUser.Split("/")[1] + ":$GetPass"; $AddArgs = " ";}
                        }
                    }
                    default {
                        switch ($Sel) {
                            "equihash_144/5" { $Naming = "equihash1445"; $AddArgs = " -pers auto " }
                        }
                    }
                }
                if ($CanUse) {
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
                        Version           = "$($(vars).nvidia.bminer.version)"
                        DeviceCall        = "bminer"
                        Arguments         = "-uri $($Naming)://$UserPass@$($_.Pool_Host):$($PoolPort)$AddArgs-logfile `'$Log`' -api 127.0.0.1:$Port $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates         = [Decimal]$Stat.Hour
                        HashRate_Adjusted = [Decimal]$Hashstat
                        Quote             = $_.Price
                        Rejections        = $Stat.Rejections
                        Power             = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 }
                        MinerPool         = "$($_.Name)"
                        Port              = $Port
                        Worker            = $Rig
                        API               = "bminer"
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
}
