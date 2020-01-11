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

function Global:Get-Priority {
    Write-Host "Doing cpu_priority"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "NOTE: Interface is limited to the amount of information it can track.
    
cpu_priority   

[0, 2, or 5]            

sets the processor priorty for cpu mining.
0 is idle
2 is normal
5 is idles

Please select the priority you wish to use.

Answer"
        $Check = Global:Confirm-Answer $ans @("0", "1", "5")
    }While ($Check -eq 1)
    $ans = [Convert]::ToInt32($ans)
    if ($(vars).config.ContainsKey("cpu_priority")) { $(vars).config.cpu_priority = $ans } else { $(vars).config.Add("cpu_priority", $ans) }
}

function Global:Get-CPU { 
    switch ($(vars).input) {
        "49" { Global:Get-Priority }
    }
    
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $Confirm = Read-Host -Prompt "Do You Wish To Continue?
    
1 Yes
2 No

Answer"
        $check = Global:Confirm-Answer $Confirm @("1", "2")
        Switch ($Confirm) {
            "1" { $(vars).continue = $true }
            "2" { $(vars).continue = $false }
        }
    }while ($check -eq 1)
    
}
