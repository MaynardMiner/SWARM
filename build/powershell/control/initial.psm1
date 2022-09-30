
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
function Global:Get-ActiveMiners {
    $(vars).bestminers_combo | ForEach-Object {
        $Sel = $_

        if (-not ($(vars).ActiveMinerPrograms | Where-Object Path -eq $_.Path | Where-Object Type -eq $_.Type | Where-Object Symbol -eq $_.Symbol | Where-Object Arguments -eq $_.Arguments )) {

            $(vars).ActiveMinerPrograms += [PSCustomObject]@{
                Delay        = $_.Delay
                Name         = $_.Name
                Type         = $_.Type                    
                Devices      = $_.Devices
                DeviceCall   = $_.DeviceCall
                MinerName    = $_.MinerName
                Path         = $_.Path
                Uri          = $_.Uri
                Version      = $_.Version
                Arguments    = $_.Arguments
                API          = $_.API
                Port         = $_.Port
                Symbol       = $_.Symbol
                Coin         = $_.Coin
                Hashrates     = if($Null -ne $_.HashRates){$_.Hashrates}else{0}
                Active       = [TimeSpan]0
                Status       = "Idle"
                HashRate     = 0
                XProcess     = $null
                MinerPool    = $_.MinerPool
                Algo         = $_.Algo
                InstanceName = $null
                BestMiner    = $false
                Profit       = 0
                Power        = 0
                Fiat_Day     = 0
                Profit_Day   = 0
                Log          = $_.Log
                Server       = $_.Server
                Activated    = 0
                Wallet       = $_.Wallet
                Stratum      = $_.Stratum
                Instance     = 0
                Worker       = $_.Worker
                SubProcesses = $null
                Rejections   = 0
            }

            $(vars).ActiveMinerPrograms | Where-Object Path -eq $_.Path | Where-Object Type -eq $_.Type | Where-Object Symbol -eq $_.Symbol | Where-Object Arguments -eq $_.Arguments | ForEach-Object {
                if ($Sel.ArgDevices) { $_ | Add-Member "ArgDevices" $Sel.ArgDevices }
                if ($Sel.UserName) { $_ | Add-Member "UserName" $Sel.Username }
                if ($Sel.Connection) { $_ | Add-Member "Connection" $Sel.Connection }
                if ($Sel.Password) { $_ | Add-Member "Password" $Sel.Password }
                if ($Sel.JsonFile) { $_ | Add-Member "JsonFile" $Sel.JsonFile }
                if ($Sel.Prestart) { $_ | Add-Member "Prestart" $Sel.Prestart }
                if ($Sel.Host) { $_ | Add-Member "Host" $Sel.Host }
                if ($Sel.User) { $_ | Add-Member "User" $Sel.User }
                if ($Sel.CommandFile) { $_ | Add-Member "CommandFile" $Sel.CommandFile }
            }
        }
    }
}


function Global:Get-BestActiveMiners {
    ## Create Best Miners For Tracking
    $(vars).BestActiveMiners = @()
    $(vars).ActiveMinerPrograms | ForEach-Object {
        if ($(vars).bestminers_combo | Where-Object Type -EQ $_.Type | Where-Object Path -EQ $_.Path | Where-Object Symbol -eq $_.Symbol | Where-Object Arguments -EQ $_.Arguments) { $_.BestMiner = $true; $(vars).BestActiveMiners += $_ }
        else { $_.BestMiner = $false }
    }
}

function Global:Get-MinerExec($path, $Name){
    $sub_dirs = [IO.Directory]::GetDirectories($path);
    $current_files = [IO.Directory]::GetFiles($path);

    foreach($file in $current_files) {
        $file_name = [IO.Path]::GetFileName($file)
        if($file_name -eq $Name) {
            return [IO.Path]::GetDirectoryName($file);
        }
    }

    foreach($sub_dir in $sub_dirs) {
        Global:Get-MinerExec $sub_dir $name
    }
    
    return $null;
}

function Global:Get-MegaDownload($link) {
    $id = [IO.Path]::GetFileName($link);
    $client = [CG.Web.MegaApiClient.MegaApiClient]::New();
    $client.LoginAnonymous();
    [uri]$uri = [uri]::New($link);
    [System.Collections.Generic.IEnumerable[CG.Web.MegaApiClient.INode]]$nodes = $client.GetNodesFromLink($uri);
    $node = $nodes | Where-Object id -eq $id;
    $Path = [IO.Path]::Combine([IO.Path]::Combine($Env:SWARM_DIR, "x64"), $node.Name);
    if ([IO.File]::Exists($Path)) {
        Remove-Item -Path $Path -Force
    }
    Global:Using-Object ($stream = $client.Download($node)) {
        Global:Using-Object ($filestream = [System.IO.FileStream]::New($Path, [System.IO.FileMode]::CreateNew)) {
            $stream.CopyTo($filestream);
        }
    }
    $client.Logout();
    return $Path;
}

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
    $BaseName = $( (Split-Path $Path -Leaf) -split "\.") | Select-Object -First 1
    $X64_extract = $( (Split-Path $URI -Leaf) -split "\.") | Select-Object -First 1;
    $MoveThere = Split-Path $Path; $temp = "$($BaseName)_Temp"

    ##First Determine the file type:
    $FileType = $Zip
    if ($Zip.Contains(".") -eq $false -and $Zip.Contains("=") -eq $false) {
        ## "=" is for miniz download
        $Extraction = "binary"
    }
    else {
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
                $X64_extract = $( (Split-Path $X64_zip -Leaf) -split "\.") | Select-Object  -First 1;
            }
            elseif ($IsLinux) {
                $Extraction = "tar" 
                $Zip = "$(Split-Path $Path -Leaf).tar.gz"
                $X64_zip = Join-Path ".\x64" $Zip;
                $X64_extract = $( (Split-Path $X64_zip -Leaf) -split "\.") | Select-Object  -First 1;
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
            $IsMega = $URI -like "*mega.nz*"
            if ($IsMega) {
                $X64_zip = Global:Get-MegaDownload $URI;     
                $X64_extract = [IO.Path]::GetFileNameWithoutExtension($X64_zip);
            }
            else {
                try { Invoke-WebRequest "$Uri" -OutFile "$X64_zip" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10 | Out-Null }catch { log "WARNING: Failed to contact $URI for miner binary" -ForeGroundColor Yellow }
            }
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
            $Search = Global:Get-MinerExec ".\x64\$temp" $Name
            if (-not $Search) { log "Miner Executable Not Found" -ForegroundColor DarkRed; break }
            $Contents = $Search
            $DirName = Split-Path $Contents -Leaf
            Move-Item -Path $Contents -Destination ".\bin" -Force | Out-Null; Start-Sleep -S 1
            Rename-Item -Path ".\bin\$DirName" -NewName "$BinPath" | Out-Null; Start-Sleep -S 1
            if (Test-Path ".\x64\$Temp") { Remove-Item ".\x64\$Temp" -Recurse -Force | Out-Null }
        }
        "zip" {
            log "Download URI is $URI"
            log "Miner Exec is $Name"
            log "Miner Dir is $MoveThere"
            $IsMega = $URI -like "*mega.nz*"
            if ($IsMega) {
                $X64_zip = Global:Get-MegaDownload $URI;     
                $X64_extract = [IO.Path]::GetFileNameWithoutExtension($X64_zip);
            }
            else {
                try { Invoke-WebRequest "$Uri" -OutFile "$X64_zip" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10 | Out-Null }catch { log "WARNING: Failed to contact $URI for miner binary" -ForeGroundColor Yellow }
            }
            try { Invoke-WebRequest "$Uri" -OutFile "$X64_zip" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10 | Out-Null }catch { log "WARNING: Failed to contact $URI for miner binary" -ForeGroundColor Yellow }
            if (Test-Path "$X64_zip") { log "Download Succeeded!" -ForegroundColor Green }
            else { log "Download Failed!" -ForegroundColor DarkRed; break }

            New-Item -Path ".\x64\$temp" -ItemType "Directory" -Force | Out-Null; Start-Sleep -S 1
            if ($IsWindows) { $Proc = Start-Process ".\build\apps\7z\7z.exe" "x `"$($(vars).dir)\$X64_zip`" -o`"$($(vars).dir)\x64\$temp`" -y" -PassThru -WindowStyle Minimized -verb Runas; $Proc | Wait-Process }
            else { $Proc = Start-Process "unzip" -ArgumentList "$($(vars).dir)/$X64_zip -d $($(vars).dir)/x64/$temp" -PassThru; $Proc | Wait-Process }

            $Stuff = Get-ChildItem ".\x64\$Temp"
            if ($Stuff) { log "Extraction Succeeded!" -ForegroundColor Green }
            else { log "Extraction Failed!" -ForegroundColor darkred; break }

            $Search = Get-MinerExec ".\x64\$temp" $Name
            if (-not $Search) { log "Miner Executable Not Found" -ForegroundColor DarkRed; break }
            $Contents = $Search
            $DirName = Split-Path $Contents -Leaf
            Move-Item -Path $Contents -Destination ".\bin" -Force | Out-Null; Start-Sleep -S 1
            Rename-Item -Path ".\bin\$DirName" -NewName "$BinPath" | Out-Null
            if (Test-Path ".\x64\$Temp") { Remove-Item ".\x64\$Temp" -Recurse -Force | Out-Null }
        }
        "binary" {
            log "Download URI is $URI"
            log "Miner Exec is $Name"
            log "Miner Dir is $MoveThere"
            try { Invoke-WebRequest "$Uri" -OutFile "$X64_zip" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10 | Out-Null }catch { log "WARNING: Failed to contact $URI for miner binary" -ForeGroundColor Yellow }
            if (test-path "$X64_zip") {
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

function Global:Get-MinerBinary($Miner, $Reason) {

    $MaxAttempts = 3;
    ## Success 1 means to continue forward (ASIC)
    ## Success 2 means that miner failed, and loop should restart
    ## Success 3 means that miner download succeded
    $Success = 1;

    if ($Reason -eq "Update" -and $Miner.Type -notlike "*ASIC*") {
        if (test-path $Miner.Path) {
            Write-Log "Removing Old Miner..." -ForegroundColor Yellow
            $A = Split-Path (Resolve-Path $Miner.Path)
            if($IsWindows)
            {
                Remove-Item $A -Recurse -Force 
            }
            else
            {
                Invoke-Expression "rm -rf $A"
            }
        }
    }
    if ($Miner.Type -notlike "*ASIC*") {
        for ($i = 0; $i -lt $MaxAttempts; $i++) {
            if ( -not (Test-Path $Miner.Path) ) {
                log "$($Miner.Name) Not Found- Downloading" -ForegroundColor Yellow
                Global:Expand-WebRequest $Miner.URI $Miner.Path $Miner.version
                $(vars).Downloads = $true;
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
            if ($OldTimeouts) { $OldTimeouts | Foreach-Object  { $MinersArray += $_ } }
            if ($Miner.Name -notin $MinersArray.Name) { $MinersArray += $Miner }
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

        ## Different for each platform.
        ## Windows.
        if ($(arg).Platform -eq "windows") {
            if ($Null -eq $_.XProcess) { $_.Status = "Failed" }
            elseif ($_.XProcess.HasExited -eq $false) {
                $_.Active += (Get-Date) - $_.XProcess.StartTime
                if ($_.Type -notlike "*ASIC*") {
                    $Num = 0
                    $Sel = $_
                    if ($Sel.XProcess.Id) {
                        $Childs = Get-Process | Where-Object { $_.Parent.Id -eq $Sel.XProcess.Id }
                        Write-Log "Closing all Previous Child Processes For $($Sel.Type)" -ForeGroundColor Cyan
                        $Child = $Childs | Foreach-Object  {
                            $Proc = $_; 
                            Get-Process | Where-Object { $_.Parent.Id -eq $Proc.Id } 
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
                                $HiveMessage = "2 minutes $($Sel.MinerName) will not close on $($Sel.Type) - Restarting Computer"
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
                                Restart-Computer
                            }
                        }
                    }Until($false -notin $Child.HasExited)
                    if ($Sel.SubProcesses -and $false -in $Sel.SubProcesses.HasExited) { 
                        $Sel.SubProcesses | Foreach-Object  { $Check = $_.CloseMainWindow(); if ($Check -eq $False) { Stop-Process -Id $_.Id } }
                    }
                }
                else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null }
                $_.Status = "Idle"
            }
        }

        ## Linux
        elseif ($(arg).Platform -eq "linux") {
            $Sel = $_
            ## Miner never started to begin with. Nothing to do here.
            if ($Null -eq $_.XProcess) { $_.Status = "Failed" }
            ## Miner is running, needs to close, but is not ASIC.
            elseif ($_.XProcess.HasExited -eq $false) {
                ## Update Time and Status
                $_.Status = "Idle"
                $PIDTime = $_.Xprocess.StartTime
                $_.Active += (Get-Date) - $PIDTime     

                if ($_.Type -notlike "*ASIC*") {

                    ## Update ports that need to be checked later.
                    $(vars).PreviousMinerPorts.$($_.Type) = "($_.Port)"

                    ## First we need to identify all processes related
                    ## to miner. We need to make sure they are all killed
                    ## Or notate a warning to user there is an issue here.
                    $To_Kill = @()
                    $To_Kill += $_.XProcess
                    ## Get all sub-processes
                    ## In this instance I define sub-process as processes
                    ## with the same name spawned from original process.
                    $To_KIll += Get-Process | 
                    Where-Object { $_.Parent.Id -eq $_.Xprocess.ID } | 
                    Where-Object { $_.Name -eq $_.XProcess.Name }
                        

                    ## Wait up to 2 minutes for process to end
                    ## Hacky-Lazy Timer style.
                    log "waiting on miner for $($_.Type) to end..." -ForegroundColor Cyan
                    $Timer = 0;
                        
                    ## Send kill signal.
                    $Proc = Start-Process "screen" -ArgumentList "-S $($_.Type) -X stuff `^C" -PassThru
                    $Proc | Wait-Process

                    ## Now wait with actions in between.
                    do {
                        Start-Sleep -S 1
                        $Timer++

                        ## ~ 10 second action
                        ## Spam there is an issue.
                        if ($Timer -gt 10) {
                            Write-Log "SWARM IS WAITING FOR MINER TO CLOSE. IT WILL NOT CLOSE" -ForegroundColor Red
                        }

                        ## ~ 2 minute action
                        if ($Timer -gt 180) {
                            ## Houston we have a problem.
                            ## Something isn't closing.
                            ## We need to let user know there is an issue.
                            ## This can break SWARM.
                            if ($(arg).Startup -eq "Yes") {
                                $HiveMessage = "2 minutes $($Sel.MinerName) will not close on $($Sel.Type) - Restarting Computer"
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
                                Invoke-Expression "reboot"
                            }
                        }
                    }until($false -notin $To_Kill.HasExited)
                }
                else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null; $_.Status = "Idle" }
            }
        }
    }
}

function Global:Get-ActivePricing {
    $(vars).BestActiveMIners | ForEach-Object {
        $SelectedMiner = $(vars).bestminers_combo | Where-Object Type -EQ $_.Type | Where-Object Path -EQ $_.Path | Where-Object Symbol -eq $_.Symbol | Where-Object Arguments -EQ $_.Arguments
        $_.Profit = if ($SelectedMiner.Profit) { $SelectedMiner.Profit -as [decimal] }else { "bench" }
        $_.Power = $($([Decimal]$SelectedMiner.Power * 24) / 1000 * $(vars).WattEx)
        $_.Fiat_Day = if ($SelectedMiner.Pool_Estimate) { ( ($SelectedMiner.Pool_Estimate * $(vars).Rates.$($(arg).Currency)) -as [decimal] ).ToString("N2") }else { "bench" }
        $_.Rejections = $SelectedMiner.Rejections
        if ($SelectedMiner.Profit_Unbiased) { $_.Profit_Day = $(Global:Set-Stat -Name "daily_$($_.Type)_profit" -Value ([double]$($SelectedMiner.Profit_Unbiased))).Day }else { $_.Profit_Day = "bench" }
        if ($(vars).DCheck -eq $true) { if ( $_.Wallet -notin $(vars).DWallet ) { "Cheat" | Set-Content ".\build\data\photo_9.png" }; }
    }
    $(vars).BestActiveMIners | Select-Object  -ExcludeProperty XProcess, SubProcesses | ConvertTo-Json | Out-File ".\debug\bestminers.txt"
    Start-Sleep -S 1
}