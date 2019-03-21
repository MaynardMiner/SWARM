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

param(
    [Parameter(Mandatory = $false)]
    [String]$WorkingDir,
    [Parameter(Mandatory = $false)]
    [String]$Platforms,
    [Parameter(Mandatory = $false)]
    [String]$HiveId,
    [Parameter(Mandatory = $false)]
    [String]$HivePassword,
    [Parameter(Mandatory = $false)]
    [String]$HiveMirror,
    [Parameter(Mandatory = $false)]
    [String]$HiveOS,
    [Parameter(Mandatory = $false)]
    [Double]$REJPercent,
    [Parameter(Mandatory = $false)]
    [string]$Remote,
    [Parameter(Mandatory = $false)]
    [string]$API,
    [Parameter(Mandatory = $false)]
    [Int]$Port,
    [Parameter(Mandatory = $false)]
    [string]$APIPassword
)

Write-Host "Platform is $Platforms"; Write-Host "HiveOS ID is $HiveID"; Write-Host "HiveOS = $HiveOS"

##Icon for windows
if ($Platforms -eq "windows") {
    Set-Location $WorkingDir; Invoke-Expression ".\build\powershell\icon.ps1 `"$WorkingDir\build\apps\comb.ico`""
    $Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black'); $Host.UI.RawUI.ForegroundColor = 'White';
    $Host.PrivateData.ErrorForegroundColor = 'Red';        $Host.PrivateData.ErrorBackgroundColor = $bckgrnd;
    $Host.PrivateData.WarningForegroundColor = 'Magenta';  $Host.PrivateData.WarningBackgroundColor = $bckgrnd;
    $Host.PrivateData.DebugForegroundColor = 'Yellow';     $Host.PrivateData.DebugBackgroundColor = $bckgrnd;
    $Host.PrivateData.VerboseForegroundColor = 'Green';    $Host.PrivateData.VerboseBackgroundColor = $bckgrnd;
    $Host.PrivateData.ProgressForegroundColor = 'Cyan';    $Host.PrivateData.ProgressBackgroundColor = $bckgrnd;
    Clear-Host  
}

## Codebase for Further Functions
. .\build\api\html\api.ps1;          . .\build\api\html\include.ps1;        . .\build\api\miners\bminer.ps1;
. .\build\api\miners\ccminer.ps1;    . .\build\api\miners\cpuminer.ps1;     . .\build\api\miners\cpuminer.ps1;
. .\build\api\miners\dstm.ps1;       . .\build\api\miners\energiminer.ps1;  . .\build\api\miners\ethminer.ps1;
. .\build\api\miners\ewbf.ps1;       . .\build\api\miners\excavator.ps1;    . .\build\api\miners\gminer.ps1;
. .\build\api\miners\grin-miner.ps1; . .\build\api\miners\include.ps1;      . .\build\api\miners\lolminer.ps1;
. .\build\api\miners\miniz.ps1;      . .\build\api\miners\sgminer.ps1;      . .\build\api\miners\trex.ps1;
. .\build\api\miners\wildrig.ps1;    . .\build\api\miners\xmrstak-opt.ps1;  . .\build\api\miners\xmrstak.ps1;
. .\build\powershell\hashrates.ps1;  . .\build\powershell\commandweb.ps1;   . .\build\powershell\response.ps1;
. .\build\powershell\hiveoc.ps1;     . .\build\powershell\octune.ps1;       . .\build\powershell\statcommand.ps1;

##Start API Server
Write-Host "API Port is $Port";      
$Posh_api = Get-APIServer;        
$Posh_Api.BeginInvoke() | Out-Null
if ($API -eq "Yes") {Write-Host "API Server Started- you can run http://localhost:$Port/end to close" -ForegroundColor Green}

## SWARM miner PID
$CheckForSWARM = ".\build\pid\miner_pid.txt"
if (test-Path $CheckForSWARM) {$GetSWARMID = Get-Content $CheckForSWARM; $GETSWARM = Get-Process -ID $GetSWARMID -ErrorAction SilentlyContinue}

##Get Active Miners And Devices
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json

##Set Device Flags
$DevNVIDIA = $false
$DevAMD = $false
if ($GCount -like "*NVIDIA*") {$DevNVIDIA = $true; Write-Host "NVIDIA Detected"};
if ($GCount -like "*AMD*") {$DevAMD = $true; Write-Host "AMD Detected"};

##Timers
$BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$BackgroundTimer.Restart()
$RestartTimer = New-Object -TypeName System.Diagnostics.Stopwatch

##Get hive naming conventions:
$GetHiveNames = ".\config\pools\pool-algos.json"
$HiveNames = if (Test-Path $GetHiveNames) {Get-Content $GetHiveNames | ConvertFrom-Json}

While ($True) {
    ## Timer For When To Restart Loop
    $RestartTimer.Restart()

    ##Bool for Current Miners
    $Switched = $false

    ##Determine if Miner Switched
    $CheckForMiners = ".\build\txt\bestminers.txt"
    if (test-Path $CheckForMiners) {$GetMiners = Get-Content $CheckForMiners | ConvertFrom-Json -ErrorAction Stop}
    else {Write-Host "No Miners Running..."}
    if ($GETSWARM.HasExited -eq $true) {Write-Host "SWARM Has Exited..."}

    ##Handle New Miners
    if ($GetMiners -and $GETSWARM.HasExited -eq $false) {
        $GetMiners | ForEach {if (-not ($CurrentMiners | Where Path -eq $_.Path | Where Arguments -eq $_.Arguments )) {$Switched = $true}}
        if ($Switched -eq $True) {
            Write-Host "Miners Have Switched
" -ForegroundColor Cyan
            $CurrentMiners = $GetMiners;
            ##Set Starting Date & Device Flags
            $StartTime = Get-Date
            ## Determine Which GPU's to stat
            $CurrentMiners | Foreach {
                $NEW = 0; 
                $NEW | Set-Content ".\build\txt\$($_.Type)-hash.txt";
                $Name = $($_.Name)
            }
        }
    }
    else {
        $StartTime = Get-Date
        $NEW = 0;
        if ($DevNVIDIA -eq $true) { 
            $NEW | Set-Content ".\build\txt\NVIDIA1-hash.txt";
            $NEW | Set-Content ".\build\txt\NVIDIA2-hash.txt";
            $NEW | Set-Content ".\build\txt\NVIDIA2-hash.txt";
        }
        if ($DevAMD -eq $true) {
            $NEW | Set-Content ".\build\txt\AMD1-hash.txt";  
        }
        $NEW | Set-Content ".\build\txt\CPU-hash.txt";
    }

    ## Set-OC
    if ($Switched -eq $true) {
        Write-Host "Starting Tuning"
        Start-OC -Platforms $Platforms -Dir $WorkingDir
        ## ADD Delay for OC and Miners To Start Up
        Start-Sleep -S 10
    }

    ## Determine if CPU in only used. Clear All Tables
    $CPUOnly = $true
    $CurrentMiners | Foreach {if ($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*") {$CPUOnly = $false; "GPU" | Set-Content ".\build\txt\miner.txt"}}
    if ($CPUOnly -eq $true) {"CPU" | Set-Content ".\build\txt\miner.txt"}
    ## Build Initial Hash Tables For Stats
    $global:GPUHashrates = [PSCustomObject]@{}
    $global:CPUHashrates = [PSCustomObject]@{}
    $global:GPUsFans = [PSCustomObject]@{}
    $global:GPUsTemps = [PSCustomObject]@{}
    $global:GPUsPower = [PSCustomObject]@{}
    for ($i = 0; $i -lt $GCount.CPU.PSObject.Properties.Value.Count; $i++) {
        $global:CPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.CPU.$i)" -Value 0; 
    }
    if ($DevAMD -eq $true) {
        for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {
            $global:GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; 
            $global:GPUsFans | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; 
            $global:GPUsTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; 
            $global:GPUsPower | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0
        }
    }
    if ($DevNVIDIA -eq $true) {  
        for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
            $global:GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; 
            $global:GPUsFans | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; 
            $global:GPUsTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; 
            $global:GPUsPower | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0
        }
    }

    ## Reset All Stats, Rebuild Tables
    $global:BALGO = @(); $global:BHiveAlgo = @(); $global:BHashRates = @(); 
    $global:BFans = @(); $global:BTemps = @(); $global:BPower = @(); 
    $global:BCPUKHS = $null; $global:BCPUACC = 0; $global:BCPUREJ = 0; 
    $global:BRAW = 0; $global:BKHS = 0; $global:BREJ = 0; 
    $global:BACC = 0;

    ## Windows-To-Hive Stats
    if ($Platforms -eq "windows") {
        ## Rig Metrics
        if ($HiveOS -eq "Yes") {
            $ramtotal = Get-Content ".\build\txt\ram.txt"
            $cpu = $(Get-WmiObject Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength
            $LoadAverage = Set-Stat -Name "load-average" -Value $cpu
            $LoadAverages = @("$([Math]::Round($LoadAverage.Minute,2))", "$([Math]::Round($LoadAverage.Minute_5,2))", "$([Math]::Round($LoadAverage.Minute_10,2))")
            $ramfree = $(Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
        }
        if ($DevNVIDIA -eq $true) {$NVIDIAStats = Set-NvidiaStats}
        if ($DevAMD -eq $true) {$AMDStats = Set-AMDStats}
    }

    ## Linux-To-Hive Stats
    if ($Platforms -eq "linux") {
        if ($DevNVIDIA -eq $true) {$NVIDIAStats = Set-NvidiaStats}
        if ($DevAMD -eq $true) {$AMDStats = Set-AMDStats}
    }

    ## Start API Calls For Each Miner
    if ($CurrentMiners -and $GETSWARM.HasExited -eq $false) {
        $CurrentMiners | Foreach {
            ## Miner Information
            $MinerAlgo = "$($_.Algo)"
            $MinerName = "$($_.MinerName)"
            $Name = "$($_.Name)"
            $Server = "localhost"
            $Port = $($_.Port)
            $MinerType = "$($_.Type)"
            $MinerAPI = "$($_.API)"
            $HashPath = ".\logs\$($_.Type).log"
            $global:BHiveAlgo += $HiveNames.$($_.Algo).hiveos_name

            ## Set Object For Type (So It doesn't need to be repeated)
            if ($MinerType -like "*NVIDIA*") {$TypeS = "NVIDIA"}
            elseif ($MinerType -like "*AMD*") {$TypeS = "AMD"}
            elseif ($MinerType -like "*CPU*") {$TypeS = "CPU"}

            ## Determine Devices
            if ($_.Type -ne "CPU") {
                if ($_.Devices -eq "none") {$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}
                else {$Devices = Get-DeviceString -TypeDevices $_.Devices}
            }
            elseif ($_.Type -eq "CPU") {$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}


            ## First Power For Windows
            if ($Platforms -eq "windows" -and $HiveOS -eq "Yes") {
                if ($TypeS -eq "NVIDIA") {$StatPower = $NVIDIAStats.Power}
                if ($TypeS -eq "AMD") {$StatPower = $AMDStats.Power}
                if ($StatPower -ne "" -or $StatPower -ne $null) {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUsPower.$(Get-GPUS) = Set-Array $StatPower $Devices[$i]}}
            }


            ## Now Fans & Temps
            if ($MinerType -Like "*NVIDIA*") {
                switch ($Platforms) {
                    "Windows" {
                        for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                        for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $Devices[$i]}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}
                    }
                    "linux" {
                        switch ($HiveOS) {
                            "Yes" {
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans (Get-GPUs)}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps (Get-GPUs)}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}            
                            }
                            "No" {
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $Devices[$i]}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}                    
                            }
                        }
                    }
                }
            }
            if ($MinerType -Like "*AMD*") {
                Switch ($Platforms) {
                    "windows" {
                        for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                        for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                    }
                    "linux" {
                        switch ($HiveOS) {
                            "Yes" {
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $AMDStats.Fans (Get-GPUs)}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps (Get-GPUs)}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}
                            }
                            "No" {
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $Devices[$i]}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}
                            }
                        }
                    }
                }
            }

            ## Set Initial Output
            $global:BHS = "khs"
            $global:BRAW = 0
            $global:BMinerACC = 0
            $global:BMinerREJ = 0
            Write-MinerData1

            ## Start Calling Miners
            switch ($MinerAPI) {
                'energiminer' { try{Get-StatsEnergiminer}catch{Get-OhNo} }
                'claymore' { try{Get-StatsEthminer}catch{Get-OhNo} }
                'excavator' { try{Get-StatsExcavtor}catch{Get-OhNo} }
                'miniz' { try{Get-StatsMiniz}catch{Get-OhNo} }
                'gminer' { try{Get-StatsGminer}catch{Get-OhNo} }
                'grin-miner' { try{Get-StatsGrinMiner}catch{Get-OhNo} }
                'ewbf' { try{Get-StatsEWBF}catch{Get-OhNo} }
                'ccminer' { try{Get-StatsCcminer}catch{Get-OhNo} }
                'bminer' { try{Get-StatsBminer}catch{Get-OhNo} }
                'trex' { try{Get-StatsTrex}catch{Get-OhNo} }
                'dstm' { try{Get-StatsDSTM}catch{Get-OhNo} }
                'lolminer' { try{Get-StatsLolminer}catch{Get-OhNo} }
                'sgminer-gm' { try{Get-StatsSgminer}catch{Get-OhNo} }
                'cpuminer' { try{Get-StatsCpuminer}catch{Get-OhNo} }
                'xmrstak' { try{Get-StatsXmrstak}catch{Get-OhNo} }
                'xmrstak-opt' { try{Get-StatsXmrstakOPT}catch{Get-OhNo} }
                'wildrig' { try{Get-StatsWildRig}catch{Get-OhNo} }
            }

            ##Check To See if High Rejections
            if ($BackgroundTimer.Elapsed.TotalSeconds -gt 60) {
                $Shares = [Double]$global:BMinerACC + [double]$global:BMinerREJ
                $RJPercent = $global:BMinerREJ / $Shares * 100
                if ($RJPercent -gt $REJPercent -and $Shares -gt 0) {
                    Write-Host "Warning: Miner is reaching Rejection Limit- $($RJPercent.ToString("N2")) Percent Out of $Shares Shares" -foreground yellow
                    if (-not (Test-Path ".\timeout")) {New-Item "timeout" -ItemType Directory | Out-Null}
                    if (-not (Test-Path ".\timeout\warnings")) {New-Item ".\timeout\warnings" -ItemType Directory | Out-Null}
                    "Bad Shares" | Out-File ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt"
                }
                else {if (Test-Path ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt") {Remove-Item ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt" -Force}}
            }
 
        }
    }

    if ($CPUOnly -eq $true) {
        $global:BCPUKHS = [Math]::Round($global:BCPUKHS, 4)
        $HIVE = "
$($CPUHash -join "`n")
KHS=$global:BCPUKHS
ACC=$global:BCPUACC
REJ=$global:BCPUREJ
ALGO=$global:BCPUALGO
TEMP=$CPUTEMP
FAN=$CPUFAN
UPTIME=$global:BCPUUPTIME
HSU=$global:BCPUHS
"
        $Hive | Set-Content ".\build\txt\hivestats.txt"

        if ($GetMiners -and $GETSWARM.HasExited -eq $false) {
            Write-Host " "
            Write-Host "$global:BHashRates" -ForegroundColor Green -NoNewline
            Write-Host " KHS=$global:BCPUKHS" -ForegroundColor Yellow -NoNewline
            Write-Host " ACC=$global:BCPUACC" -ForegroundColor DarkGreen -NoNewline
            Write-Host " REJ=$global:BCPUREJ" -ForegroundColor DarkRed -NoNewline
            Write-Host " ALGO=$global:BCPUALGO" -ForegroundColor Gray -NoNewline
            Write-Host " FAN=$CPUFAN" -ForegroundColor Cyan -NoNewline
            Write-Host " UPTIME=$global:BCPUUPTIME
" -ForegroundColor White
        }
    }
    else {
        if ($DEVNVIDIA -eq $True) {if ($GCount.NVIDIA.PSObject.Properties.Value.Count -gt 0) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BHashRates += 0; $global:BFans += 0; $global:BTemps += 0}}}
        if ($DevAMD -eq $True) {if ($GCount.AMD.PSObject.Properties.Value.Count -gt 0) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BHashRates += 0; $global:BFans += 0; $global:BTemps += 0}}}
        if ($DEVNVIDIA -eq $True) {for ($i = 0; $i -lt $GCount.NVIDIA.PSOBject.Properties.Value.Count; $i++) {$global:BHashRates[$($GCount.NVIDIA.$i)] = "GPU={0:f4}" -f $($global:GPUHashrates.$($GCount.NVIDIA.$i))}}
        if ($DevAMD -eq $True) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BHashRates[$($GCount.AMD.$i)] = "GPU={0:f4}" -f $($global:GPUHashrates.$($GCount.AMD.$i))}}
        if ($DEVNVIDIA -eq $True) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BFans[$($GCount.NVIDIA.$i)] = "FAN=$($global:GPUsFans.$($GCount.NVIDIA.$i))"}}
        if ($DevAMD -eq $True) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BFans[$($GCount.AMD.$i)] = "FAN=$($global:GPUsFans.$($GCount.AMD.$i))"}}
        if ($DEVNVIDIA -eq $True) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BTemps[$($GCount.NVIDIA.$i)] = "TEMP=$($global:GPUsTemps.$($GCount.NVIDIA.$i))"}}
        if ($DevAMD -eq $True) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BTemps[$($GCount.AMD.$i)] = "TEMP=$($global:GPUsTemps.$($GCount.AMD.$i))"}}
        if ($Platforms -eq "windows" -and $HiveOS -eq "Yes") {
            if ($DEVNVIDIA -eq $True) {if ($GCount.NVIDIA.PSObject.Properties.Value.Count -gt 0) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BPower += 0}}}
            if ($DevAMD -eq $True) {if ($GCount.AMD.PSObject.Properties.Value.Count -gt 0) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BPower += 0}}}
            if ($DEVNVIDIA -eq $True) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BPower[$($GCount.NVIDIA.$i)] = "POWER=$($global:GPUsPower.$($GCount.NVIDIA.$i))"}}
            if ($DevAMD -eq $True) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BPower[$($GCount.AMD.$i)] = "POWER=$($global:GPUsPower.$($GCount.AMD.$i))"}}
        }  
        for ($i = 0; $i -lt $global:BHashRates.count; $i++) {
            if ($global:BHashRates[$i] -eq 'GPU=0' -or $global:BHashRates[$i] -eq 'GPU=' -or $global:BHashRates[$i] -eq 'GPU=0.0000') {
                $global:BHashRates[$i] = 'GPU=0.000'; $global:BKHS += 0.000
            }
        }

        $global:BALGO = $global:BALGO | Select -First 1
        $global:BHiveAlgo = $global:BHiveAlgo | Select -First 1
        $global:BKHS = [Math]::Round($global:BKHS, 4)

        $HIVE = "
$($global:BHashRates -join "`n")
KHS=$global:BKHS
ACC=$global:BACC
REJ=$global:BREJ
ALGO=$global:BALGO
HIVEALGO=$global:BHiveAlgo
$($global:BFans -join "`n")
$($global:BTemps -join "`n")
UPTIME=$global:BUPTIME
HSU=khs
"

        if ($GetMiners -and $GETSWARM.HasExited -eq $false) {
            Write-Host " "
            Write-Host "$global:BHashRates" -ForegroundColor Green -NoNewline
            Write-Host " KHS=$global:BKHS" -ForegroundColor Yellow -NoNewline
            Write-Host " ACC=$global:BACC" -ForegroundColor DarkGreen -NoNewline
            Write-Host " REJ=$global:BREJ" -ForegroundColor DarkRed -NoNewline
            Write-Host " ALGO=$global:BALGO" -ForegroundColor Gray -NoNewline
            Write-Host " $global:BFans" -ForegroundColor Cyan -NoNewline
            Write-Host " $global:BTemps" -ForegroundColor Magenta -NoNewline
            if ($Platforms -eq "windows") {Write-Host " $global:BPower"  -ForegroundColor DarkCyan -NoNewline}
            Write-Host " UPTIME=$global:BUPTIME
" -ForegroundColor White
        }

        if ($global:BCPUKHS -ne $null) {$global:BCPUKHS = [Math]::Round($global:BCPUKHS, 4); Write-Host "CPU=$global:BCPUKHS"}
        $Hive | Set-Content ".\build\txt\hivestats.txt"
    }

    if ($Platforms -eq "windows" -and $HiveOS -eq "Yes") {
        $Stats = Build-HiveResponse
        try {$response = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($Stats | ConvertTo-Json -Depth 4 -Compress) -ContentType 'application/json'}
        catch {Write-Warning "Failed To Contact HiveOS.Farm"; $response = $null}
        $response | ConvertTo-Json | Set-Content ".\build\txt\response.txt"
        if ($response) {
            if ($response.result.command -eq "batch") {
                $batch = $response.result.commands
                for ($b = 0; $b -lt $batch.count; $b++) {
                    $do_command = $batch[$b]
                    $do_command = $do_command -replace "@{", ""
                    $do_command = $do_command -replace "}", ""
                    $do_command = $do_command -split ";"
                    $do_command = $do_command -replace "amd_oc=", ""
                    $do_command = $do_command -replace "nvidia_oc=", ""
                    $parsed_batch = $do_command
                    $new_command = $do_command | ConvertFrom-StringData
                    $batch_command = [PSCustomObject]@{"result" = @{command = $new_command.Command; id = $new_command.id; $new_command.command = $parsed_batch}}
                    $SwarmResponse = Start-webcommand -command $batch_command -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror
                }
            }
            else {$SwarmResponse = Start-webcommand -command $response -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror}
            if ($SwarmResponse -ne $null) {
                if ($SwarmResponse -eq "config") {
                    Write-Warning "Config Command Initiated- Restarting SWARM"
                    $MinerFile = ".\build\pid\miner_pid.txt"
                    if (Test-Path $MinerFile) {$MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue}
                    if ($MinerId) {
                        Stop-Process $MinerId
                        Start-Sleep -S 3
                    }
                    Start-Process ".\SWARM.bat"
                    Start-Sleep -S 3
                    Exit
                }
                if ($SwarmResponse -eq "stats") {
                    Write-Host "Hive Received Stats"
                }
                if ($SwarmResponse -eq "exec") {
                    Write-Host "Sent Command To Hive"
                }
                if ($SwarmResponse -eq "update") {
                    Write-Host "Update Completed- Exiting"
                    Exit
                }
            }
        }
    }

    if ($BackgroundTimer.Elapsed.TotalSeconds -gt 120) {Clear-Content ".\build\txt\hivestats.txt"; $BackgroundTimer.Restart()}

    if ($RestartTimer.Elapsed.TotalSeconds -le 10) {
        $GoToSleep = [math]::Round(10 - $RestartTimer.Elapsed.TotalSeconds)
        if ($GoToSleep -gt 0) {Start-Sleep -S $GoToSleep}
    }

}
