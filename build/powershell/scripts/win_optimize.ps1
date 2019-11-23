param(
    # "set" will set the optimizations.
    # "reset" will reset the optimizations.
    [Parameter(Position=0)]
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


