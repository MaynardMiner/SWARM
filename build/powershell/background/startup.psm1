function Get-Params {
    $Global:stats.Add("summary", @{ })
    $Global:stats.Add("params", @{ })
    $Global:stats.Add("stats", @{ })
    $global:Config.Add("params", @{ })
    $global:Config.Add("Hive_Params", @{ })
    if (Test-Path ".\config\parameters\newarguments.json") {
        $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $global:Config.Params.Add("$($_)", $arguments.$_) }
        $arguments = $null
    }
    else {
        $arguments = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $global:Config.Params.Add("$($_)", $arguments.$_) }
        $arguments = $null
    }
    if (Test-Path ".\build\txt\hivekeys.txt") {
        $HiveStuff = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json
        $HiveStuff.PSObject.Properties.Name | % { $global:Config.Hive_Params.Add("$($_)", $HiveStuff.$_) }
        $HiveStuff = $null
    }
    if (-not $global:Config.Hive_Params.HiveID) {
        Write-Host "No HiveID- HiveOS Disabled"
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
}

function Set-Window {
    if ($global:Config.Params.Platform -eq "windows") {
        . .\build\powershell\icon.ps1 '.\build\apps\comb.ico'
        $Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black'); $Host.UI.RawUI.ForegroundColor = 'White';
        $Host.PrivateData.ErrorForegroundColor = 'Red'; $Host.PrivateData.ErrorBackgroundColor = $bckgrnd;
        $Host.PrivateData.WarningForegroundColor = 'Magenta'; $Host.PrivateData.WarningBackgroundColor = $bckgrnd;
        $Host.PrivateData.DebugForegroundColor = 'Yellow'; $Host.PrivateData.DebugBackgroundColor = $bckgrnd;
        $Host.PrivateData.VerboseForegroundColor = 'Green'; $Host.PrivateData.VerboseBackgroundColor = $bckgrnd;
        $Host.PrivateData.ProgressForegroundColor = 'Cyan'; $Host.PrivateData.ProgressBackgroundColor = $bckgrnd;
        Clear-Host  
    }    
}

function Start-Servers {
    ##Start API Server
    $Hive_Path = "/hive/bin"
    Write-Host "API Port is $($global:Config.Params.Port)";

    if ($Global:config.Params.API -eq "Yes") {
        Import-Module -Name "$global:html\api.psm1"
        $Posh_api = Get-APIServer;
        $Posh_Api.BeginInvoke() | Out-Null
        $Posh_api = $null
        Remove-Module -Name "api"
    }

    Import-Module -Name "$global:tcp\agentserver.psm1"
    $Posh_SwarmTCP = Get-SWARMServer;
    $Posh_SwarmTCP.BeginInvoke() | Out-Null
    $Posh_SwarmTCP = $Null
    Remove-Module -Name "agentserver"

    if (test-path $Hive_Path) {
        Import-Module -Name "$global:tcp\hiveserver.psm1"
        $Posh_HiveTCP = Get-HiveServer;
        $Posh_HiveTCP.BeginInvoke() | Out-Null
        $Posh_HiveTCP = $null
        Remove-Module -Name "hiveserver"
    }
    if ($global:Config.Params.API -eq "Yes") { Write-Host "API Server Started- you can run http://localhost:$($global:Config.Params.Port)/end to close" -ForegroundColor Green }
}