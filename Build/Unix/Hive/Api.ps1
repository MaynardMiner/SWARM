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

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:4098/') 
$listener.Start()
Write-Host "Listening ..."
$APIWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$APIWatch.Start()
while ($true) {

$message = $null
$response = $null
    function Get-API {
        param(
            [Parameter(Mandatory=$true)]
            [String]$API,
            [Parameter(Mandatory=$true)]
            [Int]$Port,
            [Parameter(Mandatory=$true)]
            [string]$GET,
            [Parameter(Mandatory=$false)]
            [Object]$Parameters = @{},
            [Parameter(Mandatory=$false)]
            [Bool]$Safe = $false
        )
    
        $Server = "localhost"
    
        try
        {
            switch($API)
            {
                "sgminer-gm"
                {
                    $Message = @{command="$GET"; parameter=""} | ConvertTo-Json -Compress
                    $Client = New-Object System.Net.Sockets.TcpClient $server, $port
                    $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
                    $Reader = New-Object System.IO.StreamReader $Client.GetStream()
                    $Writer.AutoFlush = $true
                    $Writer.WriteLine($Message)
                    $Request = $Reader.ReadLine()
                }
                "ccminer"
                {
                    $Message = "$GET"

                        $Client = New-Object System.Net.Sockets.TcpClient $server, $port
                        $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
                        $Reader = New-Object System.IO.StreamReader $Client.GetStream()
                        $Writer.AutoFlush = $true
                        $Writer.WriteLine($Message)
                        $Request = $Reader.ReadLine()
                        for($i=0; $i -lt $Request.Count; $i++)
                        {
                         $B = $Request | Select -skip $i | Select -first 1
                         $C = $B -split ";"
                         $D = $C | Convertfrom-StringData
                         $GPUArray | Add-Member "GPU$($D)" $D
                        }
                }
                   
                }
                "nicehashequihash"
                {
                    $Message = "$GET"

                        $Client = New-Object System.Net.Sockets.TcpClient $server, $port
                        $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
                        $Reader = New-Object System.IO.StreamReader $Client.GetStream()
                        $Writer.AutoFlush = $true
    
                        $Writer.WriteLine($Message)
                        $Request = $Reader.ReadLine()

                }
                "nicehash"
                {
                    $Message = @{id = 1; method = "algorithm.list"; params = @()} | ConvertTo-Json -Compress

                        $Client = New-Object System.Net.Sockets.TcpClient $server, $port
                        $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
                        $Reader = New-Object System.IO.StreamReader $Client.GetStream()
                        $Writer.AutoFlush = $true
    
                        $Writer.WriteLine($Message)
                        $Request = $Reader.ReadLine()
                }
                "ewbf"
                {
                    $Message = @{id = 1; method = "$GET"} | ConvertTo-Json -Compress

                        $Client = New-Object System.Net.Sockets.TcpClient $server, $port
                        $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
                        $Reader = New-Object System.IO.StreamReader $Client.GetStream()
                        $Writer.AutoFlush = $true
    
                        $Writer.WriteLine($Message)
                        $Request = $Reader.ReadLine()

                }
              "claymore"
                {

                        $Request = Invoke-WebRequest "http://$($Server):$Port" -UseBasicParsing
    
                        $Data = $Request | ConvertFrom-Json

                }
                "dstm" {
                    $Message = "$GET"

                        $Client = New-Object System.Net.Sockets.TcpClient $server, $port
                        $Writer = New-Object System.IO.StreamWriter $Client.GetStream()
                        $Reader = New-Object System.IO.StreamReader $Client.GetStream()
                        $Writer.AutoFlush = $true
    
                        $Writer.WriteLine($Message)
                        $Request = $Reader.ReadLine()
                        
                  }
                  
                "fireice"
                {

                        $Request = Invoke-WebRequest "http://$($Server):$Port/h" -UseBasicParsing
    
                        $Data = $Request
    
                        if(-not $Safe){break}
    
                }
                "wrapper"
                {
                        $HashRate = Get-Content ".\Wrapper_$Port.txt"
    
    
                        if($HashRate -eq $null){$HashRates = @()}
    
                        $HashRates += [Double]$HashRate

                }
                "tdxminer"
                 {                    
                     
                    $HashRate = Get-Content ".\Build\Unix\Hive\totalhashraw.sh"
    
                    if($HashRate -eq $null){$HashRates = @()}
    
                    $HashRates += [Double]$HashRate

                 }
            }
         $Request
        }
        catch
        {
        }
    }

    if($APIWatch.Elapsed.TotalSeconds -ge 10)
    {
     if($null -ne $MinerAPI -and $null -ne $MinerPort)
      {
       $ApiSummary = Get-API -API $MinerAPI -Port $MinerPort -GET "summary"
       $ApiThreads = Get-API -API $MinerAPI -Port $MinerPort -GET "threads"
       $APIWatch.Restart()
      }
    }
   
$context = $listener.GetContext() 
$request = $context.Request
$response = $context.Response
$TotalHash = $null
$HashRates = $null
$Accepted = $null
$Rejected = $null
#$Fanspeed
#$Temperature
#$Power


if($request.Url -match '/end$'){break}
else {

$requestvars = ([String]$request.Url).split("/")

if($null -ne $requestvars)
 {

 if($requestvars[3] -eq "command")
  {
    $MinerAPI = "$($requestvars[4])" 
    $MinerPort = "$($requestvars[5])" 
    $result = "Command Recieved: Setting Miner to $MinerApi, Port to $MinerPort" 
    $message = $result 
    $response.ContentType = 'text/html' 
    Write-Host "$result" 
  }

 if($requestvars[3] -eq "api")
  {
   if($requestvars[4] -eq "summary"){$result = $APISummary}
   if($requestvars[4] -eq "threads"){$result = $APIThreads}
   $message = $result ;
   $response.ContentType = 'text/html'
   Write-Host "$result"
  }

  if($message){[byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)}
  if($response)
   {
  $response.ContentLength64 = $buffer.length
  $output = $response.OutputStream
  $output.Write($buffer, 0, $buffer.length)
  $output.Close()
   }

  }
 }
}

$listener.Stop()
$listener.Dispose()