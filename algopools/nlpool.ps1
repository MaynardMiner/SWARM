$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Pool_Request = [PSCustomObject]@{ } 

$X = ""
if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

if ($Name -in $(arg).PoolName) {
    log "Warning: NLPool is a DPPLNS payment pool." -Foreground yellow
    try { $Pool_Request = Invoke-RestMethod "https://nlpool.nl/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch { log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($Pool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    }

    $Algos = @()
    $Algos += $(vars).Algorithm
    $Algos += $(arg).ASIC_ALGO
    
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
        $_.Name = $Pipe_Algos.PSObject.Properties.Name | Where { $N -in $Pipe_Algos.$_.alt_names };
        if ($_.Name) { if ($_.Name -in $Algo_List -and $Pipe_Name -notin $Pipe_Algos.$($_.Name).exclusions -and $_.Name -notin $Pipe_Hammer) { return $_ } }
    } -ThrottleLimit $(arg).Throttle

    ## These are modified, then returned back to the original
    ## value below. This is so that threading can be done.
    $DivisorTable = $Global:Config.vars.DivisorTable
    $FeeTable = $Global:Config.vars.FeeTable
    $Hashrate_Table = $Global:Config.vars.Pool_HashRates
    $Get_Params = $Global:Config.params
    $Get_Wallets = $Wallets

    $Pool_Data = $Pool_Sorted | ForEach-Object -Parallel {
        . .\build\powershell\global\classes.ps1
        $D_Table = $using:DivisorTable
        $F_Table = $using:FeeTable
        $H_Table = $using:Hashrate_Table
        $P_Name = $using:Name
        $sub = $using:X
        $Params = $using:Get_Params
        $Wallets = $using:Get_Wallets
        $StatAlgo = $_.Name -replace "`_", "`-"
        $Divisor = 1000000 * $_.mbtc_mh_factor
        $Pool_Port = $_.port
        $Pool_Host = "mine.nlpool.nl$sub"
        $StatName = "$($P_Name)_$($StatAlgo)"
        $Get_Path = [IO.File]::Exists(".\stats\pool_$($StatName)_pricing.json")
        $Hashrate = [math]::Max($_.hashrate, 1)
        $Estimate = $_.estimate_last24h
        if ($Get_Path) { $Estimate = $_.estimate_current }

        $new_estimate = [Convert]::ToDecimal($Estimate)
        $current = [Convert]::ToDecimal($new_estimate / $Divisor * (1 - ($_.fees / 100)))
        $new_actual = [Convert]::ToDecimal($_.actual_last24h)
        $actual = [Convert]::ToDecimal(($new_actual * 0.001) / $Divisor * (1 - ($_.fees / 100)))

        $Stat = [Pool_Stat]::New($StatName, $current, [Convert]::ToDecimal($Hashrate), $actual, $false)

        switch ($_.Name) {
            "equihash_125/4" { $Divisor *= 2 }
            "equihash_144/5" { $Divisor *= 2 }
            "equihash_192/7" { $Divisor *= 2 }
            "verushash" { $Divisor *= 2 }
        }

        if (-not $H_Table.$($_.Name)) {
            $H_Table.Add("$($_.Name)", @{ })
        }
        elseif (-not $H_Table.$($_.Name).$P_Name) {
            $H_Table.$($_.Name).Add("$P_Name", @{
                    Hashrate = "$Hashrate"
                    Percent  = ""
                })
        }

        $Level = $Stat.$($Params.Stat_Algo)

        if ($Params.Historical_Bias) {
            $SmallestValue = 1E-20 
            $Values = $Params.Historical_Bias.Split("`:")
            $Max_Penalty = $Values | Select -First 1
            $Max_Bonus = $Values | Select -Last 1

            ## Penalize
            if ($Stat.Historical_Bias -lt 0) {
                $Deviation = [Math]::Max($Stat.Historical_Bias, ($Max_Penalty * -0.01))
            }
            ## Bonus
            else {
                $Deviation = [Math]::Min($Stat.Historical_Bias, ($Max_Bonus * 0.01))
            }
            $Level = [Math]::Max($Level + ($Level * $Deviation), $SmallestValue)
        }        

        $Pass1 = $Wallets.Wallet1.Keys
        $id = ".$($Params.Rigname1)"
        $User1 = "$($Wallets.Wallet1.$($Params.Passwordcurrency1).address)$id"

        $Pass2 = $Wallets.Wallet2.Keys
        $id = ".$($Params.Rigname2)"
        $User2 = "$($Wallets.Wallet2.$($Params.Passwordcurrency2).address)$id"

        $Pass3 = $Wallets.Wallet3.Keys
        $id = ".$($Params.Rigname3)"
        $User3 = "$($Wallets.Wallet3.$($Params.Passwordcurrency3).address)$id"

        if ($Wallets.AltWallet1.keys) {
            $Wallets.AltWallet1.Keys | ForEach-Object {
                if ($Wallets.AltWallet1.$_.Pools -contains $Name) {
                    $Pass1 = $_;
                    $id = ".$($Params.Rigname1)"
                    $User1 = "$($Wallets.AltWallet1.$_.address)$id"
                }
            }
        }
        if ($Wallets.AltWallet2.keys) {
            $Wallets.AltWallet2.Keys | ForEach-Object {
                if ($Wallets.AltWallet2.$_.Pools -contains $Name) {
                    $Pass2 = $_;
                    $id = ".$($Params.Rigname2)"
                    $User2 = "$($Wallets.AltWallet2.$_.address)$id"
                }
            }
        }
        if ($Wallets.AltWallet3.keys) {
            $Wallets.AltWallet3.Keys | ForEach-Object {
                if ($Wallets.AltWallet3.$_.Pools -contains $Name) {
                    $Pass3 = $_;
                    $id = ".$($Params.Rigname3)"
                    $User3 = "$($Wallets.AltWallet3.$_.address)$id"
                }
            }
        }

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
            "c=$Pass1",
            ## Pass2
            "c=$Pass2",
            ## Pass3
            "c=$Pass3",
            ## Previous
            $actual
        )
    } -ThrottleLimit $(arg).Throttle
    
    $Global:Config.vars.DivisorTable = $DivisorTable
    $Global:Config.vars.FeeTable = $FeeTable
    $Global:Config.vars.Pool_HashRates = $Hashrate_Table
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
    $Pool_Data
}