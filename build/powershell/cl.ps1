function get-AMDPlatform {
  param(
  [Parameter(Mandatory=$true)]
  [string]$Platforms
  )

 if($Platforms -eq "linux")
 {
   $A = Invoke-Expression ".\build\apps\getplatforms > .\build\txt\platforms.txt"
   $GetPlatforms = Get-Content ".\build\txt\platforms.txt"
   Start-Sleep -S .5
 }
 else
 {
 $A = Invoke-Expression ".\build\apps\platforms.exe > .\build\txt\platforms.txt"
 $GetPlatforms = Get-Content ".\build\txt\platforms.txt"
 Start-Sleep -S .5
 }

 $GPUPlatform = $GetPlatforms | Select-String "AMD Accelerated Parallel Processing"
 $GPUPlatform = $GPUPlatform -replace (" ","")
 $GPUPlatform = $GPUPlatform -split "AMD" | Select -First 1

 $GPUPlatform

if($Platforms -eq "windows")
{
 $A = (clinfo) | Select-string "Platform Vendor"
 for($i = 0; $i -lt $A.count; $i++){$A[$i] = $A[$i] -replace "Platform Vendor","$i"; $A[$i] =  $A[$i] -replace ":","="}
 $A = $A | ConvertFrom-StringData
 $A.keys | %{if($A.$_ -eq "AMD Accelerated Parallel Processing" -or $A.$_ -eq "Advanced Micro Devices, Inc."){$B = $_}}
 $B
}
}