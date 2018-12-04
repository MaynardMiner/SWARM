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
}
