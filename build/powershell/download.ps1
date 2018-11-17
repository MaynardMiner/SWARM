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
        [Parameter(Mandatory=$false)]
        [String]$Uri,
	    [Parameter(Mandatory=$false)]
	    [String]$BuildPath,
	    [Parameter(Mandatory=$false)]
	    [String]$Path,
        [Parameter(Mandatory=$false)]
	    [String]$MineName,
	    [Parameter(Mandatory=$false)]
        [String]$MineType
          )
          
if (-not (Test-Path ".\bin")) {New-Item "bin" -ItemType "directory" | Out-Null; Start-Sleep -S 3}
if (-not (Test-Path ".\x64")) {New-Item "x64" -ItemType "directory" | Out-Null; Start-Sleep -S 3}
if (-not $Path) {$Path = Join-Path ".\x64" ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName}
$Old_Path = Split-Path $Uri -Parent
$FileName1 = Join-Path ".\x64" (Split-Path $Uri -Leaf)
$New_Path = Split-Path $Old_Path -Leaf
$FileName = Join-Path ".\bin" $New_Path


    if($BuildPath -eq "Linux")
     {
        if(-not (Test-Path $Filename))
        {
        Start-Process "apt-get" "-y install git automake autoconf pkg-config libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev make g++" -Wait
        Write-Host "Cloning Miner" -BackgroundColor "Red" -ForegroundColor "White"
        Set-Location ".\bin"
        Start-Process -FilePath "git" -ArgumentList "clone $Uri $New_Path" -Wait
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
        Write-Host "Building Miner" -BackgroundColor "Red" -ForegroundColor "White"
        Set-Location $Filename
        Start-Process -Filepath "chmod" -ArgumentList "+x ./configure.sh" -Wait
        Start-Process -Filepath "bash" -ArgumentList "autogen.sh" -Wait
        Start-Process -Filepath "bash" -ArgumentList "configure" -Wait
        Start-Process -FilePath "bash" -ArgumentList "build.sh" -Wait
        Start-Sleep -S 10
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
        Write-Host "Miner Completed!" -BackgroundColor "Red" -ForegroundColor "White"
        }
     }

     if($BuildPath -eq "Dpkg")
     {
      if(Test-Path "/usr/bin/$MineName")
      {
       Write-Host "Detected Excavator Installation" -ForegroundColor Green
       if(Test-Path $Path){Remove-Item $Path -Recurse}
       New-Item $Path -ItemType "directory"
       Copy-Item "/usr/bin/$MineName" -Destination $Path
      }
      else{
        $DownloadFileURI = Split-Path "$Uri" -Leaf
        Write-Host "Did Not Detect Excavator Installion Attempting install" -ForegroundColor yellow
        Start-Process -Filepath "wget" -ArgumentList "$Uri -O x64/$DownloadFileURI" -Wait
        Start-Process "dpkg" -ArgumentList "-i x64/$DownloadFileURI" -Wait
        Start-Process "apt-get" -ArgumentList "install -y -f" -Wait
        if(Test-Path $Path){Remove-Item $Path -Recurse}
        New-Item $Path -ItemType "directory"
        if(Test-Path "/usr/bin/$MineName")
        {
          Write-Host "Excavator Was Installed!" -ForegroundColor Green
          Copy-Item "/usr/bin/$MineName" -Destination $Path
        }
        else{Write-Host "Excavator Installation Failed- Install Manually" -ForegroundColor Red}
      }
     }

     if($BuildPath -eq "Zip")
      {
       if (-not $Path) {$Path = Join-Path ".\x64" ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName}
       $FileName = Join-Path ".\x64" (Split-Path $Uri -Leaf)
       if (Test-Path $FileName) {Remove-Item $FileName}
       [System.Net.ServicePointManager]::SecurityProtocol = ("Tls12","Tls11","Tls")
       Invoke-WebRequest $Uri -OutFile $FileName -UseBasicParsing
       
       if (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) {Start-Process $FileName "-qb" -Wait}
       else {
       $Path_Old = (Join-Path (Split-Path $Path) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
       $Path_New = (Join-Path (Split-Path $Path) (Split-Path $Path -Leaf))

       if (Test-Path $Path_Old) {Remove-Item $Path_Old -Recurse}
       Start-Process "7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait
       if (Test-Path $Path_New) {Remove-Item $Path_New -Recurse}
       
       if (Get-ChildItem $Path_Old | Where-Object PSIsContainer -EQ $false) {Rename-Item $Path_Old (Split-Path $Path -Leaf)}
       else {
             Get-ChildItem $Path_Old | Where-Object PSIsContainer -EQ $true | ForEach-Object {Move-Item (Join-Path $Path_Old $_) $Path_New}
             Remove-Item $Path_Old -Recurse
       }
      }
     }

    if($BuildPath -eq "Tar")
     {
        $DownloadFileURI = Split-Path "$Uri" -Leaf
        $DownloadFileName = $DownloadFileURI -replace (".tar.gz","")
        $TargzPath = Join-Path ".\x64" "$($DownloadFileName)"
        $NewTargzPath = Join-Path ".\bin" "$($DownloadFileName)"
        
        Write-Host "Download Directory is $TargzPath"
        Write-Host "Miner Exec is $NewTargzPath"
        Write-Host "Miner Path is $Path"
    
        if(Test-Path $TargzPath){Remove-Item $TargzPath -Recurse -Force}
        
        Write-Host "Downloading .tar.gz File." -ForegroundColor Green
        
        Start-Process -Filepath "wget" -ArgumentList "$Uri -O x64/$DownloadFileURI" -Wait
        if(Test-Path $NewTargzPath){Remove-Item $NewTargzPath -recurse}
        $Path_New = Join-Path ".\bin" (Split-Path $Path -Leaf)
        
        Set-Location ".\x64"
        Start-Process "tar" -ArgumentList "-xzvf $DownloadFileURI" -Wait
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
        if(Test-Path $Path_New){Remove-Item $Path_New -Recurse -Force; Start-Sleep -S 1}
        Copy-Item $TargzPath -Destination ".\bin" -Recurse
        Rename-Item $NewTargzPath (Split-Path $Path_New -Leaf)
        Remove-Item $TargzPath -Recurse -Force
    
        if($MineName -eq "lyclMiner")
         {
          Set-Location $Path_New
          Start-Process "./lyclMiner" -ArgumentList "-g lyclMiner.conf" -Wait
          Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
         }
        
        if($MinerType -like "*AMD*" -or $MinerType -like "*NVIDIA*")
         {
           Set-Location $Path_New
           Start-Process "chmod" -ArgumentLIst "+x $MineName"
           Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
         }
       }
    }
    

