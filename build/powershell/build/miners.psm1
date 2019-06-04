function Global:Get-minerfiles {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Types,
        [Parameter(Mandatory = $false)]
        [string]$Cudas
    )
 
    $miner_update = [PSCustomObject]@{ }

    switch ($Types) {
        "CPU" {
            if ($Global:Config.params.Platform -eq "linux") { $global:Config.Params.Update = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json }
            elseif ($Global:Config.params.Platform -eq "windows") { $global:Config.Params.Update = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json }
        }

        "NVIDIA" {
            if ($Global:Config.params.Platform -eq "linux") {
                if ($Cudas -eq "10") { $global:Config.Params.Update = Get-Content ".\config\update\nvidia10-linux.json" | ConvertFrom-Json }
                if ($Cudas -eq "9.2") { $global:Config.Params.Update = Get-Content ".\config\update\nvidia9.2-linux.json" | ConvertFrom-Json }
            }
            elseif ($Global:Config.params.Platform -eq "windows") { $global:Config.Params.Update = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json }
        }

        "AMD" {
            if ($Global:Config.params.Platform -eq "linux") { $global:Config.Params.Update = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json }
            elseif ($Global:Config.params.Platform -eq "windows") { $global:Config.Params.Update = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json }
        }
    }

    $global:Config.Params.Update | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { if ($_ -ne "name") { $miner_update | Add-Member $global:Config.Params.Update.$_.Name $global:Config.Params.Update.$_ } }

    $miner_update

}
