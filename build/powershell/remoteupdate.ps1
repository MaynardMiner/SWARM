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
        [Parameter(Mandatory = $true)]
        [String]$Update,
        [Parameter(Mandatory = $true)]
        [String]$Dir,
        [Parameter(Mandatory = $true)]
        [String]$Platforms
    )

    $Location = split-Path $Dir
    $StartUpdate = $True
    if ($Platforms -eq "linux" -and $Update -eq "No") {$StartUpdate = $false}

    if ($StartUpdate -eq $true) {
        #$PreviousVersions = @()
        $PreviousVersions += "SWARM.2.1.8"

        Write-Host "User Specfied Updates: Searching For Previous Version" -ForegroundColor Yellow
        Write-Host "Check $Location For any Previous Versions"

        $PreviousVersions | foreach {
            $PreviousPath = Join-Path "$Location" "$_"
            if (Test-Path $PreviousPath) {
                Write-Host "Detected Previous Version"
                Write-Host "Previous Version is $($PreviousPath)"
                Write-Host "Gathering Old Version Config And HashRates- Then Deleting"
                Start-Sleep -S 10
                $ID = ".\build\pid\background_pid.txt"
                if ($Platforms -eq "windows") {Start-Sleep -S 10}
                if ($Platforms -eq "windows") {
                    Write-Host "Stopping Previous Agent"
                    if (Test-Path $ID) {$Agent = Get-Content $ID}
                    if ($Agent) {$BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue}
                    if ($BackGroundID.name -eq "powershell") {Stop-Process $BackGroundID | Out-Null}
                }
                $OldBackup = Join-Path $PreviousPath "backup"
                $OldStats = Join-Path $PreviousPath "stats"
                $OldTime = Join-Path $PreviousPath "build\data"
                $OldConfig = Join-Path $PreviousPath "config"
                $OldTimeout = Join-Path $PreviousPath "timeout"
                if (-not (Test-Path "backup")) {New-Item "backup" -ItemType "directory"  | Out-Null }
                if (-not (Test-Path "stats")) {New-Item "stats" -ItemType "directory"  | Out-Null }
                if (Test-Path $OldBackup) {
                    Get-ChildItem -Path "$($OldStats)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\stats"
                    Get-ChildItem -Path "$($OldBackup)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\backup"
                }
                #if(Test-Path $OldTime){Get-ChildItem -Path "$($OldTime)\*" -Include *.txt -Recurse | Copy-Item -Destination ".\build\data"}
                if (Test-Path $OldTimeout) {
                    if (-not (Test-Path ".\timeout")) {New-Item "timeout" -ItemType "directory" | Out-Null }
                    if (-not (Test-Path ".\timeout\algo_block")) {New-Item ".\timeout\algo_block" -ItemType "directory" | Out-Null }
                    if (-not (Test-Path ".\timeout\pool_block")) {New-Item ".\timeout\pool_block" -ItemType "directory" | Out-Null }
                    if (Test-Path "$OldTimeout\algo_block") {Get-ChildItem -Path "$($OldTimeout)\algo_block" -Include *.txt, *.conf -Recurse | Copy-Item -Destination ".\timeout\algo_block"}
                    if (Test-Path "$OldTimeout\algo_block") {Get-ChildItem -Path "$($OldTimeout)\pool_block" -Include *.txt, *.conf -Recurse | Copy-Item -Destination ".\timeout\pool_block"}
                    Get-ChildItem -Path "$($OldTimeout)\*" -Include *.txt | Copy-Item -Destination ".\timeout"
                }
                $Jsons = @("miners", "oc", "power", "pools", "asic", "wallets")
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
                        if ($ChangeFile -ne "new_sample.json" -and $ChangeFile -ne "sgminer-kl.json" -and $ChangeFile -ne "vega-oc.json") {
                            $JsonData = Get-Content $OldJson;
                            Write-Host "Pulled $OldJson"
                            $Data = $JsonData | ConvertFrom-Json;

                            #if ($ChangeFile -eq "pool-algos.json") {
                             # $Data | Add-Member "yespowerr16" @{"hiveos_name" = "yespowerr16"; "pools_to_exclude" = @("add pools here","comma seperated"); "miners_to_exclude" = @("add miners here","comma seperate")} -ErrorAction SilentlyContinue
                              #$Data | Add-Member "yespowerr8" @{"hiveos_name" = "yespowerr8"; "pools_to_exclude" = @("add pools here","comma seperated"); "miners_to_exclude" = @("add miners here","comma seperate")} -ErrorAction SilentlyContinue
                            #}

                            #if ($ChangeFile -eq "cryptodredge.json") {
                             #   $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    ##2.1.3
                              #      if ($_ -ne "name") {
                               #         $Data.$_.commands| Add-Member "argon2d-dyn" "" -ErrorAction SilentlyContinue
                                #        $Data.$_.difficulty | Add-Member "argon2d-dyn" "" -ErrorAction SilentlyContinue
                                 #       $Data.$_.naming | Add-Member "argon2d-dyn" "argon2d" -ErrorAction SilentlyContinue
                                  #      $Data.$_.oc | Add-Member "argon2d-dyn" @{Power = ""; Core = ""; Memory = ""; Fans = ""} -ErrorAction SilentlyContinue

                                   #     $Data.$_.commands| Add-Member "grincuckaroo29" "" -ErrorAction SilentlyContinue
                                    #    $Data.$_.difficulty | Add-Member "grincuckaroo29" "" -ErrorAction SilentlyContinue
                                     #   $Data.$_.naming | Add-Member "grincuckaroo29" "cuckaroo29" -ErrorAction SilentlyContinue
                                      #  $Data.$_.oc | Add-Member "grincuckaroo29" @{Power = ""; Core = ""; Memory = ""; Fans = ""} -ErrorAction SilentlyContinue
                                    #}
                              #  }
                           # }

                          #  if ($ChangeFile -eq "gminer_amd.json") {
                           #     $Data | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
                                    ##2.1.3
                            #        if ($_ -ne "name") {

                             #           $Data.$_.commands| Add-Member "equihash210" "--algo 210_9 --pers auto" -ErrorAction SilentlyContinue
                              #          $Data.$_.difficulty | Add-Member "equihash210" "" -ErrorAction SilentlyContinue
                               #         $Data.$_.naming | Add-Member "equihash210" "equihash210" -ErrorAction SilentlyContinue
                                #        $Data.$_.oc | Add-Member "equihash210"  @{dpm = ""; v = ""; core = ""; mem = ""; mdpm = ""; fans = ""} -ErrorAction SilentlyContinue
                                 #   }
                              #  }
                           # }

                           # if($ChangeFile -eq "pool-algos.json") {
                            #        $Data.veil.hiveos_name = "veil"
                            #}                            

                            $Data | ConvertTo-Json -Depth 3 | Set-Content $NewJson;
                            Write-Host "Wrote To $NewJson"
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
                    Write-Host "Pulled $NameJson"
                    $Data = $JsonData | ConvertFrom-Json;
                    $Data | Add-Member "name" "$NewName" -ErrorAction SilentlyContinue
                    $Data | ConvertTo-Json -Depth 3 | Set-Content $NameJson;
                    Write-Host "Wrote To $NameJson"
                }
                Remove-Item $PreviousPath -recurse -force
            }
        }
    }
}
