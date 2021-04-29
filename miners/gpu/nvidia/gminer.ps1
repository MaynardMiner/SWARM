. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;
$(vars).NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($(vars).nvidia.gminer.$ConfigType) { $Path = "$($(vars).nvidia.gminer.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).nvidia.gminer.uri) { $Uri = "$($(vars).nvidia.gminer.uri)" }
    else { $Uri = "None" }
    if ($(vars).nvidia.gminer.minername) { $MinerName = "$($(vars).nvidia.gminer.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "gminer-$Num"; $Port = "4600$Num"

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
    $MinerConfig = $Global:config.miners.gminer

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
            $Pools | Where-Object Algorithm -eq $MinerAlgo | Where-Object Name -ne "hashrent" | ForEach-Object {
                $SelAlgo = $_.Algorithm
                $SelName = $_.Name
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                $UserPass = "--pass $($_.$Pass)$Diff "
                $GetUser = "$($_.$User)";
                $GetWorker = $_.Worker;
                switch ($SelName) {
                    "zergpool" { $GetUser = "$($GetUser).x" };
                    "whalesburg" { $GetUser = $GetUser + "." + $GetWorker };
                }
                switch ($SelAlgo) {
                    "equihash_150/5" { $AddArgs = "--algo 150_5 " }
                    "cuckoo_cycle" { $AddArgs = "--algo aeternity " }
                    "cuckaroom" { $AddArgs = "--algo grin29 " }
                    "cuckarooz29" { $AddArgs = "--algo grin29 " }
                    "cuckaroo29-bfc" { $AddArgs = "--algo bfc " }
                    "cuckatoo31" { $AddArgs = "--algo grin31 " }
                    "cuckatoo32" { $AddArgs = "--algo grin32 " }
                    "beamv2" { $AddArgs = "--algo 150_5 " }
                    "equihash_96/5" { $AddArgs = "--algo 96_5 --pers auto " }
                    "equihash_125/4" { $AddArgs = "--algo 125_4 --pers auto " }
                    "equihash_192/7" { 
                        switch ($SelName) {
                            "nlpool" { $AddArgs = "--algo 192_7 --pers auto " }
                            "zergpool" { $AddArgs = "--algo 192_7 --pers auto " }
                            "mph" { $AddArgs = "--algo 192_7 --pers ZcashPoW " }
                        }
                    }
                    "equihash_144/5" {
                        switch ($SelName) {
                            "nlpool" { $AddArgs = "--algo 192_7 --pers auto " }
                            "zergpool" { $AddArgs = "--algo 144_5 --pers auto " }
                            "mph" { $AddArgs = "--algo 144_5 --pers BgoldPoW " }
                        }
                    }
                    "equihash_210/9" { $AddArgs = "--algo 210_9 --pers auto " }
                    "equihash_200/9" { $AddArgs = "--algo 200_9 --pers auto " }
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
                    "eaglesong" { $AddArgs = "--algo eaglesong " }
                    "beamhashv3" { $AddArgs = "--algo beamhash " }
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
                    Version           = "$($(vars).nvidia.gminer.version)"
                    DeviceCall        = "gminer"
                    Arguments         = "--api $Port --server $($_.Pool_Host) --nvml 0 --port $($_.Port) $AddArgs--user $GetUser $UserPass--logfile `'$Log`' $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
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
