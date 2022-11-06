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

function Global:Get-TCP {
     
    param(
        [Parameter(Mandatory = $false)]
        [String]$Server = "localhost", 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $true)]
        [String]$Message, 
        [Parameter(Mandatory = $false)]
        [Int]$Timeout = 10 #seconds
    )

    try {
        $Client = New-Object System.Net.Sockets.TcpClient $Server, $Port
        $Stream = $Client.GetStream()
        $Writer = New-Object System.IO.StreamWriter $Stream
        $Reader = New-Object System.IO.StreamReader $Stream
        $client.SendTimeout = $Timeout * 1000
        $client.ReceiveTimeout = $Timeout * 1000
        $Writer.AutoFlush = $true

        $Writer.WriteLine($Message)
        $Response = $Reader.ReadLine()
    }
    catch { $Error.Remove($error[$Error.Count - 1])}
    finally {
        if ($Reader) {$Reader.Close()}
        if ($Writer) {$Writer.Close()}
        if ($Stream) {$Stream.Close()}
        if ($Client) {$Client.Close()}
        if ($Reader) {$Reader.Dispose()}
        if ($Writer) {$Writer.Dispose()}
        if ($Stream) {$Stream.Dispose()}
        if ($Client) {$Client.Dispose()}
    }

    $response
  
}

function Global:Get-HTTP {
     
    param(
        [Parameter(Mandatory = $false)]
        [String]$Server = "localhost", 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $false)]
        [String]$Message = $null,
        [Parameter(Mandatory = $false)]
        [Int]$Timeout = 5 #seconds
    )

    try {
        $response = Invoke-WebRequest "http://$($Server):$($Port)$($Message)" -UseBasicParsing -TimeoutSec $Timeout
    }
    catch {$Error.Remove($error[$Error.Count - 1])}
    $response
}


function Global:Get-SWARMTCP {

    $Port = 5099
    $Message = "summary"
    $Server = "localhost"
    $Timeout = 5

    try {
        $Client = New-Object System.Net.Sockets.TcpClient $Server, $Port
        $Stream = $Client.GetStream()
        $Writer = New-Object System.IO.StreamWriter $Stream
        $Reader = New-Object System.IO.StreamReader $Stream
        $client.SendTimeout = $Timeout * 1000
        $client.ReceiveTimeout = $Timeout * 1000
        $Writer.AutoFlush = $true

        $Writer.WriteLine($Message)
        $Response = $Reader.ReadLine()
    }
    catch { $Error.Remove($error[$Error.Count - 1])}
    finally {
        if ($Reader) {$Reader.Close()}
        if ($Writer) {$Writer.Close()}
        if ($Stream) {$Stream.Close()}
        if ($Client) {$Client.Close()}
        if ($Reader) {$Reader.Dispose()}
        if ($Writer) {$Writer.Dispose()}
        if ($Stream) {$Stream.Dispose()}
        if ($Client) {$Client.Dispose()}
    }

    if($response) {
        $response = $response | ConvertFrom-Json
        $Response = $Response.Summary
    } else {$response = $null}

    $Response
}

function Global:Get-Rejections {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Type
    )

    $res = Global:Get-SWARMTCP
    if($res.$Type.rej){
        $data = $res.$Type.rej
    } else {
        $data = "0:0"
   }

   $data
}

function Global:Get-HashRate {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Type
    )

    $res = Global:Get-SWARMTCP
    if($res.$Type.hash){
        $data = [Double]$res.$Type.hash
    } else {
        $data = 0
   }
   
   $data
}

function Global:Get-Power {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Type
    )

    $res = Global:Get-SWARMTCP
    if($res.$Type.hash){
        $data = [Double]$res.$Type.Watts
    } else {
        $data = 0
   }
   
   $data
}

filter Global:ConvertTo-Hash {
    $Hash = $_
    switch ([math]::truncate([math]::log($Hash, [Math]::Pow(1000, 1)))) {
        -0 {"{0:n2} H" -f ($Hash / [Math]::Pow(1000, 0))}
        0 {"{0:n2} H" -f ($Hash / [Math]::Pow(1000, 0))}
        1 {"{0:n2} KH" -f ($Hash / [Math]::Pow(1000, 1))}
        2 {"{0:n2} MH" -f ($Hash / [Math]::Pow(1000, 2))}
        3 {"{0:n2} GH" -f ($Hash / [Math]::Pow(1000, 3))}
        4 {"{0:n2} TH" -f ($Hash / [Math]::Pow(1000, 4))}
        Default {"{0:n2} PH" -f ($Hash / [Math]::Pow(1000, 5))}
    }
}

function Global:Get-MinerHashRate {
    $(vars).BestActiveMiners | ForEach-Object {
        if ($_.Profit_Day -ne "bench") { $ScreenProfit = "$(($_.Profit_Day * $(vars).Rates.$($(arg).Currency)).ToString("N2")) $($(arg).Currency)/Day" } else { $ScreenProfit = "Benchmarking" }
        if ($_.Fiat_Day -ne "bench") { $CurrentProfit = "$($_.Fiat_Day) $($(arg).Currency)/Day" } else { $CurrentProfit = "Benchmarking" }
        if ($_.Profit_Day -ne "bench") { $BTCScreenProfit = "$($($_.Profit_Day).ToString("N5") ) BTC/Day" } else { $BTCScreenProfit = "Benchmarking" }
        if ($_.Fiat_Day -ne "bench") { $BTCCurrentProfit = "$($($_.Fiat_Day / $(vars).Rates.$($(arg).Currency)).ToString("N5")) BTC/Day" } else { $BTCCurrentProfit = "Benchmarking" }
        if ($null -eq $_.Xprocess -or $_.XProcess.HasExited) { $_.Status = "Failed" }
        $Miner_HashRates = $(vars).Hashtable.$($_.type).hashrate;
        $NewName = $_.Algo -replace "`_","`-"
        $GetDayStat = Global:Get-Stat "$($_.Name)_$($NewName)_HashRate"
        $DayStat = "$($GetDayStat.Hour)"
        $MinerPrevious = "$($DayStat | Global:ConvertTo-Hash)"
        $ScreenHash = "$($Miner_HashRates | Global:ConvertTo-Hash)"
        log "$($_.Type) is currently" -foreground Green -NoNewLine -Start
        if ($_.Status -eq "Running") { log " Running: " -ForegroundColor green -nonewline }
        if ($_.Status -eq "Failed") { log " Not Running: " -ForegroundColor darkred -nonewline } 
        log "$($_.Name) current avg. hashrate for $($_.Symbol) is" -nonewline
        log " $ScreenHash/s" -foreground green -End
        log "$($_.Name) current hashrate for $($_.Symbol) is" -NoNewLine -Start
        log " $( $(vars).hashtable.$($_.type).actual.ToString("N2") | Global:ConvertTo-Hash )/s" -foreground yellow -End
        log "$($_.Name) previous hashrates for $($_.Symbol) is" -NoNewLine -Start
        log " $MinerPrevious/s " -foreground yellow -End
        $No_Watts = @("CPU","ASIC")
        if($(arg).Wattometer -eq "yes" -and $_.type -notin $No_Watts) {
            log "$($_.Name) current power usage for $($_.Symbol) is" -NoNewLine -Start
            log " $( $(vars).hashtable.$($_.type).watts.ToString("N2") ) watts" -ForegroundColor Cyan -End    
        }
        log "$($_.Type) is currently mining $($_.Algo) on $($_.MinerPool)" -foregroundcolor Cyan
        log "$($_.Name) average rejection percentage for $($_.Algo) is " -NoNewLine -Start
        log "$( if($_.Rejections){ $( $($_.Rejections).ToString("N2") ) }else{"0.00"})`%" -foregroundcolor yellow -End
        log "Current Pool Projection: $CurrentProfit `| $BTCCurrentProfit  (This is live value with no modifiers)"
        if($_.Type -ne "CPU" -and $_.Type -ne "ASIC") {
            log "Current Daily Profit   : $ScreenProfit `| $BTCScreenProfit  (This is daily miner average with watt calculations)
            "            
        }
        else {
            log "Current Daily Profit   : $ScreenProfit `| $BTCScreenProfit  (This is daily miner average)
            "            
        }
    }
}
