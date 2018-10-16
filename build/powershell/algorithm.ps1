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
function Get-AlgoList {
    param(
        [Parameter(Mandatory=$true)]
        [Array]$Devices,
        [Parameter(Mandatory=$false)]
        [Array]$No_Algo
         )

    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

    $AlgorithmList = @()
    $GetAlgorithms = Get-Content ".\config\naming\get-pool.txt" -Force | ConvertFrom-Json
    $PoolAlgorithms = @()
    $GetAlgorithms | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
     $PoolAlgorithms += $_
    }
    
    if($No_Algo -ne $null)
     {
     $GetNoAlgo = Compare-Object $No_Algo $PoolAlgorithms
     $GetNoAlgo.InputObject | foreach{$AlgorithmList += $_}
     }
     else{$PoolAlgorithms | foreach { $AlgorithmList += $($_)} }
         
    $AlgorithmList
}
