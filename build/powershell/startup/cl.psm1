function get-AMDPlatform {

    if ($Global:Config.Params.Platform -eq "linux") {
        $A = Invoke-Expression ".\build\apps\getplatforms" | Tee-Object -Variable amdclplatform
        Start-Sleep -S .5
        $GPUPlatform = $amdclplatform | Select-String "AMD Accelerated Parallel Processing"
        $GPUPlatform = $GPUPlatform -replace (" ", "")
        $GPUPlatform = $GPUPlatform -split "AMD" | Select -First 1
        $GPUPlatform
    }

    if ($Global:Config.Params.Platform -eq "windows") {
        $A = (clinfo) | Select-string "Platform Vendor"
        $PlatformA = @()
        for ($i = 0; $i -lt $A.Count; $i++) { $PlatSel = $A | Select -Skip $i -First 1; $PlatSel = $PlatSel -replace "Platform Vendor", "$i"; $PlatSel = $PlatSel -replace ":", "="; $PlatformA += $PlatSel}
        $PlatformA = $PlatformA | ConvertFrom-StringData
        $PlatformA.keys | % {if ($PlatformA.$_ -eq "AMD Accelerated Parallel Processing" -or $PlatformA.$_ -eq "Advanced Micro Devices, Inc.") {$B = $_}}
        $B
    }
}
