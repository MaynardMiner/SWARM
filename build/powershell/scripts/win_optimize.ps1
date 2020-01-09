Using namespace System.Diagnostics;

param(
    # "set" will set the optimizations.
    # "reset" will reset the optimizations.
    [Parameter(Position = 0)]
    [String]$Command = "set"
)

## Replace Utilman with CMD
Write-Host "Replacing Utiliman With CMD" -ForegroundColor Green
invoke-expression "reg add `"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\utilman.exe`" /v `"Debugger`" /t REG_SZ /d `"cmd.exe`" /f"

Write-Host "Disabling Lock Screen Windows Feature" -ForegroundColor Green
invoke-expression "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization`" /v `"NoLockScreen`" /t REG_DWORD /d 1 /f"

Write-Host "Disabling Windows Update sharing" -ForegroundColor Green
invoke-expression "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config`" /v `"DownloadMode`" /t REG_DWORD /d 0 /f"
invoke-expression "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config`" /v `"DODownloadMode`" /t REG_DWORD /d 0 /f"

Write-Host "Disabling Windows Error Reporting" -ForegroundColor Green
invoke-expression "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting`" /v `"Disabled`" /t REG_DWORD /d 1 /f"

Write-Host "Disabling Automatic Updates" -ForegroundColor Green
invoke-expression "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update`" /v `"AUOptions`" /t REG_DWORD /d 2 /f"

Write-Host "Disabling Hibernation" -ForegroundColor Green
invoke-expression "reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power`" /v `"HiberbootEnabled`" /t REG_DWORD /d 0 /f"

Write-Host "Disabling Windows Tracking Services" -ForegroundColor Green
invoke-expression "sc config DiagTrack start= disabled"
invoke-expression "sc config diagnosticshub.standardcollector.service start= disabled"
invoke-expression "sc config TrkWks start= disabled"
invoke-expression "sc config WMPNetworkSvc start= disabled"

Write-Host "Disabling Windows Defender" -ForegroundColor Green
invoke-expression "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender`" /v `"DisableAntiSpyware`" /t REG_DWORD /d 1 /f"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Windows Defender\Windows Defender Cleanup`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Windows Defender\Windows Defender Verification`" /Disable"

Write-Host "Removing Error And Customer Reporting Scheduled Tasks" -ForegroundColor Green
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\AppID\SmartScreenSpecific`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Customer Experience Improvement Program\Consolidator`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Customer Experience Improvement Program\UsbCeip`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\NetTrace\GatherNetworkInfo`" /Disable"
invoke-expression "schtasks /Change /TN `"Microsoft\Windows\Windows Error Reporting\QueueReporting`" /Disable"

Write-Host "Disabling One-Drive" -ForegroundColor Green
invoke-expression "reg add `"HKLM\Software\Policies\Microsoft\Windows\OneDrive`" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f"

## AMD REGISTRY
[string]$regKeyName = 'SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
[string]$internalLargePageName = 'KMD_EnableInternalLargePage'
[string]$enableulps = 'EnableUlps'
[string]$enableulps_NA = 'EnableUlps_NA'
[string]$enablecrossfireautolink = 'EnableCrossFireAutoLink'
[string]$aMDPnPId = 'AMD'
$reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Default)

if ($reg) {
    if ($reg) {
        $key = $reg.OpenSubKey($regKeyName, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree)
        ForEach ($subKey in $key.GetSubKeyNames()) {
            if ($subKey -match '\d{4}') {
                $gpu = $key.OpenSubKey($subKey, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadSubTree)
                if ($gpu) {
                    $pnPId = $gpu.GetValue("Distribution")
                    if ($pnPId -match $aMDPnPId ) {
                        $gpukey = $key.OpenSubKey($subKey, $true)
                        $gpuitem = $gpukey.name.Substring($gpukey.name.LastIndexOf('\') + 1)
                        Write-Host "Detected GPU $gpuitem in registry to be AMD - Modifying Registries" -ForeGround Cyan 
                        $gpukey.SetValue($internalLargePageName, 2, [Microsoft.Win32.RegistryValueKind]::DWord)
                        Write-Host "GPU $gpuitem KMD_EnableInternalLargePage Set to 2" -ForeGround Yellow 
                        $gpukey.SetValue($enableulps, 0, [Microsoft.Win32.RegistryValueKind]::DWord)
                        Write-Host "GPU $gpuitem EnableUlps Set to 0" -ForeGround Yellow 
                        $gpukey.SetValue($enableulps_NA, "0", [Microsoft.Win32.RegistryValueKind]::String)
                        Write-Host "GPU $gpuitem EnableUlps_NA Set to 0" -ForeGround Yellow 
                        $gpukey.SetValue($enablecrossfireautolink, 0, [Microsoft.Win32.RegistryValueKind]::DWord)
                        Write-Host "GPU $gpuitem EnableCrossFireAutoLink Set to 0" -ForeGround Yellow 
                        Write-Host "done" -ForeGround green 
                    }
                }
            }
        }	
        $reg.Close()
        $reg.Dispose()
    }                
}


## Reset Device Drivers.
Write-Host "Enabling/Disabling GPU Devices To Reset Driver" -ForeGround Cyan 
$G = $(Get-CIMinstance Win32_VideoController).Where( { $_.PNPDeviceID -like "PCI\VEN_1002*" -or $_.PNPDeviceID -like "PCI\VEN_10DE*" })
Write-Host "disabling GPUs" -ForeGround Cyan 
$G | Foreach {
    Write-Host "disabling $($_.name) $($_.DeviceID)" -ForeGround yellow 
    $Proc = [Process]::New()
    $info = [ProcessStartInfo]::New()
    $info.FileName = "powershell";
    $info.Arguments = "-executionpolicy Bypass -Command `"Disable-PnpDevice -InstanceId `'$($_.PNPDeviceID)`' -confirm:`$false`"";
    $info.Verb = "runas";
    $info.CreateNoWindow = $true;
    $Proc.StartInfo = $info;
    $Proc.Start() | OUt-Null;
    $Proc.WaitForExit();
    $Proc.Dispose();
}
Write-Host "done" -ForeGround green 
Write-Host "enabling GPUs" -ForeGround cyan 
$G | foreach {
    Write-Host "enabling $($_.name) $($_.DeviceID)" -ForeGround yellow 
    $info = [ProcessStartInfo]::New()
    $Proc = [Process]::New()
    $info.FileName = "powershell";
    $info.Arguments = "-ExecutionPolicy bypass -Command `"Enable-PnpDevice -InstanceId `'$($_.PNPDeviceID)`' -confirm:`$false`"";
    $info.Verb = "runas";
    $info.CreateNoWindow = $true;
    $Proc.StartInfo = $info;
    $Proc.Start() | Out-Null;
    $Proc.WaitForExit();
    $Proc.Dispose();
}
Write-Host "done" -ForeGround green 
