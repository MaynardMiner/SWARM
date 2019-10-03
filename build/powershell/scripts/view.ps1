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

Param (
  [Parameter(Mandatory = $false)]
  [int]$n,
  [Parameter(Mandatory = $false, Position=0)]
  [string]$Command,
  [Parameter(Mandatory = $false, Position=1)]
  [string]$Arg1,
  [Parameter(Mandatory = $false, Position=2)]
  [string]$Arg2,
  [Parameter(Mandatory = $false, Position=3)]
  [string]$Arg3,
  [Parameter(Mandatory = $false, Position=4)]
  [string]$Arg4,
  [Parameter(Mandatory = $false, Position=5)]
  [string]$Arg5,
  [Parameter(Mandatory = $false, Position=6)]
  [string]$Arg6,
  [Parameter(Mandatory = $false, Position=7)]
  [string]$Arg7,
  [Parameter(Mandatory = $false, Position=8)]
  [string]$Arg8,
  [Parameter(Mandatory = $false, Position=9)]
  [string]$Arg9,
  [Parameter(Mandatory = $false, Position=10)]
  [string]$Arg10,
  [Parameter(Mandatory = $false)]
  [switch]$OnChange
)

if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
if(($IsWindows)){$Platform = "windows"}
if(-not $n){$n = 5}
[cultureinfo]::CurrentCulture = 'en-US'

While($True) {
  $OutPut = $null
  Invoke-Expression "$Command $Arg1 $Arg2 $Arg3 $Arg4 $Arg5 $Arg6 $Arg7 $Arg8 $Arg9 $Arg10" | Tee-Object -Variable Output | Out-Null;
  if($OnChange.IsPresent) {
    if([string]$Previous -ne [string]$OutPut) {
      if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
      Write-Host "Refreshing Screen Every $N seconds"  
      $Output; 
      $Previous = $OutPut
    }
  }
  else {
    if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
    Write-Host "Refreshing Screen Every $N seconds"
    $OutPut
  }
  Start-Sleep -S $n
}