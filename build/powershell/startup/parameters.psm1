<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

function Global:Get-Parameters {
    $Global:config.add("params", @{ })
    $Global:Config.add("user_params",@{ })
    $Global:Config.add("hive_params",@{})
    $Global:Config.add("SWARM_Params",@{})
    ## Use new arguments first.
    if (Test-Path ".\config\parameters\newarguments.json") {
        $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $(arg).Add("$($_)", $arguments.$_) }
        $arguments.PSObject.Properties.Name | % { $Global:Config.user_params.Add("$($_)", $arguments.$_) }
    }
    ## else use arguments user specified.
    else {
        $arguments = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $(arg).Add("$($_)", $arguments.$_) }
        $arguments.PSObject.Properties.Name | % { $Global:Config.user_params.Add("$($_)", $arguments.$_) }
        $arguments = $Null
    }
    if (Test-Path ".\config\parameters\Hive_params_keys.json") {
        $HiveStuff = Get-Content ".\config\parameters\Hive_params_keys.json" | ConvertFrom-Json
        $HiveStuff.PSObject.Properties.Name | % { $global:Config.hive_params.Add("$($_)", $HiveStuff.$_) }
        $HiveStuff = $null
    }
    if (-not $global:Config.hive_params.Id) {
        $global:Config.hive_params.Add("Id", $Null)
        $global:Config.hive_params.Add("Password", $Null)
        $global:Config.hive_params.Add("Worker", "$($global:Config.user_params.Worker)")
        $global:Config.hive_params.Add("Mirror", "https://api.hiveos.farm")
        $global:Config.hive_params.Add("FarmID", $Null)
        $global:Config.hive_params.Add("Wd_Enabled", $null)
        $Global:config.hive_params.Add("Wd_miner", $Null)
        $Global:config.hive_params.Add("Wd_reboot", $Null)
        $Global:config.hive_params.Add("Wd_minhashes", $Null)
        $Global:config.hive_params.Add("Miner", $Null)
        $global:Config.hive_params.Add("Miner2", $Null)
        $global:Config.hive_params.Add("Timezone", $Null)
        $global:Config.hive_params.Add("WD_CHECK_GPU", $Null)
        $global:Config.hive_params.Add("PUSH_INTERVAL", $Null)
        $global:Config.hive_params.Add("MINER_DELAY", $Null)
    }

    if (Test-Path ".\config\parameters\SWARM_params_keys.json") {
        $SWARMStuff = Get-Content ".\config\parameters\SWARM_params_keys.json" | ConvertFrom-Json
        $SWARMStuff.PSObject.Properties.Name | % { $global:Config.SWARM_Params.Add("$($_)", $SWARMStuff.$_) }
        $SWARMStuff = $null
    }
    if (-not $global:Config.SWARM_Params.Id) {
        $global:Config.SWARM_Params.Add("Id", $Null)
        $global:Config.SWARM_Params.Add("Password", $Null)
        $global:Config.SWARM_Params.Add("Worker", "$($global:Config.user_params.Worker)")
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

    if ([string]$global:config.user_params.Platform -eq "") {
        write-Host "Detecting Platform..." -Foreground Cyan
        if ($IsWindows) { 
            $global:config.user_params.Platform = "windows" 
            $(arg).Platform = "windows"
        }
        elseif($IsLinux) { 
            $global:config.user_params.Platform = "linux" 
            $(arg).Platform = "linux"
        }
        Write-Host "OS = $($global:config.user_params.Platform)" -ForegroundColor Green
    }
    if (-not (Test-Path ".\build\txt")) { New-Item -Name "txt" -ItemType "Directory" -Path ".\build" | Out-Null }
    $global:config.user_params.Platform | Set-Content ".\build\txt\os.txt"
    ## Get Algorithms
    $global:Config.Add("Pool_Algos",(Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json))
}
