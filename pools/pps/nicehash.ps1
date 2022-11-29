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

    $nicehash_Request = [PSCustomObject]@{ } 


    <#
    ## This is depreciated, as nicehash uses only one port.
    ## Make a Port map so I don't have to pull from nicehash twice
    $Nicehash_Ports = 
    '{
    "scrypt":"3333",            "btc":"3334",               "scryptnf":"3335",          "x11":"3336",
    "x13":"3337",               "keccak":"3338",            "x15":"3339",               "nist5":"3340",
    "neoscrypt":"3341",         "lyra2re":"3342",           "whirlpoolx":"3343",        "qubit":"3344",
    "quark":"3345",             "axiom":"3346",             "lyra2rev2":"3347",         "scryptjanenf16":"3348",
    "blake256r8":"3349",        "blake256r14":"3350",       "blake256r8vnl":"3351",     "hodl":"3352",
    "daggerhashimoto":"3353",   "decred":"3354",            "cryptonight":"3355",       "lbry":"3356",
    "equihash":"3357",          "pascal":"3358",            "x11ghost":"3359",          "sia":"3360",
    "blake2s":"3361",           "skunk":"3362",             "cryptonightv7":"3363",     "cryptonightheavy":"3364",
    "lyra2z":"3365",            "x16r":"3366",              "cryptonightv8":"3367",     "sha256asicboost":"3368",
    "zhash":"3369",             "beam":"3370",              "grincuckaroo29":"3371",    "grincuckatoo31":"3372",
    "lyra2rev3":"3373",         "mtp":"3374",               "cryptonightr":"3375",      "cuckoocycle":"3376",
    "grincuckarood29":"3377",   "beamv2":"3378",            "x16rv2":"3379",            "randomxmonero":"3380",
    "eaglesong":"3381",         "cuckaroom": "3382",        "grincuckatoo32":"3383",    "handshake":"3384",
    "kawpow": "3385",           "cuckaroo29bfc": "3386",     "beamv3": "3387",          "cuckarooz29": "3388",
    "octopus": "3389"
    }'    

    $Nicehash_Ports = $Nicehash_Ports | ConvertFrom-Json
    #>

    $X = ""
    if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" }

    try { $nicehash_Request = Invoke-RestMethod "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info" -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop } 
    catch { return "WARNING: SWARM contacted ($Name) but there was no response." }
 
    if ($nicehash_Request.miningAlgorithms.Count -le 1) {
        return "WARNING: SWARM contacted ($Name) but ($Name) the response was empty." 
         
    } 
  
    ## Nicehash has auto location
    Switch ($(arg).Location) {
        "US" { $Region = "auto" }
        "ASIA" { $Region = "auto" }
        "EUROPE" { $Region = "auto" }
        "JAPAN" { $Region = "auto" }
    }

    $Get_Params = $Global:Config.params
    $Algos = @()
    $(vars).Algorithm | Foreach-Object {
        $Algos += $_
    }
    $(arg).ASIC_ALGO | ForEach-Object {
        $Algos += $_
    }
    $Pool_Algos = $global:Config.Pool_Algos
    $Ban_Hammer = $global:Config.vars.BanHammer;

    $Pool_Data = $nicehash_Request.miningAlgorithms | 
    Where-Object paying -gt 0 | 
    Where-Object speed -gt 0 |
    ForEach-Object -Parallel {
        $N = $using:name
        $P_ALgos = $using:Pool_Algos;
        $Algorithms = $using:Algos;
        $Pipe_Hammer = $using:Ban_Hammer;
        $Algo = $_.Algorithm.ToLower()
        $Nicehash_Algorithm = $P_ALgos.PSObject.Properties.Name | Where-Object { $Algo -in $P_ALgos.$_.alt_names }
        if ($Algorithms -contains $Nicehash_Algorithm) {
            if ($N -notin $P_ALgos.$Nicehash_Algorithm.exclusions -and $Nicehash_Algorithm -notin $Pipe_Hammer) {

                . .\build\powershell\global\classes.ps1
                $reg = $using:Region;
                $params = $using:Get_Params;
                $sub = $using:X

                ## Nicehash 'Gets' you with the fees. If you read the fine print,
                ## If you do not use a nicehash wallet- Your total fee will end up
                ## becoming 5%. If you use a nicehash wallet, the fee is variable,
                ## but usually around 2%.
            
                if (-not $params.Nicehash_Wallet1) { $NH_Wallet1 = $params.Wallet1; [Double]$Fee = 5; }else { $NH_Wallet1 = $params.Nicehash_Wallet1; [Double]$Fee = $params.Nicehash_Fee }
                if (-not $params.Nicehash_Wallet2) { $NH_Wallet2 = $params.Wallet2; [Double]$Fee = 5; }else { $NH_Wallet2 = $params.Nicehash_Wallet2; [Double]$Fee = $params.Nicehash_Fee }
                if (-not $params.Nicehash_Wallet3) { $NH_Wallet3 = $params.Wallet3; [Double]$Fee = 5; }else { $NH_Wallet3 = $params.Nicehash_Wallet3; [Double]$Fee = $params.Nicehash_Fee }

                $nicehash_Host = "${Algo}.${reg}.nicehash.com${sub}"
                ## 8 bit estimates
                $Divisor = 100000000
                $value = ([Convert]::ToDecimal($_.paying) / $Divisor * (1 - ($Fee / 100)))
                $hashrate = 1

                ## Nicehash is pretty straightforward being PPS. In
                ## My experience, whatever they state is return- Is
                ## usually pretty close to actual.

                $StatAlgo = $Nicehash_Algorithm -replace "`_", "`-"

                $Stat = [Pool_Stat]::New("$($N)_$($StatAlgo)", $value, $hashrate, -1, $false)

                $previous = $Stat.Day_MA

                $Level = $Stat.$($Params.Stat_Algo)

                if ($Params.Historical_Bias -ne "") {
                    $SmallestValue = 1E-20 
                    $Values = $Params.Historical_Bias.Split("`:")
                    $Max_Penalty = [double]($Values | Select-Object -First 1)
                    $Max_Bonus = [double]($Values | Select-Object -Last 1)
                
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
                
                ## According to Incode, 9200 works best.
                $nicehash_Port = 9200

                [Pool]::New(
                    ## Symbol
                    "$($nicehash_Algorithm)-Algo",
                    ## Algorithm
                    $nicehash_Algorithm,
                    ## Level
                    $Level,
                    ## Stratum
                    "stratum+tcp",
                    ## Pool_Host
                    $nicehash_Host,
                    ## Pool_Port
                    $nicehash_Port,
                    ## User1
                    "$NH_Wallet1.$($Params.Rigname1)",
                    ## User2
                    "$NH_Wallet2.$($Params.RigName2)",
                    ## User3
                    "$NH_Wallet3.$($Params.RigName3)",
                    ## Pass1
                    "x",
                    ## Pass2
                    "x",
                    ## Pass3
                    "x",
                    ## Previous
                    $previous
                )
            }
        }
    } -ThrottleLimit $(arg).Throttle

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
    $Pool_Data
}
