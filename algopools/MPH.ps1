$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

if($Poolname -eq $Name)
 {
    try {
        $MiningPoolHub_Request = Invoke-RestMethod "http://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    }
    catch {
        Write-Log -Level Warn "Pool API ($Name) has failed. "
        return
    }

if(-not $MiningPoolHub_Request.success)
{
    return
    Write-Host "Warning: SWARM Failed To Contact Mining Pool Hub."
}

$Locations = 'Europe', 'US', 'Asia'

$Locations | foreach {

    $MPH_Location = $_

    $MiningPoolHub_Request.return | ForEach-Object {
    if($Algorithm -eq (Get-Algorithm($_.algo)))
     {
       $MPH_Algo = Get-Algorithm $_.algo
       $MPH_Port = $_.algo_switch_port
       if($MPH_Algo -eq "equihash-btg"){$MPH_Protocol = 'stratum+tcp'}
       else{$MPH_Protocol = 'stratum+tcp'}
       $MPH_Name = $_.coin_name
       $MPH_SymHostName = $_.algo
       Switch($MPH_SymHostName){"Equihash-BTG"{$MPH_SymHostName = "equihash"}
       }

       $MPH_Hostname = $_.all_host_list

       if($Location -eq 'Europe')
        {
         if($MPH_Hostname -ne "us-east.$($MPH_SymhostName)-hub.miningpoolhub.com;europe.$($MPH_SymhostName)-hub.miningpoolhub.com;asia.$($MPH_SymhostName)-hub.miningpoolhub.com"){$MPH_Host = "hub.miningpoolhub.com"}
         else{$MPH_Host = "europe.$($MPH_SymhostName)-hub.miningpoolhub.com"}
        }
       if($Location -eq 'US')
        {
         if($MPH_Hostname -ne "us-east.$($MPH_SymhostName)-hub.miningpoolhub.com;europe.$($MPH_SymhostName)-hub.miningpoolhub.com;asia.$($MPH_SymhostName)-hub.miningpoolhub.com"){$MPH_Host = "hub.miningpoolhub.com"}
         else{$MPH_Host = "us-east.$($MPH_SymhostName)-hub.miningpoolhub.com"}
        }
        if($Location -eq 'Asia')
        {
         if($MPH_Hostname -ne "us-east.$($MPH_SymhostName)-hub.miningpoolhub.com;europe.$($MPH_SymhostName)-hub.miningpoolhub.com;asia.$($MPH_SymhostName)-hub.miningpoolhub.com"){$MPH_Host = "hub.miningpoolhub.com"}
         else{$MPH_Host = "asia.$($MPH_SymhostName)-hub.miningpoolhub.com"}
        }

     if($Algorithm -eq $MPH_Algo)
      {
        $Stat = Set-Stat -Name "$($Name)_$($MPH_Algo)_profit" -Value ([decimal]$_.profit/1000000000)
        $Price = (($Stat.Live*(1-[Math]::Min($Stat.Day_Fluctuation,1)))+($Stat.Day*(0+[Math]::Min($Stat.Day_Fluctuation,1))))
      
      if($Wallet)
       {
           [PSCustomObject]@{
            Coin = "No"
            Symbol = $MPH_Algo
            Mining = $MPH_Name
            Algorithm = $MPH_Algo
            Price = $Price
            StablePrice = $Stat.Week
            Protocol = $MPH_Protocol
            Host = $MPH_Host
            Port = $MPH_Port
            User1 = '$UserName.$WorkerName'
            User2 = '$UserName.$WorkerName'
            User3 = '$UserName.$WorkerName'
            Pass1 = 'x'
            Pass2 = 'x'
            Pass3 = 'x'
            Location = $MPH_Location
            SSL = $true
            }
           }
		  }
         }   
       }
     }
    }
