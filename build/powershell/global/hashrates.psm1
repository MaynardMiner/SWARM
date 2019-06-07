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
        [String]$Message,
        [Parameter(Mandatory = $false)]
        [Int]$Timeout = 10 #seconds
    )

    try {
        $response = Invoke-WebRequest "http://$($global:Server):$($Port)$($Message)" -UseBasicParsing -TimeoutSec $Timeout
    }
    catch {$Error.Remove($error[$Error.Count - 1])}
    $response
}


function Global:Get-HashRate {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Type
    )

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
    }

    if($response) {
        $response = $response | ConvertFrom-Json
        $response = [Double]$response.summary.$Type
    }
    else{$response = [Double]0}

    $Response
}
filter Global:ConvertTo-Hash {
    $Hash = $_
    switch ([math]::truncate([math]::log($Hash, [Math]::Pow(1000, 1)))) {
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
        if ($null -eq $_.Xprocess -or $_.XProcess.HasExited) { $_.Status = "Failed" }
        $Miner_HashRates = Global:Get-HashRate -Type $_.Type
        $NewName = $_.Algo -replace "`_","`-"
        $GetDayStat = Global:Get-Stat "$($_.Name)_$($NewName)_HashRate"
        $DayStat = "$($GetDayStat.Hour)"
        $MinerPrevious = "$($DayStat | Global:ConvertTo-Hash)"
        $ScreenHash = "$($Miner_HashRates | Global:ConvertTo-Hash)"
        Global:Write-Log "$($_.Type) is currently" -foreground Green -NoNewLine -Start
        if ($_.Status -eq "Running") { Global:Write-Log " Running: " -ForegroundColor green -nonewline }
        if ($_.Status -eq "Failed") { Global:Write-Log " Not Running: " -ForegroundColor darkred -nonewline } 
        Global:Write-Log "$($_.Name) current hashrate for $($_.Symbol) is" -nonewline
        Global:Write-Log " $ScreenHash/s" -foreground green -End
        Global:Write-Log "$($_.Type) is currently mining $($_.Algo) on $($_.MinerPool)" -foregroundcolor Cyan
        Global:Write-Log "$($_.Type) previous hashrates for $($_.Symbol) is" -NoNewLine -Start
        Global:Write-Log " $MinerPrevious/s" -foreground yellow -End
        Global:Write-Log "Current Pool Projection: $CurrentProfit.  (This is live value with no modifiers)"
        Global:Write-Log "Current Daily Profit: $ScreenProfit.      (This is daily average with watt calculations)
"
    }
}
