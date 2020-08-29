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

$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp", "/root"
Set-Location $dir

"export SWARM_DIR=$dir" | Set-Content "/etc/profile.d/SWARM.sh"

##Check for libc
$Proc = Start-Process ".\build\bash\screen.sh" -PassThru
$Proc | Wait-Process
$Proc = Start-Process ".\build\bash\python.sh" -PassThru
$Proc | Wait-Process
$Proc = Start-Process ".\build\bash\libc.sh" -PassThru
$Proc | Wait-Process
$Proc = Start-Process ".\build\bash\libv.sh" -PassThru
$Proc | Wait-Process
$Proc = Start-Process ".\build\bash\libcurl3.sh" -PassThru
$Proc | Wait-Process

$dir | set-content ".\build\bash\dir.sh"

$Execs = @()
$Execs += "stats"
$Execs += "swarm_batch"
$Execs += "nview"
$Execs += "bans"
$Execs += "modules"
$Execs += "get"
$Execs += "get-oc"
$Execs += "version"
$Execs += "mine"
$Execs += "background"
$Execs += "pidinfo"
$Execs += "dir.sh"
$Execs += "bench"
$Execs += "clear_profits"
$Execs += "clear_watts"
$Execs += "swarm_help"
$Execs += "send-config"
$Execs += "miner"


foreach ($exec in $Execs) {
    if (Test-Path ".\build\bash\$exec") {
        Copy-Item ".\build\bash\$exec" -Destination "/usr/bin" -Force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x $exec"
        Set-Location "/"
        Set-Location $dir     
    }
}

if (Test-Path ".\build\apps\wolfamdctrl\wolfamdctrl") {
    Copy-Item ".\build\apps\wolfamdctrl\wolfamdctrl" -Destination "/usr/bin" -Force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x wolfamdctrl"
    Set-Location "/"
    Set-Location $dir     
}

if (-not (test-path "/usr/local/swarm/lib64")) {
    ## HiveOS is messing with ownership of SWARM folder through custom miners.
    ## I believe this is causing an issue with miners accessing libs contained in SWARM.
    ## Testing has shown if libs are placed anywhere else, they work fine.
    ## Therefor I have decided to place libs in a more proper location: /usr/local/swarm/lib64 
    log "library folder not found (/usr/local/swarm/lib64). Exracting lib64.tar.gz" -ForegroundColor Yellow;
    $check = [IO.Directory]::Exists("/usr/local/swarm")
    if(!$check){
     Start-Process "mkdir" -ArgumentList "/usr/local/swarm"
    }
    $check = [IO.Directory]::Exists("/usr/local/swarm/lib64")
    if(!$check){
        Start-Process "mkdir" -ArgumentList "/usr/local/swarm/lib64"
    }
    $Proc = Start-Process "tar" -ArgumentList "-xzvf build/lib64.tar.gz -C /usr/local/swarm" -PassThru; 
    $Proc | Wait-Process;
}    

$Libs = @()
$Libs += [PSCustomObject]@{ link = "libcurl.so.4"; path = "/usr/local/swarm/lib64/libcurl.so.4.4.0" }
$Libs += [PSCustomObject]@{ link = "libcurl.so.3"; path = "/usr/local/swarm/lib64/libcurl.so.4" }

$Libs += [PSCustomObject]@{ link = "libmicrohttpd.so.10"; path = "/usr/local/swarm/lib64/libmicrohttpd.so.10.34.0" }
$Libs += [PSCustomObject]@{ link = "libhwloc.so.5"; path = "/usr/local/swarm/lib64/libhwloc.so.5.6.8" }
$Libs += [PSCustomObject]@{ link = "libstdc++.so.6"; path = "/usr/local/swarm/lib64/libstdc++.so.6.0.25" }

$Libs += [PSCustomObject]@{ link = "libcudart.so.11.0"; path = "/usr/local/swarm/lib64/libcudart.so.11.0.221" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.10.0"; path = "/usr/local/swarm/lib64/libcudart.so.10.0.130" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.10.1"; path = "/usr/local/swarm/lib64/libcudart.so.10.1.105" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.10.2"; path = "/usr/local/swarm/lib64/libcudart.so.10.2.89" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.9.0"; path = "/usr/local/swarm/lib64/libcudart.so.9.0.176" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.9.1"; path = "/usr/local/swarm/lib64/libcudart.so.9.1.85" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.9.2"; path = "/usr/local/swarm/lib64/libcudart.so.9.2.148" }
$Libs += [PSCustomObject]@{ link = "libcudart.so"; path = "/usr/local/swarm/lib64/libcudart.so.10.2.89" }

$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.11.0"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.11.0.221" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.0"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.10.0.130" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.1"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.10.1.105" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.2"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.10.2.89" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.9.2"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.9.2.148" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so"; path = "/usr/local/swarm/lib64/libnvrtc-builtins.so.10.2.89" }

$Libs += [PSCustomObject]@{ link = "libnvrtc.so.11.0"; path = "/usr/local/swarm/lib64/libnvrtc.so..so.11.0.221" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.0"; path = "/usr/local/swarm/lib64/libnvrtc.so.10.0.130" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.1"; path = "/usr/local/swarm/lib64/libnvrtc.so.10.1.105" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.2"; path = "/usr/local/swarm/lib64/libnvrtc.so.10.2.89" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.0"; path = "/usr/local/swarm/lib64/libnvrtc.so.9.0.176" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.1"; path = "/usr/local/swarm/lib64/libnvrtc.so.9.1.xxx" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.2"; path = "/usr/local/swarm/lib64/libnvrtc.so.9.2.148" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so"; path = "/usr/local/swarm/lib64/libnvrtc.so.10.2.89" }

Set-Location "/usr/local/swarm/lib64/"

foreach ($lib in $Libs) {
    $link = $lib.link; 
    $path = $lib.path; 
    $Proc = Start-Process "ln" -ArgumentList "-sf $path $link" -PassThru; 
    $Proc | Wait-Process
}

Set-Location "/"
Set-Location $dir     
