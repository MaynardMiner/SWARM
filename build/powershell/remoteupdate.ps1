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

function start-update {
    param (
        [Parameter(Mandatory = $false)]
        [String]$Update
    )

    $Location = split-Path $($global:Dir)
    $StartUpdate = $True
    if ($Global:Config.params.Platform -eq "linux" -and $Update -eq "No") { $StartUpdate = $false }

    if ($StartUpdate -eq $true) {
        $PreviousVersions = @()
        $PreviousVersions += "SWARM.2.1.8"
        $PreviousVersions += "SWARM.2.1.9"
        $PreviousVersions += "SWARM.2.2.0"
        $PreviousVersions += "SWARM.2.2.1"
        $PreviousVersions += "SWARM.2.2.2"
        $PreviousVersions += "SWARM.2.2.3"
        $PreviousVersions += "SWARM.2.2.4"
        $PreviousVersions += "SWARM.2.2.5"
        $PreviousVersions += "SWARM.2.2.6"
        $PreviousVersions += "SWARM.2.2.7"

        $StatsOnly = $null

        Write-Log "User Specfied Updates: Searching For Previous Version" -ForegroundColor Yellow
        Write-Log "Check $Location For any Previous Versions"

        $CurrentVersion = (Get-Content ".\h-manifest.conf" | ConvertFrom-StringData).CUSTOM_VERSION
        $CurrentVersion = "$($CurrentVersion[0])$($CurrentVersion[2])$($CurrentVersion[4])"
        $CurrentVersion = [Int]$CurrentVersion

        $PreviousVersions | foreach {
            $PreviousPath = Join-Path "$Location" "$_"
            if (Test-Path $PreviousPath) {
                Write-Log "Detected Previous Version"
                Write-Log "Previous Version is $($PreviousPath)"
                Write-Log "Gathering Old Version Config And HashRates- Then Deleting"
                Start-Sleep -S 10
                $ID = ".\build\pid\background_pid.txt"
                if ($Global:Config.params.Platform -eq "windows") { Start-Sleep -S 10 }
                if ($Global:Config.params.Platform -eq "windows") {
                    Write-Log "Stopping Previous Agent"
                    if (Test-Path $ID) { $Agent = Get-Content $ID }
                    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
                    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
                }
                $OldBackup = Join-Path $PreviousPath "backup"
                $OldStats = Join-Path $PreviousPath "stats"
                $OldTime = Join-Path $PreviousPath "build\data"
                $OldConfig = Join-Path $PreviousPath "config"
                $OldTimeout = Join-Path $PreviousPath "timeout"
                if (-not (Test-Path "backup")) { New-Item "backup" -ItemType "directory" | Out-Null }
                if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" | Out-Null }
                if (Test-Path $OldBackup) {
                    Get-ChildItem -Path "$($OldStats)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\stats"
                    Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\backup"
                }
                #if(Test-Path $OldTime){Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\build\data"}
                if (Test-Path $OldTimeout) {
                    if (-not (Test-Path ".\timeout")) { New-Item "timeout" -ItemType "directory" | Out-Null }
                    if (-not (Test-Path ".\timeout\algo_block")) { New-Item ".\timeout\algo_block" -ItemType "directory" | Out-Null }
                    if (-not (Test-Path ".\timeout\pool_block")) { New-Item ".\timeout\pool_block" -ItemType "directory" | Out-Null }
                    if (Test-Path "$OldTimeout\algo_block") { Get-ChildItem -Path "$($OldTimeout)\algo_block" -Include *.txt, *.conf -Recurse | Copy-Item -Destination ".\timeout\algo_block" }
                    if (Test-Path "$OldTimeout\algo_block") { Get-ChildItem -Path "$($OldTimeout)\pool_block" -Include *.txt, *.conf -Recurse | Copy-Item -Destination ".\timeout\pool_block" }
                    Get-ChildItem -Path "$($OldTimeout)\*" -Include *.txt | Copy-Item -Destination ".\timeout"
                }
                if ($StatsOnly -ne "Yes") {
                    $Jsons = @("miners", "oc", "power", "pools", "asic", "wallets")
                    $UpdateType = @("CPU", "AMD1", "NVIDIA1", "NVIDIA2", "NVIDIA3")
                    $Exclude = @("claymore_amd.json", "ehssand_amd.json", "gminer_amd.json", "phoenix_amd.json", "progminer_amd.json", "stak_cpu.json", "xmrig_cpu.json", "enemy.json", "xmrig_nv.json")
                    if ($CurrentVersion -lt 222) { $Exclude += "pool-algo.json" }
                
                    $Jsons | foreach {
                        $OldJson_Path = Join-Path $OldConfig "$($_)";
                        $NewJson_Path = Join-Path ".\config" "$($_)";
                        $GetOld_Json = Get-ChildItem $OldJson_Path;
                        $GetOld_Json = $GetOld_Json.Name
                        $GetOld_Json | foreach {
                            $ChangeFile = $_
                            $OldJson = Join-Path $OldJson_Path "$ChangeFile";
                            $NewJson = Join-Path $NewJson_Path "$ChangeFile";
                            if ($ChangeFile -notin $Exclude) {
                                $JsonData = Get-Content $OldJson;
                                Write-Log "Pulled $OldJson"
                                $Data = $JsonData | ConvertFrom-Json;

                                if ($ChangeFile -eq "t-rex.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        ##2.1.3
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "mtp" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "mtp" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "mtp" "mtp" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "mtp" 1 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "cryptodredge.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        ##2.1.3
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "argon2d4096" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "argon2d4096" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "argon2d4096" "argon2d4096" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "argon2d4096" 1 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "argon2d250" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "argon2d250" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "argon2d250" "argon2d250" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "argon2d250" 1 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "argond2d-dyn" "" -ErrorAction SilentlyContinue -Force
                                            $Data.$_.difficulty | Add-Member "argond2d-dyn" "" -ErrorAction SilentlyContinue -Force
                                            $Data.$_.naming | Add-Member "argond2d-dyn" "argond2d-dyn" -ErrorAction SilentlyContinue -Force
                                            $Data.$_.fee | Add-Member "argond2d-dyn" 1 -ErrorAction SilentlyContinue -Force

                                            $Data.$_.commands = $Data.$_.commands | Select -ExcludeProperty "cryptonightv7"
                                            $Data.$_.difficulty = $Data.$_.difficulty | Select -ExcludeProperty "cryptonightv7"
                                            $Data.$_.naming = $Data.$_.naming | Select -ExcludeProperty "cryptonightv7"
                                            $Data.$_.fee = $Data.$_.fee | Select -ExcludeProperty "cryptonightv7"
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "wildrig.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands = $Data.$_.commands | Select -ExcludeProperty "rainforest"
                                            $Data.$_.difficulty = $Data.$_.difficulty | Select -ExcludeProperty "rainforest"
                                            $Data.$_.naming = $Data.$_.naming | Select -ExcludeProperty "rainforest"
                                            $Data.$_.fee = $Data.$_.fee | Select -ExcludeProperty "rainforest"

                                            $Data.$_.commands | Add-Member "wildkeccak" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "wildkeccak" "" -ErrorAction SilentlyContinue
                                            $Data.$_.naming | Add-Member "wildkeccak" "wildkeccak" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "wildkeccak" 1 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "xevan" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "xevan" "" -ErrorAction SilentlyContinue
                                            $Data.$_.naming | Add-Member "xevan" "xevan" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "xevan" 1 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "pool-algos.json") {
                                    $Data | Add-Member "argon2d4096" @{ hiveos_name = "argon2d-uis"; exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                                    $Data | Add-Member "argon2d250" @{ hiveos_name = "argon2d250"; exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                                }                            

                                $Data | ConvertTo-Json -Depth 3 | Set-Content $NewJson;
                                Write-Log "Wrote To $NewJson"
                            }
                        }
                    }
                    $NameJson_Path = Join-Path ".\config" "miners";
                    $GetOld_Json = Get-ChildItem $NameJson_Path;
                    $GetOld_Json = $GetOld_Json.Name
                    $GetOld_Json | foreach {
                        $ChangeFile = $_
                        $NewName = $ChangeFile -Replace ".json", "";
                        $NameJson = Join-Path ".\config\miners" "$ChangeFile";
                        $JsonData = Get-Content $NameJson;
                        Write-Log "Pulled $NameJson"
                        $Data = $JsonData | ConvertFrom-Json;
                        $Data | Add-Member "name" "$NewName" -ErrorAction SilentlyContinue
                        $Data | ConvertTo-Json -Depth 3 | Set-Content $NameJson;
                        Write-Log "Wrote To $NameJson"
                    }
                    Remove-Item $PreviousPath -recurse -force
                }
            }
        }
    }
}
