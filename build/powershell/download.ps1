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

function Expand-WebRequest {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Uri,
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$Path
    )

    $Zip = Split-Path $Uri -Leaf; $BinPath = (Split-Path $Path); $BinPath = (Split-Path $BinPath -Leaf);
    $Name = (Split-Path $Path -Leaf); $X64_zip = Join-Path ".\x64" $Zip;
    $BaseName = $( (Split-Path $Path -Leaf) -split "\.") | Select -First 1
    $X64_extract = $( (Split-Path $URI -Leaf) -split "\.") | Select -First 1;
    $MoveThere = Split-Path $Path; $temp = "$($BaseName)_Temp"

    ##First Determine the file type:
    $FileType = $Zip
    $FileType = $FileType -split "\."
    if ("7z" -in $FileType) { $Extraction = "zip" }
    if ("zip" -in $FileType) { $Extraction = "zip" }
    if ("tar" -in $FileType) { $Extraction = "tar" }

    if($Extraction -eq "tar") {
        if("gz" -in $FileType) { $Tar = "gz"}
        if("xz" -in $FileType) { $Tar = "xz"}
    }

    ##Delete any old download attempts - Start Fresh
    if (Test-Path $X64_zip) { Remove-Item $X64_zip -Recurse -Force }
    if (Test-Path $X64_extract) { Remove-Item $X64_extract -Recurse -Force }
    if (Test-Path ".\bin\$BinPath") { Remove-Item ".\bin\$BinPath" -Recurse -Force }
    if (Test-Path ".\x64\$temp") { Remove-Item ".x64\$temp" -Recurse -Force }

    ##Make Dirs if not there
    if (-not (Test-Path ".\bin")) { New-Item "bin" -ItemType "directory" | Out-Null; Start-Sleep -S 1 }
    if (-not (Test-Path ".\x64")) { New-Item "x64" -ItemType "directory" | Out-Null; Start-Sleep -S 1 }

    Switch ($Extraction) {
    
        "tar" {
            Write-Log "Download URI is $URI"
            Write-Log "Miner Exec is $Name"
            Write-Log "Miner Dir is $MoveThere"
            Start-Process -Filepath "wget" -ArgumentList "$Uri -O x64/$Zip" -Wait

            if (Test-Path "$X64_zip") { Write-Log "Download Succeeded!" -ForegroundColor Green }
            else { Write-Log "Download Failed!" -ForegroundColor DarkRed; break }

            Write-Log "Extracting to temporary folder" -ForegroundColor Yellow
            New-Item -Path ".\x64\$temp" -ItemType "Directory" -Force | Out-Null; Start-Sleep -S 1
            switch($Tar) {
             "gz"{Start-Process "tar" -ArgumentList "-xzvf x64/$Zip -C x64/$temp" -Wait}
             "xz"{Start-Process "tar" -ArgumentList "-xvJf x64/$Zip -C x64/$temp" -Wait}
            }

            $Stuff = Get-ChildItem ".\x64\$Temp"
            if ($Stuff) { Write-Log "Extraction Succeeded!" -ForegroundColor Green }
            else { Write-Log "Extraction Failed!" -ForegroundColor darkred; break }

            ##Now the fun part find the dir that the exec is in.
            $Search = Get-ChildItem -Path ".\x64\$temp" -Filter "$Name" -Recurse -ErrorAction SilentlyContinue
            if (-not $Search) { Write-Log "Miner Executable Not Found" -ForegroundColor DarkRed; break }
            $Contents = $Search.Directory.FullName | Select -First 1
            $DirName = Split-Path $Contents -Leaf
            Move-Item -Path $Contents -Destination ".\bin" -Force | Out-Null; Start-Sleep -S 1
            Rename-Item -Path ".\bin\$DirName" -NewName "$BinPath" | Out-Null; Start-Sleep -S 1
            if (Test-Path $Path) { Write-Log "Finished Successfully!" -ForegroundColor Green }
            if (Test-Path ".\x64\$Temp") { Remove-Item ".\x64\$Temp" -Recurse -Force | Out-Null }
        }
        "zip" {
            Write-Log "Download URI is $URI"
            Write-Log "Miner Exec is $Name"
            Write-Log "Miner Dir is $MoveThere"
            Invoke-WebRequest $Uri -OutFile "$X64_zip" -UseBasicParsing
            if (Test-Path "$X64_zip") { Write-Log "Download Succeeded!" -ForegroundColor Green }
            else { Write-Log "Download Failed!" -ForegroundColor DarkRed; break }

            New-Item -Path ".\x64\$temp" -ItemType "Directory" -Force | Out-Null; Start-Sleep -S 1
            Start-Process ".\build\apps\7z.exe" "x `"$dir\$X64_zip`" -o`"$dir\x64\$temp`" -y" -Wait -WindowStyle Minimized -verb Runas

            $Stuff = Get-ChildItem ".\x64\$Temp"
            if ($Stuff) { Write-Log "Extraction Succeeded!" -ForegroundColor Green }
            else { Write-Log "Extraction Failed!" -ForegroundColor darkred; break }

            $Search = Get-ChildItem -Path ".\x64\$temp" -Filter "$Name" -Recurse -ErrorAction SilentlyContinue
            if (-not $Search) { Write-Log "Miner Executable Not Found" -ForegroundColor DarkRed; break }
            $Contents = $Search.Directory.FullName | Select -First 1
            $DirName = Split-Path $Contents -Leaf
            Move-Item -Path $Contents -Destination ".\bin" -Force | Out-Null; Start-Sleep -S 1
            Rename-Item -Path ".\bin\$DirName" -NewName "$BinPath" | Out-Null
            if (Test-Path $Path) { Write-Log "Finished Successfully!" -ForegroundColor Green }
            if (Test-Path ".\x64\$Temp") { Remove-Item ".\x64\$Temp" -Recurse -Force | Out-Null }
        }

    }
}
    

