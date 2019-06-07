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

function Global:Add-LogErrors {
    if ($Error.Count -gt 0) {
        $TimeStamp = (Get-Date)
        $errormesage = "[$TimeStamp]: SWARM Generated The Following Warnings/Errors-"
        $errormesage | Add-Content $(vars).logname
        $Message = @()
        $error | foreach { $Message += "$($_.InvocationInfo.InvocationName)`: $($_.Exception.Message)"; $Message += $_.InvocationINfo.PositionMessage; $Message += $_.InvocationInfo.Line; $Message += $_.InvocationINfo.Scriptname; $MEssage += "" }
        $Message | Add-Content $(vars).logname
        $error.clear()
    }
}

function Global:Write-Log {
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$In,
        [Parameter(Mandatory = $false)]
        [string]$ForeGroundColor,
        [Parameter(Mandatory = $false)]
        [string]$ForeGround,
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,
        [Parameter(Mandatory = $false)]
        [switch]$Start,
        [Parameter(Mandatory = $false)]
        [switch]$End
    )
    
    $Date = (Get-Date)
    $File = $(vars).logname

    if ($ForeGround) { $Color = $ForeGround }
    if ($ForeGroundColor) { $Color = $ForeGroundColor }

    if ($NoNewLine) {
        if ($Start) { Add-Content -Path $File -Value "[$Date]`: " -NoNewline }
        Add-Content -Path $file -Value "$In" -NoNewline
    } 
    else {
        if ($End) { Add-Content -Path $file -Value "$In" }
        else { Add-Content -Path $file -Value "[$Date]`: $In" }
    }


    if ($NoNewLine) {
        if ($ForeGroundColor -or $ForeGround) {
            if ($Start) { Write-Host "[$Date]`: " -NoNewline }
            Write-Host $In -ForeGroundColor $Color -NoNewline
        } 
        else {
            if ($Start) { Write-Host "[$Date]`: " -NoNewline }
            Write-Host $In -NoNewline
        }
    }
    else {
        if ($ForeGroundColor -or $ForeGround) {
            if ($End) { Write-Host "$In" -ForeGroundColor $Color }
            else {
                Write-Host "[$Date]`: " -NoNewline
                Write-Host "$In" -ForegroundColor $Color
            }
        }
        else {
            if ($End) { Write-Host "$In" }
            else {
                Write-Host "[$Date]`: " -NoNewline
                Write-Host "$In"
            }
        }
    }

}

function Global:Get-ChildItemContent {
    param(
        [Parameter(Mandatory = $false)]
        [String]$Path,
        [Parameter(Mandatory = $false)]
        [array]$Items
    )

    if ($Items) { $Child = $Items }
    else { $Child = Get-ChildItem $Path }

    $ChildItems = $Child | ForEach-Object {
        $Name = $_.BaseName
        $FullName = $_.FullName
        $Content = @()
        if ($_.Extension -eq ".ps1") {
            $Content = &$_.FullName
        }
        else {
            try { $Content = $_ | Get-Content | ConvertFrom-Json }catch { Global:Write-Log "WARNING: Could Not Identify $FullName, It Is Corrupt- Remove File To Stop." -ForegroundColor Red }
        }
        $Content | ForEach-Object {
            [PSCustomObject]@{Name = $Name; Content = $_ }
        }
    }

    $ChildItems | ForEach-Object {
        $Item = $_
        $ItemKeys = $Item.Content.PSObject.Properties.Name.Clone()
        $ItemKeys | ForEach-Object {
            if ($Item.Content.$_ -is [String]) {
                $Item.Content.$_ = Invoke-Expression "`"$($Item.Content.$_)`""
            }
            elseif ($Item.Content.$_ -is [PSCustomObject]) {
                $Property = $Item.Content.$_
                $PropertyKeys = $Property.PSObject.Properties.Name
                $PropertyKeys | ForEach-Object {
                    if ($Property.$_ -is [String]) {
                        $Property.$_ = Invoke-Expression "`"$($Property.$_)`""
                    }
                }
            }
        }
    }

    $AllContent = New-Object System.Collections.ArrayList
    $ChildItems | % { $AllContent.Add($_) | Out-Null }
    $AllContent
}

function Global:start-killscript {

    ##Clear-Screens In Case Of Restart
    $OpenScreens = @()
    $OpenScreens += "NVIDIA1"
    $OpenScreens += "NVIDIA2"
    $OpenScreens += "NVIDIA3"
    $OpenScreens += "AMD1"
    $OpenScreens += "AMD2"
    $OpenScreens += "AMD3"
    $OpenScreens += "CPU"
    $OpenScreens += "OC_AMD"
    $OpenScreens += "OC_NVIDIA1"
    $OpenScreens += "OC_NVIDIA2"
    $OpenScreens += "OC_NVIDIA3"
    $OpenScreens += "pill-NVIDIA1"
    $OpenScreens += "pill-NVIDIA2"
    $OpenScreens += "pill-NVIDIA3"
    $OpenScreens += "API"
    $OpenScreens | foreach {
        Start-Process ".\build\bash\killall.sh" -ArgumentList $_ -Wait
    }
    Start-Process ".\build\bash\killall.sh" -ArgumentList "background" -Wait
}