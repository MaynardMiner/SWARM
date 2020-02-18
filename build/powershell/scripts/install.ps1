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

## Extract export folder.
if (-not (test-path ".\build\export")) {
    log "export folder not found. Exracting export.tar.gz" -ForegroundColor Yellow;
    New-Item -ItemType Directory -Name "export" -path ".\build" | Out-Null;
    $Proc = Start-Process "tar" -ArgumentList "-xzvf build/export.tar.gz -C build" -PassThru; 
    $Proc | Wait-Process;
}    

$Libs = @()
$Libs += [PSCustomObject]@{ link = "libcurl.so.4"; path = "libcurl.so.4.4.0" }
$Libs += [PSCustomObject]@{ link = "libcurl.so.3"; path = "libcurl.so.4" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.9.2"; path = "libnvrtc-builtins.so.9.2.148" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.0"; path = "libnvrtc-builtins.so.10.0.130" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.1"; path = "libnvrtc-builtins.so.10.1.105" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so.10.2"; path = "libnvrtc-builtins.so.10.2.89" }
$Libs += [PSCustomObject]@{ link = "libnvrtc-builtins.so"; path = "libnvrtc-builtins.so.10.2" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.8.0"; path = "libcudart.so.8.0.61" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.9.0"; path = "libcudart.so.9.0.176" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.9.1"; path = "libcudart.so.9.1.85" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.9.2"; path = "libcudart.so.9.2.148" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.10.0"; path = "libcudart.so.10.0.130" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.10.1"; path = "libcudart.so.10.1.105" }
$Libs += [PSCustomObject]@{ link = "libcudart.so.10.2"; path = "libcudart.so.10.2.89" }
$Libs += [PSCustomObject]@{ link = "libmicrohttpd.so.10"; path = "libmicrohttpd.so.10.34.0" }
$Libs += [PSCustomObject]@{ link = "libhwloc.so.5"; path = "libhwloc.so.5.6.8" }
$Libs += [PSCustomObject]@{ link = "libstdc++.so.6"; path = "libstdc++.so.6.0.25" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.0"; path = "libnvrtc.so.9.0.176" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.1"; path = "libnvrtc.so.9.2.xxx" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.9.2"; path = "libnvrtc.so.9.2.148" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.0"; path = "libnvrtc.so.10.0.130" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.1"; path = "libnvrtc.so.10.1.105" }
$Libs += [PSCustomObject]@{ link = "libnvrtc.so.10.2"; path = "libnvrtc.so.10.2.89" }

foreach ($lib in $Libs) {
    $link = "$dir/build/export/$($lib.link)"
    $path = "$dir/build/export/$($lib.path)"
    $check = [IO.File]::exists($link)
    if ($check) {
        Remove-Item $link -Force
    }
    $Proc = Start-Process "ln" -ArgumentList "-s $path $link" -PassThru
    $Proc | Wait-Process
}                                     
