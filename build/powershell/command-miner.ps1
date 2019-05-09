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
function Get-Miners {
    param (
        [Parameter(Mandatory = $true)]
        [Array]$Pools
    )

    ## Reset Arrays In Case Of Weirdness
    $GetPoolBlocks = $null
    $GetAlgoBlocks = $null
    $GetMinerBlocks = $null
    $GPUMiners = $false
    $ASICMiners = $false
    $NVB = $false
    $AMDB = $false
    $CPUB = $false

    $Global:Config.Params.Type | ForEach-Object {
        if ($_ -like "*ASIC*") { $ASICMiners = $true }
        if ($_ -like "*NVIDIA*") { $NVB = $true; $GPUMiners = $true }
        if ($_ -like "*AMD*") { $AMDB = $true; $GPUMiners = $true }
        if ($_ -like "*CPU*") { $CPUB = $true; $GPUMiners = $true }
    }


    ## Pool Bans From File && Specify miner folder based on platform
    if (Test-Path ".\timeout\pool_block\pool_block.txt") { $GetPoolBlocks = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json }
    if (Test-Path ".\timeout\algo_block\algo_block.txt") { $GetAlgoBlocks = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json }
    if (Test-Path ".\timeout\miner_block\miner_block.txt") { $GetMinerBlocks = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json }

    ## Start Running miner scripts, Create an array of Miner Hash Tables
    $GetMiners = New-Object System.Collections.ArrayList

    if ($GPUMiners -eq $true) {
        if ($NVB -eq $true) {
            $minerfilepath = ".\miners\gpu\nvidia"    
            $NVIDIAMiners = if (Test-Path $minerfilepath) { Get-ChildItemContent $minerfilepath | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
                Where-Object { $global:Config.Params.Type.Count -eq 0 -or (Compare-Object $global:Config.Params.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
                Where-Object { $_.Path -ne "None" } |
                Where-Object { $_.Uri -ne "None" } |
                Where-Object { $_.MinerName -ne "None" }
            }
        }
        if ($AMDB -eq $true) {
            $minerfilepath = ".\miners\gpu\amd"    
            $AMDMiners = if (Test-Path $minerfilepath) { Get-ChildItemContent $minerfilepath | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
                Where-Object { $global:Config.Params.Type.Count -eq 0 -or (Compare-Object $global:Config.Params.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
                Where-Object { $_.Path -ne "None" } |
                Where-Object { $_.Uri -ne "None" } |
                Where-Object { $_.MinerName -ne "None" }
            }
        }
        if ($CPUB -eq $true) {
            $minerfilepath = ".\miners\cpu"
            $CPUMiners = if (Test-Path $minerfilepath) { Get-ChildItemContent $minerfilepath | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
                Where-Object { $global:Config.Params.Type.Count -eq 0 -or (Compare-Object $global:Config.Params.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
                Where-Object { $_.Path -ne "None" } |
                Where-Object { $_.Uri -ne "None" } |
                Where-Object { $_.MinerName -ne "None" }
            }
        }

        if ($NVIDIAMiners) { $NVIDIAminers | ForEach-Object { $_.Name = $_.MName; $GetMiners.Add($_) | Out-Null } }
        if ($AMDMiners) { $AMDMiners | ForEach-Object { $_.Name = $_.MName; $GetMiners.Add($_) | Out-Null } }
        if ($CPUMiners) { $CPUMiners | ForEach-Object { $_.Name = $_.MName; $GetMiners.Add($_) | Out-Null } }
        
        $NVIDIA1EX = $GetMiners | Where-Object TYPE -eq "NVIDIA1" | ForEach-Object { if ($No_Algo1 -contains $_.Algo) { $_ } }
        $NVIDIA2EX = $GetMiners | Where-Object TYPE -eq "NVIDIA2" | ForEach-Object { if ($No_Algo2 -contains $_.Algo) { $_ } }
        $NVIDIA3EX = $GetMiners | Where-Object TYPE -eq "NVIDIA3" | ForEach-Object { if ($No_Algo3 -contains $_.Algo) { $_ } }
        $AMD1EX = $GetMiners | Where-Object TYPE -eq "AMD1" | ForEach-Object { if ($No_Algo1 -contains $_.Algo) { $_ } }
        $AMD2EX = $GetMiners | Where-Object TYPE -eq "AMD2" | ForEach-Object { if ($No_Algo2 -contains $_.Algo) { $_ } }
        $AMD3EX = $GetMiners | Where-Object TYPE -eq "AMD3" | ForEach-Object { if ($No_Algo3 -contains $_.Algo) { $_ } }

        $NVIDIA1EX | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
        $NVIDIA2EX | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
        $NVIDIA3EX | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
        $AMD1EX | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
        $AMD2EX | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
        $AMD3EX | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
    }
    if ($ASICMiners -eq $True) {
        $minerfilepath = ".\miners\asic"    
        $ASICMiners = if (Test-Path $minerfilepath) { Get-ChildItemContent $minerfilepath | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } |
            Where-Object { $global:Config.Params.Type.Count -eq 0 -or (Compare-Object $global:Config.Params.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } |
            Where-Object { $_.Path -ne "None" } |
            Where-Object { $_.Uri -ne "None" } |
            Where-Object { $_.MinerName -ne "None" }
        }
        $ASICMiners | ForEach-Object { $GetMiners.Add($_) | Out-Null }
        $ASICEX = $GetMiners | Where-Object TYPE -eq "ASIC" | ForEach-Object { if ($No_Algo1 -contains $_.Algo) { $_ } }
        $ASICEX | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
    }
        
    $Note = @()
    $ScreenedMiners = @()

    ## This Creates A New Array Of Miners, Screening Miners That Were Bad. As it does so, it notfies user.
    $GetMiners | ForEach-Object {
      
        $TPoolBlocks = $GetPoolBlocks | Where-Object Algo -eq $_.Algo | Where-Object Name -eq $_.Name | Where-Object Type -eq $_.Type | Where-Object MinerPool -eq $_.Minerpool
        $TAlgoBlocks = $GetAlgoBlocks | Where-Object Algo -eq $_.Algo | Where-Object Name -eq $_.Name | Where-Object Type -eq $_.Type
        $TMinerBlocks = $GetMinerBlocks | Where-Object Name -eq $_.Name | Where-Object Type -eq $_.Type

        if ($TPoolBlocks) {
            $Warning = "Warning: Blocking $($_.Name) mining $($_.Algo) on $($_.MinerPool) for $($_.Type)"; 
            if ($Note -notcontains $Warning) { $Note += $Warning }
            $ScreenedMiners += $_
        }
        elseif ($TAlgoBlocks) {
            $Warning = "Warning: Blocking $($_.Name) mining $($_.Algo) on all pools for $($_.Type)"; 
            if ($Note -notcontains $Warning) { $Note += $Warning }
            $ScreenedMiners += $_
        }
        elseif ($TMinerBlocks) {
            $Warning = "Warning: Blocking $($_.Name) for $($_.Type)"; 
            if ($Note -notcontains $Warning) { $Note += $Warning }
            $ScreenedMiners += $_
        }
    }
    
    $ScreenedMiners | ForEach-Object { $GetMiners.Remove($_) } | Out-Null;
    if ($Note) { $Note | ForEach-Object { Write-Log "$($_)" -ForegroundColor Magenta } }
    $GetMiners
}

function Get-MinerTimeout {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$minerjson
    )

    $miner = $minerjson | ConvertFrom-Json
    $reason = "error"

    if ($Miner.hashrate -eq 0 -or $null -eq $Miner.hashrate) {
        if ($null -eq $miner.xprocess) { $reason = "no start" }
        else {
            $MinerProc = Get-Process -Id $miner.xprocess.id -ErrorAction SilentlyContinue
            if ($null -eq $MinerProc) { $reason = "crashed" }
            else { $reason = "no hash" }
        }
    }
    $RejectCheck = Join-Path ".\timeout\warnings" "$($miner.Name)_$($miner.Algo)_rejection.txt"
    if (Test-Path $RejectCheck) { $reason = "rejections" }

    return $reason
}

function Get-minerfiles {
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

function start-minersorting {
    param (
        [Parameter(Mandatory = $true)]
        [array]$SortMiners,
        [Parameter(Mandatory = $true)]
        [decimal]$WattCalc
    )

    $SortMiners | ForEach-Object {
        $Miner = $_

        $Miner_HashRates = [PSCustomObject]@{ }
        $Miner_Profits = [PSCustomObject]@{ }
        $Miner_Unbias = [PSCustomObject]@{ }
        $Miner_PowerX = [PSCustomObject]@{ }
        $Miner_Pool_Estimates = [PSCustomObject]@{ }
        $Miner_Vol = [PSCustomObject]@{ }
     
        $Miner_Types = $Miner.Type | Select-Object -Unique
        $MinerPool = $Miner.MinerPool | Select-Object -Unique

        $Miner.HashRates | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
            if ($Miner.PowerX.$_ -ne $null) {
                $Day = 24;
                $Kilo = 1000;
                $WattCalc1 = (([Double]$Miner.PowerX.$_) * $Day)
                $WattCalc2 = [Double]$WattCalc1 / $Kilo;
                $WattCalc3 = [Double](($WattCalc2 * $WattCalc) * -1)
            }
            else { $WattCalc3 = 0 }
            
            if ($global:Pool_Hashrates.$_.$MinerPool.Percent -gt 0) {$Hash_Percent = $global:Pool_Hashrates.$_.$MinerPool.Percent * 100}
            else{$Hash_Percent = 0}

            $Miner_Volume = ([Double]($Miner.Quote * (1 - ($Hash_Percent / 100))))
            $Miner_Modified = ([Double]($Miner_Volume * (1 - ($Miner.Fees / 100))))

            $Miner_HashRates | Add-Member $_ ([Double]$Miner.HashRates.$_)
            $Miner_PowerX | Add-Member $_ ([Double]$Miner.PowerX.$_)
            $Miner_Profits | Add-Member $_  ([Double]($Miner_Modified + $WattCalc3))  ##Used to calculate BTC/Day and sort miners
            $Miner_Unbias | Add-Member $_  ([Double]($Miner_Modified + $WattCalc3))  ##Uset to calculate Daily profit/day moving averages
            $Miner_Pool_Estimates | Add-Member $_ ([Double]($Miner.Quote)) ##RAW calculation for Live Value (Used On screen)
            $Miner_Vol | Add-Member $_ $( if($global:Pool_Hashrates.$_.$MinerPool.Percent -gt 0){[Double]$global:Pool_Hashrates.$_.$MinerPool.Percent * 100} else { 0 } )
        }
            
        $Miner_Power = [Double]($Miner_PowerX.PSObject.Properties.Value | Measure-Object -Sum).Sum
        $Miner_Profit = [Double]($Miner_Profits.PSObject.Properties.Value | Measure-Object -Sum).Sum
        $Miner_Unbiased = [Double]($Miner_Unbias.PSObject.Properties.Value | Measure-Object -Sum).Sum
        $Miner_Pool_Estimate = [Double]($Miner_Pool_Estimates.PSObject.Properties.Value | Measure-Object -Sum).sum
        $Miner_Volume = [Double]($Miner_Vol.PSObject.Properties.Value | Measure-Object -Sum).sum

        $Miner.HashRates | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
            if ((-not [String]$Miner.HashRates.$_) -or (-not [String]$Miner.PowerX.$_)) {
                $Miner_HashRates.$_ = $null
                $Miner_PowerX.$_ = $null
                $Miner_Profit = $null
                $Miner_Unbiased = $null
                $Miner_Power = $null
                $Miner_Pool_Estimate = $null
                $Miner_Volume = $null
            }
        }

        $Miner.HashRates = $Miner_HashRates
        $Miner.PowerX = $Miner_PowerX
        $Miner | Add-Member Profit $Miner_Profit
        $Miner | Add-Member Profit_Unbiased $Miner_Unbiased
        $Miner | Add-Member Power $Miner_Power
        $Miner | Add-Member Pool_Estimate $Miner_Pool_Estimate
        $Miner | Add-Member Volume $Miner_Volume
    }
}

function Start-MinerReduction {

    param (
        [Parameter(Mandatory = $true)]
        [array]$SortMiners,
        [Parameter(Mandatory = $true)]
        [decimal]$WattCalc
    )

    $CutMiners = @()
    $global:Config.Params.Type | ForEach-Object {
        $GetType = $_;
        $SortMiners.Symbol | Select-Object -Unique | ForEach-Object {
            $zero = $SortMiners | Where-Object Type -eq $GetType | Where-Object Symbol -eq $_ | Where-Object Quote -EQ 0; 
            $nonzero = $SortMiners | Where-Object Type -eq $GetType | Where-Object Symbol -eq $_ | Where-Object Quote -NE 0;

            if ($zero) {
                $GetMinersToCut = @()
                $GetMinersToCut += $zero
                $GetMinersToCut += $nonzero | Sort-Object @{Expression = "Quote"; Descending = $true }
                $GetMinersToCut = $GetMinersToCut | Select-Object -Skip 1;
                $GetMinersToCut | ForEach-Object { $CutMiners += $_ };
            }
            else {
                $GetMinersToCut = @()
                $GetMinersToCut = $nonzero | Sort-Object @{Expression = "Quote"; Descending = $true };
                $GetMinersToCut = $GetMinersToCut | Select-Object -Skip 1;
                $GetMinersToCut | ForEach-Object { $CutMiners += $_ };
            }
        }
    }

    $CutMiners
}

function Get-TypeTable {
    $TypeTable = @{};
    if($global:Config.Params.Type -like "*NVIDIA*") {
        $Search = Get-ChildItem ".\miners\gpu\nvidia"
        $Search.Basename | %{
        $TypeTable.Add("$($_)-1","NVIDIA1")
        $TypeTable.ADD("$($_)-2","NVIDIA2")
        $TypeTable.ADD("$($_)-3","NVIDIA3")
        }
    }

    if($global:Config.Params.Type -like "*AMD*") {
        $Search = Get-ChildItem ".\miners\gpu\amd"
        $Search.Basename | %{
        $TypeTable.Add("$($_)-1","AMD1")
        }
    }

    if($global:Config.Params.Type -like "*CPU*") {
        $Search = Get-ChildItem ".\miners\cpu"
        $Search.Basename | %{
        $TypeTable.Add("$($_)","CPU")
        }
    }
    if($global:Config.Params.Type -eq "ASIC") {$TypeTable.Add("cgminer","ASIC")}
    $TypeTable
}

function Get-MinerHashTable {
        Invoke-Expression ".\build\powershell\get.ps1 benchmarks all -asjson" | Tee-Object -Variable Miner_HashTable | Out-Null
        if($Miner_HashTable -and $Miner_HashTable -ne "No Stats Found"){
            $Miner_HashTable = $Miner_HashTable | ConvertFrom-Json
        }else{$Miner_HashTable = $null}

        if($Miner_HashTable) {
            $Miner_HashTable | %{$_ | Add-Member "Type" $global:TypeTable.$($_.Miner)}
            $NotBest = @()
            $Miner_HashTable.Algo | %{
                $A = $_
                $global:Config.Params.Type | %{
                    $T = $_
                    $Sel = $Miner_HashTable | Where Algo -eq $A | Where Type -EQ $T
                    $NotBest += $Sel | Sort-Object RAW -Descending | Select-Object -Skip 1
                }
            }

            $Miner_HashTable | % {$Sel = $NotBest | Where Miner -eq $_.Miner | Where Algo -eq $_.Algo | Where Type -eq $_.Type; if($Sel){$_.Raw = "Bad"}}
        }
        $Miner_HashTable
}
function Get-BestMiners {

    $BestMiners = @()

    $global:Config.Params.Type | foreach {
        $SelType = $_
        $BestTypeMiners = @()
        $OldMiners = @()
        $OldTypeMiners = @()
        $MinerCombo = @()

        $TypeMiners = $Miners | Where Type -EQ $SelType
        $BestActiveMiners | ForEach {$Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | Where Type -EQ $SelType | ForEach {$OldMiners += $_}}
        if ($OldMiners) {
            $OldTypeMiners += $OldMiners | Where Profit -gt 0 | Sort-Object @{Expression = "Profit"; Descending = $true} | Select -First 1
            $OldTypeMiners += $OldMiners | Where Profit -lt 0 | Sort-Object @{Expression = "Profit"; Descending = $false} | Select -First 1
            $OldTypeMiners = $OldTypeMiners | Select -First 1
            $OldTypeMiners | foreach { $_ | Add-Member "Old" "Yes"}
        }
        if ($OldTypeMiners) {$MinerCombo += $OldTypeMiners}
        $MinerCombo += $TypeMiners | Where Profit -NE $NULL
        $BestTypeMiners += $TypeMiners | Where Profit -EQ $NULL | Select -First 1
        $BestTypeMiners += $MinerCombo | Where Profit -NE $Null | Where Profit -gt 0 | Sort-Object {($_ | Measure Profit -Sum).Sum} -Descending | Select -First 1
        $BestTypeMiners += $MinerCombo | Where Profit -NE $Null | Where Profit -lt 0 | Sort-Object {($_ | Measure Profit -Sum).Sum} -Descending | Select -First 1
        $BestMiners += $BestTypeMiners | Select -first 1
    }

    $BestMiners
}