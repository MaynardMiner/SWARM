. .\build\powershell\global\modules.ps1

if ($Name -in $(arg).PoolName) {
    $Pool_Request = [PSCustomObject]@{ } 

    $X = ""
    if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

    try { $Pool_Request = Invoke-RestMethod "miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop }
    catch { return "WARNING: SWARM contacted ($Name) but there was no response." }
 
    if (($Pool_Request.return | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        return "WARNING: SWARM contacted ($Name) but ($Name) the response was empty." 
    }

    if (!$Pool_Request.success) { 
        return "WARNING: SWARM contacted ($Name) but ($Name) indicated it was not successful." 
    }

    $Algos = @()
    $Algos += $(vars).Algorithm
    $Algos += $(arg).ASIC_ALGO

    $Pool_Algos = $global:Config.Pool_Algos;
    $Ban_Hammer = $global:Config.vars.BanHammer;
    $Pool_Sorted = $Pool_Request.Return | ForEach-Object -Parallel { 
        $Pipe_Algos = $using:Pool_Algos;
        $Pipe_Hammer = $using:Ban_Hammer;
        $Algo_List = $using:Algos;
        $Pipe_Name = $using:Name;
        $N = $_.algo;
        $_ | Add-Member "Original_Algo" $N.ToLower();
        $_.algo = $Pipe_Algos.PSObject.Properties.Name | Where-Object { $N -in $Pipe_Algos.$_.alt_names };
        if ($_.algo) { if ($_.algo -in $Algo_List -and $Pipe_Name -notin $Pipe_Algos.$($_.algo).exclusions -and $_.algo -notin $Pipe_Hammer) { return $_ } }
    } -ThrottleLimit $(arg).Throttle

    $Get_Params = $Global:Config.params
    $Get_Wallets = $Global:Wallets

    Switch ($Get_Params.Location) {
        "US" { $region = "us-east" }
        "EUROPE" { $region = "europe" }
        "ASIA" { $region = "asia" }
        "JAPAN" { $region = "asia" }
    }    

    $Pool_Data = $Pool_Sorted | ForEach-Object -Parallel {
        . .\build\powershell\global\classes.ps1
        $P_Name = $using:Name
        $sub = $using:X
        $Params = $using:Get_Params
        $A_Wallets = $using:Get_Wallets
        $reg = $using:region
        $StatAlgo = $_.algo -replace "`_", "`-"
        $Divisor = 1000000000
        $Pool_Port = $_.algo_switch_port
        $Pool_Host = $_.host;
        if($_.all_host_list.count -gt 1) {
            $Pool_Hosts = $_.all_host_list.split(";")
            $Pool_Host = $Pool_Hosts | Where {$_ -like "*$reg*"}
        }
        $StatName = "$($P_Name)_$($StatAlgo)"
        $Get_Path = [IO.File]::Exists(".\stats\pool_$($P_Name)_$($StatAlgo)_pricing.json")
        $Fee = 1.1;
        $new_estimate = [Convert]::ToDecimal($_.profit);
        $current = [Convert]::ToDecimal($new_estimate / $Divisor * (1 - ($Fee / 100)));
        $hashrate = 1

        $Stat = [Pool_Stat]::New($StatName, $current, $hashrate, -1, $false);
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

        $user1 = "$($Params.MPH_User).$($Params.Rigname1)";
        $user2 = "$($Params.MPH_User).$($Params.Rigname2)";
        $user3 = "$($Params.MPH_User).$($Params.Rigname3)";
        $pass = "x";

        if ($Hashrate -gt 0) {
            [Pool]::New(
                ## Symbol
                "$($_.algo)-Algo",
                ## Algorithm
                "$($_.algo)",
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
                $pass,
                ## Pass2
                $pass,
                ## Pass3
                $pass,
                ## Previous
                $actual
            )
        }
    } -ThrottleLimit $(arg).Throttle

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
    $Pool_Data
}

