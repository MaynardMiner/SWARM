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
function set-minerconfig {
    param (
        [Parameter(mandatory = $true, position = 0)]
        [string] $InputMiner,
        [Parameter(mandatory = $true, position = 1)]
        [string] $Logs
    )
      
    $ConfigMiner = $InputMiner | ConvertFrom-JSon
    $ConfigPathDir = Split-Path $ConfigMiner.Path
    if ($null -ne $ConfigMiner.Devices) {$MinerDevices = Get-DeviceString -TypeDevices $ConfigMiner.Devices}
    else {
        $GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
        if($ConfigMiner.Type -like "*NVIDIA*"){$TypeS = "NVIDIA"}
        if($ConfigMiner.Type -like "*AMD*"){$TypeS = "AMD"}
        $MinerDevices = Get-DeviceString -TypeCount $($GCount.$TypeS.PSObject.Properties.Value.Count)
    }
    $ConfigFile = @()

    switch ($ConfigMiner.DeviceCall) {
        "grin-miner" {
            $ConfigPath = "grin-miner.toml"
            $ConfigFile += "[logging]"
            $ConfigFile += "log_to_stdout = true"
            $ConfigFile += "stdout_log_level = `"Info`""
            $ConfigFile += "log_to_file = true"
            $ConfigFile += "log_file_path = `"$($Logs)`""
            $ConfigFile += "log_file_append = false"
            $ConfigFile += "file_log_level = `"Debug`""
            $ConfigFile += ""
            $ConfigFile += "[mining]"
            $ConfigFile += "run_tui = true"
            $ConfigFile += "stratum_server_addr = `"$($ConfigMiner.Host)`""
            $ConfigFile += "stratum_server_login = `"$($ConfigMiner.User)`""
            $ConfigFile += "stratum_server_password = `"x`""
            $ConfigFile += "stratum_server_tls_enabled = false"
            $ConfigFile += ""
            switch ($ConfigMiner.Algo) {
                "grincuckaroo29" {
                    switch -WildCard ($ConfigMiner.Type) {
                        "*NVIDIA*" {
                            $MinerDevices | % {
                                $ConfigFile += "[[mining.miner_plugin_config]]"
                                $ConfigFile += "plugin_name = `"cuckaroo_cuda_29`""
                                $ConfigFile += "[mining.miner_plugin_config.parameters]"
                                $ConfigFile += "device = $($_)"
                                $ConfigFile += "cpuload = 1"
                                $ConfigFile += "ntrims = 176"
                                $ConfigFile += "genablocks = 4096"
                                $ConfigFile += "genatpb = 128"
                                $ConfigFile += "genbtpb = 128"
                                $ConfigFile += "trimtpb = 512"
                                $ConfigFile += "tailtpb = 1024"
                                $ConfigFile += "recoverblocks = 1024"
                                $ConfigFile += "recovertpb = 1024"
                                $ConfigFile += ""
                            }
                        }
                        "*AMD*" {
                            $MinerDevices | % {
                                $ConfigFile += "[[mining.miner_plugin_config]]"
                                $ConfigFile += "plugin_name = `"ocl_cuckaroo`""
                                $ConfigFile += "[mining.miner_plugin_config.parameters]"
                                $ConfigFile += "platform = 1"
                                $ConfigFile += "device = $($_)"
                                $ConfigFile += ""
                            }
                        }
                    }
                }
            }
        }

    }
    $Config = Join-Path $ConfigPathDir $ConfigPath
    Write-Host "Settng Config File To $Config" -ForegroundColor Yellow
    $ConfigFile | Set-Content $Config
}