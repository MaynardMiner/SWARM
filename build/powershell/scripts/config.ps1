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

## Send Config Command
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$config_name,
    [Parameter(Mandatory = $false, Position = 1)]
    [string]$json_content
)

$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp", "/root"
Set-Location $dir
Clear-Content ".\build\txt\get.txt"
[cultureinfo]::CurrentCulture = 'en-US'

$Get = @()
$continue = $true

if (-not $config_name -and $continue -eq $true) {
    Write-Host "no config name specified"; 
    $Get += "no config name specified";
    $continue = $false
}

if (-not $json_content -and $continue -eq $true) {
    Write-Host "no json data specified"; 
    $Get += "no json data specified"
    $continue = $false
}

$json_content = $json_content.Substring(1)
$json_content = $json_content.substring(0,$json_content.Length-1)

## Test if .json
if ($continue -eq $true) { 
    try { $json = $json_content | ConvertFrom-Json -ErrorAction Stop } catch {
        Write-Host "content sent was not valid json"; 
        $Get += "content sent was not valid json"
        $continue = $false
    }
}

if ($continue -eq $true) { 
    $filepaths = Get-ChildItem ".\config"
    $filepaths | % { $List = Get-ChildItem $_; if ($config_name -in $List.BaseName) { $Item = $_ } }
    if (-not $Item) {
        $Get += "No config found that matches $config_name"
        Write-Host "No config found that matches $config_name"
        $continue = $false
    }
}
if ($continue -eq $true) { 
    $Get += "Found config that matches $Config_name in $($Item.Basename) directory"
    Write-Host "Found config that matches $Config_name in $($Item.Basename) directory"
    try { 
        $json | ConvertTo-Json -Depth 10 | Set-Content "$Item\$Config_name.json" -ErrorAction Stop 
        $Get += "New $Config_Name saved! You may need to restart SWARM."
        Write-Host "New $Config_Name saved! You may need to restart SWARM."
    }
    catch {
        $Get += "Failed to write $Config_Name to $($Item.BaseName) directory"
        Write-Host "Failed to write $Config_Name to $($Item.BaseName) directory"
        $continue = $false
    }
}

$Get | Set-Content ".\build\txt\get.txt"