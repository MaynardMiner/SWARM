. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;
$(vars).NVIDIATypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""

    ##Miner Path Information
    if ($(vars).nvidia.nbminer.$ConfigType) { $Path = "$($(vars).nvidia.nbminer.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).nvidia.nbminer.uri) { $Uri = "$($(vars).nvidia.nbminer.uri)" }
    else { $Uri = "None" }
    if ($(vars).nvidia.nbminer.minername) { $MinerName = "$($(vars).nvidia.nbminer.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "nbminer-$Num"; $Port = "6200$Num";

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
    $MinerConfig = $Global:config.miners.nbminer

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
                $GetUser = $_.$User;
                $GetPass = $_.$Pass;
                $GetWorker = $_.Worker;
                switch ($MinerAlgo) {
                    "ethash" {
                        Switch ($SelName) {
                            "nicehash" { $Stratum = "nicehash+tcp://"; $A = "ethash"; $UserValue = $GetUser + ":" + $GetPass }
                            "zergpool" { $Stratum = "stratum+tcp://"; $A = "ethash"; $UserValue = $GetUser + ":" + $GetPass }
                            "whalesburg" { $Stratum = "ethproxy+tcp://"; $A = "ethash"; $UserValue = $GetUser + "." + $GetWorker + ":" + "x" }
                            "hashrent" { $Stratum = "ethproxy+tcp://"; $A = "ethash"; $UserValue = $GetUser + "." + $GetUser.Split("/")[1] + ":" + $GetPass }
                        }
                    }
                    "cuckaroo29" { $Stratum = "nicehash+tcp://"; $A = "cuckarood" }
                    "cuckaroo29-bfc" { $Stratum = "nicehash+tcp://"; $A = "bfc" }
                    "cuckaroo29d" { $Stratum = "nicehash+tcp://"; $A = "cuckarood" }
                    "cuckatoo31" { $Stratum = "nicehash+tcp://"; $A = "cuckatoo" }
                    "cuckatoo32" { $Stratum = "nicehash+tcp://"; $A = "cuckatoo32" }
                    "handshake" { $Stratum = "stratum+tcp://"; $A = "hns" }
                    "kawpow" { $Stratum = "stratum+tcp://"; $A = "kawpow" }
                    default { $Stratum = "stratum+tcp://"; $A = "$($MinerConfig.$ConfigType.naming.$MinerAlgo)" }
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
                    Version    = "$($(vars).nvidia.nbminer.version)"
                    DeviceCall = "ccminer"
                    Arguments  = "-a $A --api 0.0.0.0:$Port --no-nvml --platform 1 --log-file `'$log`' --url $Stratum$($_.Pool_Host):$($_.Port) --user $UserValue$Diff $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [Decimal]$Stat.Hour
                    HashRate_Adjusted = [Decimal]$Hashstat
                    Quote      = $_.Price
                    Rejections = $Stat.Rejections
                    Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                    MinerPool  = "$($_.Name)"
                    API        = "nebutech"
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