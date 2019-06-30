
function Global:Start-HiveTune {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Algo
    )

    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

    Global:Write-Log "Checking Hive OC Tuning" -ForegroundColor Cyan
    $OCSheet = @()
    $Algo = $Algo -replace "`_", " "
    $Algo = $Algo -replace "veil","x16rt"
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
    try { $A = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { Global:Write-Log "WARNING: Failed to Contact HiveOS for OC" -ForegroundColor Yellow; return }

    ## Patch Worker:
    if ($Algo -in $A.oc_config.by_algo.algo) { $Choice = $Algo; $Message = $Choice} else { $choice = $null; $Message = "Default" }
        Global:Write-Log "Setting Hive OC to $Message Settings" -ForegroundColor Cyan
    if ($A.oc_algo -ne $Choice) {
        Global:Write-Log "Contacting HiveOS To Set $Message as current OC setting" -ForegroundColor Cyan
        $T = @{Authorization = "Bearer $($(arg).API_Key)" }
        $Command = @{oc_algo = $Choice } | ConvertTo-Json
        $Splat = @{ Method = "Patch"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }
        try { $A = Invoke-RestMethod @Splat -Body $Command -TimeoutSec 10 -ErrorAction Stop }catch { Global:Write-Log "WARNING: Failed To Send OC to HiveOS" -ForegroundColor Yellow; return }
        if ($A.commands.id) { Global:Write-Log "Sent OC to HiveOS" -ForegroundColor Green; $CheckOC = $true; }
    } else {
        Global:Write-Log "HiveOS Settings Already Set to $Message" -ForegroundColor Cyan
        if($IsWindows) {
        if(test-path ".\build\txt\ocnvidia.txt"){ $OCSheet += Get-Content ".\build\txt\ocnvidia.txt" }
        if(test-path ".\build\txt\ocamd.txt"){ $OCSheet += Get-Content ".\build\txt\ocamd.txt" }
        } else {
        if(test-path "/var/log/nvidia-oc.log"){ $OCSheet += Get-Content "/var/log/nvidia-oc.log" }
        if(test-path "/var/log/amd-oc.txt"){ $OCSheet += Get-Content "/var/log/amd-oc.txt" }
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
                    Global:Write-Log "Verifying OC was Set...." -ForegroundColor Cyan
                    $OCT = New-Object -TypeName System.Diagnostics.Stopwatch
                    $OCT.Restart()
                    $CheckFile = ".\build\txt\ocnvidia.txt"
                    do {
                        $LastWrite = Get-Item $CheckFile | Foreach { $_.LastWriteTime }
                        $CheckTime = [math]::Round(($CheckDate - $LastWrite).TotalSeconds)
                        $TOtalTime = $OCT.Elapsed.TotalSeconds
                        Start-Sleep -Milliseconds 50
                    } Until ( $CheckTime -le 0 -or $TOtalTime -ge 30 )
                    $OCT.Stop()
                    if($OCT.Elapsed.TotalSeconds -ge 30){
                        $Success = $false
                        Global:Write-Log "WARNING: HiveOS did not set OC." -ForegroundColor Yellow
                    } else{
                        Global:Write-Log "OC Was Changed." -ForegroundColor Cyan
                        if(test-path ".\build\txt\ocnvidia.txt"){ $OCSheet += Get-Content ".\build\txt\ocnvidia.txt" }
                        $OCSheet += Get-Content ".\build\txt\ocamd.txt"
                        $Success  = $true
                    }
                }
                if ($CheckAMD) {
                    Global:Write-Log "Verifying OC was Set...." -ForegroundColor Cyan
                    $OCT = New-Object -TypeName System.Diagnostics.Stopwatch
                    $OCT.Restart()
                    $CheckFile = ".\build\txt\ocamd.txt"
                    do {
                        $LastWrite = Get-Item $CheckFile | Foreach { $_.LastWriteTime }
                        $CheckTime = [math]::Round(($CheckDate - $LastWrite).TotalSeconds)
                        $TOtalTime = $OCT.Elapsed.TotalSeconds
                        Start-Sleep -Milliseconds 50
                    } Until ( $CheckTime -le 0 -or $TOtalTime -ge 30 )
                    $OCT.Stop()
                    if($OCT.Elapsed.TotalSeconds -ge 30){
                        $Success = $false
                        Global:Write-Log "WARNING: HiveOS did not set OC." -ForegroundColor Yellow
                    } else{
                        Global:Write-Log "OC Was Changed." -ForegroundColor Cyan
                        if(test-path ".\build\txt\ocamd.txt"){ $OCSheet += Get-Content ".\build\txt\ocamd.txt" }
                        $OCSheet += Get-Content ".\build\txt\ocnvidia.txt"
                        $Success  = $true
                    }
                }
            }
            "linux" {
                if ($CheckNVIDIA) {
                    Global:Write-Log "Verifying OC was Set...." -ForegroundColor Cyan
                    $OCT = New-Object -TypeName System.Diagnostics.Stopwatch
                    $OCT.Restart()
                    $Checkfile = "/var/log/nvidia-oc.log"
                    do {
                        if(test-path $Checkfile){
                        $LastWrite = Get-Item $CheckFile | Foreach { $_.LastWriteTime }
                        $CheckTime = [math]::Round(($CheckDate - $LastWrite).TotalSeconds)
                        $TOtalTime = $OCT.Elapsed.TotalSeconds
                        }
                        Start-Sleep -Milliseconds 50
                    } Until ( $CheckTime -le 0 -or $TOtalTime -ge 30 )
                    if($OCT.Elapsed.TotalSeconds -ge 30){
                        $Success = $false
                        Global:Write-Log "WARNING: HiveOS did not set OC." -ForegroundColor Yellow
                    } else{
                        Global:Write-Log "OC Was Changed." -ForegroundColor Cyan
                        if(test-path "/var/log/amd-oc.log"){ $OCSheet += Get-Content "/var/log/amd-oc.log" }
                        $OCSheet += Get-Content "/var/log/nvidia-oc.log"
                        $Success  = $true
                    }
                }
                if ($CheckAMD) {
                    Global:Write-Log "Verifying OC was Set...." -ForegroundColor Cyan
                    $OCT = New-Object -TypeName System.Diagnostics.Stopwatch
                    $OCT.Restart()
                    $Checkfile = "/var/log/amd-oc.log"
                    do {
                        if(test-path $Checkfile){
                        $LastWrite = Get-Item $CheckFile | Foreach { $_.LastWriteTime }
                        $CheckTime = [math]::Round(($CheckDate - $LastWrite).TotalSeconds)
                        $TOtalTime = $OCT.Elapsed.TotalSeconds
                        Start-Sleep -Milliseconds 50
                        }
                    } Until ( $CheckTime -le 0 -or $TOtalTime -ge 30 )
                    $OCT.Stop()
                    if($OCT.Elapsed.TotalSeconds -ge 30){
                        $Success = $false
                        Global:Write-Log "WARNING: HiveOS did not set OC." -ForegroundColor Yellow
                    } else{
                        Global:Write-Log "OC Was Changed." -ForegroundColor Cyan
                        if(test-path "/var/log/nvidia-oc.log"){ $OCSheet += Get-Content "/var/log/nvidia-oc.log" }
                        $OCSheet += Get-Content "/var/log/amd-oc.log"
                        $Success  = $true
                    }
                }
            }
        }
    }
    
    $OCSheet | Add-Content -Path ".\build\txt\oc-settings.txt"
    $Success
}