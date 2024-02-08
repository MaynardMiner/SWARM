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

. .\build\powershell\global\modules.ps1

if ($Name -in $(arg).PoolName) {

    $Pool_Request = [PSCustomObject]@{ } 

    $X = ""
    if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 
 
    try { $Pool_Request = Invoke-RestMethod "https://zergpool.com/api/status" -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop } 
    catch { return "WARNING: SWARM contacted ($Name) but there was no response." }
  
    if (($Pool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        return "WARNING: SWARM contacted ($Name) but ($Name) the response was empty." 
    } 

    $Algos = @()
    $Algos = @()
    $(vars).Algorithm | Foreach-Object {
        $Algos += $_
    }
    $(arg).ASIC_ALGO | ForEach-Object {
        $Algos += $_
    }
    
    ## Only get algos we need & convert name to universal schema
    $Pool_Algos = $global:Config.Pool_Algos;
    $Ban_Hammer = $global:Config.vars.BanHammer;
    $Pool_Sorted = $Pool_Request.PSobject.Properties.Value | ForEach-Object -Parallel { 
        $Pipe_Algos = $using:Pool_Algos;
        $Pipe_Hammer = $using:Ban_Hammer;
        $Algo_List = $using:Algos;
        $Pipe_Name = $using:Name;
        $N = $_.Name;
        $_ | Add-Member "Original_Algo" $N;
        $_.Name = $Pipe_Algos.PSObject.Properties.Name | Where-Object { $N -in $Pipe_Algos.$_.alt_names };
        if ($_.Name) { if ($_.Name -in $Algo_List -and $Pipe_Name -notin $Pipe_Algos.$($_.Name).exclusions -and $_.Name -notin $Pipe_Hammer) { return $_ } }
    } -ThrottleLimit $(arg).Throttle

    Switch ($(arg).Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "asia" }
        "JAPAN" { $region = "asia" }
    }    

    ## These are modified, then returned back to the original
    ## value below. This is so that threading can be done.
    $DivisorTable = $Global:Config.vars.DivisorTable
    $FeeTable = $Global:Config.vars.FeeTable
    $Hashrate_Table = $Global:Config.vars.Pool_HashRates
    $Get_Params = $Global:Config.params
    $Get_Wallets = $Global:Wallets

    $Pool_Data = $Pool_Sorted | ForEach-Object -Parallel {
        . .\build\powershell\global\classes.ps1
        $D_Table = $using:DivisorTable
        $F_Table = $using:FeeTable
        $H_Table = $using:Hashrate_Table
        $P_Name = $using:Name
        $sub = $using:X
        $Params = $using:Get_Params
        $A_Wallets = $using:Get_Wallets
        $reg = $using:region

        ##
        $StatAlgo = $_.Name -replace "`_", "`-"
        $Divisor = 1000000 * $_.mbtc_mh_factor
        $Pool_Port = $_.port
        $Pool_Host = "$($_.Original_Algo.ToLower()).$reg.mine.zergpool.com$sub"
        $StatName = "$($P_Name)_$($StatAlgo)"
        $Get_Path = [IO.File]::Exists(".\stats\pool_$($StatName)_pricing.json")
        $Hashrate = [math]::Max([Convert]::ToDecimal($_.hashrate_shared), 1)
        $Estimate = $_.estimate_last24h
        if ($Get_Path) { $Estimate = $_.estimate_current }

        $D_Table.zergpool.Add($_.Name, $_.mbtc_mh_factor)
        $F_Table.zergpool.Add($_.Name, $_.Fees)

        $new_estimate = [Convert]::ToDecimal($Estimate)
        $current = [Convert]::ToDecimal($new_estimate / $Divisor * (1 - ($_.fees / 100)))
        $new_actual = [Convert]::ToDecimal($_.actual_last24h_shared)
        $actual = [Convert]::ToDecimal(($new_actual * 0.001) / $Divisor * (1 - ($_.fees / 100)))

        $Stat = [Pool_Stat]::New($StatName, $current, [Convert]::ToDecimal($Hashrate), $actual, $false)

        if (-not $H_Table.$($_.Name)) {
            $H_Table.Add("$($_.Name)", @{})
        }
        elseif (-not $H_Table.$($_.Name).$P_Name) {
            $H_Table.$($_.Name).Add("$P_Name", @{
                    Hashrate = "$Hashrate"
                    Percent  = ""
                })
        }

        $Level = $Stat.$($Params.Stat_Algo)

        if ($Params.Historical_Bias -ne "") {
            $SmallestValue = 1E-20 
            $Values = $Params.Historical_Bias.Split("`:")
            $Max_Penalty = [double]($Values | Select-Object -First 1)
            $Max_Bonus = [double]($Values | Select-Object -Last 1)

            ## Penalize
            if ($Stat.Historical_Bias -lt 0) {
                $Deviation = [Math]::Max($Stat.Historical_Bias, ($Max_Penalty * -0.01))
                ### Make SWARM remove any coin that did not have any 24 hour returns
                ### Deviation -1 = -100%
                if($Stat.Historical_Bias -eq -1) {
                    ## (estimate * -1) + estimate = 0
                    $Deviation = -1
                }
            }
            ## Bonus
            else {
                $Deviation = [Math]::Min($Stat.Historical_Bias, ($Max_Bonus * 0.01))
            }
            $Level = [Math]::Max($Level + ($Level * $Deviation), $SmallestValue)
        }        

    
        $Pass1 = $A_Wallets.Wallet1.Keys
        $User1 = $A_Wallets.Wallet1.$($Params.Passwordcurrency1).address
        $Pass2 = $A_Wallets.Wallet2.Keys
        $User2 = $A_Wallets.Wallet2.$($Params.Passwordcurrency2).address
        $Pass3 = $A_Wallets.Wallet3.Keys
        $User3 = $A_Wallets.Wallet3.$($Params.Passwordcurrency3).address
                
        if ($A_Wallets.AltWallet1.keys) {
            $A_Wallets.AltWallet1.Keys | ForEach-Object {
                if ($A_Wallets.AltWallet1.$_.Pools -contains $P_Name) {
                    $Pass1 = $_;
                    $User1 = $A_Wallets.AltWallet1.$_.address;
                }
            }
        }
        if ($A_Wallets.AltWallet2.keys) {
            $A_Wallets.AltWallet2.Keys | ForEach-Object {
                if ($A_Wallets.AltWallet2.$_.Pools -contains $P_Name) {
                    $Pass2 = $_;
                    $User2 = $A_Wallets.AltWallet2.$_.address;
                }
            }
        }
        if ($A_Wallets.AltWallet3.keys) {
            $A_Wallets.AltWallet3.Keys | ForEach-Object {
                if ($A_Wallets.AltWallet3.$_.Pools -contains $P_Name) {
                    $Pass3 = $_;
                    $User3 = $A_Wallets.AltWallet3.$_.address;
                }
            }
        }

        if ($Hashrate -gt 0) {
            [Pool]::New(
                ## Symbol
                "$($_.Name)-Algo",
                ## Algorithm
                "$($_.Name)",
                ## Level
                $Level,
                ## Stratum
                "stratum+tcp",
                ## Pool_Host
                $Pool_Host,
                ## Pool_Port
                $Pool_Port,
                ## User1
                $User1,
                ## User2
                $User2,
                ## User3
                $User3,
                ## Pass1
                "ID=$($Params.RigName1),c=$Pass1",
                ## Pass2
                "ID=$($Params.RigName2),c=$Pass2",
                ## Pass3
                "ID=$($Params.RigName3),c=$Pass3",
                ## Previous
                $actual
            )
        }
    } -ThrottleLimit $(arg).Throttle

    $Global:Config.vars.DivisorTable = $DivisorTable
    $Global:Config.vars.FeeTable = $FeeTable
    $Global:Config.vars.Pool_HashRates = $Hashrate_Table
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
    $Pool_Data
}
