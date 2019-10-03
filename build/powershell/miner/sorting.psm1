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

function Global:Expand-WebRequest {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Uri,
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$Path,
        [Parameter(Mandatory = $true, Position = 2)]
        [String]$version
    )

    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

    $Zip = Split-Path $Uri -Leaf; $BinPath = $($Z = Split-Path $Path -Parent; Split-Path $Z -Leaf);
    $Name = (Split-Path $Path -Leaf); $X64_zip = Join-Path ".\x64" $Zip;
    $BaseName = $( (Split-Path $Path -Leaf) -split "\.") | Select -First 1
    $X64_extract = $( (Split-Path $URI -Leaf) -split "\.") | Select -First 1;
    $MoveThere = Split-Path $Path; $temp = "$($BaseName)_Temp"

    ##First Determine the file type:
    $FileType = $Zip
    if ($Zip.Contains(".") -eq $false -and $Zip.Contains("=") -eq $false) { ## "=" is for miniz download
        $Extraction = "binary"
    } else {
        $FileType = $FileType -split "\."
        if ("7z" -in $FileType) { $Extraction = "zip" }
        elseif ("zip" -in $FileType) { $Extraction = "zip" }
        elseif ("tar" -in $FileType) { $Extraction = "tar" }
        elseif ("tgz" -in $FileType) { $Extraction = "tar" }
        else {
            if ($IsWindows) {
                $Extraction = "zip"; 
                $Zip = $(Split-Path $Path -Leaf) -replace ".exe", ".zip"
                $X64_zip = Join-Path ".\x64" $Zip;
                $X64_extract = $( (Split-Path $X64_zip -Leaf) -split "\.") | Select -First 1;
            }
            elseif ($IsLinux) {
                $Extraction = "tar" 
                $Zip = "$(Split-Path $Path -Leaf).tar.gz"
                $X64_zip = Join-Path ".\x64" $Zip;
                $X64_extract = $( (Split-Path $X64_zip -Leaf) -split "\.") | Select -First 1;
            }
            log "WARNING: File download type is unknown attepting to guess file type as $Zip" -ForeGroundColor Yellow
        }
    }

    if ($Extraction -eq "tar") {
        if ("gz" -in $FileType) { $Tar = "gz" }
        elseif ("xz" -in $FileType) { $Tar = "xz" }
        elseif ("tgz" -in $FileType) { $Tar = "gz" }
        else { $Tar = "gz" }
    }

    ##Delete any old download attempts - Start Fresh
    if (Test-Path $X64_zip) { Remove-Item $X64_zip -Recurse -Force }
    if (Test-Path $X64_extract) { Remove-Item $X64_extract -Recurse -Force }
    if (Test-Path ".\bin\$BinPath") { Remove-Item ".\bin\$BinPath" -Recurse -Force }
    if (Test-Path ".\x64\$temp") { Remove-Item ".\x64\$temp" -Recurse -Force }

    ##Make Dirs if not there
    if (-not (Test-Path ".\bin")) { New-Item "bin" -ItemType "directory" | Out-Null; Start-Sleep -S 1 }
    if (-not (Test-Path ".\x64")) { New-Item "x64" -ItemType "directory" | Out-Null; Start-Sleep -S 1 }

    Switch ($Extraction) {
    
        "tar" {
            log "Download URI is $URI"
            log "Miner Exec is $Name"
            log "Miner Dir is $MoveThere"
            try { Invoke-WebRequest "$Uri" -OutFile "$X64_zip" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10 }catch { log "WARNING: Failed to contact $URI for miner binary" -ForeGroundColor Yellow }

            if (Test-Path "$X64_zip") { log "Download Succeeded!" -ForegroundColor Green }
            else { log "Download Failed!" -ForegroundColor DarkRed; break }

            log "Extracting to temporary folder" -ForegroundColor Yellow
            New-Item -Path ".\x64\$temp" -ItemType "Directory" -Force | Out-Null; Start-Sleep -S 1
            switch ($Tar) {
                "gz" { $Proc = Start-Process "tar" -ArgumentList "-xzvf x64/$Zip -C x64/$temp" -PassThru; $Proc | Wait-Process }
                "xz" { $Proc = Start-Process "tar" -ArgumentList "-xvJf x64/$Zip -C x64/$temp" -PassThru; $Proc | Wait-Process }
            }

            $Stuff = Get-ChildItem ".\x64\$Temp"
            if ($Stuff) { log "Extraction Succeeded!" -ForegroundColor Green }
            else { log "Extraction Failed!" -ForegroundColor darkred; break }

            ##Now the fun part find the dir that the exec is in.
            $Search = Get-ChildItem -Path ".\x64\$temp" -Filter "$Name" -Recurse -ErrorAction SilentlyContinue
            if (-not $Search) { log "Miner Executable Not Found" -ForegroundColor DarkRed; break }
            $Contents = $Search.Directory.FullName | Select -First 1
            $DirName = Split-Path $Contents -Leaf
            Move-Item -Path $Contents -Destination ".\bin" -Force | Out-Null; Start-Sleep -S 1
            Rename-Item -Path ".\bin\$DirName" -NewName "$BinPath" | Out-Null; Start-Sleep -S 1
            if (Test-Path ".\x64\$Temp") { Remove-Item ".\x64\$Temp" -Recurse -Force | Out-Null }
        }
        "zip" {
            log "Download URI is $URI"
            log "Miner Exec is $Name"
            log "Miner Dir is $MoveThere"
            try { Invoke-WebRequest "$Uri" -OutFile "$X64_zip" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10 }catch { log "WARNING: Failed to contact $URI for miner binary" -ForeGroundColor Yellow }
            if (Test-Path "$X64_zip") { log "Download Succeeded!" -ForegroundColor Green }
            else { log "Download Failed!" -ForegroundColor DarkRed; break }

            New-Item -Path ".\x64\$temp" -ItemType "Directory" -Force | Out-Null; Start-Sleep -S 1
            if ($IsWindows) { $Proc = Start-Process ".\build\apps\7z\7z.exe" "x `"$($(vars).dir)\$X64_zip`" -o`"$($(vars).dir)\x64\$temp`" -y" -PassThru -WindowStyle Minimized -verb Runas; $Proc | Wait-Process}
            else { $Proc = Start-Process "unzip" -ArgumentList "$($(vars).dir)/$X64_zip -d $($(vars).dir)/x64/$temp" -PassThru; $Proc | Wait-Process }
            $Stuff = Get-ChildItem ".\x64\$Temp"
            if ($Stuff) { log "Extraction Succeeded!" -ForegroundColor Green }
            else { log "Extraction Failed!" -ForegroundColor darkred; break }

            $Search = Get-ChildItem -Path ".\x64\$temp" -Filter "$Name" -Recurse -ErrorAction SilentlyContinue
            if (-not $Search) { log "Miner Executable Not Found" -ForegroundColor DarkRed; break }
            $Contents = $Search.Directory.FullName | Select -First 1
            $DirName = Split-Path $Contents -Leaf
            Move-Item -Path $Contents -Destination ".\bin" -Force | Out-Null; Start-Sleep -S 1
            Rename-Item -Path ".\bin\$DirName" -NewName "$BinPath" | Out-Null
            if (Test-Path ".\x64\$Temp") { Remove-Item ".\x64\$Temp" -Recurse -Force | Out-Null }
        }
        "binary" {
            log "Download URI is $URI"
            log "Miner Exec is $Name"
            log "Miner Dir is $MoveThere"
            try { Invoke-WebRequest "$Uri" -OutFile "$X64_zip" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10 }catch { log "WARNING: Failed to contact $URI for miner binary" -ForeGroundColor Yellow }
            if(test-path "$X64_zip") {
                New-Item ".\bin\$BinPath" -ItemType Directory -Force | Out-Null
                Move-Item -Path $X64_zip -Destination ".\bin\$BinPath" | Out-Null
                Rename-Item -Path ".\bin\$BinPath\$(Split-Path $X64_zip -Leaf)" -NewName (Split-Path $Path -Leaf)
            }
        }    
    }
    if (Test-Path $Path) {
        $Version | Set-Content ".\bin\$BinPath\swarm-version.txt"
        log "Finished Successfully!" -ForegroundColor Green  
    }
}

function Global:Get-MinerBinary($Miner,$Reason) {

    $MaxAttempts = 3;
    ## Success 1 means to continue forward (ASIC)
    ## Success 2 means that miner failed, and loop should restart
    ## Success 3 means that miner download succeded
    $Success = 1;

    if($Reason -eq "Update" -and $Miner.Type -notlike "*ASIC*") {
        if(test-path $Miner.Path){
            Write-Log "Removing Old Miner..." -ForegroundColor Yellow
            Remove-Item (Split-Path $Miner.Path) -Recurse -Force | Out-Null
        }
    }
    if ($Miner.Type -notlike "*ASIC*") {
        for ($i = 0; $i -lt $MaxAttempts; $i++) {
            if ( -not (Test-Path $Miner.Path) ) {
                log "$($Miner.Name) Not Found- Downloading" -ForegroundColor Yellow
                Global:Expand-WebRequest $Miner.URI $Miner.Path $Miner.version
            }
        }
        if ( Test-Path $Miner.Path ) {
            $Success = 3
        }
        else {
            $Success = 2
            if ( -not (Test-Path ".\timeout\download_block") ) { New-Item -Name "download_block" -Path ".\timeout" -ItemType "directory" | OUt-Null }
            $MinersArray = @()
            if (Test-Path ".\timeout\download_block\download_block.txt") { $OldTimeouts = Get-Content ".\timeout\download_block\download_block.txt" | ConvertFrom-Json }
            if ($OldTimeouts) { $OldTimeouts | % { $MinersArray += $_ } }
            if($Miner.Name -notin $MinersArray.Name) { $MinersArray += $Miner }
            $MinersArray | ConvertTo-Json -Depth 3 | Set-Content ".\timeout\download_block\download_block.txt"
            $HiveMessage = "$($Miner.Name) Has Failed To Download"
            $HiveWarning = @{result = @{command = "timeout" } }
            if ($(vars).WebSites) {
                $(vars).WebSites | ForEach-Object {
                    $Sel = $_
                    try {
                        Global:Add-Module "$($(vars).web)\methods.psm1"
                        Global:Get-WebModules $Sel
                        $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                    }
                    catch { log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                    Global:Remove-WebModules $sel
                }
            }
            log "$HiveMessage" -ForegroundColor Red
        }
    }
    else { $Success = 1 }

    $Success
}

function Global:Stop-AllMiners {
    $(vars).ActiveMinerPrograms | ForEach-Object {
           Write-Log "WARNING: Stopping All Miners For Download" -ForegroundColor Yellow
        ##Miners Not Set To Run        
            if ($(arg).Platform -eq "windows") {
                if ($_.XProcess -eq $Null) { $_.Status = "Failed" }
                elseif ($_.XProcess.HasExited -eq $false) {
                    $_.Active += (Get-Date) - $_.XProcess.StartTime
                    if ($_.Type -notlike "*ASIC*") {
                        $Num = 0
                        $Sel = $_
                        if ($Sel.XProcess.Id) {
                            $Childs = Get-Process | Where { $_.Parent.Id -eq $Sel.XProcess.Id }
                            Write-Log "Closing all Previous Child Processes For $($Sel.Type)" -ForeGroundColor Cyan
                            $Child = $Childs | % {
                                $Proc = $_; 
                                Get-Process | Where { $_.Parent.Id -eq $Proc.Id } 
                            }
                        }
                        do {
                            $Sel.XProcess.CloseMainWindow() | Out-Null
                            Start-Sleep -S 1
                            $Num++
                            if ($Num -gt 5) {
                                Write-Log "SWARM IS WAITING FOR MINER TO CLOSE. IT WILL NOT CLOSE" -ForegroundColor Red
                            }
                            if ($Num -gt 180) {
                                if ($(arg).Startup -eq "Yes") {
                                    $HiveMessage = "2 minutes miner will not close - Restarting Computer"
                                    $HiveWarning = @{result = @{command = "timeout" } }
                                    if ($(vars).WebSites) {
                                        $(vars).WebSites | ForEach-Object {
                                            $Sel = $_
                                            try {
                                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                                Global:Get-WebModules $Sel
                                                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                            }
                                            catch { log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                            Global:Remove-WebModules $sel
                                        }
                                    }
                                    log "$HiveMessage" -ForegroundColor Red
                                }
                                Restart-Computer
                            }
                        }Until($false -notin $Child.HasExited)
                        if ($Sel.SubProcesses -and $false -in $Sel.SubProcesses.HasExited) { 
                            $Sel.SubProcesses | % { $Check = $_.CloseMainWindow(); if ($Check -eq $False) { Stop-Process -Id $_.Id } }
                        }
                    }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null }
                    $_.Status = "Idle"
                }
            }

            if ($(arg).Platform -eq "linux") {
                if ($_.XProcess -eq $Null) { $_.Status = "Failed" }
                else {
                    if ($_.Type -notlike "*ASIC*") {
                        $MinerInfo = ".\build\pid\$($_.InstanceName)_info.txt"
                        if (Test-Path $MinerInfo) {
                            $_.Status = "Idle"
                            $(vars).PreviousMinerPorts.$($_.Type) = "($_.Port)"
                            $MI = Get-Content $MinerInfo | ConvertFrom-Json
                            $PIDTime = [DateTime]$MI.start_date
                            $Exec = Split-Path $MI.miner_exec -Leaf
                            $_.Active += (Get-Date) - $PIDTime
                            $Proc = Start-Process "start-stop-daemon" -ArgumentList "--stop --name $Exec --pidfile $($MI.pid_path) --retry 5" -PassThru
                            $Proc | Wait-Process
                        }
                    }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null; $_.Status = "Idle" }
                }
            }
        }
}
function Global:Start-MinerDownloads {
    $MinersStopped = $False
    $(vars).Miners | ForEach-Object {
        $Sel = $_
        $Success = 0;
        if ( $Sel.Type -notlike "*ASIC*") {
            $CheckPath = Test-Path $Sel.Path
            $VersionPath = Join-Path (Split-Path $Sel.Path) "swarm-version.txt"
            if ( $CheckPath -eq $false ) {
                if($MinersStopped -eq $false){
                    Global:Stop-AllMiners
                    $MinersStopped = $true
                }
                $Success = Global:Get-MinerBinary $Sel "New"
            }
            elseif(test-path $VersionPath){
                [String]$Old_Version = Get-Content $VersionPath
                if($Old_Version -ne [string]$Sel.Version) {
                    if($MinersStopped -eq $false){
                        Global:Stop-AllMiners
                        $MinersStopped = $true
                    }
                        Write-Log "There is a new version availble for $($Sel.Name), Downloading" -ForegroundColor Yellow
                    $Success = Global:Get-MinerBinary $Sel "Update"
                }
            }
            else{
                if($MinersStopped -eq $false){
                    Global:Stop-AllMiners
                    $MinersStopped = $true
                }
                Write-Log "Binary found, but swarm-version.txt is missing for $($Sel.Name), Downloading" -ForegroundColor Yellow
                $Success = Global:Get-MinerBinary $Sel "Update"
            }
        }
        else { $Success = 1 }
        if ($Success -eq 2) {
            log "WARNING: Miner Failed To Download Three Times- Restarting SWARM" -ForeGroundColor Yellow
            remove all
            continue
        }
    }
}
function Global:Start-MinerReduction {

    $CutMiners = @()
    $(arg).Type | ForEach-Object {
        $GetType = $_;
        $(vars).Miners.Symbol | Select-Object -Unique | ForEach-Object {
            $zero = $(vars).Miners | Where-Object Type -eq $GetType | Where-Object Symbol -eq $_ | Where-Object Quote -EQ 0; 
            $nonzero = $(vars).Miners | Where-Object Type -eq $GetType | Where-Object Symbol -eq $_ | Where-Object Quote -NE 0;

            if ($zero) {
                $GetMinersToCut = @()
                $GetMinersToCut += $zero
                $GetMinersToCut += $nonzero | Sort-Object @{Expression = "Quote"; Descending = $true }
                $GetMinersToCut = $GetMinersToCut | Select-Object -Skip 1;
                $GetMinersToCut | ForEach-Object { $CutMiners += $_ };
            }
            else {
                $GetMinersToCut = @()
                $GetMinersToCut = $nonzero | Sort-Object @{Expression = "Quote"; Descending = $true };
                $GetMinersToCut = $GetMinersToCut | Select-Object -Skip 1;
                $GetMinersToCut | ForEach-Object { $CutMiners += $_ };
            }
        }
    }

    $CutMiners
}


function Global:Get-Volume {
    $(vars).Pool_Hashrates.keys | ForEach-Object {
        $SortAlgo = $_
        $Sorted = @()
        $(vars).Pool_Hashrates.$SortAlgo.keys | ForEach-Object { $Sorted += [PSCustomObject]@{Name = "$($_)"; HashRate = [Decimal]$(vars).Pool_Hashrates.$SortAlgo.$_.HashRate } }
        $BestHash = [Decimal]$($Sorted | Sort-Object HashRate -Descending | Select -First 1).HashRate
        $(vars).Pool_Hashrates.$SortAlgo.keys | ForEach-Object { $(vars).Pool_Hashrates.$SortAlgo.$_.Percent = (([Decimal]$BestHash - [Decimal]$(vars).Pool_Hashrates.$SortAlgo.$_.HashRate) / [decimal]$BestHash) }
    }
}

function Global:Start-Sorting {

    $(vars).Miners | ForEach-Object {

        $Miner = $_
     
        $MinerPool = $Miner.MinerPool | Select-Object -Unique

        if ($Miner.Power -gt 0) { $WattCalc3 = (((([Double]$Miner.Power * 24) / 1000) * $(vars).WattEx) * -1) }
        else { $WattCalc3 = 0 }
            
        if ($(vars).Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent -gt 0) { $Hash_Percent = $(vars).Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent * 100 }
        else { $Hash_Percent = 0 }

        $Miner_Volume = ([Double]($Miner.Quote * (1 - ($Hash_Percent / 100))))
        $Miner_Modified = ([Double]($Miner_Volume * (1 - ($Miner.Fees / 100))))

        $Miner | Add-Member Profit ([Double]($Miner_Modified + $WattCalc3)) ##Used to calculate BTC/Day and sort miners
        $Miner | Add-Member Profit_Unbiased ([Double]($Miner_Modified + $WattCalc3)) ##Uset to calculate Daily profit/day moving averages
        $Miner | Add-Member Pool_Estimate ([Double]($Miner.Quote)) ##RAW calculation for Live Value (Used On screen)
        $Miner | Add-Member Volume $( if ($(vars).Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent -gt 0) { [Double]$(vars).Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent * 100 } else { 0 } )
            
        if (-not $Miner.HashRates) {
            $miner.HashRates = $null
            $Miner.Profit = $null
            $Miner.Profit_Unbiased = $null
            $Miner.Pool_Estimate = $null
            $Miner.Volume = $null
            $Miner.Power = $null
        }
    }
}

function Global:Add-SwitchingThreshold {
    $(vars).BestActiveMiners | ForEach-Object {
        $Sel = $_
        $SWMiner = $(vars).Miners | Where-Object Path -EQ $Sel.path | Where-Object Arguments -EQ $Sel.Arguments | Where-Object Type -EQ $Sel.Type 
        if ($SWMiner -and $SWMiner.Profit -ne $NULL -and $SWMiner.Profit -ne "bench") {
            if ($(arg).Switch_Threshold) {
                log "Switching_Threshold changes $($SWMiner.Name) $($SWMiner.Algo) base factored price from $(($SWMiner.Profit * $(vars).Rates.$($(arg).Currency)).ToString("N2"))" -ForegroundColor Cyan -NoNewLine -Start; 
                if ($SWMiner.Profit -GT 0) {
                    $($(vars).Miners | Where Path -eq $SWMiner.path | Where Arguments -eq $SWMiner.Arguments | Where Type -eq $SWMINer.Type).Profit = [Decimal]$SWMiner.Profit * (1 + ($(arg).Switch_Threshold / 100)) 
                }
                else {
                    $($(vars).Miners | Where Path -eq $SWMiner.path | Where Arguments -eq $SWMiner.Arguments | Where Type -eq $SWMINer.Type).Profit = [Decimal]$SWMiner.Profit * (1 + ($(arg).Switch_Threshold / -100))
                }  
                log " to $(($SWMiner.Profit * $(vars).Rates.$($(arg).Currency)).ToString("N2"))" -ForegroundColor Cyan -End
            }
        }
    }
}