Add-Type -Path ".\OpenCL.DotNetCore.dll"
Add-Type -Path ".\OpenCL.DotNetCore.Interop.dll"
$platforms = [OpenCl.DotNetCore.Platforms.Platform]::GetPlatforms();