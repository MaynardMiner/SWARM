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


Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

##Check for libc
Start-Process ".\Build\Unix\Hive\libc.sh" -wait


Set-Location ".\Build"

if(Test-Path ".\version")
{
 Copy-Item ".\version" -Destination "/usr/bin" -force | Out-Null
 Set-Location "/usr/bin"
 Start-Process "chmod" -ArgumentList "+x version"
 Set-Location "/"
 Set-Location $CmdDir
}

if(Test-Path ".\get-oc")
{
     Copy-Item ".\get-oc" -Destination "/usr/bin" -force | Out-Null
     Set-Location "/usr/bin"
     Start-Process "chmod" -ArgumentList "+x get-oc"
     Set-Location "/"
     Set-Location $CmdDir     
}

if(Test-Path ".\benchmark")
{
   Copy-Item ".\benchmark" -Destination "/usr/bin" -force | Out-Null
   Set-Location "/usr/bin"
   Start-Process "chmod" -ArgumentList "+x benchmark"
   Set-Location "/"
   Set-Location $CmdDir
   }


if(Test-Path ".\clear_profits")
 {
  Copy-Item ".\clear_profits" -Destination "/usr/bin" -force | Out-Null
  Set-Location "/usr/bin"
  Start-Process "chmod" -ArgumentList "+x clear_profits"
  Set-Location "/"
  Set-Location $CmdDir
}  

    if(Test-Path ".\dir.sh")
     {
      Copy-Item ".\dir.sh" -Destination "/usr/bin" -force | Out-Null
      Set-Location "/usr/bin"
      Start-Process "chmod" -ArgumentList "+x dir.sh"
      Set-Location "/"
      Set-Location $CmdDir
     }

    if(Test-Path ".\stats")
    {
         Copy-Item ".\stats" -Destination "/usr/bin" -force | Out-Null
         Set-Location "/usr/bin"
         Start-Process "chmod" -ArgumentList "+x stats"
         Set-Location "/"
         Set-Location $CmdDir     
    }
   
   if(Test-Path ".\active")
    {
       Copy-Item ".\active" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x active"
       Set-Location "/"
       Set-Location $CmdDir
       }
    
       if(Test-Path ".\get-screen")
    {
       Copy-Item ".\get-screen" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x get-screen"
       Set-Location "/"
       Set-Location $CmdDir
       }
   
   if(Test-Path ".\mine")
    {
       Copy-Item ".\mine" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x mine"
       Set-Location "/"
       Set-Location $CmdDir
       }
   
   if(Test-Path ".\logdata")
    {
       Copy-Item ".\logdata" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x logdata"
       Set-Location "/"
       Set-Location $CmdDir
       }
   
   if(Test-Path ".\pidinfo")
    {
       Copy-Item ".\pidinfo" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x pidinfo"
       Set-Location "/"
       Set-Location $CmdDir
       }

   if(Test-Path ".\dir.sh")
    {
       Copy-Item ".\dir.sh" -Destination "/usr/bin" -force | Out-Null
       Set-Location "/usr/bin"
       Start-Process "chmod" -ArgumentList "+x dir.sh"
       Set-Location "/"
       Set-Location $CmdDir
       }
