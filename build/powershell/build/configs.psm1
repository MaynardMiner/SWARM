function Global:Get-MinerConfigs {
    if ($Global:config.Params.Type -like "*AMD*" -or $Global:config.params.Type -like "*NVIDIA*" -or $Global:config.params.Type -like "*CPU*") {
        $Configs = Get-ChildItem ".\config\miners"
        $Configs.Name | % {
            $FileDir = Join-Path ".\config\miners" $_
            $A = Get-Content $FileDir | ConvertFrom-Json
            if (-not $global:Config.miners) { $global:Config.Add("miners", @{ })
            }
            if ($A.Name -notin $global:Config.miners.keys) { $global:Config.miners.Add($A.Name, $A) }
        }
    }
}

function Global:Add-ASICS {

    if ($global:Config.Params.ASIC_ALGO -and $global:Config.Params.ASIC_ALGO -ne "") {
        $global:Config.Params.ASIC_ALGO | ForEach-Object {
            if ($_ -notin $global:Config.Pool_Algos.PSObject.Properties.Name) {
                $global:Config.Pool_Algos | Add-Member $_ @{"alt_names" = $_; exclusions = @("add pool or miner here", "comma seperated") }
                $global:Config.Pool_Algos | Set-Content ".\config\pools\pool-algos.json"
            }
        } 
    }
    ## Parse ASIC_IP
    if ($Global:config.Params.ASIC_IP -and $Global:config.Params.ASIC_IP -ne "") {
        $ASIC_COUNT = 1
        $Config.Params.ASIC_IP | ForEach-Object {
            $SEL = $_ -Split "`:"
            $global:ASICS.ADD("ASIC$ASIC_COUNT", @{IP = $($SEL | Select -First 1) })
            if ($SEL.Count -gt 1) {
                $global:ASICS."ASIC$ASIC_COUNT".ADD("NickName", $($SEL | Select -Last 1))
            }
            $ASIC_COUNT++
        }
    }
    elseif (Test-Path ".\config\miners\asic.json") {
        $global:ASICS = @{ }
        $ASIC_COUNT = 1
        $ASICList = Get-Content ".\config\miners\asic.json" | ConvertFrom-Json
        if ($ASICList.ASIC.ASIC1.IP -ne "IP ADDRESS") {
            $ASICList.ASICS.PSObject.Properties.Name | ForEach-Object {
                $global:ASICS.ADD("ASIC$ASIC_COUNT", @{IP = $ASICList.ASICS.$_.IP; NickName = $ASICList.ASICS.$_.NickName })
                $ASIC_COUNT++
            }
        }
    }
    
    if ($Global:ASICS.Count -gt 0) {
        $Global:ASICS.Keys | ForEach-Object {
            if ($_ -notin $Global:Config.Params.Type) {
                $Global:Config.Params.Type += $_
            }
        }
    }

    $Global:Config.Params.Type = $GLobal:Config.Params.Type | Where { $_ -ne "ASIC" }
    if ($global:Config.Params.Type -like "*ASIC*") { $global:Config.Params.Type | Where { $_ -like "*ASIC*" } | % { $Global:ASICTypes += $_ } }
    if ($global:Config.Params.ASIC_IP -eq "") { $global:Config.Params.ASIC_IP = "localhost" }
}
