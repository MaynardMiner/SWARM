<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

[Int32]$Lib_Version = 8;
$Extract = $false;
$Paths = @();
$Paths += "/usr";
$Paths += "/usr/local";
$Paths += "/usr/local/swarm";
$IsLib = [IO.Directory]::Exists("/usr/local/swarm/lib64");
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
$Dir = $Dir -replace "/var/tmp", "/root"
Set-Location $Dir

## HiveOS is messing with ownership of SWARM folder through custom miners.
## I believe this is causing an issue with miners accessing libs contained in SWARM.
## Testing has shown if libs are placed anywhere else, they work fine.
## Therefor I have decided to place libs in a more proper location: /usr/local/swarm/lib64 

foreach($Path in $Paths) {
    $exists = [IO.Directory]::Exists($Path)
    if(!$exists) {
        [IO.Directory]::CreateDirectory($Path)
        $Extract = $true;
    }
}

if([IO.File]::Exists("/usr/local/swarm/lib64/version.txt")) {
    $Version = [Int32]::Parse([IO.File]::ReadAllText("/usr/local/swarm/lib64/version.txt"));
    if($Version -lt $Lib_Version) {
        $Extract = $true;
    }
}

if($Extract) {
    ## Delete old files if they are there.
    if($IsLib) {
        $files = [System.IO.Directory]::GetFiles("/usr/local/swarm/lib64")
        if($files.Count -gt 0) {
            foreach($file in $files) {
                [System.IO.File]::Delete($file)
            }
        }    
    }
    log "Updating library folder (/usr/local/swarm/lib64). Downloading and extracting lib64.tar.gz from Github" -ForegroundColor Yellow;
    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    $Uri = "https://github.com/MaynardMiner/MM.Compiled-Miners/releases/download/v10.0/lib64.tar.gz"
    if(-not (Test-Path ".\x64")) {
        New-Item ".\x64" -ItemType Directory | Out-Null;
    }
    $X64_zip = Join-Path ".\x64" "lib64.tar.gz";
    try { Invoke-WebRequest "$Uri" -OutFile "$X64_zip" -UseBasicParsing -SkipCertificateCheck -TimeoutSec 10 | Out-Null }
    catch {
        log "WARNING: Failed to contact $URI for miner binary" -ForeGroundColor Yellow
        Start-Sleep -Seconds 10;
        log "Error: SWARM will not work without library- Check internet connection to www.github.com and restart SWARM" -ForegroundColor Red;
        Start-Sleep -Seconds 5;
        ## Delete the old directory to ensur a trigger download.
        [System.IO.Directory]::Delete("/usr/local/swarm/",$true);
        exit;
    }
    if (Test-Path "$X64_zip") { log "Download Succeeded!" -ForegroundColor Green }
    else { log "Download Failed! Verify you can connect to Github from rig!" -ForegroundColor DarkRed; Start-Sleep -S 10; exit }
    log "Extracting to temporary folder" -ForegroundColor Yellow
    New-Item -Path ".\x64\$temp" -ItemType "Directory" -Force | Out-Null; Start-Sleep -S 1
    $Proc = Start-Process "tar" -ArgumentList "-xzvf x64/lib64.tar.gz -C /usr/local/swarm" -PassThru; 
    $Proc | Wait-Process;
    [IO.File]::WriteAllText("/usr/local/swarm/lib64/version.txt",$Lib_Version);
    $Libs = @()
    $Libs += [PSCustomObject]@{ link = "libcurl.so.4"; path = "/usr/local/swarm/lib64/libcurl.so.4.5.0" }
    $Libs += [PSCustomObject]@{ link = "libcurl.so.3"; path = "/usr/local/swarm/lib64/libcurl.so.4.4.0" }

    $Libs += [PSCustomObject]@{ link = "libmicrohttpd.so.10"; path = "/usr/local/swarm/lib64/libmicrohttpd.so.10.34.0" }
    $Libs += [PSCustomObject]@{ link = "libhwloc.so.5"; path = "/usr/local/swarm/lib64/libhwloc.so.5.6.8" }
    $Libs += [PSCustomObject]@{ link = "libstdc++.so.6"; path = "/usr/local/swarm/lib64/libstdc++.so.6.0.25" }

            $Libs += [PSCustomObject]@{ link = "libcudart.so.8.0"; path = "/usr/local/swarm/lib64/libcudart.so.8.0.61" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.9.0"; path = "/usr/local/swarm/lib64/libcudart.so.9.0.176" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.9.1"; path = "/usr/local/swarm/lib64/libcudart.so.9.1.85" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.9.2"; path = "/usr/local/swarm/lib64/libcudart.so.9.2.148" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.10.0"; path = "/usr/local/swarm/lib64/libcudart.so.10.0.130" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.10.1"; path = "/usr/local/swarm/lib64/libcudart.so.10.1.105" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.11.0"; path = "/usr/local/swarm/lib64/libcudart.so.11.0.221" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.11.1"; path = "/usr/local/swarm/lib64/libcudart.so.11.1.74" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.11.2"; path = "/usr/local/swarm/lib64/libcudart.so.11.2.152" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.11.3"; path = "/usr/local/swarm/lib64/libcudart.so.11.3.109" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.11.4"; path = "/usr/local/swarm/lib64/libcudart.so.11.4.108" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.11.5"; path = "/usr/local/swarm/lib64/libcudart.so.11.5.117" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.11.6"; path = "/usr/local/swarm/lib64/libcudart.so.11.6.55" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so.11.0"; path = "/usr/local/swarm/lib64/libcudart.so.11.6.55" }
            $Libs += [PSCustomObject]@{ link = "libcudart.so"; path = "/usr/local/swarm/lib64/libcudart.so.11.6.55" }

            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.8.0"; path = "/usr/local/swarm/lib64/libnvrtc.so.8.0.61" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.0"; path = "/usr/local/swarm/lib64/libnvrtc.so.9.0.176" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.1"; path = "/usr/local/swarm/lib64/libnvrtc.so.9.1.xxx" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.2"; path = "/usr/local/swarm/lib64/libnvrtc.so.9.2.148" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.0"; path = "/usr/local/swarm/lib64/libnvrtc.so.10.0.130" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.1"; path = "/usr/local/swarm/lib64/libnvrtc.so.10.1.105" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.2"; path = "/usr/local/swarm/lib64/libnvrtc.so.10.2.89" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.11.0"; path = "/usr/local/swarm/lib64/libnvrtc.so.11.0.221" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.11.1"; path = "/usr/local/swarm/lib64/libnvrtc.so.11.1.105" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.11.2"; path = "/usr/local/swarm/lib64/libnvrtc.so.11.2.152" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.11.3"; path = "/usr/local/swarm/lib64/libnvrtc.so.11.3.109" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.11.4"; path = "/usr/local/swarm/lib64/libnvrtc.so.11.4.120" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.11.5"; path = "/usr/local/swarm/lib64/libnvrtc.so.11.5.119" }        
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so.11.6"; path = "/usr/local/swarm/lib64/libnvrtc.so.11.6.124" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc.so"; path = "/usr/local/swarm/lib64/libnvrtc.so.11.6.124" }

            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.8.0"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.8.0.61" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.9.2"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.9.2.148" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.0"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.10.0.130" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.1"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.10.1.105" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.2"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.10.2.89" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.11.0"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.0.221" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.11.1"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.1.105" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.11.2"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.2.152" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.11.3"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.3.109" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.11.4"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.4.120" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.11.5"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.5.119" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.11.6"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.6.124" }
            $Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.6.124" }

    Set-Location "/usr/local/swarm/lib64/"

    foreach ($lib in $Libs) {
        $link = $lib.link; 
        $path = $lib.path; 
        $Proc = Start-Process "ln" -ArgumentList "-sf $path $link" -PassThru; 
        $Proc | Wait-Process
    }    
    Set-Location "/"
    Set-Location $Dir    
}