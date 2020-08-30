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
function Global:Get-SWARMServer {

    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.Open()
    $Runspace.SessionStateProxy.SetVariable('stats', $global:Config)

    $TCPServer = {
        $addr = [ipaddress]'127.0.0.1'
        $port = 5099
        $endpoint = New-Object Net.IPEndPoint ($addr, $port)
        $server = New-Object Net.Sockets.TcpListener $endpoint
        $server.Start()
        While ($true) {
            $connection = $server.AcceptTcpClient()
            $stream = $connection.GetStream()
            $reader = New-Object System.IO.StreamReader $stream
            $line = $reader.ReadLine()
            if ($line) {
                switch ($line) {
                    "summary" { $Message = $Stats.Summary | ConvertTo-Json -Compress }
                    "stats" { $Message = $Stats.Stats | ConvertTo-Json -Compress }
                    "params" { $Message = $Stats.params | ConvertTo-Json -Compress }
                }
                $writer = New-Object IO.StreamWriter($stream)
                $writer.WriteLine($Message)
                $writer.Dispose()        
            }
            $reader.Dispose()
            $stream.Dispose()
            $client.Dispose()
            Start-Sleep -Milliseconds 500
            [GC]::Collect()
        }
        $server.Stop()
    }

    $Posh_Api = [powershell]::Create()
    $Posh_Api.Runspace = $Runspace
    $Posh_Api.AddScript($TCPServer) | Out-Null
    $Posh_Api
    Write-Host "Starting Agent TCP Server" -ForegroundColor "Yellow"

}
