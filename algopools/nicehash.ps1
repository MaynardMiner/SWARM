$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$nicehash_Request = [PSCustomObject]@{ } 

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
"grincuckarood29":"3377",   "beamv2":3378,              "x16rv2":3379
}'    

$Nicehash_Ports = $Nicehash_Ports | ConvertFrom-Json

if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" }
 
if ($Name -in $(arg).PoolName) {
    try { $nicehash_Request = Invoke-RestMethod "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { log "SWARM contacted ($Name) but there was no response."; return }
 
    if ($nicehash_Request.miningAlgorithms.Count -le 1) {
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    } 
  
    Switch ($(arg).Location) {
        "US" { $Region = "usa" }
        "ASIA" { $Region = "hk" }
        "EUROPE" { $Region = "eu" }
    }


    $nicehash_Request.miningAlgorithms | 
    Where-Object paying -gt 0 | 
    Where-Object {
        $Algo = $_.Algorithm.ToLower();
        $local:Nicehash_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $Nicehash_Algorithm
    } |
    ForEach-Object {
        if ($(vars).Algorithm -contains $nicehash_Algorithm -or $(arg).ASIC_ALGO -contains $nicehash_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$nicehash_Algorithm.exclusions -and $nicehash_Algorithm -notin $(vars).BanHammer) {

                ## Nicehash 'Gets' you with the fees. If you read the fine print,
                ## If you do not use a nicehash wallet- Your total fee will end up
                ## becoming 5%. If you use a nicehash wallet, the fee is variable,
                ## but usually around 2%.
            
                if (-not $(arg).Nicehash_Wallet1) { $NH_Wallet1 = $(arg).Wallet1; [Double]$Fee = 5; }else { $NH_Wallet1 = $(arg).Nicehash_Wallet1; [Double]$Fee = $(arg).Nicehash_Fee }
                if (-not $(arg).Nicehash_Wallet2) { $NH_Wallet2 = $(arg).Wallet2; [Double]$Fee = 5; }else { $NH_Wallet2 = $(arg).Nicehash_Wallet2; [Double]$Fee = $(arg).Nicehash_Fee }
                if (-not $(arg).Nicehash_Wallet3) { $NH_Wallet3 = $(arg).Wallet3; [Double]$Fee = 5; }else { $NH_Wallet3 = $(arg).Nicehash_Wallet3; [Double]$Fee = $(arg).Nicehash_Fee }

                $nicehash_Host = "$($Algo).$Region.nicehash.com$X"
                $nicehash_excavator = "nhmp.$Region.nicehash.com$X"
                $nicehash_Port = $nicehash_ports.$Algo
                ## 8 bit estimates
                $Divisor = 100000000
                $previous = [Math]::Max($_.paying * 0.001  / $Divisor * (1 - ($Fee / 100)),$SmallestValue)

                ## Nicehash is pretty straightforward being PPS. In
                ## My experience, whatever they state is return- Is
                ## usually pretty close to actual.

                $StatAlgo = $Nicehash_Algorithm -replace "`_","`-"
                $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -Value ([Double]$_.paying / $Divisor * (1 - ($Fee / 100)))
                $Level = $Stat.$($(arg).Stat_Algo)
     
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
                    "$NH_Wallet1.$($(arg).RigName1)",
                    ## User2
                    "$NH_Wallet2.$($(arg).RigName2)",
                    ## User3
                    "$NH_Wallet3.$($(arg).RigName3)",
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
    }
}
