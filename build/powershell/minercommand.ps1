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
        [Parameter(Mandatory = $false)]
        [string]$Platforms,        
        [Parameter(Mandatory = $false)]
        [string]$MinerType,
        [Parameter(Mandatory = $false)]
        [Array]$Stats,
        [Parameter(Mandatory = $false)]
        [Array]$Pools
    )

    ## Reset Arrays In Case Of Weirdness
    $GetPoolBlocks = $null
    $GetAlgoBlocks = $null

    ## Pool Bans From File && Specify miner folder based on platform
    if (Test-Path ".\timeout\pool_block\pool_block.txt") {$GetPoolBlocks = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json}
    if (Test-Path ".\timeout\algo_block\algo_block.txt") {$GetAlgoBlocks = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json}
    if (Test-Path ".\timeout\miner_block\miner_block.txt") {$GetMinerBlocks = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json}
    if ($Type -notlike "*ASIC*") {$minerfilepath = "miners\gpu"}
    else {$minerfilepath = "miners\asic"}

    ## Start Running miner scripts, Create an array of Miner Hash Tables
    $GetMiners = if (Test-Path $minerfilepath) {Get-ChildItemContent $minerfilepath | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} |
            Where {$Type.Count -eq 0 -or (Compare-Object $Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} |
            Where {$No_Miner -notcontains $_.Name} |
            Where {$_.Path -ne "None"} |
            Where {$_.Uri -ne "None"} |
            Where {$_.MinerName -ne "None"}
    }

    $NoAlgoMiners = @()
    $GetMiners | Where TYPE -eq "NVIDIA1" | % {if ($No_Algo1 -notcontains $_.Algo) {$NoAlgoMiners += $_}}
    $GetMiners | Where TYPE -eq "NVIDIA2"  | % {if ($No_Algo2 -notcontains $_.Algo) {$NoAlgoMiners += $_}}
    $GetMiners | Where TYPE -eq "NVIDIA3"  | % {if ($No_Algo3 -notcontains $_.Algo) {$NoAlgoMiners += $_}}
    $GetMiners | Where TYPE -eq "AMD1"  | % {if ($No_Algo1 -notcontains $_.Algo) {$NoAlgoMiners += $_}}
    $GetMiners | Where TYPE -eq "AMD2"  | % {if ($No_Algo2 -notcontains $_.Algo) {$NoAlgoMiners += $_}}
    $GetMiners | Where TYPE -eq "AMD3"  | % {if ($No_Algo3 -notcontains $_.Algo) {$NoAlgoMiners += $_}}

    $ScreenedMiners = @()
    $Note = @()

    ## This Creates A New Array Of Miners, Screening Miners That Were Bad. As it does so, it notfies user.
    $NoAlgoMiners | foreach {
        if (-not ($GetPoolBlocks | Where Algo -eq $_.Algo | Where Name -eq $_.Name | Where Type -eq $_.Type | Where MinerPool -eq $_.Minerpool)) {
            if (-not ($GetAlgoBlocks | Where Algo -eq $_.Algo | Where Name -eq $_.Name | Where Type -eq $_.Type)) {
                if (-not ($GetMinerBlocks | Where Name -eq $_.Name | Where Type -eq $_.Type)) {
                    $ScreenedMiners += $_
                }
                else {$Warning = "Warning: Blocking $($_.Name) for $($_.Type)"; if ($Note -notcontains $Warning) {$Note += $Warning}}
            }
            else {$Warning = "Warning: Blocking $($_.Name) mining $($_.Algo) on all pools for $($_.Type)"; if ($Note -notcontains $Warning) {$Note += $Warning}}
        }
        else {$Warning = "Warning: Blocking $($_.Name) mining $($_.Algo) on $($_.MinerPool) for $($_.Type)"; if ($Note -notcontains $Warning) {$Note += $Warning}}
    }

    if ($Note) {$Note | % {Write-Host "$($_)" -ForegroundColor Magenta}}

    $ScreenedMiners
}