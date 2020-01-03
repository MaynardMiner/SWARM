<#

Startup checks and initial setup

#>

Using namespace System;
Using module ".\helper.psm1";

class startup {
    ## Make folders if they don't exsist.
    static [void] make_folders(){
        [string[]]$Folders = @()
        $Folders += 'stats'
        $Folders += 'logs'
        $Folders += 'debug'

        foreach($Folder in $Folders) {
            [string]$Path = [IO.Path]::Join($Global:Dir,$Folder)
            [bool]$Check = [IO.Directory]::Exists($Path)
            if(-not $Check) {
                New-Item -ItemType Directory -Path $Global:Dir -Name $folder | Out-Null
            }
        }
    }
}