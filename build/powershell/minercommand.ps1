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
        [string]$Platforms,        
        [Parameter(Mandatory = $true)]
        [Array]$MinerType,
        [Parameter(Mandatory = $true)]
        [Array]$Stats,
        [Parameter(Mandatory = $true)]
        [Array]$Pools
    )

    ## Reset Arrays In Case Of Weirdness
    $GetPoolBlocks = $null
    $GetAlgoBlocks = $null
    $GetMinerBlocks = $null

    ## Pool Bans From File && Specify miner folder based on platform
    if (Test-Path ".\timeout\pool_block\pool_block.txt") {$GetPoolBlocks = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json}
    if (Test-Path ".\timeout\algo_block\algo_block.txt") {$GetAlgoBlocks = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json}
    if (Test-Path ".\timeout\miner_block\miner_block.txt") {$GetMinerBlocks = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json}
    if ($MinerType -notlike "*ASIC*") {$minerfilepath = "miners\gpu"}
    else {$minerfilepath = "miners\asic"}

    ## Start Running miner scripts, Create an array of Miner Hash Tables
    $GetMiners = New-Object System.Collections.ArrayList
    $ChildMiners = if (Test-Path $minerfilepath) {Get-ChildItemContent $minerfilepath | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} |
            Where {$MinerType.Count -eq 0 -or (Compare-Object $MinerType $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} |
            Where {$No_Miner -notcontains $_.Name} |
            Where {$_.Path -ne "None"} |
            Where {$_.Uri -ne "None"} |
            Where {$_.MinerName -ne "None"}
    }

    $ChildMiners | %{$GetMiners.Add($_) | Out-Null}

    $NVIDIA1EX = $GetMiners | Where TYPE -eq "NVIDIA1" | % {if ($No_Algo1 -contains $_.Algo){$_}}
    $NVIDIA2EX = $GetMiners | Where TYPE -eq "NVIDIA2" | % {if ($No_Algo2 -contains $_.Algo){$_}}
    $NVIDIA3EX = $GetMiners | Where TYPE -eq "NVIDIA3" | % {if ($No_Algo3 -contains $_.Algo){$_}}
    $AMD1EX = $GetMiners | Where TYPE -eq "AMD1" | % {if ($No_Algo1 -contains $_.Algo){$_}}
    $AMD2EX = $GetMiners | Where TYPE -eq "AMD2" | % {if ($No_Algo2 -contains $_.Algo){$_}}
    $AMD3EX = $GetMiners | Where TYPE -eq "AMD3" | % {if ($No_Algo3 -contains $_.Algo){$_}}

    $NVIDIA1EX | %{$GetMiners.Remove($_)} | Out-Null;
    $NVIDIA2EX | %{$GetMiners.Remove($_)} | Out-Null;
    $NVIDIA3EX | %{$GetMiners.Remove($_)} | Out-Null;
    $AMD1EX | %{$GetMiners.Remove($_)} | Out-Null;
    $AMD2EX | %{$GetMiners.Remove($_)} | Out-Null;
    $AMD3EX | %{$GetMiners.Remove($_)} | Out-Null;

    $Note = @()
    $ScreenedMiners = @()

    ## This Creates A New Array Of Miners, Screening Miners That Were Bad. As it does so, it notfies user.
    $GetMiners | foreach {
        
        $TPoolBlocks = $GetPoolBlocks | Where Algo -eq $_.Algo | Where Name -eq $_.Name | Where Type -eq $_.Type | Where MinerPool -eq $_.Minerpool
        $TAlgoBlocks = $GetAlgoBlocks | Where Algo -eq $_.Algo | Where Name -eq $_.Name | Where Type -eq $_.Type
        $TMinerBlocks = $GetMinerBlocks | Where Name -eq $_.Name | Where Type -eq $_.Type

        if ($TPoolBlocks) {
            $Warning = "Warning: Blocking $($_.Name) mining $($_.Algo) on $($_.MinerPool) for $($_.Type)"; 
            if ($Note -notcontains $Warning) {$Note += $Warning}
            $ScreenedMiners += $_
         }
        elseif ($TAlgoBlocks) {
            $Warning = "Warning: Blocking $($_.Name) mining $($_.Algo) on all pools for $($_.Type)"; 
            if ($Note -notcontains $Warning) {$Note += $Warning}
            $ScreenedMiners += $_
        }
        elseif($TMinerBlocks) {
            $Warning = "Warning: Blocking $($_.Name) for $($_.Type)"; 
            if ($Note -notcontains $Warning) {$Note += $Warning}
            $ScreenedMiners += $_
        }
    }
    
    $ScreenedMiners | %{$GetMiners.Remove($_)} | Out-Null;
    if ($Note) {$Note | % {Write-Host "$($_)" -ForegroundColor Magenta}}
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
        if ($null -eq $miner.xprocess) {$reason = "no start"}
        else {
        $MinerProc = Get-Process -Id $miner.xprocess.id -ErrorAction SilentlyContinue
        if ($null -eq $MinerProc) {$reason = "crashed"}
        else {$reason = "no hash"}
        }
    }
    $RejectCheck = Join-Path ".\timeout\warnings" "$($miner.Name)_$($miner.Algo)_rejection.txt"
    if (Test-Path $RejectCheck) {$reason = "rejections"}

    return $reason
}

function Get-minerfiles {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Types,
        [Parameter(Mandatory = $false)]
        [string]$Platforms,
        [Parameter(Mandatory = $false)]
        [string]$Cudas
    )
 
    $miner_update = [PSCustomObject]@{}

    switch ($Types) {
        "CPU" {
            if ($Platforms -eq "linux") {$update = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json}
            elseif ($Platforms -eq "windows") {$update = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json}
        }

        "NVIDIA" {
            if ($Platforms -eq "linux") {
                if ($Cudas -eq "10") {$update = Get-Content ".\config\update\nvidia10-linux.json" | ConvertFrom-Json}
                if ($Cudas -eq "9.2") {$update = Get-Content ".\config\update\nvidia9.2-linux.json" | ConvertFrom-Json}
            }
            elseif ($Platforms -eq "windows") {$update = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json}
        }

        "AMD" {
            if ($Platforms -eq "linux") {$update = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json}
            elseif ($Platforms -eq "windows") {$update = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json}
        }
    }

    $update | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {if ($_ -ne "name") {$miner_update | Add-Member $update.$_.Name $update.$_}}

    $miner_update

}

function start-minersorting {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [Parameter(Mandatory = $true)]
        [array]$Stats,
        [Parameter(Mandatory = $true)]
        [array]$Pools,
        [Parameter(Mandatory = $true)]
        [array]$SortMiners,
        [Parameter(Mandatory = $true)]
        [decimal]$WattCalc
    )

    $SortMiners | foreach {
        $Miner = $_

        $Miner_HashRates = [PSCustomObject]@{}
        $Miner_Pools = [PSCustomObject]@{}
        $Miner_Profits = [PSCustomObject]@{}
        $Miner_PowerX = [PSCustomObject]@{}
        $Miner_Pool_Estimate = [PSCustomObject]@{}
     
        $Miner_Types = $Miner.Type | Select -Unique
        $Miner_Indexes = $Miner.Index | Select -Unique
     
        $Miner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
            if ($Miner.PowerX.$_ -ne $null) {
                $Day = 24;
                $Kilo = 1000;
                $WattCalc1 = (([Decimal]$Miner.PowerX.$_) * $Day)
                $WattCalc2 = [Decimal]$WattCalc1 / $Kilo;
                $WattCalc3 = [Decimal]$WattCalc2 * $WattCalc;
            }
            else {$WattCalc3 = 0}
            $Pool = $Pools | Where Symbol -EQ $_ | Where Name -EQ $($Miner.MinerPool)
            $Miner_HashRates | Add-Member $_ ([Double]$Miner.HashRates.$_)
            $Miner_PowerX | Add-Member $_ ([Double]$Miner.PowerX.$_)
            $Miner_Pools | Add-Member $_ ([PSCustomObject]$Pool.Name)
            $Miner_Profits | Add-Member $_ ([Decimal](($Miner.HashRates.$_ * $Pool.Price) - $WattCalc3))
            $Miner_Pool_Estimate | Add-Member $_ ([Decimal]($Pool.Price))
        }
            
        $Miner_Power = [Double]($Miner_PowerX.PSObject.Properties.Value | Measure -Sum).Sum
        $Miner_Profit = [Double]($Miner_Profits.PSObject.Properties.Value | Measure -Sum).Sum
        $Miner_Pool_Estimate = [Double]($Miner_Pool_Estimate.PSObject.Properties.Value | Measure -Sum).sum

        if ($Command -eq "Algo") {
            $Miner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
                if ((-not [String]$Miner.HashRates.$_) -or (-not [String]$Miner.PowerX.$_) -and $Miner.Type -ne "ASIC") {
                    $Miner_HashRates.$_ = $null
                    $Miner_PowerX.$_ = $null
                    $Miner_Profits.$_ = $null
                    $Miner_Profit = $null
                    $Miner_Power = $null
                }
            }
        } 
                                 
        $Miner.HashRates = $Miner_HashRates
        $Miner.PowerX = $Miner_PowerX
        $Miner | Add-Member Pools $Miner_Pools
        $Miner | Add-Member Profits $Miner_Profits
        $Miner | Add-Member Profit $Miner_Profit
        $Miner | Add-Member Power $Miner_Power
        $Miner | Add-Member Pool_Estimate $Miner_Pool_Estimate     
    }
}

function Start-MinerReduction {

    param (
        [Parameter(Mandatory = $true)]
        [array]$Stats,
        [Parameter(Mandatory = $true)]
        [array]$Pools,
        [Parameter(Mandatory = $true)]
        [array]$SortMiners,
        [Parameter(Mandatory = $true)]
        [decimal]$WattCalc,
        [Parameter(Mandatory = $true)]
        [array]$Type
    )

$CutMiners = @()
$Type | Foreach {
    $GetType = $_;
    $SortMiners.Symbol | Select -Unique | foreach {
        $zero = $SortMiners | Where Type -eq $GetType | Where Symbol -eq $_ | Where Quote -EQ 0; 
        $nonzero = $SortMiners | Where Type -eq $GetType | Where Symbol -eq $_ | Where Quote -NE 0;

        if ($zero) {
            $GetMinersToCut = @()
            $GetMinersToCut += $zero
            $GetMinersToCut += $nonzero | Sort-Object @{Expression = "Quote"; Descending = $true}
            $GetMinersToCut = $GetMinersToCut | Select-Object -Skip 1;
            $GetMinersToCut | %{$CutMiners += $_};
        }
        else {
            $GetMinersToCut = @()
            $GetMinersToCut = $nonzero | Sort-Object @{Expression = "Quote"; Descending = $true};
            $GetMinersToCut = $GetMinersToCut | Select-Object -Skip 1;
            $GetMinersToCut | %{$CutMiners += $_};
        }
    }
  }

  $CutMiners
}