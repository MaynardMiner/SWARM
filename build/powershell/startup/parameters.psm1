function Get-Parameters {
    $Global:config.add("params", @{ })
    $Global:Config.add("user_params",@{ })
    $Global:Config.add("Hive_Params",@{})
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
    if (Test-Path ".\build\txt\hivekeys.txt") {
        $HiveStuff = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json
        $HiveStuff.PSObject.Properties.Name | % { $global:Config.Hive_Params.Add("$($_)", $HiveStuff.$_) }
    }
    if (-not $global:Config.Hive_Params.HiveID) {
        $global:Config.Hive_Params.Add("HiveID", $Null)
        $global:Config.Hive_Params.Add("HivePassword", $Null)
        $global:Config.Hive_Params.Add("HiveWorker", $Null)
        $global:Config.Hive_Params.Add("HiveMirror", "https://api.hiveos.farm")
        $global:Config.Hive_Params.Add("FarmID", $Null)
        $global:Config.Hive_Params.Add("Wd_Enabled", $null)
        $Global:config.Hive_Params.Add("Wd_miner", $Null)
        $Global:config.Hive_Params.Add("Wd_reboot", $Null)
        $Global:config.Hive_Params.Add("Wd_minhashes", $Null)
        $Global:config.Hive_Params.Add("Miner", $Null)
        $global:Config.Hive_Params.Add("Miner2", $Null)
        $global:Config.Hive_Params.Add("Timezone", $Null)
    }

    if (-not $global:Config.Params.Platform) {
        write-Host "Detecting Platform..." -Foreground Cyan
        if (Test-Path "C:\") { $global:Config.Params.Platform = "windows" }
        else { $global:Config.Params.Platform = "linux" }
        Write-Host "OS = $($global:Config.Params.Platform)" -ForegroundColor Green
    }
    if (-not (Test-Path ".\build\txt")) { New-Item -Name "txt" -ItemType "Directory" -Path ".\build" | Out-Null }
    $global:Config.Params.Platform | Set-Content ".\build\txt\os.txt"
    ## Get Algorithms
    $global:Config.Add("Pool_Algos",(Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json))
}
