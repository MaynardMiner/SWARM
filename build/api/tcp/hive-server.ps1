function Get-HiveServer {

    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.Open()
    $Runspace.SessionStateProxy.SetVariable('stats', $global:stats)

    $TCPServer = {
        if (Test-Path ".\build\pid\tcp_pid.txt") { $AFID = Get-Content ".\build\pid\tcp_pid.txt"; $AID = Get-Process -ID $AFID -ErrorAction SilentlyContinue }
        if ($AID) { Stop-Process $AID -ErrorAction SilentlyContinue }
        $PID | Set-Content ".\build\pid\tcp_pid.txt"
        $addr = [ipaddress]'127.0.0.1'
        $port = 6099
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
        }
        $server.Stop()
    }

    $Posh_Api = [powershell]::Create()
    $Posh_Api.Runspace = $Runspace
    $Posh_Api.AddScript($TCPServer) | Out-Null
    $Posh_Api
    Write-Host "Starting HiveOS TCP Server" -ForegroundColor "Yellow"

}
