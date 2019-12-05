function Global:Invoke-MinerCheck {

    ##Bool for Current Miners
    $Switched = $false
    
    ##Determine if Miner Switched
    $CheckForMiners = ".\debug\bestminers.txt"
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
            $global:CPUOnly = $false; "GPU" | Set-Content ".\debug\miner.txt"
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
            $diskSpace = try { Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop | Select-Object Freespace } catch { Write-Host "Failed To Get disk info" -ForegroundColor Red; 0 }
            $diskSpace = $diskSpace.Freespace / [math]::pow( 1024, 3 )
            $diskSpace = [math]::Round($diskSpace)
            $global:diskSpace = "$($diskSpace)G"
            $global:ramtotal = Get-Content ".\debug\ram.txt" | Select-Object -First 1
            $global:ramfree = try { [math]::Round((Get-Ciminstance Win32_OperatingSystem -ErrorAction Stop | Select FreePhysicalMemory).FreePhysicalMemory / 1kb, 2) } catch { Write-Host "Failed To Get RAM Size" -ForegroundColor Red, 0 }

            ## LOAD AVERAGE NOTES FOR WINDOWS:
            ## We use an exponentially weighted moving average, just like Unix systems do
            ## https://en.wikipedia.org/wiki/Load_(computing)#Unix-style_load_calculation
            ##
            ## These constants serve as the damping factor and are calculated with
            ## 1 / exp(sampling interval in seconds / window size in seconds)
            ##
            ## This formula comes from linux's include/linux/sched/loadavg.h
            ## https://github.com/torvalds/linux/blob/345671ea0f9258f410eb057b9ced9cefbbe5dc78/include/linux/sched/loadavg.h#L20-L23

            ## https://documentation.solarwindsmsp.com/remote-management/helpcontents/processorqueuelength.htm
            ## 'A bottleneck on the processor may be thought to occur where the number of threads in the queue is more than 2 times the
            ## number of processor cores over a continuous period.'
            ## Therefor to match linux a Processor Queue Length of 2 = 1 LA in linux for a single core processor.
            ## 8 = 4 LA in Linux for a quad core processor, etc.

            [Decimal]$LOADAVG_FACTOR_1F = 0.9200444146293232478931553241
            [Decimal]$LOADAVG_FACTOR_5F = 0.6592406302004437462547604110
            [Decimal]$LOADAVG_FACTOR_15F = 0.2865047968601901003248854266
            $Length = 0
            $CPU = [Decimal[]](Get-CimInstance -className Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength
            $Length += $($CPU | Measure-Object -Sum).Sum
            ## Divide by 2 (2 x Cores = bottlenecking)
            if($Length -gt 0){ $Length = $Length / 2}
            ## Force a value if 0 (Just to let user know it is working)
            if($Length -eq 0){ $Length = 0.01 }
            $Global:load_avg_1m = [math]::Round($global:load_avg_1m * $LOADAVG_FACTOR_1F + $Length * (1.0 - $LOADAVG_FACTOR_1F), 2)
            $global:load_avg_5m = [math]::Round($global:load_avg_5m * $LOADAVG_FACTOR_5F + $Length * (1.0 - $LOADAVG_FACTOR_5F), 2)
            $global:load_avg_15m = [math]::Round($global:load_avg_15m * $LOADAVG_FACTOR_15F + $Length * (1.0 - $LOADAVG_FACTOR_15F), 2)
            Write-Host "CPU Load Averages- 1m: $Global:load_avg_1m, 5m: $global:load_avg_5m, 15m: $global:load_avg_15m" -ForegroundColor Yellow
        }
    }
}
