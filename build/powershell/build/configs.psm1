function Global:Get-MinerConfigs {
    if ($(arg).Type -like "*AMD*" -or $(arg).Type -like "*NVIDIA*" -or $(arg).Type -like "*CPU*") {
        $Configs = Get-ChildItem ".\config\miners" | Where-Object  Extension -ne ".md"
        $Configs.Name | Foreach-Object  {
            $FileDir = Join-Path ".\config\miners" $_
            $A = Get-Content $FileDir | ConvertFrom-Json
            if (-not $global:Config.miners) { $global:Config.Add("miners", @{ })
            }
            if ($A.Name -notin $global:Config.miners.keys) { $global:Config.miners.Add($A.Name, $A) }
        }
    }
}

function Global:Add-ASICS {

    if ($(arg).ASIC_ALGO -and $(arg).ASIC_ALGO -ne "") {
        $(arg).ASIC_ALGO | ForEach-Object {
            if ($_ -notin $global:Config.Pool_Algos.PSObject.Properties.Name) {
                $global:Config.Pool_Algos | add-Member "$($_)" ([PSCustomObject]@{alt_names = $_; exclusions = @("add pool or miner here", "comma seperated") })
                $global:Config.Pool_Algos | ConvertTo-Json -Depth 5 | Set-Content ".\config\pools\pool-algos.json"
            }
        } 
    }
    ## Parse ASIC_IP
    if ($(arg).Type -like "*ASIC*") {
        if ($(arg).ASIC_IP -and $(arg).ASIC_IP -ne "") {
            $ASIC_COUNT = 1
            $Config.Params.ASIC_IP | ForEach-Object {
                $SEL = $_ -Split "`:"
                $(vars).ASICS.ADD("ASIC$ASIC_COUNT", @{IP = $($SEL | Select-Object  -First 1) })
                if ($SEL.Count -gt 1) {
                    $(vars).ASICS."ASIC$ASIC_COUNT".ADD("NickName", $($SEL | Select-Object  -Last 1))
                }
                $ASIC_COUNT++
            }
        }
    }
    elseif (Test-Path ".\config\miners\asic.json") {
        $(vars).ASICS = @{ }
        $ASIC_COUNT = 1
        $ASICList = Get-Content ".\config\miners\asic.json" | ConvertFrom-Json
        if ($ASICList.ASIC.ASIC1.IP -ne "IP ADDRESS") {
            $ASICList.ASICS.PSObject.Properties.Name | ForEach-Object {
                $(vars).ASICS.ADD("ASIC$ASIC_COUNT", @{IP = $ASICList.ASICS.$_.IP; NickName = $ASICList.ASICS.$_.NickName })
                $ASIC_COUNT++
            }
        }
    }
    
    if ($(vars).ASICS.Count -gt 0) {
        $(vars).ASICS.Keys | ForEach-Object {
            if ($_ -notin $(arg).Type) {
                $(arg).Type += $_
            }
        }
    }

    $(arg).Type = $(arg).Type | Where-Object  { $_ -ne "ASIC" }
    if ($(arg).Type -like "*ASIC*") { $(arg).Type | Where-Object  { $_ -like "*ASIC*" } | Foreach-Object  { $(vars).ASICTypes += $_ } }
    if ($(arg).ASIC_IP -eq "") { $(arg).ASIC_IP = "localhost" }
}
