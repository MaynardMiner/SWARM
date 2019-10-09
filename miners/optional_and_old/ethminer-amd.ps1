$(vars).AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""
    $CName = "ethminer-amd"

    ##Miner Path Information
    if ($(vars).amd.$CName.$ConfigType) { $Path = "$($(vars).amd.$CName.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).amd.$CName.uri) { $Uri = "$($(vars).amd.$CName.uri)" }
    else { $Uri = "None" }
    if ($(vars).amd.$CName.minername) { $MinerName = "$($(vars).amd.$CName.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "$CName-$Num"; $Port = "3700$Num"

    Switch ($Num) {
        1 { $Get_Devices = $(vars).AMDDevices1; $Rig = $(arg).Rigname1 }
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
    $MinerConfig = $Global:config.miners.$CName

    ##Export would be /path/to/[SWARMVERSION]/build/export##
    $ExportDir = Join-Path $($(vars).dir) "build\export"

    ##Prestart actions before miner launch
    $Prestart = @()
    $PreStart += "export LD_LIBRARY_PATH=$ExportDir"
    $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

    if ($(vars).Coins) { $Pools = $(vars).CoinPools } else { $Pools = $(vars).AlgoPools }

    if ($(vars).Bancount -lt 1) { $(vars).Bancount = 5 }

    ##Build Miner Settings
    $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

        $MinerAlgo = $_

        if ($MinerAlgo -in $(vars).Algorithm -and $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and $Name -notin $(vars).BanHammer) {
            $StatAlgo = $MinerAlgo -replace "`_", "`-"
            $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate" 
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
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
                    Version    = "$($(vars).amd.$CName.version)"
                    DeviceCall = "progminer_amd"
                    Arguments  = "-P stratum2+tcp://$($_.$User).$($_.$Pass):x@$($_.Pool_Host):$($_.Port) --opencl --api-bind 127.0.0.1:$Port --noeval --dag-load-mode 1 $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = $Stat.Hour
                    Quote      = if ($Stat.Hour) { $Stat.Hour * ($_.Price) }else { 0 }
                    Power      = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 } 
                    API        = "claymore"
                    Port       = $Port
                    Worker     = $Rig
                    MinerPool  = "$($_.Name)"
                    Wallet     = "$($_.$User)"
                    URI        = $Uri
                    Server     = "localhost"
                    Algo       = "$($_.Algorithm)"                         
                    Log        = $Log 
                }            
            }
        }
    }
}