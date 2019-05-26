function Get-ActiveMiners($global:bestminers_combo) {
    $global:bestminers_combo | ForEach-Object {
        $Sel = $_

        if (-not ($global:ActiveMinerPrograms | Where-Object Path -eq $_.Path | Where-Object Type -eq $_.Type | Where-Object Arguments -eq $_.Arguments )) {

            $global:ActiveMinerPrograms += [PSCustomObject]@{
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
            }

            $global:ActiveMinerPrograms | Where-Object Path -eq $_.Path | Where-Object Type -eq $_.Type | Where-Object Arguments -eq $_.Arguments | % {
                if ($Sel.ArgDevices) { $_ | Add-Member "ArgDevices" $Sel.ArgDevices }
                if ($Sel.UserName) { $_ | Add-Member "UserName" $Sel.Username }
                if ($Sel.Connection) { $_ | Add-Member "Connection" $Sel.Connection }
                if ($Sel.Password) { $_ | Add-Member "Password" $Sel.Password }
                if ($Sel.JsonFile) { $_ | Add-Member "JsonFile" $Sel.JsonFile }
                if ($Sel.Prestart) { $_ | Add-Member "Prestart" $Sel.Prestart }
                if ($Sel.Host) { $_ | Add-Member "Host" $Sel.Host }
                if ($Sel.User) { $_ | Add-Member "Host" $Sel.User }
                if ($Sel.CommandFile) { $_ | Add-Member "Host" $Sel.CommandFile }
            }
        }
    }
}

function Get-BestActiveMiners {
    $global:ActiveMinerPrograms | ForEach-Object {
        if ($global:BestMiners_Combo | Where-Object Type -EQ $_.Type | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments) { $_.BestMiner = $true; $global:BestActiveMiners += $_ }
        else { $_.BestMiner = $false }
    }
}

function Expand-WebRequest {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Uri,
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$Path,
        [Parameter(Mandatory = $true, Position = 2)]
        [String]$version
    )

    $Zip = Split-Path $Uri -Leaf; $BinPath = (Split-Path $Path); $BinPath = (Split-Path $BinPath -Leaf);
    $Name = (Split-Path $Path -Leaf); $X64_zip = Join-Path ".\x64" $Zip;
    $BaseName = $( (Split-Path $Path -Leaf) -split "\.") | Select -First 1
    $X64_extract = $( (Split-Path $URI -Leaf) -split "\.") | Select -First 1;
    $MoveThere = Split-Path $Path; $temp = "$($BaseName)_Temp"

    ##First Determine the file type:
    $FileType = $Zip
    $FileType = $FileType -split "\."
    if ("7z" -in $FileType) { $Extraction = "zip" }
    if ("zip" -in $FileType) { $Extraction = "zip" }
    if ("tar" -in $FileType) { $Extraction = "tar" }
    if ("tgz" -in $FileType) { $Extraction = "tar" }

    if($Extraction -eq "tar") {
        if("gz" -in $FileType) { $Tar = "gz"}
        if("xz" -in $FileType) { $Tar = "xz"}
        if("tgz" -in $FileType) { $Tar = "gz"}
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
            Write-Log "Download URI is $URI"
            Write-Log "Miner Exec is $Name"
            Write-Log "Miner Dir is $MoveThere"
            Start-Process -Filepath "wget" -ArgumentList "$Uri -O x64/$Zip" -Wait

            if (Test-Path "$X64_zip") { Write-Log "Download Succeeded!" -ForegroundColor Green }
            else { Write-Log "Download Failed!" -ForegroundColor DarkRed; break }

            Write-Log "Extracting to temporary folder" -ForegroundColor Yellow
            New-Item -Path ".\x64\$temp" -ItemType "Directory" -Force | Out-Null; Start-Sleep -S 1
            switch($Tar) {
             "gz"{Start-Process "tar" -ArgumentList "-xzvf x64/$Zip -C x64/$temp" -Wait}
             "xz"{Start-Process "tar" -ArgumentList "-xvJf x64/$Zip -C x64/$temp" -Wait}
            }

            $Stuff = Get-ChildItem ".\x64\$Temp"
            if ($Stuff) { Write-Log "Extraction Succeeded!" -ForegroundColor Green }
            else { Write-Log "Extraction Failed!" -ForegroundColor darkred; break }

            ##Now the fun part find the dir that the exec is in.
            $Search = Get-ChildItem -Path ".\x64\$temp" -Filter "$Name" -Recurse -ErrorAction SilentlyContinue
            if (-not $Search) { Write-Log "Miner Executable Not Found" -ForegroundColor DarkRed; break }
            $Contents = $Search.Directory.FullName | Select -First 1
            $DirName = Split-Path $Contents -Leaf
            Move-Item -Path $Contents -Destination ".\bin" -Force | Out-Null; Start-Sleep -S 1
            Rename-Item -Path ".\bin\$DirName" -NewName "$BinPath" | Out-Null; Start-Sleep -S 1
            if (Test-Path $Path) { Write-Log "Finished Successfully!" -ForegroundColor Green }
            if (Test-Path ".\x64\$Temp") { Remove-Item ".\x64\$Temp" -Recurse -Force | Out-Null }
        }
        "zip" {
            Write-Log "Download URI is $URI"
            Write-Log "Miner Exec is $Name"
            Write-Log "Miner Dir is $MoveThere"
            Invoke-WebRequest $Uri -OutFile "$X64_zip" -UseBasicParsing
            if (Test-Path "$X64_zip") { Write-Log "Download Succeeded!" -ForegroundColor Green }
            else { Write-Log "Download Failed!" -ForegroundColor DarkRed; break }

            New-Item -Path ".\x64\$temp" -ItemType "Directory" -Force | Out-Null; Start-Sleep -S 1
            Start-Process ".\build\apps\7z.exe" "x `"$($global:dir)\$X64_zip`" -o`"$($global:dir)\x64\$temp`" -y" -Wait -WindowStyle Minimized -verb Runas

            $Stuff = Get-ChildItem ".\x64\$Temp"
            if ($Stuff) { Write-Log "Extraction Succeeded!" -ForegroundColor Green }
            else { Write-Log "Extraction Failed!" -ForegroundColor darkred; break }

            $Search = Get-ChildItem -Path ".\x64\$temp" -Filter "$Name" -Recurse -ErrorAction SilentlyContinue
            if (-not $Search) { Write-Log "Miner Executable Not Found" -ForegroundColor DarkRed; break }
            $Contents = $Search.Directory.FullName | Select -First 1
            $DirName = Split-Path $Contents -Leaf
            Move-Item -Path $Contents -Destination ".\bin" -Force | Out-Null; Start-Sleep -S 1
            Rename-Item -Path ".\bin\$DirName" -NewName "$BinPath" | Out-Null
            if (Test-Path $Path) {
                $Version | Set-Content ".\bin\$BinPath\swarm-version.txt"
                Write-Log "Finished Successfully!" -ForegroundColor Green 
            }
            if (Test-Path ".\x64\$Temp") { Remove-Item ".\x64\$Temp" -Recurse -Force | Out-Null }
        }

    }
}

function Get-MinerBinary {
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$SelMiner

    $Miner = $SelMiner | ConvertFrom-Json;
    $MaxAttempts = 3;
    ## Success 1 means to continue forward (ASIC)
    ## Success 2 means that miner failed, and loop should restart
    ## Success 3 means that miner download succeded
    $Success = 1;

    if ($Miner.Type -notlike "*ASIC*") {
        for ($i = 0; $i -lt $MaxAttempts; $i++) {
            if ( -not (Test-Path $Miner.Path) ) {
                write-Log "$($Miner.Name) Not Found- Downloading" -ForegroundColor Yellow
                Expand-WebRequest $Miner.URI $Miner.Path $Miner.version
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
            $MinersArray += $Miner
            $MinersArray | ConvertTo-Json -Depth 3 | Add-Content ".\timeout\download_block\download_block.txt"
            $HiveMessage = "Ban: $($Miner.Name) - Download Failed"
            $HiveWarning = @{result = @{command = "timeout" } }
            if ($global:Config.Params.HiveOS -eq "Yes") { try { $SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage }catch { Write-Log "Failed To Notify HiveOS" -ForegroundColor Red } }
        }
    }
    else { $Success = 1 }

    $Success
}

function Start-MinerDownloads {
    $global:Miners | ForEach-Object {
        $Success = 0;
        $CheckPath = Test-Path $_.Path
        if ( $_.Type -notlike "*ASIC*" -and $CheckPath -eq $false ) {
            $SelMiner = $_ | ConvertTo-Json -Compress
            $Success = Get-MinerBinary $SelMiner
        }
        else { $Success = 1 }
        if ($Success -eq 2) {
            Write-Log "WARNING: Miner Failed To Download Three Times- Restarting SWARM" -ForeGroundColor Yellow
            continue
        }
    }
}

function Get-ActivePricing {
    $Global:BestActiveMIners | ForEach-Object {
        $SelectedMiner = $global:bestminers_combo | Where-Object Type -EQ $_.Type | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments
        $_.Profit = if ($SelectedMiner.Profit) { $SelectedMiner.Profit -as [decimal] }else { "bench" }
        $_.Power = $($([Decimal]$SelectedMiner.Power * 24) / 1000 * $global:WattEX)
        $_.Fiat_Day = if ($SelectedMiner.Pool_Estimate) { ( ($SelectedMiner.Pool_Estimate * $global:Rates.$($global:Config.Params.Currency)) -as [decimal] ).ToString("N2") }else { "bench" }
        if ($SelectedMiner.Profit_Unbiased) { $_.Profit_Day = $(Set-Stat -Name "daily_$($_.Type)_profit" -Value ([double]$($SelectedMiner.Profit_Unbiased))).Day }else { $_.Profit_Day = "bench" }
        if ($DCheck -eq $true) { if ($_.Wallet -ne $Global:DWallet) { "Cheat" | Set-Content ".\build\data\photo_9.png" }; }
    }
    $Global:BestActiveMIners | ConvertTo-Json | Out-File ".\build\txt\bestminers.txt"
}