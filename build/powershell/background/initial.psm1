function Global:Invoke-MinerCheck {

    ##Bool for Current Miners
    $Switched = $false
    
    ##Determine if Miner Switched
    $CheckForMiners = ".\build\txt\bestminers.txt"
    if (Test-Path $CheckForMiners) { $global:GetMiners = Get-Content $CheckForMiners | ConvertFrom-Json -ErrorAction Stop }
    else { Write-Host "No Miners Running..." }
    if ($global:GETSWARM.HasExited -eq $true) { Write-Host "SWARM Has Exited..."; }

    ##Handle New Miners
    if ($global:GetMiners -and $global:GETSWARM.HasExited -eq $false) {
        $global:GetMiners | ForEach-Object { if (-not ($global:CurrentMiners | Where-Object Path -eq $_.Path | Where-Object Arguments -eq $_.Arguments )) { $Switched = $true } }
        if ($Switched -eq $True) {
            Write-Host "Miners Have Switched `n" -ForegroundColor Cyan
            $global:CurrentMiners = $global:GetMiners;
            $global:StartTime = Get-Date
        }
    }
        
    ## Determine if CPU in only used. Set Flags for what to do.
    $global:CurrentMiners | ForEach-Object {
        if ($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*" -or $_.Type -like "*ASIC*") {
            $global:CPUOnly = $false; "GPU" | Set-Content ".\build\txt\miner.txt"
        }
        if ($_.Type -like "*NVIDIA*") {
            $global:DoNVIDIA = $true
        }
        if ($_.Type -like "*AMD*") {
            $global:DoAMD = $true
        }
        if ($_.Type -eq "CPU") {
            $global:DoCPU = $true
        }
        if ($_.Type -like "*ASIC*") {
            $global:DoASIC = $true
        }
    }    
}


function Global:New-StatTables {

    ## Build All Initial Global Value
    if ($global:DoAMD -or $global:DoNVIDIA) {
        $global:GPUHashrates = [PSCustomObject]@{ }; $global:GPUHashTable = @();             
        $global:GPUFans = [PSCustomObject]@{ }; $global:GPUTemps = [PSCustomObject]@{ }; 
        $global:GPUPower = [PSCustomObject]@{ }; $global:GPUFanTable = @();              
        $global:GPUTempTable = @(); $global:GPUPowerTable = @();                
        $global:GPUKHS = 0;
    }
    
    if ($global:DoCPU) {
        $global:CPUHashrates = [PSCustomObject]@{ }; $global:CPUHashTable = @(); 
        $global:CPUKHS = 0;
    }

    if ($global:DoASIC) {
        $global:ASICHashrates = [PSCustomObject]@{ }; $global:ASICHashTable = @(); 
        $global:ASICKHS = 0;
    }

    ##Start Adding Zeros
    if ($global:DoAMD -or $global:DoNVIDIA) {
        if ($global:DoAMD) {
            for ($i = 0; $i -lt $(vars).GCount.AMD.PSObject.Properties.Value.Count; $i++) {
                $global:GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.AMD.$i)" -Value 0; 
                $global:GPUFans | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.AMD.$i)" -Value 0; 
                $global:GPUTemps | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.AMD.$i)" -Value 0; 
                $global:GPUPower | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.AMD.$i)" -Value 0
            }
        }
        if ($global:DoNVIDIA) {
            for ($i = 0; $i -lt $(vars).GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
                $global:GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.NVIDIA.$i)" -Value 0; 
                $global:GPUFans | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.NVIDIA.$i)" -Value 0; 
                $global:GPUTemps | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.NVIDIA.$i)" -Value 0; 
                $global:GPUPower | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.NVIDIA.$i)" -Value 0    
            }
        }
    }
    
    if ($global:DoCPU) {
        for ($i = 0; $i -lt $(vars).GCount.CPU.PSObject.Properties.Value.Count; $i++) {
            $global:CPUHashrates | Add-Member -MemberType NoteProperty -Name "$($(vars).GCount.CPU.$i)" -Value 0; 
        }
    }
    if ($global:DoASIC) { 
        $ASICS = $global:CurrentMiners.Type | Where { $_ -like "*ASIC*" }
        for ($i = 0; $i -lt $ASICS.Count; $i++) {
            $global:ASICHashRates | Add-Member -MemberType NoteProperty -Name "$i" -Value 0; 
        }
    }
}
function Global:Get-Metrics {
    if ($IsWindows) {
        ## Rig Metrics
        if ($(arg).HiveOS -eq "Yes") {
            $diskSpace = try { Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop | Select-Object Freespace } catch {  Write-Host "Failed To Get disk info" -ForegroundColor Red; 0 }
            $diskSpace = $diskSpace.Freespace / [math]::pow( 1024, 3 )
            $diskSpace = [math]::Round($diskSpace)
            $global:diskSpace = "$($diskSpace)G"
            $global:ramtotal = Get-Content ".\build\txt\ram.txt" | Select-Object -First 1
            $Global:cpu = try { ((Get-CimInstance Win32_PerfFormattedData_PerfOS_System -ErrorAction Stop).ProcessorQueueLength) + 0.01 } catch { Write-Host "Failed To Get CPU load" -ForegroundColor Red; 0  }
            $LoadAverage = Global:Set-Stat -Name "load-average" -Value $Global:cpu
            $Global:LoadAverages = @("$([Math]::Round($LoadAverage.Minute,2))", "$([Math]::Round($LoadAverage.Minute_5,2))", "$([Math]::Round($LoadAverage.Minute_15,2))")
            $global:ramfree = try { [math]::Round((Get-Ciminstance Win32_OperatingSystem -ErrorAction Stop | Select FreePhysicalMemory).FreePhysicalMemory / 1kb, 2) } catch {Write-Host "Failed To Get RAM Size" -ForegroundColor Red, 0 }
        }
    }
}
