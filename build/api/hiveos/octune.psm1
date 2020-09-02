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

function Global:Start-HiveTune {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Algo,
        [Parameter(Position = 1, Mandatory = $false)]
        [string]$Miner_Name,
        [Parameter(Position = 2, Mandatory = $false)]
        [string]$Miner_Pool,
        [Parameter(Position = 3, Mandatory = $false)]
        [string]$Profit_Day
    )

    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

    log "Checking Hive OC Tuning" -ForegroundColor Cyan
    $OCSheet = @()
    $Algo = $Algo -replace "`_", " "
    $Algo = $Algo -replace "veil", "x16rt"
    $Url = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/workers/$($Global:Config.hive_params.Id)"
    $CheckOC = $false
    $CheckDate = Get-Date
    $Success = $false

    ## Generate New Auth Token:
    #$Auth = @{ login = "User"; password = "pass"; twofa_code = ""; remember = $true; } | ConvertTo-Json -Compress
    #$Url = "https://api2.hiveos.farm/api/v2/auth/login"
    #$A = Invoke-RestMethod $Url -Method Post -Body $Auth -ContentType 'application/json' -TimeoutSec 10
    #Token = $A.access_token

    ## Get Current Worker:
    $T = @{Authorization = "Bearer $($(arg).API_Key)" }
    $Splat = @{ Method = "GET"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }
    try { $Worker = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { log "WARNING: Failed to Contact HiveOS for OC" -ForegroundColor Yellow; return }

    ## Patch Worker:
    if ($Algo -in $Worker.oc_config.by_algo.algo) { $Choice = $Algo; $Message = $Choice } else { $choice = $null; $Message = "Default" }
    log "Setting Hive OC to $Message Settings" -ForegroundColor Cyan
    if ($Worker.oc_algo -ne $Choice) {
        log "Contacting HiveOS To Set $Message as current OC setting" -ForegroundColor Cyan
        $T = @{Authorization = "Bearer $($(arg).API_Key)" }
        $Command = @{oc_algo = $Choice } | ConvertTo-Json
        $Splat = @{ Method = "Patch"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }
        try { $Worker_Post = Invoke-RestMethod @Splat -Body $Command -TimeoutSec 10 -ErrorAction Stop }catch { log "WARNING: Failed To Send OC to HiveOS" -ForegroundColor Yellow; return }
        if ($Worker_Post.commands.id) { log "Sent OC to HiveOS" -ForegroundColor Green; $CheckOC = $true; }
    }
    else {
        log "HiveOS Settings Already Set to $Message" -ForegroundColor Cyan
        if ($IsWindows) {
            if (test-path ".\debug\ocnvidia.txt") { $OCSheet += Get-Content ".\debug\ocnvidia.txt" }
            if (test-path ".\debug\ocamd.txt") { $OCSheet += Get-Content ".\debug\ocamd.txt" }
        }
        else {
            if (test-path "/var/log/nvidia-oc.log") { $OCSheet += Get-Content "/var/log/nvidia-oc.log" }
            if (test-path "/var/log/amd-oc.txt") { $OCSheet += Get-Content "/var/log/amd-oc.txt" }
        }
        $Success = $true
    }

    if ($CheckOC) {
        $(arg).Type | ForEach-Object {
            if ($_ -like "*NVIDIA1*") { $CheckNVIDIA = $true }
            if ($_ -like "*AMD1*") { $CheckAMD = $True }
        }
        switch ($(arg).Platform) {
            "windows" {
                if ($CheckNVIDIA) {
                    log "Verifying OC was Set...." -ForegroundColor Cyan
                    $OCT = New-Object -TypeName System.Diagnostics.Stopwatch
                    $OCT.Restart()
                    $CheckFile = ".\debug\ocnvidia.txt"
                    do {
                        $LastWrite = (Get-Item $CheckFile).LastWriteTime
                        $CheckTime = [math]::Round(($CheckDate - $LastWrite).TotalSeconds)
                        $TOtalTime = $OCT.Elapsed.TotalSeconds
                        Start-Sleep -Milliseconds 50
                    } Until ( $CheckTime -le 0 -or $TOtalTime -ge 30 )
                    $OCT.Stop()
                    if ($OCT.Elapsed.TotalSeconds -ge 30) {
                        $Success = $false
                        log "WARNING: HiveOS did not set OC." -ForegroundColor Yellow
                    }
                    else {
                        log "OC Was Changed." -ForegroundColor Cyan
                        $Success = $true
                    }
                }
                if ($CheckAMD) {
                    log "Verifying OC was Set...." -ForegroundColor Cyan
                    $OCT = New-Object -TypeName System.Diagnostics.Stopwatch
                    $OCT.Restart()
                    $CheckFile = ".\debug\ocamd.txt"
                    do {
                        $LastWrite = (Get-Item $CheckFile).LastWriteTime
                        $CheckTime = [math]::Round(($CheckDate - $LastWrite).TotalSeconds)
                        $TOtalTime = $OCT.Elapsed.TotalSeconds
                        Start-Sleep -Milliseconds 50
                    } Until ( $CheckTime -le 0 -or $TOtalTime -ge 30 )
                    $OCT.Stop()
                    if ($OCT.Elapsed.TotalSeconds -ge 30) {
                        $Success = $false
                        log "WARNING: HiveOS did not set OC." -ForegroundColor Yellow
                    }
                    else {
                        log "OC Was Changed." -ForegroundColor Cyan
                        $Success = $true
                    }
                }
            }
            "linux" {
                if ($CheckNVIDIA) {
                    log "Verifying OC was Set...." -ForegroundColor Cyan
                    $OCT = New-Object -TypeName System.Diagnostics.Stopwatch
                    $OCT.Restart()
                    $Checkfile = "/var/log/nvidia-oc.log"
                    do {
                        if (test-path $Checkfile) {
                            $LastWrite = (Get-Item $CheckFile).LastWriteTime
                            $CheckTime = [math]::Round(($CheckDate - $LastWrite).TotalSeconds)
                            $TOtalTime = $OCT.Elapsed.TotalSeconds
                        }
                        Start-Sleep -Milliseconds 50
                    } Until ( $CheckTime -le 0 -or $TOtalTime -ge 30 )
                    if ($OCT.Elapsed.TotalSeconds -ge 30) {
                        $Success = $false
                        log "WARNING: HiveOS did not set OC." -ForegroundColor Yellow
                    }
                    else {
                        log "OC Was Changed." -ForegroundColor Cyan
                        $Success = $true
                    }
                }
                if ($CheckAMD) {
                    log "Verifying OC was Set...." -ForegroundColor Cyan
                    $OCT = New-Object -TypeName System.Diagnostics.Stopwatch
                    $OCT.Restart()
                    $Checkfile = "/var/log/amd-oc.log"
                    do {
                        if (test-path $Checkfile) {
                            $LastWrite = (Get-Item $CheckFile).LastWriteTime
                            $CheckTime = [math]::Round(($CheckDate - $LastWrite).TotalSeconds)
                            $TOtalTime = $OCT.Elapsed.TotalSeconds
                            Start-Sleep -Milliseconds 50
                        }
                    } Until ( $CheckTime -le 0 -or $TOtalTime -ge 30 )
                    $OCT.Stop()
                    if ($OCT.Elapsed.TotalSeconds -ge 30) {
                        $Success = $false
                        log "WARNING: HiveOS did not set OC." -ForegroundColor Yellow
                    }
                    else {
                        log "OC Was Changed." -ForegroundColor Cyan
                        $Success = $true
                    }
                }
            }
        }
    }
    
    if ($Success) {
        if (test-path ".\debug\ocamd.txt") { $OCSheet += Get-Content ".\debug\ocnvidia.txt" }
        if (test-path ".\debug\ocamd.txt") { $OCSheet += Get-Content ".\debug\ocnvidia.txt" }
        if (test-path "/var/log/nvidia-oc.log") { $OCSheet += Get-Content "/var/log/nvidia-oc.log" }
        if (test-path "/var/log/amd-oc.log") { $OCSheet += Get-Content "/var/log/amd-oc.log" }
    }

    if ($Miner_Name) {
        $miner_tagid = $null
        $pool_tagid = $null
        $T = @{Authorization = "Bearer $($(arg).API_Key)" }
        $Url = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags";
        $Splat = @{ Method = "GET"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }    
        try { $Tags = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { log "WARNING: Failed to Get Tags From HiveOS" -ForegroundColor Yellow; return }

        ## Delete old profit tag
        $Old_Profit_Tag = ($Tags.data | Where name -like "*$($Global:Config.hive_params.Worker) Profit:*").id
        if ($Old_Profit_Tag) {
            $T = @{Authorization = "Bearer $($(arg).API_Key)" }
            $Url = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags/$Old_Profit_Tag";
            $Splat = @{ Method = "Delete"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }    
            try { $Set_Tag = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { log "WARNING: Failed to Delete Profit Tag From HiveOS" -ForegroundColor Yellow; return }    
        }
        ## Create new profit tag
        $Profit_Tag = "$($Global:Config.hive_params.Worker) Profit: BENCHMARKING"
        if($Profit_Day -ne "bench") {
            $Profit_Day = [math]::Round($Profit_Day,6)
            $Profit_Tag = "$($Global:Config.hive_params.Worker) Profit: $Profit_Day BTC\Day"
        }
        $Tag = @{
            name  = $Profit_Tag;
            color = 11;
        } | ConvertTo-Json -Compress;
        $T = @{Authorization = "Bearer $($(arg).API_Key)" }
        $Url = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags";
        $Splat = @{ Body = $tag; Method = "Post"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }    
        try { $Set_Tag = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { log "WARNING: Failed To Update Profit Tag From HiveOS" -ForegroundColor Yellow; return }    
        $new_profit_tag = $Set_Tag.id;

        ## Create the tag if it does not exist
        if ($Miner_Name -notin $Tags.data.name) {            
            $Tag = @{
                name  = $Miner_Name;
                color = 17;
            } | ConvertTo-Json -Compress;
            $T = @{Authorization = "Bearer $($(arg).API_Key)" }
            $Url = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags";
            $Splat = @{ Body = $tag; Method = "Post"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }    
            try { $Set_Tag = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { log "WARNING: Failed To Set Miner Tag From HiveOS" -ForegroundColor Yellow; return }    
            $miner_tagid = $Set_Tag.id
        }
        if ($Miner_Pool -notin $Tags.data.name) {
            $Tag = @{
                name  = $Miner_Pool;
                color = 8;
            } | ConvertTo-Json -Compress;
            $T = @{Authorization = "Bearer $($(arg).API_Key)" }
            $Url = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags";
            $Splat = @{ Body = $tag; Method = "Post"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }    
            try { $Set_Tag = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { log "WARNING: Failed to Set Pool Tag From HiveOS" -ForegroundColor Yellow; return }    
            $pool_tagid = $Set_Tag.id
        }

        $tag_list = @()
        $tag_list += (Get-ChildItem "miners\gpu\amd" | Where-Object name -like "*ps1*").BaseName
        $tag_list += (Get-ChildItem "miners\gpu\nvidia" | Where-Object name -like "*ps1*").BaseName
        $tag_list += (Get-ChildItem "miners\optional_and_old" | Where-Object name -like "*ps1*").BaseName
        $tag_list += (Get-ChildItem "pools\pplns" | Where-Object name -like "*ps1*").BaseName
        $tag_list += (Get-ChildItem "pools\pps" | Where-Object name -like "*ps1*").BaseName
        $tag_list += (Get-ChildItem "pools\prop" | Where-Object name -like "*ps1*").BaseName
        $set_tags = $Tags.data | Where-Object { $_.name -in $tag_list }
        $worker_tagids = @();
        foreach ($worker_tag in $Worker.tag_ids) {
            if ($worker_tag -notin $set_tags.id -and $worker_tag -ne $Old_Profit_Tag) {
                $worker_tagids += $worker_tag;
            }
        }
        if (!$miner_tagid) {
            $miner_tagid = ($Tags.data | Where-Object { $_.name -eq $Miner_Name }).id
        }
        if (!$pool_tagid) {
            $pool_tagid = ($Tags.data | Where-Object { $_.name -eq $Miner_Pool }).id
        }
        $worker_tagids += $miner_tagid;
        $worker_tagids += $pool_tagid;
        $worker_tagids += $new_profit_tag;
        $Command = @{tag_ids = $worker_tagids } | ConvertTo-Json
        $Url = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/workers/$($Global:Config.hive_params.Id)"
        $T = @{Authorization = "Bearer $($(arg).API_Key)" }
        $Splat = @{ Body = $Command; Method = "Patch"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }
        try { $Worker_Post = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop }catch { log "WARNING: Failed To update miner name" -ForegroundColor Yellow; return }
    }

    $OCSheet | Add-Content -Path ".\debug\oc-settings.txt"
    $Success
}