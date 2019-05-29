function Get-PoolTables {
    $global:FeeTable.Add("zpool", @{ })
    $global:FeeTable.Add("zergpool", @{ })
    $global:FeeTable.Add("fairpool", @{ })

    $global:divisortable.Add("zpool", @{ })
    $global:divisortable.Add("zergpool", @{ })
    $global:divisortable.Add("fairpool", @{ })
    
    if ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "" -and $SWARMAlgorithm.Count -eq 1 -and $global:Config.Params.SWARM_Mode -ne "") {
        $global:SingleMode = $true
    }
}

function Remove-BanHashrates {
    Write-Log "Loading Miner Hashrates" -ForegroundColor Yellow
    if ($global:BanHammer -gt 0 -and $global:BanHammer -ne "") {
        if (test-path ".\stats") { $A = Get-ChildItem "stats" | Where BaseName -Like "*hashrate*" }
        $global:BanHammer | ForEach-Object {
            $Sel = $_.ToLower()
            $Sel = $Sel -replace "`/","`-"
            $Sel = $Sel -replace "`_","`-"        
            $A.BaseName | ForEach-Object {
                $Parse = $_ -split "`_"
                if ($Parse[0] -eq $Sel) {
                    Remove-Item ".\stats\$($_).txt" -Force
                }
                elseif ($Parse[1] -eq $Sel) {
                    Remove-Item ".\stats\$($_).txt" -Force
                }
            }
        }
    }
}
function Get-MinerHashTable {
    Invoke-Expression ".\build\powershell\scripts\get.ps1 benchmarks all -asjson" | Tee-Object -Variable Miner_Hash | Out-Null
    if ($Miner_Hash -and $Miner_Hash -ne "No Stats Found") {
        $Miner_Hash = $Miner_Hash | ConvertFrom-Json
    }
    else { $Miner_Hash = $null }

    $TypeTable = @{ }
    $cpu.PSobject.Properties.Name | %{ if($_ -ne "name"){$TypeTable.Add("$($_)","CPU")} }
    $amd.PSObject.Properties.Name | %{if($_ -ne "name"){$TypeTable.Add("$($_)-1","AMD1")}}
    $nvidia.PSObject.Properties.Name | % {
        if($_ -ne "name"){
            $TypeTable.Add("$($_)-1","NVIDIA1")
            $TypeTable.Add("$($_)-2","NVIDIA2")
            $TypeTable.Add("$($_)-3","NVIDIA3")
        }
    }
    $SELASIC = $global:Config.Params.Type | Where {$_ -like "*ASIC*"}

    $SELASIC | %{
        $SelType = $_
        $SelNum = $_ -replace "ASIC",""
        $TypeTable.Add("$($_)-$SelNum",$SelType)
    }

    if ($Miner_Hash) {
        $Miner_Hash | % { $_ | Add-Member "Type" $TypeTable.$($_.Miner) }
        $NotBest = @()
        $Miner_Hash.Algo | % {
            $A = $_
            $global:Config.Params.Type | % {
                $T = $_
                $Sel = $Miner_Hash | Where Algo -eq $A | Where Type -EQ $T
                $NotBest += $Sel | Sort-Object RAW -Descending | Select-Object -Skip 1
            }
        }
        $Miner_Hash | % { $Sel = $NotBest | Where Miner -eq $_.Miner | Where Algo -eq $_.Algo | Where Type -eq $_.Type; if ($Sel) { $_.Raw = "Bad" } }
    }

    $Miner_Hash
}
