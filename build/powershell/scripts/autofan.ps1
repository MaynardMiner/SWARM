Using namespace System;
Using namespace System.Diagnostics

## A GPU on the bus
Class GPU {
    [String]$Model
    [Int]$Device_Number ## Actual Number On Rig. (Including Onboard)
    [Int]$Rig_Number ## HiveOS Rig Number
    [Int]$OC_Number  ## AMD slots include other model cards. NVIDIA Only Does NVIDIA cards.
    [String]$Bus_Id ## The Bus identifier
    [Int]$FanSpeed ## Current Fan Speed
    [int]$prev_fan ## previous speed
    [int]$pprev_fan ## previous speed
    [Double]$Deviation ## Suggested Adjustment
    [Int]$New_Speed ## New Fan Speed
    [Int]$cur_temp ## Current Temperature
    [int]$prev_temp ## last temp reading
    [String[]]$Errors ## Any errors that need to be addressed.

    GPU( [String]$Model, 
        [Int]$Device_Number, 
        [int]$Rig_Number, 
        [Int]$OC_Number, 
        [string]$Bus_Id
    ) {
        $this.Model = $Model
        $this.Device_Number = $Device_Number
        $this.Rig_Number = $Rig_Number
        $this.OC_Number = $OC_Number
        $this.Bus_Id = $Bus_Id
    }

    ## Moves Current Values To Old Values
    [void] Update($Temperature, $FanSpeed, $Critical) {
        $this.prev_temp = $this.cur_temp

        if ($Temperature -lt 120 -and $Temperature -gt 0) {
            $this.cur_temp = $Temperature
            if ($Temperature -gt $Critical) { $This.Errors += "Critical" }
        } 
        elseif ($Temperature -gt 120) { $This.Errors += "Unreal" }
        else { $this.Errors += "No Temp" }

        if ($FanSpeed -lt 101 -and $FanSpeed -gt -1) {
            $this.FanSpeed = $FanSpeed
        }
        else { $this.Errors += "No Speed" }

        $this.pprev_fan = $this.prev_fan
        $this.prev_fan = $this.FanSpeed
        $this.FanSpeed = $FanSpeed
    }
    
    [void] Set_Speed([hashtable]$config) {

        $speed = $this.FanSpeed
        ## Using original autofan = It works best
        ## The new version will overheat cards easily.
        if ($this.prev_temp -ne 0 -and $this.cur_temp -gt $Config.TARGET_TEMP) {
            if ($this.cur_temp -lt $this.prev_temp) {
                $this.Deviation = -1
            }
            elseif ($this.cur_temp -ge $this.prev_temp) {
                $this.Deviation = $this.cur_temp - $Config.TARGET_TEMP - 1
            }
        }
        elseif ($this.prev_temp -ne 0 -and $this.cur_temp -lt $Config.TARGET_TEMP) {
            if ($this.cur_temp -gt $this.prev_temp) {
                $this.Deviation = 1
                if (($this.cur_temp - 2) -gt $this.prev_temp) {
                    $this.Deviation = $this.cur_temp - $this.prev_temp
                }
            }
            elseif ($this.cur_temp -le $This.prev_temp) {
                $this.Deviation = $this.cur_temp - $Config.TARGET_TEMP + 1
            }
        }

        $speed = $this.FanSpeed + $this.Deviation

        if ($speed -gt $config.MAX_FAN) { $Speed = $config.MAX_FAN }
        if ($Speed -lt $config.MIN_FAN) { $Speed = $config.MIN_FAN }
        $this.New_Speed = $speed
    }

}

class RIG {
    [GPU[]]$GPUS ## All GPUS
    [String[]]$Models ## Quick reference of model list
    [bool]$IsMinerStopped = $false ## Bool to denote if miner stopped
    [hashtable]$Config = @{ } ## The current config.
    [String[]]$Websites
    [Stopwatch]$Timer = [Stopwatch]::New()

    RIG() {
        ## Set Websites
        $Path = [IO.Path]::Join($GLobal:Dir, "config\parameters\newarguments.json");
        $Params = cat $Path | ConvertFrom-Json;
        if ([string]$Params.Hive_Hash -ne "" -and [string]$Params.Hive_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") {
            $this.Websites += "HiveOS";
        }
        if ([string]$Params.SWARM_Hash -ne "" -and [string]$Params.SWARM_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") {
            $this.Websites += "SWARM";
        }
        $Path = [IO.Path]::Join($GLobal:Dir, "logs\autofan.log");
        Start-Transcript -Path $Path;

        ## Set Timer
        $This.Timer.Restart();

        ## Add GPUS
        $Path = [IO.Path]::Join($GLobal:Dir, "debug\hive_hello.txt")
        $GPU_List = $(cat $Path | ConvertFrom-Json).params.gpu
        $Path = [IO.Path]::Join($GLobal:Dir, "debug\oclist.txt")
        $GPU_OCList = cat $Path | ConvertFrom-Json
        $NVIDIA_Count = 0
        $AMD_Count = 0
        $Count = 0
        $GPU_List | % {
            $Sel = $_
            Switch ($Sel.Brand) {
                "nvidia" {
                    $this.GPUS += [GPU]::New($Sel.Brand, $NVIDIA_Count, $Count, $NVIDIA_Count, $Sel.busid) ## OC is same as Device Position
                    $NVIDIA_Count++
                    $Count++
                    if ("NVIDIA" -notin $this.Models) { $this.Models += "NVIDIA" }
                }
                "amd" {
                    $this.GPUS += [GPU]::New($Sel.Brand, $AMD_Count, $Count, $GPU_OCList.AMD.$AMD_Count, $Sel.busid) ## OC Number is Bus Position
                    $AMD_Count++
                    $Count++
                    if ("AMD" -notin $this.Models) { $this.Models += "AMD" }
                }
            }
        }

        ## Print Found GPUS
        $This.GPUS | % {
            Write-Host "GPU $($_.Rig_Number): $($_.Model), Slot Number $($_.Device_Number), $($_.Model) GPU Number $($_.OC_Number)"
        }
    }

    [void] Get_Config($path) {
        if (test-path $path) {
            $this.Config = @{ }
            $Content = Get-Content $Path | ConvertFrom-Json | ConvertFrom-StringData 
            foreach ($key in $Content.keys) {
                $this.Config.Add("$key", $Content.$key.Replace("`"", ""))
            }
        }

        if ("VERY_HIGH_TEMP" -notin $this.config.keys) {
            $this.Config.Add("VERY_HIGH_TEMP", $null)
        }

        if ("HIGH_TEMP" -notin $this.config.keys) {
            $this.Config.Add("HIGH_TEMP", $null)
        }

        if ("LOW_TEMP" -notin $this.config.keys) {
            $this.Config.Add("LOW_TEMP", $null)
        }

        if ("VERY_HIGH_FAN" -notin $this.config.keys) {
            $this.Config.Add("VERY_HIGH_FAN", $null)
        }
        
        if ("AUTO_SPEED" -notin $this.config.keys) {
            $this.Config.Add("AUTO_SPEED", $null)
        }
        
        ## Set defaults:
        if ([string]$this.Config.CRITICAL_TEMP -eq "") {
            $this.Config.CRITICAL_TEMP = 90
        }

        if ([string]$this.Config.CRITICAL_TEMP_ACTION -eq "") {
            $this.Config.CRITICAL_TEMP_ACTION = $null
        }

        if ([string]$this.Config.MIN_FAN -eq "") {
            $this.Config.MIN_FAN = 30
        }

        if ([string]$this.Config.MAX_FAN -eq "") {
            $this.Config.MAX_FAN = 100
        }

        if ([string]$this.Config.NO_AMD -eq "") {
            $this.Config.NO_AMD = 0
        }

        if ([string]$this.Config.REBOOT_ON_ERROR -eq "") {
            $this.Config.REBOOT_ON_ERROR = 0
        }

        if ([string]$this.Config.VERY_HIGH_TEMP -eq "") {
            $this.Config.VERY_HIGH_TEMP = $this.Config.TARGET_TEMP + 6
        }

        if ([string]$this.Config.VERY_HIGH_FAN -eq "") {
            $this.Config.VERY_HIGH_FAN = $this.Config.MAX_FAN - 10
        }

        if ([string]$this.Config.AUTO_SPEED -eq "") {
            $this.Config.AUTO_SPEED = 25
        }

        if ([string]$this.Config.HIGH_TEMP -eq "") {
            $this.Config.HIGH_TEMP = $this.Config.TARGET_TEMP + 1
        }

        if ([string]$this.Config.LOW_TEMP -eq "") {
            $this.Config.LOW_TEMP = $this.Config.TARGET_TEMP - 1
        }

    }

    [void] Log_Cleanup() {
        if ($This.Timer.Elapsed.TotalSeconds -ge 3600) {
            Write-Host ""
            Write-Host "Clearing AutoFan Log"
            Write-Host ""
            Stop-Transcript
            Start-Sleep -S 3
            $Path = [IO.Path]::Join($Global:DIR, "logs\autofan.log")
            Clear-Content $Path -Force
            Start-Sleep -S 3
            Start-Transcript -Path $Path
            $This.Timer.Restart()
        }
    }

    [void] Get_GPUData() {

        ## Reset errors if miner was just stopped
        $This.GPUS | % { [string[]]$_.Errors = @() }
        
        if ("NVIDIA" -in $This.Models) {
            $this.Get_NVIDIA()
        }
        if (
            "AMD" -in $This.Models -and
            $this.Config.NO_AMD -ne 1
        ) {
            $this.Get_AMD()
        }
    }

    [void] Get_NVIDIA() {
        $continue = $false
        $nvidiaout = @()
        try {
            $smi = [IO.Path]::Join($env:ProgramFiles, "NVIDIA Corporation\NVSMI\nvidia-smi.exe")
            $info = [System.Diagnostics.ProcessStartInfo]::new()
            $info.FileName = $smi
            $info.Arguments = "--query-gpu=gpu_bus_id,power.draw,fan.speed,temperature.gpu --format=csv"
            $info.UseShellExecute = $false
            $info.RedirectStandardOutput = $true
            $info.Verb = "runas"
            $Proc = [System.Diagnostics.Process]::New()
            $proc.StartInfo = $Info
            $ttimer = [System.Diagnostics.Stopwatch]::New()
            $ttimer.Restart();
            $proc.Start() | Out-Null
            while (-not $Proc.StandardOutput.EndOfStream) {
                $nvidiaout += $Proc.StandardOutput.ReadLine();
                if ($ttimer.Elapsed.Seconds -gt 15) {
                    $proc.kill() | Out-Null;
                    break;
                }
            }
            $Proc.Dispose();            
        }
        catch { Write-Host "WARNING: Failed to get nvidia stats" -ForegroundColor DarkRed }

        if ($nvidiaout) {
            $nvidiaout = $nvidiaout | ConvertFrom-Csv
            $Continue = $true
        }
        else {
            Write-Host "WARNING: Failed to get nvidia stats" -ForegroundColor DarkRed
        }

        if ($nvidiaout -and $continue -eq $true ) {
            $Stats = @()
            $nvidiaout | % {
                $Stats += @{ $($_.'pci.bus_id' -replace '00000000:', '') = @{
                        fan  = $( $_.'fan.speed [%]' -replace ' \%', '')
                        temp = $($_.'temperature.gpu')
                    }
                }
            }

            $This.GPUS | Where Model -eq "NVIDIA" | % {
                if ($Stats.$($_.Bus_Id)) {
                    $Speed = if ([int]$Stats.$($_.Bus_Id).temp) { [Int]$Stats.$($_.Bus_Id).fan } else { -1 };

                    $Temp = if ([int]$Stats.$($_.Bus_Id).temp) { [Int]$Stats.$($_.Bus_Id).temp } else { -1 };

                    $_.Update($Temp, $Speed, [int]$this.Config.CRITICAL_TEMP);
                }
                else { $_.Errors += "No Data" }
            }
        }
        else {
            $This.GPUS | Where Model -eq "NVIDIA" | % {
                $_.Errors += "No Data"
            }
        }
    }

    [void] Get_AMD() {
        if ($this.GPUS | Where model -eq "AMD") {
            $continue = $false
            $stats = @()
            try {
                if ([Environment]::Is64BitOperatingSystem) {
                    $odvii = [IO.Path]::Join($Global:Dir, "build\apps\odvii\odvii_x64.exe")
                } 
                else {
                    $odvii = [IO.Path]::Join($Global:Dir, "build\apps\odvii\odvii_x86.exe")
                }
                $info = [System.Diagnostics.ProcessStartInfo]::new()
                $info.FileName = $odvii
                $info.UseShellExecute = $false
                $info.RedirectStandardOutput = $true
                $info.Verb = "runas"
                $Proc = [System.Diagnostics.Process]::New()
                $proc.StartInfo = $Info
                $ttimer = [System.Diagnostics.Stopwatch]::New()
                $ttimer.Restart();
                $proc.Start() | Out-Null
                while (-not $Proc.StandardOutput.EndOfStream) {
                    $stats += $Proc.StandardOutput.ReadLine();
                    if ($ttimer.Elapsed.Seconds -gt 15) {
                        $proc.kill() | Out-Null;
                        break;
                    }
                }
                $Proc.Dispose();            
            }
            catch { Write-Host "WARNING: Failed to get amd stats" -ForegroundColor DarkRed }

            if ($stats) {
                $stats = $stats | ConvertFrom-Json
                $continue = $true
            }
            else {
                Write-Host "Failed To Get Gpu Data From OverdriveN API! Cannot Do OC For AMD!" -ForegroundColor Red;
            }

            if ($stats -and $continue -eq $true) {
                $Cards = $This.GPUS | Where Model -eq "AMD"

                ## First Check To Make Sure All Values Are There:
                $Temps = $stats | % { $_.Temperature }
                $Fans = $stats | % { $_.'Fan Speed %' }

                ## Add New Temperature Readings
                for ($i = 0; $i -lt $Cards.Count; $i++) {
                    $this.GPUS | Where model -eq "AMD" | Where Device_Number -eq $i | % {
                        $_.Update([Int]$Temps[$i], [Int]$fans[$i], [Int]$This.Config.CRITICAL_TEMP)
                    } 
                }
            }
            else {
                $This.GPUS | Where Model -eq "AMD" | % {
                    $_.Errors += "No Data"
                }
            }
        }
    }

    [void] Adjust() { 
        Write-Host ""
        Write-Host "Target Temperature is currently: $($this.Config.TARGET_TEMP)" -ForegroundColor Yellow
        if ("NVIDIA" -in $this.Models) { Write-Host "NVIDIA GPUS" -ForegroundColor Green }
        $this.GPUS | Where Model -eq "NVIDIA" | ForEach-Object {
            $_.Set_Speed($this.Config); 
            if ($_.New_Speed -ne $_.FanSpeed) {
                $FanArgs = "--index $($_.OC_Number) --speed $($_.New_Speed)"
                $Path = [IO.Path]::Join($Global:Dir, "build\apps\nvfans\nvfans.exe")
                $debug = [IO.Path]::Join($Global:Dir, "debug\nv_fan.txt")
                $Proc = Start-Process $Path -ArgumentList "$FanArgs" -NoNewWindow -PassThru -RedirectStandardOutput $debug
                $Proc | Wait-Process
            }
            Write-Host "GPU $($_.Rig_Number): " -NoNewLine
            Write-Host "Temp: $($_.cur_temp), " -ForegroundColor Red -NoNewline
            Write-Host "Fan Speed: $($_.FanSpeed), " -ForegroundColor Cyan -NoNewline 
            Write-Host "Change: $($_.New_Speed - $_.FanSpeed)%, " -ForegroundColor Yellow -NoNewline
            Write-Host "Actual New Fan Speed %: $($_.New_Speed)" -ForegroundColor Green -NoNewline
            Write-Host ""    
        }
        if ("AMD" -in $this.Models -and $this.Config.NO_AMD -ne 1) { Write-Host "AMD GPUS" -ForegroundColor Red }
        $this.GPUS | Where Model -eq "AMD" | ForEach-Object {
            if ($Config.NO_AMD -ne 1) {
                $_.Set_Speed($this.Config); 
                if ($_.New_Speed -ne $_.FanSpeed) {
                    $FanArgs = "-ac$($_.OC_Number) Fan_P0=80;$($_.New_Speed) Fan_P1=80;$($_.New_Speed) Fan_P2=80;$($_.New_Speed) Fan_P3=80;$($_.New_Speed) Fan_P4=80;$($_.New_Speed)"
                    $Path = [IO.Path]::Join($Global:Dir, "build\apps\overdriventool\OverdriveNTool.exe")
                    $Proc = Start-Process $Path -ArgumentList $FanArgs -PassThru -NoNewWindow
                    $Proc | Wait-Process
                }
                Write-Host "GPU $($_.Rig_Number): " -NoNewLine
                Write-Host "Temp: $($_.cur_temp), " -ForegroundColor Red -NoNewline
                Write-Host "Fan Speed: $($_.FanSpeed), " -ForegroundColor Cyan -NoNewline 
                Write-Host "Change: $($_.New_Speed - $_.FanSpeed)%, " -ForegroundColor Yellow -NoNewline
                Write-Host "Actual New Fan Speed %: $($_.New_Speed)" -ForegroundColor Green -NoNewline
                Write-Host ""    
            }
        }
    }

    Handle_Errors() {
        $this.GPUS | % {
            $Errors = $_.Errors
            ## Determine Error
            if ($Errors) {
                switch ($Errors) {
                    "No Speed" {
                        switch ($This.Config.REBOOT_ON_ERROR) {
                            1 { $Message = "GPU driver error, no fan speed, rebooting"; $Action = 1 }
                        }
                    }
                    "No Temp" {
                        switch ($This.Config.REBOOT_ON_ERROR) {
                            1 { $Message = "GPU driver error, no temps, rebooting"; $Action = 1 }
                        }
                    }
                    "No Data" {
                        switch ($This.Config.REBOOT_ON_ERROR) {
                            1 { $Message = "GPU driver error, no data, rebooting"; $Action = 1 }
                        }
                    }
                    "Critical" {
                        switch ($This.Config.CRITICAL_TEMP_ACTION) {
                            "shutdown" { $Message = "GPU $($_.Rig_Number) Critical- shutting down"; $Action = 2 }
                            "reboot" { $Message = "GPU $($_.Rig_Number) Critical- rebooting"; $Action = 1 }
                            default { $Message = "GPU $($_.Rig_Number) Critical- mining stopped"; $Action = 3; $this.IsMinerStopped = $true }
                        }
                    }
                    "Unreal" {
                        switch ($This.Config.REBOOT_ON_ERROR) {
                            1 { $Message = "Autofan: GPU temperature is unreal, driver error, rebooting" }
                        }
                    }
                }

                ## Notify Website:
                if ($Message -and $this.Websites) {
                    $this.Websites | % { $Send = [Message]::New("message", "warning", $message, "$($_)") }
                }

                ## Take Action:
                if ($Action) {
                    switch ($Action) {
                        1 { Restart-Computer -Force }
                        2 { Stop-Computer -Force }
                        3 { Invoke-Expression "miner stop"; $this.IsMinerStopped = $True }
                    }
                }

                ## Restart Miner if Autofan stopped it.
                if ($this.IsMinerStopped -eq $true) {
                    if ($this.GPUS.Errors.count -eq 0) {
                        Invoke-expression "miner start"; $this.IsMinerStopped = $false
                    }
                }
                
                ## Print Errors
                Write-Host ""
                Write-Host "GPU $($_.Rig_Number): $($_.Errors)" -ForegroundColor Red
                Write-Host ""            
            }

            ## Reset Errors
            $_.Errors = $Null
        }
    }
}

class Message {
    [string]$method
    [string]$rig_id
    [string]$jsonrpc = "2.0"
    [string]$id = "0"
    [hashtable]$params = @{
        rig_id = $null
        passwd = $null
        type   = $null
        data   = $null
    }

    Message([string]$method, [string]$type, [string]$data, [string]$site) {

        $miner_keys = $null
        
        ## Get Rig ID & Password
        Switch ($site) {
            "HiveOS" { 
                $Path = [IO.Path]::Join($Global:Dir, "config\parameters\Hive_params_keys.json")
                if (test-path $Path) { 
                    $miner_keys = cat ".\config\parameters\Hive_params_keys.json" | ConvertFrom-Json 
                } 
            }
            "SWARM" { 
                $Path = [IO.Path]::Join($Global:Dir, "config\parameters\SWARM_params_keys.json")
                if (Test-Path ".\config\parameters\SWARM_params_keys.json") { 
                    $miner_keys = cat ".\config\parameters\SWARM_params_keys.json" | ConvertFrom-Json 
                } 
            }
        }

        $this.params.rig_id = $miner_keys.id
        $this.params.passwd = $miner_keys.Password
        $this.params.type = $type
        $this.params.data = $data
        $this.method = $method
        $this.rig_id = $miner_keys.id
    
        $json = $this | ConvertTo-Json -Depth 10 -Compress

        $Answer = try { Invoke-RestMethod "$($miner_keys.mirror)/worker/api" -TimeoutSec 10 -Method POST -Body $json -ContentType 'application/json' } catch [Exception] { Write-Host "Exception: "$_.Exception.Message -ForegroundColor Red; }
    }
}


## Gather Script Variables
$host.ui.RawUI.WindowTitle = "Autofan"
$Global:DIR = (Split-Path(Split-Path(Split-Path(Split-Path($script:MyInvocation.MyCommand.Path)))))
$Config_Path = [IO.Path]::Join($Global:Dir, "config\parameters\autofan.json")
Set-Location $GLobal:Dir
$Icon_Path = [IO.PATH]::Join($Global:Dir, "build\apps\icons\comb.ico");


if ($IsWindows) { 
    $Path = [IO.PATH]::Join($Global:Dir, "build\apps\icons\comb.ico");
    Start-Process "powershell" -ArgumentList "Set-Location `'$($config.dir)`'; .\build\powershell\scripts\icon.ps1 `'$Icon_Path`'" -NoNewWindow 
}
$RIG = [RIG]::New()
$RIG.Get_Config($Config_Path)
$Loop_Timer = [Stopwatch]::New()
$Loop_Timer.Restart()

While ($True) {
    $RIG.Get_Config($Config_Path);
    $RIG.Get_GPUData();
    $RIG.Handle_Errors();
    $RIG.Adjust();
    $RIG.Log_Cleanup();
    [int]$Time = [math]::Round(10 - $Loop_Timer.Elapsed.Seconds, 0)
    if ($Time -gt 0) { Start-Sleep -S $Time };
    $Loop_Timer.Restart()
}