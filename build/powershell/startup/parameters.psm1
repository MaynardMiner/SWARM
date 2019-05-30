function Get-Parameters {
    $Global:config.add("params", @{ })
    $Global:Config.add("user_params",@{ })
    $Global:Config.add("hive_params",@{})
    $Global:Config.add("SWARM_Params",@{})
    if (Test-Path ".\config\parameters\newarguments.json") {
        $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $global:Config.Params.Add("$($_)", $arguments.$_) }
        $arguments.PSObject.Properties.Name | % { $Global:Config.user_params.Add("$($_)", $arguments.$_) }
    }
    else {
        $arguments = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $global:Config.Params.Add("$($_)", $arguments.$_) }
        $arguments.PSObject.Properties.Name | % { $Global:Config.user_params.Add("$($_)", $arguments.$_) }
        $arguments = $Null
    }
    if (Test-Path ".\build\txt\hive_params_keys.txt") {
        $HiveStuff = Get-Content ".\build\txt\hive_params_keys.txt" | ConvertFrom-Json
        $HiveStuff.PSObject.Properties.Name | % { $global:Config.hive_params.Add("$($_)", $HiveStuff.$_) }
        $HiveStuff = $null
    }
    if (-not $global:Config.hive_params.HiveID) {
        $global:Config.hive_params.Add("HiveID", $Null)
        $global:Config.hive_params.Add("HivePassword", $Null)
        $global:Config.hive_params.Add("HiveWorker", $Null)
        $global:Config.hive_params.Add("HiveMirror", "https://api.hiveos.farm")
        $global:Config.hive_params.Add("FarmID", $Null)
        $global:Config.hive_params.Add("Wd_Enabled", $null)
        $Global:config.hive_params.Add("Wd_miner", $Null)
        $Global:config.hive_params.Add("Wd_reboot", $Null)
        $Global:config.hive_params.Add("Wd_minhashes", $Null)
        $Global:config.hive_params.Add("Miner", $Null)
        $global:Config.hive_params.Add("Miner2", $Null)
        $global:Config.hive_params.Add("Timezone", $Null)
    }
    if (-not $global:Config.SWARM_Params.HiveID) {
        $global:Config.SWARM_Params.Add("HiveID", $Null)
        $global:Config.SWARM_Params.Add("HivePassword", $Null)
        $global:Config.SWARM_Params.Add("HiveWorker", $Null)
        $global:Config.SWARM_Params.Add("HiveMirror", "SWARMSITE")
        $global:Config.SWARM_Params.Add("FarmID", $Null)
        $global:Config.SWARM_Params.Add("Wd_Enabled", $null)
        $Global:config.SWARM_Params.Add("Wd_miner", $Null)
        $Global:config.SWARM_Params.Add("Wd_reboot", $Null)
        $Global:config.SWARM_Params.Add("Wd_minhashes", $Null)
        $Global:config.SWARM_Params.Add("Miner", $Null)
        $global:Config.SWARM_Params.Add("Miner2", $Null)
        $global:Config.SWARM_Params.Add("Timezone", $Null)
    }

    if (-not $global:Config.Params.Platform) {
        write-Host "Detecting Platform..." -Foreground Cyan
        if ($IsWindows) { $global:Config.Params.Platform = "windows" }
        else { $global:Config.Params.Platform = "linux" }
        Write-Host "OS = $($global:Config.Params.Platform)" -ForegroundColor Green
    }
    if (-not (Test-Path ".\build\txt")) { New-Item -Name "txt" -ItemType "Directory" -Path ".\build" | Out-Null }
    $global:Config.Params.Platform | Set-Content ".\build\txt\os.txt"
    ## Get Algorithms
    $global:Config.Add("Pool_Algos",(Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json))
}
