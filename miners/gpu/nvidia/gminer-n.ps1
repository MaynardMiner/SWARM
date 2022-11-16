. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;

$(vars).NVIDIATypes | ForEach-Object {
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""
    $CName = "gminer-n"

    ##Miner Path Information
    if ($(vars).nvidia.$CName.$ConfigType) { $Path = "$($(vars).nvidia.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).nvidia.$CName.uri) { $Uri = "$($(vars).nvidia.$CName.uri)" }
    else { $Uri = "None" }
    if ($(vars).nvidia.$CName.minername) { $MinerName = "$($(vars).nvidia.$CName.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "$CName-$Num"; $Port = "4600$Num"

    $MinerAlgos = @();

    Switch ($Num) {
        1 { $Get_Devices = $(vars).NVIDIADevices1; $Rig = $(arg).RigName1; $MinerAlgos = $(vars).GPUAlgorithm1 }
        2 { $Get_Devices = $(vars).NVIDIADevices2; $Rig = $(arg).RigName2;  $MinerAlgos = $(vars).GPUAlgorithm2 }
        3 { $Get_Devices = $(vars).NVIDIADevices3; $Rig = $(arg).RigName3;  $MinerAlgos = $(vars).GPUAlgorithm3 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$Name.log"

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
        $GPUEDevices = $Get_Devices
        $GPUEDevices = $GPUEDevices -split ","
        $GPUEDevices | ForEach-Object { $ArgDevices += "$($(vars).GCount.NVIDIA.$_) " }
        $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1)
    }
    else { $(vars).GCount.NVIDIA.PSObject.Properties.Name | ForEach-Object { $ArgDevices += "$($(vars).GCount.NVIDIA.$_) " }; $ArgDevices = $ArgDevices.Substring(0, $ArgDevices.Length - 1) }

    ##Get Configuration File
    ##This is located in config\miners
    $MinerConfig = $Global:config.miners.$CName

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
            $Pools | Where-Object Algorithm -eq $MinerAlgo | Where-Object Name -ne "hashrent" | ForEach-Object {
                $SelAlgo = $_.Algorithm
                $SelName = $_.Name
                $Diff = ""
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { 
                    switch ($_.Name) {
                        "zergpool" { $Diff = ",sd=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                        default { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                    }
                }
                $UserPass = "--pass $($_.$Pass)$Diff "
                $GetUser = "$($_.$User)";
                $GetWorker = $_.Worker;
                $AddArgs = "--algo $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) "
                switch ($SelName) {
                    "zergpool" { $GetUser = "$($GetUser).x" };
                    "whalesburg" { $GetUser = $GetUser + "." + $GetWorker };
                }
                switch ($SelAlgo) {
                    "equihash_144/5" {
                        switch ($SelName) {
                            "nicehash" { $AddArgs = "--algo 144_5 --pers auto " }
                            "nlpool" { $AddArgs = "--algo 144_5 --pers auto " }
                            "zergpool" { $AddArgs = "--algo 144_5 --pers auto " }
                            "mph" { $AddArgs = "--algo 144_5 --pers BgoldPoW " }
                            "zpool" { $AddArgs = "--algo 144_5 --pers auto " }
                        }
                    }
                    "equihash_210/9" { $AddArgs = "--algo 210_9 --pers auto " }
                    "equihash_125/4" { $AddArgs = "--algo 125_4 --pers auto " }
                    "cortex" { $AddArgs = "--algo cortex " }
                    "kawpow" { $AddArgs = "--algo kawpow " }
                    "ethash" {
                        switch ($SelName) {
                            "nicehash" { $AddArgs = "--algo ethash --proto stratum " }
                            "zergpool" { $AddArgs = "--algo ethash "; }
                            "whalesburg" { $UserPass = ""; $AddArgs = "--algo ethash " }
                            "mph" { $UserPass = ""; $AddArgs = "--algo ethash " }
                            default { $AddArgs = "--algo ethash --proto stratum " }
                        }
                    }
                    "etchash" {
                        switch ($SelName) {
                            "nicehash" { $AddArgs = "--algo etchash --proto stratum " }
                            "zergpool" { $AddArgs = "--algo etchash " }
                        }
                    }
                }
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
                    ArgDevices        = $ArgDevices
                    Devices           = $Devices
                    Stratum           = "$($_.Protocol)://$($_.Pool_Host):$($_.Port)"
                    Version           = "$($(vars).nvidia.$CName.version)"
                    DeviceCall        = "gminer"
                    Arguments         = "--api $Port --server $($_.Pool_Host) --port $($_.Port) $AddArgs--user $GetUser --logfile `'$Log`' $UserPass$($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates         = [Decimal]$Stat.Hour
                    HashRate_Adjusted = [Decimal]$Hashstat
                    Quote             = $_.Price
                    Rejections        = $Stat.Rejections
                    Power             = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 }
                    MinerPool         = "$($_.Name)"
                    API               = "gminer"
                    Port              = $Port
                    Worker            = $Rig
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
