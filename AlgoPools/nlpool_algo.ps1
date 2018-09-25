$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Location = 'Europe'

$nlpool_Request = [PSCustomObject]@{}
$nlpoolAlgo_Request = [PSCustomObject]@{}

if($Auto_Algo -eq "Yes")
  {
  if($Poolname -eq $Name)
   {
    try {
        $nlpoolAlgo_Request = Invoke-RestMethod "https://nlpool.nl/api/status" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    }
    catch {
        Write-Warning "SWARM contacted ($Name) for a failed API check. "
        return
    }
   
    if (($nlpoolAlgo_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
        Write-Warning "SWARM contacted ($Name) but ($Name) Pool API was unreadable. (Algorithm) "
        return
     }

 $nlpoolAlgo_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object {$nlpoolAlgo_Request.$_.hashrate -gt 0} |ForEach-Object {

        $nlpoolAlgo_Algorithm = Get-Algorithm $nlpoolAlgo_Request.$_.name
        $nlpoolAlgo_Host = "mine.nlpool.nl"
        $nlpoolAlgo_Port = $nlpoolAlgo_Request.$_.port
        $Divisor = (1000000*$nlpoolAlgo_Request.$_.mbtc_mh_factor)

        if($Algorithm -eq $nlpoolAlgo_Algorithm)
         {
        if((Get-Stat -Name "$($Name)_$($nlpoolAlgo_Algorithm)_Profit") -eq $null){$Stat = Set-Stat -Name "$($Name)_$($nlpoolAlgo_Algorithm)_Profit" -Value ([Double]$nlpoolAlgo_Request.$_.estimate_current/$Divisor*(1-($nlpoolAlgo_Request.$_.fees/100)))}
        else{$Stat = Set-Stat -Name "$($Name)_$($nlpoolAlgo_Algorithm)_Profit" -Value ([Double]$nlpoolAlgo_Request.$_.Estimate_Current/$Divisor *(1-($nlpoolAlgo_Request.$_.fees/100)))}
         
         
          if($Wallet)
           {
            If($nlWallet1 -ne ''){$nWallet1 = $nlWallet1}
            else{$nWallet1 = $Wallet1}
            if($nlWallet2 -ne ''){$nWallet2 = $nlWallet2}
            else{$nWallet2 = $Wallet2}
            if($nWallet1 -ne ''){$nWallet3 = $nlWallet3}
            else{$nWallet3 = $Wallet3}
            if($nlpassword1 -ne ''){$npass1 = $nlpassword1}
            else{$npass1 = $Passwordcurrency1}
            if($nlpoolpassword2 -ne ''){$npass2 = $nlpassword2}
            else{$npass2 = $Passwordcurrency2}
            if($nlpoolpassword3 -ne ''){$npass3 = $nlpassword3}
            else{$npass3 = $Passwordcurrency3}
            [PSCustomObject]@{
                Coin = "No"
                Symbol = $nlpoolAlgo_Algorithm
                Mining = $nlpoolAlgo_Algorithm
                Algorithm = $nlpoolAlgo_Algorithm
                Price = $Stat.$Stat_Algo
                StablePrice = $Stat.Week
                MarginOfError = $Stat.Fluctuation
                Protocol = "stratum+tcp"
                Host = $nlpoolAlgo_Host
                Port = $nlpoolAlgo_Port
                User1 = $nWallet1
                User2 = $nWallet2
                User3 = $nWallet3
                CPUser = $CPUWallet
                CPUPass = "c=$CPUcurrency,ID=$Rigname1"
                Pass1 = "c=$npass1,ID=$Rigname1"
                Pass2 = "c=$npass2,ID=$Rigname2"
                Pass3 = "c=$npass3,ID=$Rigname3"
                Location = $Location
                SSL = $false
                }
              }
            }
          }
        }
      }
