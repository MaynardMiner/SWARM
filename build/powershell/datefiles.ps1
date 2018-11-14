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
    function Get-DateFiles {
        param (
        [Parameter(Mandatory=$false)]
        [String]$CmdDir
        )
    
   if((Get-Item ".\build\data\system.txt" -Force -ErrorAction SilentlyContinue) -eq $null)
    {New-Item -Path ".\build\data" -Name "system.txt" -Force | Out-Null}
   if((Get-Item ".\build\data\timetable.txt" -Force -ErrorAction SilentlyContinue) -eq $null)
    {New-Item -Path ".\build\data" -Name "timetable.txt" -Force | Out-Null}
    if(Test-Path ".\build\pid"){Remove-Item ".\build\pid\*" -Force | Out-Null}
    else{New-Item -Path ".\build" -Name "pid" -ItemType "Directory" -Force | Out-Null}   
}
