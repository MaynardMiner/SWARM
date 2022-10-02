Add-Type -Path ".\PSOpenCL.dll"
$test = [PSOpenCL.Loader]::GetPlatformInfo();