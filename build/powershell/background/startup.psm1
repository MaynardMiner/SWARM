function Global:Get-Params {
    $global:Config.Add("params", @{ })
    $global:Config.Add("hive_params", @{ })
    $global:Config.Add("SWARM_Params", @{ })
    $global:Config.Add("stats", @{ })
    $global:Config.Add("summary",@{ })
    if (Test-Path ".\config\parameters\newarguments.json") {
        $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $global:config.params.Add("$($_)", $arguments.$_) }
        $arguments = $null
    }
    else {
        $arguments = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $global:Config.params.Add("$($_)", $arguments.$_) }
        $arguments = $null
    }
    if (Test-Path ".\config\parameters\Hive_params_keys.json") {
        $HiveStuff = Get-Content ".\config\parameters\Hive_params_keys.json" | ConvertFrom-Json
        $HiveStuff.PSObject.Properties.Name | % { $global:Config.hive_params.Add("$($_)", $HiveStuff.$_) }
        $HiveStuff = $null
    }
    if (-not $global:Config.hive_params.Id) {
        Write-Host "No Id- HiveOS Disabled"
        $global:Config.hive_params.Add("Id", $Null)
        $global:Config.hive_params.Add("Password", $Null)
        $global:Config.hive_params.Add("Worker", $Null)
        $global:Config.hive_params.Add("Mirror", "https://api.hiveos.farm")
        $global:Config.hive_params.Add("FarmID", $Null)
        $global:Config.hive_params.Add("Wd_Enabled", $null)
        $Global:config.hive_params.Add("Wd_miner", $Null)
        $Global:config.hive_params.Add("Wd_reboot", $Null)
        $Global:config.hive_params.Add("Wd_minhashes", $Null)
        $Global:config.hive_params.Add("Miner", $Null)
        $global:Config.hive_params.Add("Miner2", $Null)
        $global:Config.hive_params.Add("Timezone", $Null)
    }

    if (Test-Path ".\config\parameters\SWARM_params_keys.json") {
        $SWARMStuff = Get-Content ".\config\parameters\SWARM_params_keys.json" | ConvertFrom-Json
        $SWARMStuff.PSObject.Properties.Name | % { $global:Config.SWARM_Params.Add("$($_)", $SWARMStuff.$_) }
        Write-Host $global:Config.SWARM_Params.Mirror
        $SWARMStuff = $null
    }
    if (-not $global:Config.SWARM_Params.Id) {
        Write-Host "No Id- SWARM website Disabled"
        $global:Config.SWARM_Params.Add("Id", $Null)
        $global:Config.SWARM_Params.Add("Password", $Null)
        $global:Config.SWARM_Params.Add("Worker", $Null)
        $global:Config.SWARM_Params.Add("Mirror", "https://swarm-web.davisinfo.ro")
        $global:Config.SWARM_Params.Add("FarmID", $Null)
        $global:Config.SWARM_Params.Add("Wd_Enabled", $null)
        $Global:config.SWARM_Params.Add("Wd_miner", $Null)
        $Global:config.SWARM_Params.Add("Wd_reboot", $Null)
        $Global:config.SWARM_Params.Add("Wd_minhashes", $Null)
        $Global:config.SWARM_Params.Add("Miner", $Null)
        $global:Config.SWARM_Params.Add("Miner2", $Null)
        $global:Config.SWARM_Params.Add("Timezone", $Null)
        $global:Config.SWARM_Params.Add("WD_CHECK_GPU", $Null)
        $global:Config.SWARM_Params.Add("PUSH_INTERVAL", $Null)
        $global:Config.SWARM_Params.Add("MINER_DELAY", $Null)
    }

    if (-not $(arg).Platform) {
        Write-Host "Detecting Platform..." -Foreground Cyan
        if ($IsWindows) { $(arg).Platform = "windows" }
        else { $(arg).Platform = "linux" }
        Write-Host "OS = $($(arg).Platform)" -ForegroundColor Green
    }
}

function Global:Set-Window {
    if ($(arg).Platform -eq "windows") {
        . .\build\powershell\scripts\icon.ps1 '.\build\apps\icons\comb.ico'
        $Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black'); $Host.UI.RawUI.ForegroundColor = 'White';
        $Host.PrivateData.ErrorForegroundColor = 'Red'; $Host.PrivateData.ErrorBackgroundColor = $bckgrnd;
        $Host.PrivateData.WarningForegroundColor = 'Magenta'; $Host.PrivateData.WarningBackgroundColor = $bckgrnd;
        $Host.PrivateData.DebugForegroundColor = 'Yellow'; $Host.PrivateData.DebugBackgroundColor = $bckgrnd;
        $Host.PrivateData.VerboseForegroundColor = 'Green'; $Host.PrivateData.VerboseBackgroundColor = $bckgrnd;
        $Host.PrivateData.ProgressForegroundColor = 'Cyan'; $Host.PrivateData.ProgressBackgroundColor = $bckgrnd;
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}  
    }    
}

function Global:Start-Servers {
    ##Start API Server
    $Hive_Path = "/hive/bin"
    Write-Host "API Port is $($(arg).Port)";

    if ($(arg).API -eq "Yes") {
        Import-Module -Name "$($(vars).html)\api.psm1"
        $Posh_api = Global:Get-APIServer;
        $Posh_Api.BeginInvoke() | Out-Null
        $Posh_api = $null
        Remove-Module -Name "api"
    }

    Import-Module -Name "$($(vars).tcp)\agentserver.psm1"
    $Posh_SwarmTCP = Global:Get-SWARMServer;
    $Posh_SwarmTCP.BeginInvoke() | Out-Null
    $Posh_SwarmTCP = $Null
    Remove-Module -Name "agentserver"

    if ( (test-path $Hive_Path) -or $(arg).TCP -eq "Yes" ) {
        Import-Module -Name "$($(vars).tcp)\tcpserver.psm1"
        $Posh_HiveTCP = Global:Get-HiveServer;
        $Posh_HiveTCP.BeginInvoke() | Out-Null
        $Posh_HiveTCP = $null
        Remove-Module -Name "tcpserver"
    }
    if ($(arg).API -eq "Yes") { Write-Host "API Server Started- you can run http://localhost:$($(arg).Port)/end to close" -ForegroundColor Green }
}