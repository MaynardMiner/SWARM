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

function Global:Get-Version {
$global:Version = Get-Content ".\h-manifest.conf" | ConvertFrom-StringData
$global:Version.CUSTOM_VERSION | Set-Content ".\build\txt\version.txt"
$global:Version = $global:Version.CUSTOM_VERSION
}

function Global:start-update {
    param (
        [Parameter(Mandatory = $false)]
        [String]$Update
    )

    $Location = split-Path $($(vars).dir)
    $StartUpdate = $true
    if ($(arg).Platform -eq "linux" -and $Update -eq "No") { $StartUpdate = $false }

    if ($StartUpdate -eq $true) {
        $PreviousVersions = @()
        $PreviousVersions += "SWARM.2.3.8"
        $PreviousVersions += "SWARM.2.3.9"
        $PreviousVersions += "SWARM.2.4.0"
        $PreviousVersions += "SWARM.2.4.1"
        $PreviousVersions += "SWARM.2.4.2"
        $PreviousVersions += "SWARM.2.4.3"        
        $PreviousVersions += "SWARM.2.4.4"
        $PreviousVersions += "SWARM.2.4.5"
        $PreviousVersions += "SWARM.2.4.6"
        $PreviousVersions += "SWARM.2.4.7"
        $PreviousVersions += "SWARM.2.4.8"
        $PreviousVersions += "SWARM.2.4.9"
        $PreviousVersions += "SWARM.2.5.0"
        $PreviousVersions += "SWARM.2.5.1"
        $PreviousVersions += "SWARM.2.5.2"
        $PreviousVersions += "SWARM.2.5.3"
        $PreviousVersions += "SWARM.2.5.4"
        $PreviousVersions += "SWARM.2.5.5"
        $PreviousVersions += "SWARM.2.5.6"
        $PreviousVersions += "SWARM.2.5.7"
        $PreviousVersions += "SWARM.2.5.8"
        $PreviousVersions += "SWARM.2.5.9"

        $StatsOnly = $null

        log "User Specfied Updates: Searching For Previous Version" -ForegroundColor Yellow
        log "Check $Location For any Previous Versions"

        if ($IsWindows) {
            $Global:amd = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json
            $Global:nvidia = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json
            $Global:cpu = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json
        }
        else {
            $Global:amd = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json
            $Global:nvidia = Get-Content ".\config\update\nvidia-linux.json" | ConvertFrom-Json
            $Global:cpu = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json
        }

        $CurrentVersion = "$($global:Version[0])$($global:Version[2])$($global:Version[4])"
        $CurrentVersion = [Int]$CurrentVersion

        $PreviousVersions | foreach {
            $PreviousPath = Join-Path "$Location" "$_"
            if (Test-Path $PreviousPath) {
                log "Detected Previous Version"
                log "Previous Version is $($PreviousPath)"
                log "Gathering Old Version Config And HashRates- Then Deleting"
                Start-Sleep -S 10
                $ID = ".\build\pid\background_pid.txt"
                if ($(arg).Platform -eq "windows") { Start-Sleep -S 10 }
                if ($(arg).Platform -eq "windows") {
                    log "Stopping Previous Agent"
                    if (Test-Path $ID) { $Agent = Get-Content $ID }
                    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
                    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
                }
                $OldBackup = Join-Path $PreviousPath "backup"
                $OldStats = Join-Path $PreviousPath "stats"
                $OldTime = Join-Path $PreviousPath "build\data"
                $OldConfig = Join-Path $PreviousPath "config"
                $OldTimeout = Join-Path $PreviousPath "timeout"
                $OldAdmin = Join-Path $PreviousPath "admin"
                if (-not (Test-Path "backup")) { New-Item "backup" -ItemType "directory" | Out-Null }
                if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" | Out-Null }
                if (Test-Path $OldBackup) {
                    Get-ChildItem -Path "$($OldStats)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\stats"
                    Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\backup"
                }
                if (Test-Path $OldAdmin){
                    if (-not (Test-Path ".\admin")) { New-Item ".\admin" -ItemType "directory" | Out-Null }
                    Get-ChildItem -Path "$($OldAdmin)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\admin"
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
                    $Jsons = @("asic","miners","oc","pools","power","wallets")
                    $UpdateType = @("CPU", "AMD1", "NVIDIA1", "NVIDIA2", "NVIDIA3")

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
                                log "Pulled $OldJson"

                                try{$Data = $JsonData | ConvertFrom-Json -ErrorAction Stop} catch{}

                                if ($ChangeFile -eq "lolminer.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_125/4" "equihash_125/4" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_125/4" 1 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "cuckaroo29" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "cuckaroo29" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "cuckaroo29" "cuckaroo29" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "cuckaroo29" 1 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "cuckaroo29d" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "cuckaroo29d" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "cuckaroo29d" "cuckaroo29d" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "cuckaroo29d" 1 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "beamv2" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "beamv2" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "beamv2" "beamv2" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "beamv2" 1 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "nbminer.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "cuckaroo29d" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "cuckaroo29d" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "cuckaroo29d" "cuckaroo29d" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "cuckaroo29d" 2 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }
                                if ($ChangeFile -eq "bminer.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "cuckaroo29d" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "cuckaroo29d" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "cuckaroo29d" "cuckaroo29d" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "cuckaroo29d" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "beamv2" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "beamv2" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "beamv2" "beamv2" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "beamv2" 2 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "nv-lolminer.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_125/4" "equihash_125/4" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_125/4" 1 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "wildrig.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "x25x" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "x25x" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "x25x" "x25x" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "x25x" 1 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "anime" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "anime" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "anime" "anime" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "anime" 1 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "skein2" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "skein2" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "skein2" "skein2" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "skein2" 1 -ErrorAction SilentlyContinue

                                        }
                                    }
                                }

                                if ($ChangeFile -eq "miniz.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "equihash_150/5" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_150/5" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_150/5" "equihash_150/5" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_150/5" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "equihash_192/7" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_192/7" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_192/7" "equihash_192/7" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_192/7" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_125/4" "equihash_125/4" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_125/4" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_96/5" "equihash_125/4" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_96/5" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "beamv2" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "beamv2" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "beamv2" "beamv2" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "beamv2" 2 -ErrorAction SilentlyContinue

                                        }
                                    }
                                }

                                if ($ChangeFile -eq "fancyix.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands.mtp = "-I 20"
                                            $Data.$_.difficulty.mtp = "700"

                                            $Data.$_.commands | Add-Member "x25x" "-gpu-threads 2 -w 256 -g 4" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "x25x" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "x25x" "x25x" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "x25x" 0 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "gminer-amd.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach { 
                                        if ($_ -ne "name") {
                                            $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "equihash125/4"
                                            $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "equihash125/4"
                                            $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "equihash125/4"
                                            $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "equihash125/4"

                                            $Data.$_.commands | Add-Member "cuckatoo31" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "cuckatoo31" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "cuckatoo31" "cuckatoo31" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "cuckatoo31" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_96/5" "equihash_96/5" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_96/5" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "beamv2" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "beamv2" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "beamv2" "beamv2" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "beamv2" 2 -ErrorAction SilentlyContinue
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

                                            $Data.$_.commands | Add-Member "cuckaroo29d" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "cuckaroo29d" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "cuckaroo29d" "cuckaroo29d" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "cuckaroo29d" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_96/5" "equihash_96/5" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_96/5" 2 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "equihash_125/4" "equihash_125/4" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "equihash_125/4" 2 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }
                                if ($ChangeFile -eq "teamredminer.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "x16r" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "x16r" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "x16r" "x16r" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "x16r" 2.5 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "x16s" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "x16s" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "x16s" "x16s" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "x16s" 2.5 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "x16rt" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "x16rt" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "x16rt" "x16rt" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "x16rt" 2.5 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "veil" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "veil" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "veil" "veil" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "veil" 2.5 -ErrorAction SilentlyContinue

                                            $Data.$_.commands | Add-Member "mtp" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "mtp" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "mtp" "mtp" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "mtp" 2.5 -ErrorAction SilentlyContinue
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

                                            $Data.$_.commands | Add-Member "honeycomb" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "honeycomb" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "honeycomb" "honeycomb" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "honeycomb" 1 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }

                                if ($ChangeFile -eq "sugarchain.json") {
                                    $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                        if ($_ -ne "name") {
                                            $Data.$_.commands | Add-Member "lyra2z330" "" -ErrorAction SilentlyContinue
                                            $Data.$_.difficulty | Add-Member "lyra2z330" "" -ErrorAction SilentlyContinue 
                                            $Data.$_.naming | Add-Member "lyra2z330" "lyra2z330" -ErrorAction SilentlyContinue
                                            $Data.$_.fee | Add-Member "lyra2z330" 0 -ErrorAction SilentlyContinue
                                        }
                                    }
                                }
 
                                if($ChangeFile -eq "pool-algos.json") {
                                    $Data | add-Member "x25x" @{alt_names = @("x25x"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue
                                    $Data | add-Member "lyra2z330" @{alt_names = @("lyra2z330"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue
                                    $Data | add-Member "cuckaroo29d" @{alt_names = @("cuckaroo29d","grincuckaroo29d"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue
                                    $Data | add-Member "bmw512" @{alt_names = @("bmw512"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue
                                    $Data | add-Member "x14" @{alt_names = @("x14"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue
                                    $Data | add-Member "cpupower" @{alt_names = @("cpupower"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue
                                    $Data | add-Member "equihash_125/4" @{alt_names = @("zelcash","equihash_125/4","equihash125"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue -Force
                                    $Data | add-Member "equihash_150/5" @{alt_names = @("equihash_150/5","equihash150","beam"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue -Force                                   
                                    $Data | add-Member "argon2d500" @{alt_names = @("argon2d500"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue -Force         
                                    $Data | add-Member "argon2d-dyn" @{alt_names = @("argon2d-dyn"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue -Force                                                             
                                    $Data | add-Member "beamv2" @{alt_names = @("beamv2"); exclusions = @("add pool or miner here","comma seperated")} -ErrorAction SilentlyContinue -Force                                                             
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

                                   $Data| Add-Member "anime" @{
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

                                    $Data| Add-Member "cuckaroo29d" @{
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

                                $Data | ConvertTo-Json -Depth 10 | Set-Content $NewJson;
                                log "Wrote To $NewJson"
                            }
                        }
                    }
                    $NameJson_Path = Join-Path ".\config" "miners";
                    $GetOld_Json = Get-ChildItem $NameJson_Path | Where Extension -ne ".md"
                    $GetOld_Json = $GetOld_Json.Name
                    $GetOld_Json | foreach {
                        $ChangeFile = $_
                        $NewName = $ChangeFile -Replace ".json", "";
                        $NameJson = Join-Path ".\config\miners" "$ChangeFile";
                        $JsonData = Get-Content $NameJson;
                        log "Pulled $NameJson"
                        $Data = $JsonData | ConvertFrom-Json;
                        $Data | Add-Member "name" "$NewName" -ErrorAction SilentlyContinue
                        $Data | ConvertTo-Json -Depth 10 | Set-Content $NameJson;
                        log "Wrote To $NameJson"
                    }

                    $Global:amd.PSobject.Properties.Name | ForEach-Object {
                        if ($_ -ne "name") {
                            if (-not (Test-Path ".\bin")) { New-Item -Name "bin" -ItemType Directory }
                            $MinerPath1 = Join-Path $PreviousPath ( Split-Path $($Global:amd.$_.AMD1 -replace "\.", ""))
                            $NewMinerPath1 = Join-Path $($(vars).dir) ( Split-Path $($Global:amd.$_.AMD1 -replace "\.", ""))
                            if ( Test-Path $Minerpath1 ) {
                                $SwarmV = "$Minerpath1\swarm-version.txt"
                                if (Test-Path $SWARMV) {    
                                    $GetVersion = Get-Content "$Minerpath1\swarm-version.txt"
                                    if ($GetVersion -eq $Global:amd.$_.version) {
                                        log "Moving $MinerPath1"
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
                            $NewMinerPath1 = Join-Path $($(vars).dir) ( Split-Path $($Global:cpu.$_.CPU -replace "\.", ""))
                            if ( Test-Path $Minerpath1 ) {
                                $SwarmV = "$Minerpath1\swarm-version.txt"
                                if (Test-Path $SWARMV) {
                                    $GetVersion = Get-Content $SwarmV
                                    if ($GetVersion -eq $Global:cpu.$_.version) {
                                        log "Moving $MinerPath1"
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
                            $NewMinerPath1 = Join-Path $($(vars).dir) ( Split-Path $($Global:nvidia.$_.NVIDIA1 -replace "\.", ""))

                            $MinerPath2 = Join-Path $PreviousPath ( Split-Path $($Global:nvidia.$_.NVIDIA2 -replace "\.", ""))
                            $NewMinerPath2 = Join-Path $($(vars).dir) ( Split-Path $($Global:nvidia.$_.NVIDIA2 -replace "\.", ""))

                            $MinerPath3 = Join-Path $PreviousPath ( Split-Path $($Global:nvidia.$_.NVIDIA3 -replace "\.", ""))
                            $NewMinerPath3 = Join-Path $($(vars).dir) ( Split-Path $($Global:nvidia.$_.NVIDIA3 -replace "\.", ""))

                            if ( Test-Path $Minerpath1 ) {
                                $SwarmV = "$Minerpath1\swarm-version.txt"
                                if (Test-Path $SWARMV) {
                                    $GetVersion = Get-Content $SwarmV
                                    if ($GetVersion -eq $Global:nvidia.$_.version) {
                                        log "Moving $MinerPath1"
                                        Move-Item $MinerPath1 $NewMinerPath1
                                    }
                                }
                            }
                            if ( Test-Path $Minerpath2 ) {
                                $SwarmV = "$Minerpath2\swarm-version.txt"
                                if (Test-Path $SWARMV) {
                                    $GetVersion = Get-Content $SwarmV
                                    if ($GetVersion -eq $Global:nvidia.$_.version) {
                                        log "Moving $MinerPath2"
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
                                        log "Moving $MinerPath3"
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

function Global:Start-AgentCheck {

    $($(vars).dir) | Set-Content ".\build\cmd\dir.txt"

    ##Get current path envrionments
    $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path

    ##First remove old Paths, in case this is an update / new dir
    $oldpathlist = "$oldpath" -split ";"
    $oldpathlist | ForEach-Object { if ($_ -like "*SWARM*" -and $_ -notlike "*$($(vars).dir)\build\cmd*" ) { Global:Set-NewPath "remove" "$($_)" } }

    if ($oldpath -notlike "*;$($(vars).dir)\build\cmd*") {
        log "
Setting Path Variable For Commands: May require reboot to use.
" -ForegroundColor Yellow
        $newpath = "$($(vars).dir)\build\cmd"
        Global:Set-NewPath "add" $newpath
    }
    $newpath = "$oldpath;$($(vars).dir)\build\cmd"
    log "Stopping Previous Agent"
    $ID = ".\build\pid\background_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    $ID = ".\build\pid\pill_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }    
}

