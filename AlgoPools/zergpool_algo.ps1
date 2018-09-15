
$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Location = 'US'

$zergpool_Request = [PSCustomObject]@{}
$ZergpoolAlgo_Request = [PSCustomObject]@{}

if($Auto_Algo -eq "Yes")
  {
  if($Poolname -eq $Name)
   {
    try {
        $ZergpoolAlgo_Request = Invoke-RestMethod "http://zergpool.com:8080/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    }
    catch {
        Write-Warning "SWARM contacted ($Name) for a failed API check. "
        return
    }
   
    if (($zergpoolAlgo_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
        Write-Warning "SWARM contacted ($Name) but ($Name) Pool API was unreadable. (Algorithm) "
        return
     }

 $zergpoolAlgo_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$zergpoolAlgo_Request.$_.hashrate -gt 0} |ForEach-Object {
    
        $zergpoolAlgo_Algorithm = Get-Algorithm $zergpoolAlgo_Request.$_.name
        $zergpoolAlgo_Host = "$_.mine.zergpool.com"
        $zergpoolAlgo_Port = $zergpoolAlgo_Request.$_.port
        $Divisor = (1000000*$zergpoolAlgo_Request.$_.mbtc_mh_factor)

        if((Get-Stat -Name "$($Name)_$($zergpoolAlgo_Algorithm)_Profit") -eq $null){$Stat = Set-Stat -Name "$($Name)_$($zergpoolAlgo_Algorithm)_Profit" -Value ([Double]$zergpoolAlgo_Request.$_.estimate_current/$Divisor*(1-($zergpoolAlgo_Request.$_.fees/100)))}
        else{$Stat = Set-Stat -Name "$($Name)_$($zergpoolAlgo_Algorithm)_Profit" -Value ([Double]$zergpoolAlgo_Request.$_.Estimate_Current/$Divisor *(1-($zergpoolAlgo_Request.$_.fees/100)))}
         
          if($Wallet)
           {
            If($ZergpoolWallet1 -ne ''){$ZergWallet1 = $ZergpoolWallet1}
            else{$ZergWallet1 = $Wallet1}
            if($ZergpoolWallet2 -ne ''){$ZergWallet2 = $ZergpoolWallet2}
            else{$ZergWallet2 = $Wallet2}
            if($ZergpoolWallet1 -ne ''){$ZergWallet3 = $ZergpoolWallet3}
            else{$ZergWallet3 = $Wallet3}
            if($Zergpoolpassword1 -ne ''){$Zergpass1 = $Zergpoolpassword1}
            else{$Zergpass1 = $Passwordcurrency1}
            if($Zergpoolpassword2 -ne ''){$Zergpass2 = $Zergpoolpassword2}
            else{$Zergpass2 = $Passwordcurrency2}
            if($Zergpoolpassword3 -ne ''){$Zergpass3 = $Zergpoolpassword3}
            else{$Zergpass3 = $Passwordcurrency3}
            [PSCustomObject]@{
                Coin = "No"
                Symbol = $zergpoolAlgo_Algorithm
                Mining = $zergpoolAlgo_Algorithm
                Algorithm = $zergpoolAlgo_Algorithm
                Price = $Stat.$StatLevel
                StablePrice = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol = "stratum+tcp"
                Host = $zergpoolAlgo_Host
                Port = $zergpoolAlgo_Port
                User1 = $ZergWallet1
                User2 = $ZergWallet2
                User3 = $ZergWallet3
                CPUser = $CPUWallet
                CPUPass = "c=$CPUcurrency,ID=$Rigname1"
                Pass1 = "c=$Zergpass1,ID=$Rigname1"
                Pass2 = "c=$Zergpass2,ID=$Rigname2"
                Pass3 = "c=$Zergpass3,ID=$Rigname3"
                Location = $Location
                SSL = $false
              }
            }
          }
        }
}
