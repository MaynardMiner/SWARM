$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$Zpool_Request = [PSCustomObject]@{ } 

if($global:Config.Params.xnsub -eq "Yes"){$X = "#xnsub"} 
 
if ($Name -in $global:Config.Params.PoolName) {
    try { $Zpool_Request = Invoke-RestMethod "http://www.zpool.ca/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop } 
    catch { Write-Log "SWARM contacted ($Name) but there was no response."; return }
  
    if (($Zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        Write-Log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    } 
   
    Switch ($global:Config.Params.Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "sea" }
    }
  
    $Zpool_Request | 
    Get-Member -MemberType NoteProperty -ErrorAction Ignore | 
    Select-Object -ExpandProperty Name | 
    Where-Object { $Zpool_Request.$_.hashrate -gt 0 } | 
    Where-Object {
        $Algo = $Zpool_Request.$_.name.ToLower();
        $local:Zpool_Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name | Where { $Algo -in $global:Config.Pool_Algos.$_.alt_names }
        return $Zpool_Algorithm
    } |
    ForEach-Object {
        if ($Algorithm -contains $Zpool_Algorithm -or $global:Config.Params.ASIC_ALGO -contains $Zpool_Algorithm) {
            if ($Name -notin $global:Config.Pool_Algos.$Zpool_Algorithm.exclusions -and $Zpool_Algorithm -notin $Global:banhammer) {
                $Zpool_Port = $Zpool_Request.$_.port
                $Zpool_Host = "$($Zpool_Request.$_.name.ToLower()).$($region).mine.zpool.ca$X"
                $Divisor = (1000000 * $Zpool_Request.$_.mbtc_mh_factor)
                $Fees = $Zpool_Request.$_.fees
                $Workers = $Zpool_Request.$_.Workers
                $Hashrate = $Zpool_Request.$_.hashrate

                $Global:DivisorTable.zpool.Add($Zpool_Algorithm, $Divisor)
                $Global:FeeTable.zpool.Add($Zpool_Algorithm, $Fees)

                $StatPath = ".\stats\($Name)_$($Zpool_Algorithm)_profit.txt"
                $Estimate = if (-not (Test-Path $StatPath)) { [Double]$Zpool_Request.$_.estimate_last24h } else { [Double]$Zpool_Request.$_.estimate_current }

                $Cut = ConvertFrom-Fees $Fees $Workers $Estimate
                $StatAlgo = $Zpool_Algorithm -replace "`_","`-"
                $Stat = Set-Stat -Name "$($Name)_$($StatAlgo)_profit" -HashRate $HashRate -Value ([Double]$Cut / $Divisor)

                if (-not $global:Pool_Hashrates.$Zpool_Algorithm) { $global:Pool_Hashrates.Add("$Zpool_Algorithm", @{ }) }
                if (-not $global:Pool_Hashrates.$Zpool_Algorithm.$Name) { $global:Pool_Hashrates.$Zpool_Algorithm.Add("$Name", @{HashRate = "$($Stat.HashRate)"; Percent = "" }) }
         
                $Pass1 = $global:Wallets.Wallet1.Keys
                $User1 = $global:Wallets.Wallet1.$($global:Config.Params.Passwordcurrency1).address
                $Pass2 = $global:Wallets.Wallet2.Keys
                $User2 = $global:Wallets.Wallet2.$($global:Config.Params.Passwordcurrency2).address
                $Pass3 = $global:Wallets.Wallet3.Keys
                $User3 = $global:Wallets.Wallet3.$($global:Config.Params.Passwordcurrency3).address

                if ($global:Wallets.AltWallet1.keys) {
                    $global:Wallets.AltWallet1.Keys | ForEach-Object {
                        if ($global:Wallets.AltWallet1.$_.Pools -contains $Name) {
                            $Pass1 = $_;
                            $User1 = $global:Wallets.AltWallet1.$_.address;
                        }
                    }
                }
                if ($global:Wallets.AltWallet2.keys) {
                    $global:Wallets.AltWallet2.Keys | ForEach-Object {
                        if ($global:Wallets.AltWallet2.$_.Pools -contains $Name) {
                            $Pass2 = $_;
                            $User2 = $global:Wallets.AltWallet2.$_.address;
                        }
                    }
                }
                if ($global:Wallets.AltWallet3.keys) {
                    $global:Wallets.AltWallet3.Keys | ForEach-Object {
                        if ($global:Wallets.AltWallet3.$_.Pools -contains $Name) {
                            $Pass3 = $_;
                            $User3 = $global:Wallets.AltWallet3.$_.address;
                        }
                    }
                }
                
                [PSCustomObject]@{
                    Symbol    = "$Zpool_Algorithm-Algo"
                    Algorithm = $Zpool_Algorithm
                    Price     = $Stat.$($global:Config.Params.Stat_Algo)
                    Protocol  = "stratum+tcp"
                    Host      = $Zpool_Host
                    Port      = $Zpool_Port
                    User1     = $User1
                    User2     = $User2
                    User3     = $User3
                    Pass1     = "c=$Pass1,id=$($global:Config.Params.RigName1)"
                    Pass2     = "c=$Pass2,id=$($global:Config.Params.RigName2)"
                    Pass3     = "c=$Pass3,id=$($global:Config.Params.RigName3)"
                }
            }
        }
    }
}
