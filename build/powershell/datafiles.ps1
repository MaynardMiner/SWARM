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
function Get-Data {
    param (
        [Parameter(Mandatory = $false)]
        [String]$CmdDir
    )

    Set-Location $CmdDir

    if (Test-Path ".\build\bash\stats") {
        Copy-Item ".\build\bash\stats" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x stats"
        Set-Location "/"
        Set-Location $CmdDir     
    }

    if (Test-Path ".\build\bash\get") {
        Copy-Item ".\build\bash\get" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get"
        Set-Location "/"
        Set-Location $CmdDir     
    }

        if (-not (Test-Path ".\build\export\libcudart.so.10.1")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.10.1.105 $dir/build/export/libcudart.so.10.1" -Wait
        Set-Location "/"
        Set-Location $CmdDir     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.0")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.10.0.130 $dir/build/export/libcudart.so.10.0" -Wait
        Set-Location "/"
        Set-Location $CmdDir     
    }
    
     if (-not (Test-Path ".\build\export\libcudart.so.9.2")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.9.2.148 $dir/build/export/libcudart.so.9.2" -Wait
        Set-Location "/"
        Set-Location $CmdDir     
    }

    if (-not (Test-Path ".\build\export\libmicrohttpd.so.10")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libmicrohttpd.so.10.34.0 $dir/build/export/libmicrohttpd.so.10" -Wait
        Set-Location "/"
        Set-Location $CmdDir     
    }

         if (-not (Test-Path ".\build\export\libcudart.so.10.1")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.10.0.130 $dir/build/export/libcudart.so.10.0" -Wait
        Set-Location "/"
        Set-Location $CmdDir     
    }
    
    if (-not (Test-Path ".\build\export\libhwloc.so.5")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libhwloc.so.5.5.0 $dir/build/export/libhwloc.so.5" -Wait
        Set-Location "/"
        Set-Location $CmdDir     
    }

     if(-not (Test-Path ".\build\export\libstdc++.so.6"))
     {
      Start-Process ln -ArgumentList "-s $CmdDir/build/export/libstdc++.so.6.0.25 $CmdDir/build/export/libstdc++.so.6" -Wait
      Set-Location "/"
      Set-Location $CmdDir     
     }

     if(-not (Test-Path ".\build\export\libnvrtc.so.9.2"))
     {
      Start-Process ln -ArgumentList "-s $CmdDir/build/export/libnvrtc.so.9.2.148 $CmdDir/build/export/libnvrtc.so.9.2" -Wait
      Set-Location "/"
      Set-Location $CmdDir     
     }

     if(-not (Test-Path ".\build\export\libnvrtc.so.10.0"))
     {
      Start-Process ln -ArgumentList "-s $CmdDir/build/export/libnvrtc.so.10.0.130 $CmdDir/build/export/libnvrtc.so.10.0" -Wait
      Set-Location "/"
      Set-Location $CmdDir     
     }

     if(-not (Test-Path ".\build\export\libnvrtc.so.10.1"))
     {
      Start-Process ln -ArgumentList "-s $CmdDir/build/export/libnvrtc.so.10.1.105 $CmdDir/build/export/libnvrtc.so.10.1" -Wait
      Set-Location "/"
      Set-Location $CmdDir     
     }

    if (Test-Path ".\build\bash\get-oc") {
        Copy-Item ".\build\bash\get-oc" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-oc"
        Set-Location "/"
        Set-Location $CmdDir     
    }
   
    if (Test-Path ".\build\bash\active") {
        Copy-Item ".\build\bash\active" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x active"
        Set-Location "/"
        Set-Location $CmdDir
    }

    if (Test-Path ".\build\bash\version") {
        Copy-Item ".\build\bash\version" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x version"
        Set-Location "/"
        Set-Location $CmdDir
    }
    
    if (Test-Path ".\build\bash\get-screen") {
        Copy-Item ".\build\bash\get-screen" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-screen"
        Set-Location "/"
        Set-Location $CmdDir
    }
   
    if (Test-Path ".\build\bash\mine") {
        Copy-Item ".\build\bash\mine" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x mine"
        Set-Location "/"
        Set-Location $CmdDir
    }
   
    if (Test-Path ".\build\bash\background") {
        Copy-Item ".\build\bash\background" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x background"
        Set-Location "/"
        Set-Location $CmdDir
    }
   
    if (Test-Path ".\build\bash\pidinfo") {
        Copy-Item ".\build\bash\pidinfo" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x pidinfo"
        Set-Location "/"
        Set-Location $CmdDir
    }

    if (Test-Path ".\build\bash\dir.sh") {
        Copy-Item ".\build\bash\dir.sh" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x dir.sh"
        Set-Location "/"
        Set-Location $CmdDir
    }

    if (Test-Path ".\build\bash\benchmark") {
        Copy-Item ".\build\bash\benchmark" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x benchmark"
        Set-Location "/"
        Set-Location $CmdDir
    }

    if (Test-Path ".\build\bash\clear_profits") {
        Copy-Item ".\build\bash\clear_profits" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x clear_profits"
        Set-Location "/"
        Set-Location $CmdDir
    }  

    if (Test-Path ".\build\bash\clear_watts") {
        Copy-Item ".\build\bash\clear_watts" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x clear_watts"
        Set-Location "/"
        Set-Location $CmdDir
    }  

    if (Test-Path ".\build\bash\get-lambo") {
        Copy-Item ".\build\bash\get-lambo" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-lambo"
        Set-Location "/"
        Set-Location $CmdDir
    }      
   
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    
}
