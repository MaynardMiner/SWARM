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

function Global:start-update {

    $Parent = Split-Path $(vars).dir
    log "User Specfied Updates: Searching For Previous Version" -ForegroundColor Yellow
    log "Checking $Parent For any Previous Versions"

    $PreviousVersions = @();
    $Folders = [IO.Directory]::GetDirectories($Parent) | Where-Object { $_ -like "*SWARM*" };

    if ([IO.File]::Exists("h-manifest.conf")) {
        [int]$version = [Convert]::ToInt32((Get-Content ".\h-manifest.conf" | `
                    ConvertFrom-StringData).CUSTOM_VERSION.replace(".", ""));
    }
    else {
        log "Warning: h-manifest.conf missing" -Foreground Red;
        return;
    }

    foreach ($Folder in $Folders) {
        $manifest = [IO.File]::Exists(([IO.Path]::Join($Folder, "h-manifest.conf")));
        $IsGit = [IO.Directory]::Exists(([IO.Path]::Join($Folder, ".git")));
        $IsCurrent = $Folder -eq $(vars).dir;

        if ($IsGit -and !$IsCurrent -and $manifest) {
            log "found previous version that was a git repository..Not updating it" -Foreground Yellow;
        }
        if (!$IsGit -and $Manifest -and !$IsCurrent) {
            $PreviousVersions += $Folder
        }
    }

    if ($PreviousVersions.Count -eq 0) {
        log "No valid SWARM versions to update" -Foreground Yellow;
        return;
    }

    $Global:amd = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json
    $Global:nvidia = Get-Content ".\config\update\nvidia-linux.json" | ConvertFrom-Json
    $Global:cpu = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json

    if ($global:IsWindows) {
        $Global:amd = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json
        $Global:nvidia = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json
        $Global:cpu = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json
    }

    $PreviousVersions | ForEach-Object {
        $Path = $_
        $Name = [IO.Path]::GetFileName($Path);
        log "Detected Another SWARM version: $Name" -Foreground Yellow
        $ThisVersion = (Get-Content ([IO.Path]::Join($Path,"h-manifest.conf")) | ConvertFrom-StringData).CUSTOM_VERSION;
        log "Previous Version is $ThisVersion" -Foreground Yellow
        $ThisVersion = [Convert]::ToInt32($ThisVersion.Replace(".",""));
        $Jsons = @("asic", "miners", "oc", "pools", "power", "wallets")
        if ($ThisVersion -gt $Version) { 
            $Jsons = @("asic", "oc", "power", "wallets")
            log "Version deteced is a new version than current" -ForeGroundColor Yellow
            log "Transferring old settings, but cannot transfer config\miners and config\pools folder data!" -ForeGroundColor Yellow
        }
        else {
            log "Gathering Old Version Config And HashRates- Then Deleting"
        }

        Start-Sleep -S 10  ## Gives User a chance to stop

        $ID = ".\build\pid\background_pid.txt"
        if ($global:IsWindows) {
            log "Stopping Previous Agent"
            if (Test-Path $ID) { $Agent = Get-Content $ID }
            if ($Agent) { $BackGroundID = Get-Process | Where-Object id -eq $Agent }
            if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
        }

        $OldBackup = Join-Path $Path "backup";
        $OldBin = Join-Path $Path "bin";
        $OldStats = Join-Path $Path "stats";
        $OldTime = Join-Path $Path "build\data";
        $OldConfig = Join-Path $Path "config";
        $OldTimeout = Join-Path $Path "timeout";
        $OldAdmin = Join-Path $Path "admin";

        if (-not (Test-Path "backup")) { New-Item "backup" -ItemType "directory" | Out-Null }
        if (-not (Test-Path "stats")) { New-Item "stats" -ItemType "directory" | Out-Null }
        if (Test-Path $OldBin) { 
            try {
                Move-Item $OldBin -Destination "$($(vars).dir)" -Force | Out-Null 
            }
            catch {
                $Message = 
                "
SWARM attempted to move old bin folder but
there was a background process from a miner still active.
Access Denied Error prevented.
"                            
                log $Message -foreground Yellow
            }
        }
        if (test-path $OldStats) {
            Get-ChildItem -Path "$($OldStats)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\stats"
        }
        if (test-path $OldBackup) {
            Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\backup"
        }
        if (Test-Path $OldAdmin) {
            if (-not (Test-Path ".\admin")) { New-Item ".\admin" -ItemType "directory" | Out-Null }
            Get-ChildItem -Path "$($OldAdmin)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\admin"
        }
        if (Test-Path $OldTime) { Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\build\data" }
        if (Test-Path $OldTimeout) {
            if (-not (Test-Path ".\timeout")) { New-Item "timeout" -ItemType "directory" | Out-Null }
            if (-not (Test-Path ".\timeout\algo_block")) { New-Item ".\timeout\algo_block" -ItemType "directory" | Out-Null }
            if (-not (Test-Path ".\timeout\pool_block")) { New-Item ".\timeout\pool_block" -ItemType "directory" | Out-Null }
            if (Test-Path "$OldTimeout\algo_block") { Get-ChildItem -Path "$($OldTimeout)\algo_block" -Include *.txt, *.conf -Recurse | Copy-Item -Destination ".\timeout\algo_block" }
            if (Test-Path "$OldTimeout\algo_block") { Get-ChildItem -Path "$($OldTimeout)\pool_block" -Include *.txt, *.conf -Recurse | Copy-Item -Destination ".\timeout\pool_block" }
            Get-ChildItem -Path "$($OldTimeout)\*" -Include *.txt | Copy-Item -Destination ".\timeout"
        }

        $UpdateType = @("CPU", "AMD1", "NVIDIA1", "NVIDIA2", "NVIDIA3")

        $Jsons | ForEach-Object {
            $OldJson_Path = Join-Path $OldConfig "$($_)";
            $NewJson_Path = Join-Path ".\config" "$($_)";
            $GetOld_Json = (Get-ChildItem $OldJson_Path).Name | Where-Object { $_ -notlike "*md*" };
            $GetOld_Json | ForEach-Object {
                $ChangeFile = $_
                $OldJson = Join-Path $OldJson_Path "$ChangeFile";
                $NewJson = Join-Path $NewJson_Path "$ChangeFile";
                if ($ChangeFile -notin $Exclude) {
                    $JsonData = Get-Content $OldJson;
                    log "Pulled $OldJson"

                    try { $Data = $JsonData | ConvertFrom-Json -ErrorAction Stop } catch { }

                    if ($ChangeFile -eq "lolminer.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "equihash_125/4" "equihash_125/4" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "equihash_125/4" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "beamv2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "beamv2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "beamv2" "beamv2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "beamv2" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckaroom" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckaroom" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckaroom" "cuckaroom" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckaroom" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckatoo32" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckatoo32" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckatoo32" "cuckatoo32" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckatoo32" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "beamhashv3" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "beamhashv3" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "beamhashv3" "beamhashv3" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "beamhashv3" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                            }
                        }
                    }

                    if ($ChangeFile -eq "xmrig-amd.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                        
                                $Data.$_.commands | Add-Member "randomx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "randomx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "randomx" "rx/0" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "randomx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-saber" "cn-heavy/tube" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-saber" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-haven" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-haven" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-haven" "cn-heavy/xhv" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "cryptonight-haven" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-heavyx" "cn/double" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "cryptonight-heavyx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-fast" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-fast" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-fast" "cn/half" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-fast" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "random-arq" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "random-arq" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "random-arq" "rx/arq" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "random-arq" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "random-sfx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "random-sfx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "random-sfx" "rx/sfx" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "random-sfx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                            }
                        }
                    }

                    if ($ChangeFile -eq "xmrig-cpu.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {

                                $Data.$_.prestart = @();

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "randomv", "randomsfx"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "randomv", "randomsfx"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "randomv", "randomsfx"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "randomv", "randomsfx"

                                $Data.$_.commands | Add-Member "randomx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "randomx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "randomx" "rx/0" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "randomx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-saber" "cn-heavy/tube" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-saber" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-haven" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-haven" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-haven" "cn-heavy/xhv" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "cryptonight-haven" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-heavyx" "cn/double" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "cryptonight-heavyx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-fast" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-fast" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-fast" "cn/half" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-fast" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "random-arq" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "random-arq" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "random-arq" "rx/arq" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "random-arq" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "random-sfx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "random-sfx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "random-sfx" "rx/sfx" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "random-sfx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "chukwa" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "chukwa" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "chukwa" "chukwa" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "chukwa" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                            }
                        }
                    }

                    if ($ChangeFile -eq "nanominer.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "randomx"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "randomx"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "randomx"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "randomx"
                            }
                        }
                    }

                    if ($ChangeFile -eq "xmrigcc-cpu.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "chukwa" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "chukwa" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "chukwa" "argon2/chukwa" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "chukwa" 1 -ErrorAction SilentlyContinue
                            }
                        }
                    }

                    if ($ChangeFile -eq "xmrig-nv.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "randomv", "randomsfx", cryptonight_gpu
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "randomv", "randomsfx", cryptonight_gpu
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "randomv", "randomsfx", cryptonight_gpu
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "randomv", "randomsfx", cryptonight_gpu

                                $Data.$_.commands | Add-Member "randomx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "randomx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "randomx" "rx/0" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "randomx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-saber" "cn-heavy/tube" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-saber" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-haven" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-haven" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-haven" "cn-heavy/xhv" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "cryptonight-haven" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-heavyx" "cn/double" -ErrorAction SilentlyContinue -Force
                                $Data.$_.fee | Add-Member "cryptonight-heavyx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-fast" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-fast" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-fast" "cn/half" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-fast" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "random-arq" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "random-arq" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "random-arq" "rx/arq" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "random-arq" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "random-sfx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "random-sfx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "random-sfx" "rx/sfx" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "random-sfx" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "randomv", "randomsfx", "cryptonight_gpu", "cryptonight_xeq"
                            }
                        }
                    }

                    if ($ChangeFile -eq "rplant.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "yespoweritc" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "yespoweritc" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "yespoweritc" "yespoweritc" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "yespoweritc" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "power2b" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "power2b" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "power2b" "power2b" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "power2b" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "yespoweriots" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "yespoweriots" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "yespoweriots" "yespoweriots" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "yespoweriots" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "yespoweric" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "yespoweric" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "yespoweric" "yespoweric" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "yespoweric" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "sha256csm" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "sha256csm" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "sha256csm" "sha256csm" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "sha256csm" 0 -ErrorAction SilentlyContinue
                            }
                        }
                    }

                    if ($ChangeFile -eq "xmr-stak.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "cryptonight-gpu" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-gpu" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-gpu" "cryptonight_gpu" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-gpu" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-heavyx" "cryptonight_heavyx" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-heavyx" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-saber" "cryptonight_bittube2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-saber" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-v7" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-v7" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-v7" "cryptonight_v7" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-v7" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-conceal" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-conceal" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-conceal" "cryptonight_conceal" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-conceal" 2 -ErrorAction SilentlyContinue

                            }
                        }
                    }

                    if ($ChangeFile -eq "nbminer.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "eaglesong" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "eaglesong" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "eaglesong" "eaglesong" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "eaglesong" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "handshake" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "handshake" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "handshake" "hns" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "handshake" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckatoo32" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckatoo32" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckatoo32" "cuckatoo32" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckatoo32" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                            }
                        }
                    }

                    if ($ChangeFile -eq "nbminer-amd.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "handshake" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "handshake" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "handshake" "hns" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "handshake" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 2 -ErrorAction SilentlyContinue
                            }
                        }
                    }

                    if ($ChangeFile -eq "cryptodredge.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x16rv2" "x16rv2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x16rv2" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-gpu" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-gpu" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-gpu" "cngpu" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-gpu" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-xeq" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-xeq" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-xeq" "cngpu" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-xeq" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-saber" "cnsaber" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-saber" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-conceal" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-conceal" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-conceal" "cnconceal" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-conceal" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-upx2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-upx2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-upx2" "CryptoNightUPX" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-upx2" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "chukwa" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "chukwa" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "chukwa" "argon2-512" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "chukwa" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                            }
                        }
                    }

                                
                    if ($ChangeFile -eq "z-enemy.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x16rv2" "x16rv2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x16rv2" 1 -ErrorAction SilentlyContinue
                            }
                        }
                    }

                    if ($ChangeFile -eq "bminer.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "cuckaroom" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckaroom" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckaroom" "cuckaroom" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckaroom" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "raven" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "beamv2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "beamv2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "beamv2" "beamv2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "beamv2" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "beamhashv3" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "beamhashv3" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "beamhashv3" "beamhashv3" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "beamhashv3" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckarooz29" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckarooz29" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckarooz29" "cuckarooz29" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckarooz29" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                            }
                        }
                    }

                    if ($ChangeFile -eq "nv-lolminer.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "equihash_125/4" "equihash_125/4" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "equihash_125/4" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckaroom" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckaroom" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckaroom" "cuckaroom" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckaroom" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                            }
                        }
                    }

                    if ($ChangeFile -eq "wildrig.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {

                                $Data.$_.commands | Add-Member "x17r" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x17r" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x17r" "x17r" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x17r" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "x25x" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x25x" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x25x" "x25x" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x25x" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x16rv2" "x16rv2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x16rv2" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "anime" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "anime" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "anime" "anime" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "anime" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "skein2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "skein2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "skein2" "skein2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "skein2" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "mtp" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "mtp" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "mtp" "mtp" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "mtp" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "mtp-tcr" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "mtp-tcr" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "mtp-tcr" "mtp-tcr" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "mtp-tcr" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "lyra2rev2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "lyra2rev2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "lyra2rev2" "lyra2v2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "lyra2rev2" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 1 -ErrorAction SilentlyContinue

                            }
                        }
                    }

                    if ($ChangeFile -eq "miniz.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
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

                                $Data.$_.commands | Add-Member "beamhashv3" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "beamhashv3" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "beamhashv3" "beamhashv3" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "beamhashv3" 2 -ErrorAction SilentlyContinue

                            }
                        }
                    }

                    if ($ChangeFile -eq "fancyix.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                            
                                $Data.$_.commands | Add-Member "x25x" "--gpu-threads 4 --worksize 256 --intensity 22" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x25x" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x25x" "x25x" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x25x" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands.x22i = "--gpu-threads 2 --worksize 256 --intensity 23"
                                $Data.$_.commands.phi2 = "--gpu-threads 1 --worksize 256 --intensity 23"
                                $Data.$_.commands.'phi2-lux' = "--gpu-threads 1 --worksize 256 --intensity 23"
                                $Data.$_.commands.allium = "--gpu-threads 1 --worksize 256 --intensity 20"
                                $Data.$_.commands.lyra2rev3 = "--gpu-threads 1 --worksize 256 --intensity 24"
                                $Data.$_.commands.argon2d500 = "--worksize 64 -g 2"
                                $Data.$_.commands.mtp = "--intensity 18"
                                $Data.$_.commands.x25x = "--gpu-threads 4 --worksize 256 --intensity 22"
                            }
                        }
                    }

                    if ($ChangeFile -eq "gminer-amd.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "equihash_96/5" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "equihash_96/5" "equihash_96/5" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "equihash_96/5" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "equihash_125/4" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "equihash_125/4" "equihash_125/4" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "equihash_125/4" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "beamv2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "beamv2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "beamv2" "beamv2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "beamv2" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckaroo29-bfc" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckaroo29-bfc" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckaroo29-bfc" "cuckaroo29-bfc" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckaroo29-bfc" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "equihash_150/5", "cuckaroo29d", "cuckaroo29"
                            }
                        }
                    }

                    if ($ChangeFile -eq "gminer.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckatoo31" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckatoo31" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckatoo31" "cuckatoo31" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckatoo31" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckatoo32" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckatoo32" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckatoo32" "cuckatoo32" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckatoo32" 2 -ErrorAction SilentlyContinue

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

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "equihash_150/5"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "equihash_150/5"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "equihash_150/5"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "equihash_150/5"

                                $Data.$_.commands | Add-Member "eaglesong" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "eaglesong" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "eaglesong" "eaglesong" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "eaglesong" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "ethash" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "ethash" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "ethash" "ethash" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "ethash" 0.65 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckaroom" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckaroom" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckaroom" "cuckaroom" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckaroom" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckaroo29-bfc" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckaroo29-bfc" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckaroo29-bfc" "cuckaroo29-bfc" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckaroo29-bfc" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "beamhashv3" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "beamhashv3" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "beamhashv3" "beamhashv3" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "beamhashv3" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckarooz29" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckarooz29" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckarooz29" "cuckarooz29" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckarooz29" 2 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                                
                            }
                        }
                    }
                    if ($ChangeFile -eq "teamredminer.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "x16r" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x16r" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x16r" "x16r" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x16r" 2.5 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x16rv2" "x16rv2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x16rv2" 2.5 -ErrorAction SilentlyContinue

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

                                $Data.$_.commands | Add-Member "phi2-lux" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "phi2-lux" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "phi2-lux" "phi2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "phi2-lux" 3 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "ethash" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "ethash" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "ethash" "ethash" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "ethash" 2.5 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-heavyx" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-heavyx" "cnv8_dbl" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-heavyx" 2.5 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-saber" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-saber" "cn_saber" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-saber" 2.5 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cryptonight-upx2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cryptonight-upx2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cryptonight-upx2" "cn_saber" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cryptonight-upx2" 2.5 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "chukwa" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "chukwa" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "chukwa" "trtl_chukwa" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "chukwa" 2.5 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 2.5 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "cuckarood29" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "cuckarood29" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "cuckarood29" "cuckarood29" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "cuckarood29" 2.5 -ErrorAction SilentlyContinue

                                $Data.$_.commands = $Data.$_.commands | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.difficulty = $Data.$_.difficulty | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.naming = $Data.$_.naming | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                                $Data.$_.fee = $Data.$_.fee | Select-Object -ExcludeProperty "cuckaroo29d", "cuckaroo29"
                            }
                        }
                    }

                    if ($ChangeFile -eq "t-rex.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "kawpow" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "x25x" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x25x" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x25x" "x25x" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x25x" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "honeycomb" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "honeycomb" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "honeycomb" "honeycomb" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "honeycomb" 1 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x16rv2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x16rv2" "x16rv2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x16rv2" 1 -ErrorAction SilentlyContinue
                            }
                        }
                    }

                    if ($ChangeFile -eq "sugarchain.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "lyra2z330" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "lyra2z330" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "lyra2z330" "lyra2z330" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "lyra2z330" 0 -ErrorAction SilentlyContinue
                            }
                        }
                    }

                    if ($ChangeFile -eq "swarm-miner.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "x12" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "x12" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "x12" "x12" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "x12" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "lyra2rev2" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "lyra2rev2" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "lyra2rev2" "lyra2v2" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "lyra2rev2" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "lyra2rev3" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "lyra2rev3" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "lyra2rev3" "lyra2v3" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "lyra2rev2" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "keccakc" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "keccakc" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "keccakc" "keccakc" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "keccakc" 0 -ErrorAction SilentlyContinue
                            }
                        }
                    }

                    if ($ChangeFile -eq "jayddee.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "power2b" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "power2b" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "power2b" "power2b" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "power2b" 0 -ErrorAction SilentlyContinue
                            }
                        }
                    }
                                
                    if ($ChangeFile -eq "tt-miner.json") {
                        $Data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            if ($_ -ne "name") {
                                $Data.$_.commands | Add-Member "eaglesong" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "eaglesong" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "eaglesong" "EAGLESONG" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "eaglesong" 0 -ErrorAction SilentlyContinue

                                $Data.$_.commands | Add-Member "kawpow" "" -ErrorAction SilentlyContinue
                                $Data.$_.difficulty | Add-Member "kawpow" "" -ErrorAction SilentlyContinue 
                                $Data.$_.naming | Add-Member "kawpow" "KAWPOW" -ErrorAction SilentlyContinue
                                $Data.$_.fee | Add-Member "kawpow" 0 -ErrorAction SilentlyContinue
                            }
                        }
                    }
 
                    if ($ChangeFile -eq "pool-algos.json") {
                        $Data | add-Member "x25x" @{alt_names = @("x25x"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "x16rv2" @{alt_names = @("x16rv2"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "lyra2z330" @{alt_names = @("lyra2z330"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cuckaroo29d" @{alt_names = @("cuckaroo29d", "grincuckaroo29d"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "bmw512" @{alt_names = @("bmw512"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "x14" @{alt_names = @("x14"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cpupower" @{alt_names = @("cpupower"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "equihash_125/4" @{alt_names = @("zelcash", "equihash_125/4", "equihash125"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "equihash_150/5" @{alt_names = @("equihash_150/5", "equihash150", "beam"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue                                   
                        $Data | add-Member "argon2d500" @{alt_names = @("argon2d500"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue         
                        $Data | add-Member "argon2d-dyn" @{alt_names = @("argon2d-dyn"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue                                                             
                        $Data | add-Member "beamv2" @{alt_names = @("beamv2"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue           
                        $Data | add-Member "x12" @{alt_names = @("x12"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "power2b" @{alt_names = @("power2b"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue                                                                                                                                                                                                                             
                        $Data | add-Member "yescryptr8g" @{alt_names = @("yescryptr8g"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue                                                                                                                                                                                                                             
                        $Data | add-Member "phi2-lux" @{alt_names = @("phi2-lux"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue                                                                                                                                                                                                                             
                        $Data | add-Member "tribus" @{alt_names = @("tribus"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "keccakc" @{alt_names = @("keccakc"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue                                                                                                                                                                                                                                                                                                                                                                                                                                                          
                        $Data | add-Member "lyra2v2" @{alt_names = @("lyra2v2"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cryptonight-heavyx" @{alt_names = @("cryptonight-heavyx", "cryptonightheavyx", "cryptonight_heavyx"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cryptonight-haven" @{alt_names = @("cryptonight-haven", "cryptonighthaven", "cryptonight_haven"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cryptonight-saber" @{alt_names = @("cryptonight-saber", "cryptonightsaber", "cryptonight_saber"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cryptonight-gpu" @{alt_names = @("cryptonight-gpu", "cryptonightgpu", "cryptonight_gpu"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cryptonight-fast" @{alt_names = @("cryptonight-fast", "cryptonightfast", "cryptonight_fast"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cryptonight-xeq" @{alt_names = @("cryptonight-xeq", "cryptonightxeq", "cryptonight_xeq"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cryptonight-conceal" @{alt_names = @("cryptonight-conceal", "cryptonightconceal", "cryptonight_conceal"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cryptonight-upx2" @{alt_names = @("cryptonight-upx2", "cryptonightupx2", "cryptonight_upx2", "cryptonight-upx", "cryptonightupx", "cryptonight_upx"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "randomsfx" @{alt_names = @("random-sfx", "randomsfx", "random_sfx"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "randomv" @{alt_names = @("random-v", "randomv", "random_v"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "randomx" @{alt_names = @("random-x", "randomx", "random_x"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "yespoweritc" @{alt_names = @("yespoweritc"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "yespoweriots" @{alt_names = @("yespoweriots"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "yespoweric" @{alt_names = @("yespoweric"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "sha256csm" @{alt_names = @("sha256csm"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "eaglesong" @{alt_names = @("eaglesong"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cuckaroom" @{alt_names = @("cuckaroom"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "sha3d" @{alt_names = @("sha3d"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "cuckatoo32" @{alt_names = @("cuckatoo32", "grincuckatoo32"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "scryptn2" @{alt_names = @("scryptn2"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue
                        $Data | add-Member "kawpow" @{alt_names = @("kawpow", "kapow", "kaapow"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue -Force
                        $Data | add-Member "kangaroo12" @{alt_names = @("kangaroo12", "k12"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue -Force
                        $Data | add-Member "beamhashv3" @{alt_names = @("beamhashv3", "beamv3"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue -Force
                        $Data | add-Member "cuckaroo29-bfc" @{alt_names = @("cuckaroo29-bfc", "cuckaroo29bfc"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue -Force
                        $Data | add-Member "cuckarooz29" @{alt_names = @("cuckarooz29"); exclusions = @("add pool or miner here", "comma seperated") } -ErrorAction SilentlyContinue -Force
                    }

                    $Data | ConvertTo-Json -Depth 10 | Set-Content $NewJson;
                    log "Wrote To $NewJson"
                }
            }
        }

        $NameJson_Path = Join-Path ".\config" "miners";
        $GetOld_Json = Get-ChildItem $NameJson_Path | Where-Object Extension -ne ".md"
        $GetOld_Json = $GetOld_Json.Name
        $GetOld_Json | ForEach-Object {
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
                $MinerPath1 = Join-Path $Path ( Split-Path $($Global:amd.$_.AMD1 -replace "\.", ""))
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
                $MinerPath1 = Join-Path $Path ( Split-Path $($Global:cpu.$_.CPU -replace "\.", ""))
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
                $MinerPath1 = Join-Path $Path ( Split-Path $($Global:nvidia.$_.NVIDIA1 -replace "\.", ""))
                $NewMinerPath1 = Join-Path $($(vars).dir) ( Split-Path $($Global:nvidia.$_.NVIDIA1 -replace "\.", ""))
                $MinerPath2 = Join-Path $Path ( Split-Path $($Global:nvidia.$_.NVIDIA2 -replace "\.", ""))
                $NewMinerPath2 = Join-Path $($(vars).dir) ( Split-Path $($Global:nvidia.$_.NVIDIA2 -replace "\.", ""))
                $MinerPath3 = Join-Path $Path ( Split-Path $($Global:nvidia.$_.NVIDIA3 -replace "\.", ""))
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

        Remove-Item $Path -recurse -force
    }
}

function Global:Start-AgentCheck {
    log "Stopping Previous Agent"
    $ID = ".\build\pid\background_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process | Where-Object id -eq $Agent }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    $ID = ".\build\pid\pill_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process | Where-Object id -eq $Agent }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }    
}

