. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;
$(vars).NVIDIATypes | ForEach-Object {

    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($(vars).nvidia.miniz.$ConfigType) { $Path = "$($(vars).nvidia.miniz.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).nvidia.miniz.uri) { $Uri = "$($(vars).nvidia.miniz.uri)" }
    else { $Uri = "None" }
    if ($(vars).nvidia.miniz.minername) { $MinerName = "$($(vars).nvidia.miniz.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "miniz-$Num"; $Port = "6000$Num";

    Switch ($Num) {
        1 { $Get_Devices = $(vars).NVIDIADevices1; $Rig = $(arg).RigName1 }
        2 { $Get_Devices = $(vars).NVIDIADevices2; $Rig = $(arg).RigName2 }
        3 { $Get_Devices = $(vars).NVIDIADevices3; $Rig = $(arg).RigName3 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$ConfigType.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") {
        $GPUDevices1 = $Get_Devices
        $GPUDevices1 = $GPUDevices1 -replace ',', ' '
        $Devices = $GPUDevices1
    }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    ##This is located in config\miners
    $MinerConfig = $Global:config.miners.miniz

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
                $SelName = $_.Name
                $SelAlgo = $_.Algorithm
                switch ($SelAlgo) {
                    "equihash_96/5" { $AddArgs = "--par=96,5 --pers auto " }
                    "equihash_144/5" {
                        switch ($SelName) {
                            "nlpool" { $AddArgs = "--algo 144,5 --pers auto " }
                            "zergpool" { $AddArgs = "--algo 144,5 --pers auto " }
                            "mph" { $AddArgs = "--algo 144,5 --pers BgoldPoW " }
                        }
                    }
                    "equihash_210/9" { $AddArgs = "--par=210,9 --pers auto " }
                    "equihash_200/9" { $AddArgs = "--par=200,9 --pers auto " }
                    "equihash_192/7" {
                        switch ($SelName) {
                        "nlpool" { $AddArgs = "--algo 192,7 --pers auto " }
                        "zergpool" { $AddArgs = "--algo 192,7 --pers auto " }
                        "mph" { $AddArgs = "--algo 192,7 --pers ZcashPoW " }
                        }
                    }
                    "equihash_125/4" { $AddArgs = "--par=125,4 --pers auto " }
                    "equihash_150/5" { $AddArgs = "--par=150,5 --pers auto " }
                    "beamv2" { $AddArgs = "--par=150,5,3 --pers auto " }
                    "beamhashv3" { $AddArgs = "--pers auto " }
                }
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
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
                    Version    = "$($(vars).nvidia.miniz.version)"
                    DeviceCall = "miniz"
                    Arguments  = "--telemetry 0.0.0.0:$Port --server $($_.Pool_Host) --port $($_.Port) $AddArgs--user $($_.$User) --pass $($_.$Pass)$($Diff) --logfile=`'$log`' $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [Decimal]$Stat.Hour
                    HashRate_Adjusted = [Decimal]$Hashstat
                    Quote      = $_.Price
                    Rejections = $Stat.Rejections
                    Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 }
                    MinerPool  = "$($_.Name)"
                    API        = "miniz"
                    Port       = $Port
                    Worker     = $Rig
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
