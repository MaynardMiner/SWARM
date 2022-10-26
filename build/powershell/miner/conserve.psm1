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

function Global:Start-OCConserve {
    if ($(vars).WebSites -and $(vars).WebSites -ne "") {
        $GetNetMods = @($(vars).NetModules | ForEach-Object { Get-ChildItem $_ })
        $GetNetMods | ForEach-Object { Import-Module -Name "$($_.FullName)" }
        $(vars).WebSites | ForEach-Object {
            switch ($_) {
                "HiveOS" {
                    ## Do oc if they have API key
                    if ([string]$(arg).API_Key -ne "") {
                        $OC_Success = Global:Start-HiveTune "sha256"
                    }
                }
            }
        }
        $GetNetMods | ForEach-Object { Remove-Module -Name "$($_.BaseName)" }
    }
}
