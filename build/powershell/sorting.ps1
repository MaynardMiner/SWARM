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
function start-minersorting {
        param (
            [Parameter(Mandatory=$false)]
            [string]$Command,
            [Parameter(Mandatory=$false)]
            [array]$Stats,
            [Parameter(Mandatory=$false)]
            [array]$Pools,
            [Parameter(Mandatory=$false)]
            [array]$Pools_Comparison,
            [Parameter(Mandatory=$false)]
            [array]$SortMiners,
            [Parameter(Mandatory=$false)]
            [int]$DBase,
            [Parameter(Mandatory=$false)]
            [int]$DExponent,
            [Parameter(Mandatory=$false)]
            [decimal]$WattCalc
            )

        $SortMiners | foreach {
        $Miner = $_

            $Miner_HashRates = [PSCustomObject]@{}
            $Miner_Pools = [PSCustomObject]@{}
            $Miner_Pools_Comparison = [PSCustomObject]@{}
            $Miner_Profits = [PSCustomObject]@{}
            $Miner_Profits_Comparison = [PSCustomObject]@{}
            $Miner_Profits_Bias = [PSCustomObject]@{}
            $Miner_PowerX = [PSCustomObject]@{}
            $Miner_Pool_Estimate = [PSCustomObject]@{}
     
            $Miner_Types = $Miner.Type | Select -Unique
            $Miner_Indexes = $Miner.Index | Select -Unique
     
            $Miner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
            if($Miner.PowerX.$_ -ne $null){
            $Day = 24;
            $Kilo = 1000;
            $WattCalc1 = (([Decimal]$Miner.PowerX.$_)*$Day)
            $WattCalc2 = [Decimal]$WattCalc1/$Kilo;
            $WattCalc3 = [Decimal]$WattCalc2*$WattCalc;}
            else{$WattCalc3 = 0}
            $Pool = $Pools | Where Symbol -EQ $_ | Where Name -EQ $($Miner.MinerPool)
            $Pool_Comparison = $Pools_Comparison | Where Symbol -EQ $_ | Where Name -EQ $($Miner.MinerPool)
            $Miner_HashRates | Add-Member $_ ([Double]$Miner.HashRates.$_)
            $Miner_PowerX | Add-Member $_ ([Double]$Miner.PowerX.$_)
            $Miner_Pools | Add-Member $_ ([PSCustomObject]$Pool.Name)
            $Miner_Pools_Comparison | Add-Member $_ ([PSCustomObject]$Pool_Comparison.Name)
            $Miner_Profits | Add-Member $_ ([Decimal](($Miner.HashRates.$_*$Pool.Price)-$WattCalc3))
            $Miner_Profits_Comparison | Add-Member $_ ([Decimal](($Miner.HashRates.$_*$Pool_Comparison.Price)-$WattCalc3))
            $Miner_Profits_Bias | Add-Member $_ ([Decimal](($Miner.HashRates.$_*$Pool.Price*(1-($Pool.MarginOfError*[Math]::Pow($DBase,$DExponent))))-$WattCalc3))
            $Miner_Pool_Estimate | Add-Member $_ ([Decimal]($Pool.Price))
            }
            
            $Miner_Power = [Double]($Miner_PowerX.PSObject.Properties.Value | Measure -Sum).Sum
            $Miner_Profit = [Double]($Miner_Profits.PSObject.Properties.Value | Measure -Sum).Sum
            $Miner_Profit_Comparison = [Double]($Miner_Profits_Comparison.PSObject.Properties.Value | Measure -Sum).Sum
            $Miner_Profit_Bias = [Double]($Miner_Profits_Bias.PSObject.Properties.Value | Measure -Sum).Sum
            $Miner_Pool_Estimate = [Double]($Miner_Pool_Estimate.PSObject.Properties.Value | Measure -Sum).sum

        if($Command -eq "Algo")
         {
            $Miner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
             if((-not [String]$Miner.HashRates.$_) -or (-not [String]$Miner.PowerX.$_) -and $Miner.Type -ne "ASIC")
              {
                    $Miner_HashRates.$_ = $null
                    $Miner_PowerX.$_ = $null
                    $Miner_Profits.$_ = $null
                    $Miner_Profits_Comparison.$_ = $null
                    $Miner_Profits_Bias.$_ = $null
                    $Miner_Profit = $null
                    $Miner_Profit_Comparison = $null
                    $Miner_Profit_Bias = $null
                    $Miner_Power = $null
              }
            }
         } 
         
            if($Miner_Types -eq $null){$Miner_Types = $Miners.Type | Select -Unique}
            if($Miner_Indexes -eq $null){$Miner_Indexes = $Miners.Index | Select -Unique}
            
            if($Miner_Types -eq $null){$Miner_Types = ""}
            if($Miner_Indexes -eq $null){$Miner_Indexes = 0}
            
            $Miner.HashRates = $Miner_HashRates
            $Miner.PowerX = $Miner_PowerX
            $Miner | Add-Member Pools $Miner_Pools
            $Miner | Add-Member Profits $Miner_Profits
            $Miner | Add-Member Profits_Comparison $Miner_Profits_Comparison
            $Miner | Add-Member Profits_Bias $Miner_Profits_Bias
            $Miner | Add-Member Profit $Miner_Profit
            $Miner | Add-Member Profit_Comparison $Miner_Profit_Comparison
            $Miner | Add-Member Profit_Bias $Miner_Profit_Bias
            $Miner | Add-Member Power $Miner_Power
            $Miner | Add-Member Pool_Estimate $Miner_Pool_Estimate
            $Miner | Add-Member Type $Miner_Types -Force
            $Miner | Add-Member Index $Miner_Indexes -Force
     
            $Miner.Path = Convert-Path $Miner.Path

        }

        $SortMiners | ForEach {
            $Miner = $_
            $Miner_Devices = $Miner.Device | Select -Unique
            if($Miner_Devices -eq $null){$Miner_Devices = ($SortMiners | Where {(Compare-Object $Miner.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}).Device | Select -Unique}
            if($Miner_Devices -eq $null){$Miner_Devices = $Miner.Type}
            $Miner | Add-Member Device $Miner_Devices -Force
            }
   }