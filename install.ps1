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

$dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$dir = $dir -replace "/var/tmp","/root"
Set-Location $dir
$dir

##Check for libc
$Proc = Start-Process ".\build\bash\libc.sh" -PassThru
$Proc | Wait-Process
Start-Process ".\build\bash\libv.sh" -PassThru
$Proc | Wait-Process
Start-Process ".\build\bash\libcurl3.sh" -PassThru
$Proc | Wait-Process

$dir | set-content ".\build\bash\dir.sh"

if (Test-Path ".\build\bash\stats") {
    Copy-Item ".\build\bash\stats" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x stats"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\swarm_batch") {
    Copy-Item ".\build\bash\swarm_batch" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x swarm_batch"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\view") {
    Copy-Item ".\build\bash\view" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x view"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\apps\wolfamdctrl\wolfamdctrl") {
    Copy-Item ".\build\apps\wolfamdctrl" -Destination "/usr/bin" -force | Out-Null
    $proc = Start-Process ln -ArgumentList "-s $dir/build/apps/wolfamdctrl/wolfamdctrl /usr/bin/wolfamdctrl/wolfamdctrl" -PassThru
    $proc | Wait-Process
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x wolfamdctrl"
    Set-Location "/"
    Set-Location $Dir
}

if (Test-Path ".\build\bash\miner") {
    Copy-Item ".\build\bash\miner" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x miner"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\get") {
    Copy-Item ".\build\bash\get" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x get"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\modules") {
    Copy-Item ".\build\bash\modules" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x modules"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\get-lambo") {
    Copy-Item ".\build\bash\get-lambo" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x get-lambo"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\export\libcudart.so.9.2.148") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.9.2.148 $dir/build/export/libcudart.so.9.2" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\export\libcudart.so.10.0.130") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.10.0.130 $dir/build/export/libcudart.so.10.0" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\export\libcurl.so.3.0.0") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libcurl.so.3.0.0 $dir/build/export/libcurl.so.3" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir    
}

if (Test-Path ".\build\export\libcudart.so.10.1.105") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.10.1.105 $dir/build/export/libcudart.so.10.1" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}


if (Test-Path ".\build\export\libmicrohttpd.so.10.34.0") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libmicrohttpd.so.10.34.0 $dir/build/export/libmicrohttpd.so.10" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\export\libstdc++.so.6.0.25") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libstdc++.so.6.0.25 $dir/build/export/libstdc++.so.6" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\export\libhwloc.so.5.5.0") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libhwloc.so.5.5.0 $dir/build/export/libhwloc.so.5" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}


if (Test-Path ".\build\export\libnvrtc.so.9.2.148") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libnvrtc.so.9.2.148 $dir/build/export/libnvrtc.so.9.2" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\export\libnvrtc.so.10.0.130") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libnvrtc.so.10.0.130 $dir/build/export/libnvrtc.so.10.0" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\export\libnvrtc.so.10.1.105") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libnvrtc.so.10.2.105 $dir/build/export/libnvrtc.so.10.1" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\export\libnvrtc-builtins.so.10.1.105") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libnvrtc-builtins.so.10.1.105 $dir/build/export/libnvrtc-builtins.so.10.1" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir
    Start-Sleep -S 1
}

if (Test-Path ".\build\export\libnvrtc-builtins.so.10.1") {
    $Proc = Start-Process ln -ArgumentList "-s $dir/build/export/libnvrtc-builtins.so.10.1 $dir/build/export/libnvrtc-builtins.so" -PassThru
    $Proc | Wait-Process
    Set-Location "/"
    Set-Location $Dir     
}
 
if (Test-Path ".\build\bash\get-oc") {
    Copy-Item ".\build\bash\get-oc" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x get-oc"
    Set-Location "/"
    Set-Location $Dir     
}
   
if (Test-Path ".\build\bash\active") {
    Copy-Item ".\build\bash\active" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x active"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\version") {
    Copy-Item ".\build\bash\version" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x version"
    Set-Location "/"
    Set-Location $Dir     
}
    
if (Test-Path ".\build\bash\get-screen") {
    Copy-Item ".\build\bash\get-screen" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x get-screen"
    Set-Location "/"
    Set-Location $Dir     
}
   
if (Test-Path ".\build\bash\mine") {
    Copy-Item ".\build\bash\mine" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x mine"
    Set-Location "/"
    Set-Location $Dir     
}
   
if (Test-Path ".\build\bash\background") {
    Copy-Item ".\build\bash\background" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x background"
    Set-Location "/"
    Set-Location $Dir     
}
   
if (Test-Path ".\build\bash\pidinfo") {
    Copy-Item ".\build\bash\pidinfo" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x pidinfo"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\dir.sh") {
    Copy-Item ".\build\bash\dir.sh" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x dir.sh"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\bench") {
    Copy-Item ".\build\bash\bench" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x bench"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\clear_profits") {
    Copy-Item ".\build\bash\clear_profits" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x clear_profits"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\clear_watts") {
    Copy-Item ".\build\bash\clear_watts" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x clear_watts"
    Set-Location "/"
    Set-Location $Dir
}  

if (Test-Path ".\build\bash\get-lambo") {
    Copy-Item ".\build\bash\get-lambo" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x get-lambo"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\set_swarm") {
    Copy-Item ".\build\bash\set_swarm" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x set_swarm"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\swarm_help") {
    Copy-Item ".\build\bash\swarm_help" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x swarm_help"
    Set-Location "/"
    Set-Location $Dir     
}

if (Test-Path ".\build\bash\send-config") {
    Copy-Item ".\build\bash\send-config" -Destination "/usr/bin" -force | Out-Null
    Set-Location "/usr/bin"
    Start-Process "chmod" -ArgumentList "+x send-config"
    Set-Location "/"
    Set-Location $Dir     
}
   
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
