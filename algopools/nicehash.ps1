
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$nicehash_Request = [PSCustomObject]@{ } 

if($(arg).xnsub -eq "Yes"){$X = "#xnsub"}
 
if ($Name -in $(arg).PoolName) {
    try { $nicehash_Request = Invoke-RestMethod "https://api.nicehash.com/api?method=simplemultialgo.info" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Global:Write-Log "SWARM contacted ($Name) but there was no response."; return }
 
    if (($nicehash_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Global:Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return 
    } 
  
    Switch ($(arg).Location) {
        "US" { $Region = "usa" }
        "ASIA" { $Region = "hk" }
        "EUROPE" { $Region = "eu" }
    }

    $nicehash_Request.result | 
    Select-Object -ExpandProperty simplemultialgo | 
    Where-Object paying -ne 0 | 
    Where-Object {
        $Algo = $_.name.ToLower();
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

                $nicehash_Host = "$($_.name).$Region.nicehash.com$X"
                $nicehash_excavator = "nhmp.$Region.nicehash.com$X"
                $nicehash_Port = $_.port
                $Divisor = 1000000000

                ## Nicehash is pretty straightforward being PPS. In
                ## My experience, whatever they state is return- Is
                ## usually pretty close to actual.

                $StatAlgo = $Nicehash_Algorithm -replace "`_","`-"
                $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -Value ([Double]$_.paying / $Divisor * (1 - ($Fee / 100)))
     
                [PSCustomObject]@{
                    Excavator = $nicehash_excavator
                    Symbol    = "$nicehash_Algorithm-Algo"
                    Algorithm = $nicehash_Algorithm
                    Price     = $Stat.$($(arg).Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $nicehash_Host
                    Port      = $nicehash_Port
                    User1     = "$NH_Wallet1.$($(arg).RigName1)"
                    User2     = "$NH_Wallet2.$($(arg).RigName2)"
                    User3     = "$NH_Wallet3.$($(arg).RigName3)"
                    Pass1     = "x"
                    Pass2     = "x"
                    Pass3     = "x"
                }
            }
        }
    }
}
