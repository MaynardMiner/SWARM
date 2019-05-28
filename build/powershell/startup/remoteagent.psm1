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

function Get-Version {
$global:Version = Get-Content ".\h-manifest.conf" | ConvertFrom-StringData
$global:Version.CUSTOM_VERSION | Set-Content ".\build\txt\version.txt"
$global:Version = $global:Version.CUSTOM_VERSION
}

function start-update {
    param (
        [Parameter(Mandatory = $false)]
        [String]$Update
    )

    $Location = split-Path $($global:Dir)
    $StartUpdate = $true
    if ($Global:Config.params.Platform -eq "linux" -and $Update -eq "No") { $StartUpdate = $false }

    if ($StartUpdate -eq $true) {
        $PreviousVersions = @()
        $PreviousVersions += "SWARM.2.2.9"
        $PreviousVersions += "SWARM.2.3.0"
        $PreviousVersions += "SWARM.2.3.1"

        $StatsOnly = $null

        Write-Log "User Specfied Updates: Searching For Previous Version" -ForegroundColor Yellow
        Write-Log "Check $Location For any Previous Versions"

        if (Test-Path "C:\") {
            $Global:amd = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json
            $Global:nvidia = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json
            $Global:cpu = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json
        }
        else {
            $Global:amd = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json
            $Global:nvidia = Get-Content ".\config\update\nvidia10-linux.json" | ConvertFrom-Json
            $Global:cpu = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json
        }

        $CurrentVersion = "$($global:Version[0])$($global:Version[2])$($global:Version[4])"
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
                    $Jsons = @("oc", "power", "pools", "asic", "wallets")
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

                                #if ($ChangeFile -eq "cryptodredge.json") {
                                #   $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                #      if ($_ -ne "name") {
                                #         $Data.$_.commands | Add-Member "argon2d4096" "" -ErrorAction SilentlyContinue
                                #        $Data.$_.difficulty | Add-Member "argon2d4096" "" -ErrorAction SilentlyContinue 
                                #       $Data.$_.naming | Add-Member "argon2d4096" "argon2d4096" -ErrorAction SilentlyContinue
                                #       $Data.$_.fee | Add-Member "argon2d4096" 1 -ErrorAction SilentlyContinue
                                #   }
                                # }
                                #}


                                if ($ChangeFile -eq "wildrig.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "x25x" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "x25x" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "x25x" "x25x" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "x25x" 1 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "gminer-amd.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "cuckatoo31" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "cuckatoo31" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "cuckatoo31" "cuckatoo31" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "cuckatoo31" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_96/5" "equihash_96/5" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_96/5" 2 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "gminer.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "cuckatoo31" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "cuckatoo31" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "cuckatoo31" "cuckatoo31" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "cuckatoo31" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_96/5" "equihash_96/5" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_96/5" 2 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "t-rex.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "x25x" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "x25x" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "x25x" "x25x" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "x25x" 1 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }
 
                                if($ChangeFile -eq "pool-algos.json") {
                                    $Data | add-Member "x25x" @{alt_names = @("x25x"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue
                                }

                                if($ChangeFile -eq "oc-algos.json") {
                                    $Data | Add-Member "x25x" @{
                                        "NVIDIA1" = @{
                                            "Fans" = ""
                                            "ETHPill"= ""
                                            "Core"=""
                                            "Memory"=""
                                            "Power"= ""
                                            "PillDelay"= ""
                                        };               
                                        "NVIDIA2" = @{
                                            "Fans" = ""
                                            "ETHPill"= ""
                                            "Core"=""
                                            "Memory"=""
                                            "Power"= ""
                                            "PillDelay"= ""
                                        };                          
                                        "NVIDIA3" = @{
                                            "Fans" = ""
                                            "ETHPill"= ""
                                            "Core"=""
                                            "Memory"=""
                                            "Power"= ""
                                            "PillDelay"= ""
                                        };                         
                                        "AMD1"= @{
                                            "fans"= ""
                                            "v"= ""
                                            "dpm"= ""
                                            "mem"= ""
                                            "mdpm"= ""
                                            "core"= ""
                                        }                                
                                    } -ErrorAction SilentlyContinue
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

                    $Global:amd.PSobject.Properties.Name | ForEach-Object {
                        if ($_ -ne "name") {
                            if (-not (Test-Path ".\bin")) { New-Item -Name "bin" -ItemType Directory }
                            $MinerPath1 = Join-Path $PreviousPath ( Split-Path $($Global:amd.$_.AMD1 -replace "\.", ""))
                            $NewMinerPath1 = Join-Path $global:Dir ( Split-Path $($Global:amd.$_.AMD1 -replace "\.", ""))
                            if ( Test-Path $Minerpath1 ) {
                                $SwarmV = "$Minerpath1\swarm-version.txt"
                                if (Test-Path $SWARMV) {    
                                    $GetVersion = Get-Content "$Minerpath1\swarm-version.txt"
                                    if ($GetVersion -eq $Global:amd.$_.version) {
                                        Write-Log "Moving $MinerPath1"
                                        Move-Item $MinerPath1 $NewMinerPath1
                                    }
                                }
                            }
                        }
                    }

                    $Global:cpu.PSobject.Properties.Name | ForEach-Object {
                        if ($_ -ne "name") {
                            if (-not (Test-Path ".\bin")) { New-Item -Name "bin" -ItemType Directory }
                            $MinerPath1 = Join-Path $PreviousPath ( Split-Path $($Global:cpu.$_.CPU -replace "\.", ""))
                            $NewMinerPath1 = Join-Path $global:Dir ( Split-Path $($Global:cpu.$_.CPU -replace "\.", ""))
                            if ( Test-Path $Minerpath1 ) {
                                $SwarmV = "$Minerpath1\swarm-version.txt"
                                if (Test-Path $SWARMV) {
                                    $GetVersion = Get-Content $SwarmV
                                    if ($GetVersion -eq $Global:cpu.$_.version) {
                                        Write-Log "Moving $MinerPath1"
                                        Move-Item $MinerPath1 $NewMinerPath1
                                    }
                                }
                            }
                        }
                    }

                    $Global:nvidia.PSobject.Properties.Name | ForEach-Object {
                        if ($_ -ne "name") {

                            if (-not (Test-Path ".\bin")) { New-Item -Name "bin" -ItemType Directory }

                            $MinerPath1 = Join-Path $PreviousPath ( Split-Path $($Global:nvidia.$_.NVIDIA1 -replace "\.", ""))
                            $NewMinerPath1 = Join-Path $global:Dir ( Split-Path $($Global:nvidia.$_.NVIDIA1 -replace "\.", ""))

                            $MinerPath2 = Join-Path $PreviousPath ( Split-Path $($Global:nvidia.$_.NVIDIA2 -replace "\.", ""))
                            $NewMinerPath2 = Join-Path $global:Dir ( Split-Path $($Global:nvidia.$_.NVIDIA2 -replace "\.", ""))

                            $MinerPath3 = Join-Path $PreviousPath ( Split-Path $($Global:nvidia.$_.NVIDIA3 -replace "\.", ""))
                            $NewMinerPath3 = Join-Path $global:Dir ( Split-Path $($Global:nvidia.$_.NVIDIA3 -replace "\.", ""))

                            if ( Test-Path $Minerpath1 ) {
                                $SwarmV = "$Minerpath1\swarm-version.txt"
                                if (Test-Path $SWARMV) {
                                    $GetVersion = Get-Content $SwarmV
                                    if ($GetVersion -eq $Global:nvidia.$_.version) {
                                        Write-Log "Moving $MinerPath1"
                                        Move-Item $MinerPath1 $NewMinerPath1
                                    }
                                }
                            }
                            if ( Test-Path $Minerpath2 ) {
                                $SwarmV = "$Minerpath2\swarm-version.txt"
                                if (Test-Path $SWARMV) {
                                    $GetVersion = Get-Content $SwarmV
                                    if ($GetVersion -eq $Global:nvidia.$_.version) {
                                        Write-Log "Moving $MinerPath2"
                                        Move-Item $MinerPath2 $NewMinerPath2
                                    }
                                }
                            }
                            if ( Test-Path $Minerpath3 ) {
                                $SwarmV = "$Minerpath3\swarm-version.txt"
                                if (Test-Path $SWARMV) {
                                    $GetVersion = Get-Content $SwarmV
                                    $GetVersion = Get-Content "$Minerpath3\swarm-version.txt"
                                    if ($GetVersion -eq $Global:nvidia.$_.version) {
                                        Write-Log "Moving $MinerPath3"
                                        Move-Item $MinerPath3 $NewMinerPath3
                                    }
                                }
                            }
                        }
                    }

                    Remove-Item $PreviousPath -recurse -force
                }
            }
        }
    }
}

function Start-AgentCheck {

    $Global:dir | Set-Content ".\build\cmd\dir.txt"

    ##Get current path envrionments
    $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path

    ##First remove old Paths, in case this is an update / new dir
    $oldpathlist = "$oldpath" -split ";"
    $oldpathlist | ForEach-Object { if ($_ -like "*SWARM*" -and $_ -notlike "*$($global:dir)\build\cmd*" ) { Set-NewPath "remove" "$($_)" } }

    if ($oldpath -notlike "*;$($global:dir)\build\cmd*") {
        write-Log "
Setting Path Variable For Commands: May require reboot to use.
" -ForegroundColor Yellow
        $newpath = "$global:dir\build\cmd"
        Set-NewPath "add" $newpath
    }
    $newpath = "$oldpath;$($global:dir)\build\cmd"
    write-Log "Stopping Previous Agent"
    $ID = ".\build\pid\background_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    $ID = ".\build\pid\pill_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }    
}

