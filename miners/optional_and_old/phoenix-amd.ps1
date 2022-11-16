. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;
$(vars).AMDTypes | ForEach-Object {
    
    $ConfigType = $_; $Num = $ConfigType -replace "AMD", ""
    $Cname = "phoenix-amd"

    ##Miner Path Information
    if ($(vars).amd.$Cname.$ConfigType) { $Path = "$($(vars).amd.$Cname.$ConfigType)" }
    else { $Path = "None" }
    if ($(vars).amd.$Cname.uri) { $Uri = "$($(vars).amd.$Cname.uri)" }
    else { $Uri = "None" }
    if ($(vars).amd.$Cname.minername) { $MinerName = "$($(vars).amd.$Cname.minername)" }
    else { $MinerName = "None" }

    $User = "User$Num"; $Pass = "Pass$Num"; $Name = "$Cname-$Num"; $Port = "2600$Num"

    Switch ($Num) {
        1 { $Get_Devices = $(vars).AMDDevices1; $Rig = $(arg).Rigname1 }
    }

    ##Log Directory
    $Log = Join-Path $($(vars).dir) "logs\$Name.log"

    ##Parse -GPUDevices
    if ($Get_Devices -ne "none") {
        $ClayDevices1 = $Get_Devices -split ","
        $ClayDevices1 = Switch ($ClayDevices1) { "10" { "a" }; "11" { "b" }; "12" { "c" }; "13" { "d" }; "14" { "e" }; "15" { "f" }; "16" { "g" }; "17" { "h" }; "18" { "i" }; "19" { "j" }; "20" { "k" }; default { "$_" }; }
        $ClayDevices1 = $ClayDevices1 | ForEach-Object { $_ -replace ("$($_)", ",$($_)") }
        $ClayDevices1 = $ClayDevices1 -join ""
        $ClayDevices1 = $ClayDevices1.TrimStart(" ", ",")  
        $ClayDevices1 = $ClayDevices1 -replace (",", "")
        $Devices = $ClayDevices1
    }
    else { $Devices = $Get_Devices }

    ##Get Configuration File
    ##This is located in config\miners
    $MinerConfig = $Global:config.miners.$Cname

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
            $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                $SelName = $_.Name
                $SelAlgo = $_.Algorithm
                $Diff = ""
                if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { 
                    switch($_.Name) {
                        "zergpool" { $Diff = ",sd=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                        default { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }
                    }
                }
                if ($_.Worker) { $MinerWorker = " -worker $($_.Worker) " }
                else { $MinerWorker = " -pass $($_.$Pass)$($Diff) " }
                $GetUser = $_.$User;
                switch ($SelName) {
                    "nicehash" {
                        switch ($SelAlgo) {
                            "ethash" { $AddArgs = " -proto 4 -stales 0 " }
                        }
                    }
                    "whalesburg" {
                        switch ($SelAlgo) {
                            "ethash" { $AddArgs = " -proto 2 -rate 1 " }
                        }
                    }
                    "zergpool" {
                        switch ($SelAlgo) {
                            "progpow" { $AddArgs = " -coin bci -proto 1 " }
                            "ethash" { $AddArgs = " -proto 2 -rate 1 " }
                            "etchash" { $AddArgs = " -proto 2 -rate 1 " }
                        }
                    }
                    "hashrent" {
                        switch ($SelAlgo) {
                            "ethash" { $AddArgs = " -proto 2 -rate 1 -stales 0 "; $MinerWorker = " -worker $($GetUser.Split("/")[1] ) -pass x" }
                        }
                    }
                    "mph" {
                        switch ($SelAlgo) {
                            "ethash" { $AddArgs = " -proto 1 -rate 1 "; $MinerWorker = " -worker $GetUser -pass x" }
                        }
                    }
                }
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
                    DeviceCall = "claymore"
                    Arguments  = "-amd -mport $Port -pool $($_.Protocol)://$($_.Pool_Host):$($_.Port) -wal $($_.$User)$MinerWorker$AddArgs -wd 0 -log 0 -gser 2 -dbg -1 -eres 1 $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates  = [Decimal]$Stat.Hour
                    HashRate_Adjusted = [Decimal]$Hashstat
                    Quote      = $_.Price
                    Rejections = $Stat.Rejections
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