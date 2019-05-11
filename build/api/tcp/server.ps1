function Get-TCPServer {

    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.Open()
    $Runspace.SessionStateProxy.SetVariable('stats', $global:stats)

    $TCPServer = {
        if (Test-Path ".\build\pid\tcp_pid.txt") { $AFID = Get-Content ".\build\pid\tcp_pid.txt"; $AID = Get-Process -ID $AFID -ErrorAction SilentlyContinue }
        if ($AID) { Stop-Process $AID -ErrorAction SilentlyContinue }
        $PID | Set-Content ".\build\pid\tcp_pid.txt"
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
                    "summary" {
                        $Current_Stats = $Stats.Summary | ConvertTo-Json -Compress
                        $writer = New-Object IO.StreamWriter($stream)
                        $writer.WriteLine($Current_Stats)
                        $writer.Dispose()        
                    }
                }
            }
            $reader.Dispose()
            Start-Sleep -Milliseconds 500
        }
        $server.Stop()
    }

    $Posh_Api = [powershell]::Create()
    $Posh_Api.Runspace = $Runspace
    $Posh_Api.AddScript($TCPServer) | Out-Null
    $Posh_Api
    Write-Host "Starting TCP Server" -ForegroundColor "Yellow"

}
