function start-APIServer {
if($API -eq "Yes")
{
## Shutdown Previous API if stuck by running a command
Write-Host "Checking to ensure API port is free" -ForegroundColor "Yellow"
try{Invoke-RestMethod "http://localhost:4099/end" -UseBasicParsing -TimeoutSec 5}catch{}
## API Server Start
$APIServer = {
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$WorkingDir
   )

    Set-Location $WorkingDir
    if(test-Path ".\build\pid\api_pid.txt"){$AFID = Get-Content ".\build\pid\api_pid.txt"; $AID = Get-Process -ID $AFID -ErrorAction SilentlyContinue}
    if($AID){Stop-Process $AID -ErrorAction SilentlyContinue}
    $PID | Set-Content ".\build\pid\api_pid.txt"
    $listener = New-Object System.Net.HttpListener
    Write-Host "Listening ..."
   
   # Run until you send a GET request to /end
  try{
      $listener.Prefixes.Add('http://localhost:4099/') 
      $listener.Start()
   while ($listener.IsListening){
       $context = $listener.GetContext() 
   
       # Capture the details about the request
       $request = $context.Request
   
       # Setup a place to deliver a response
       $response = $context.Response
      
       # Break from loop if GET request sent to /end
       if ($request.Url -match '/end') { 
           break 
       } else {
   
           # Split request URL to get command and options
           $requestvars = ([String]$request.Url).split("/");
           if($requestvars[3])
           {
           switch($requestvars[3])
           {
               "summary" 
               {
                if(Test-Path ".\build\txt\profittable.txt")
                 {
                  $result = @()
                  $getsummary = Get-Content ".\build\txt\profittable.txt" | ConvertFrom-JSon;
                  $Types = $getsummary.type | Select -Unique
                  $Types | foreach{
                   $MinersOn = $false
                   $Selected = $getsummary | Where Type -eq $_
                   $Selected | foreach{if($_.Profits -ne $null){$MinersOn = $true}}
                   if($MinersOn -eq $true){$Selected = $Selected | Sort-Object -Property Profits -Descending}
                   else{$Selected = $Selected | Sort-Object -Property Pool_Estimate -Descending}                
                   $result += @{"$($_)" = @($Selected)}
                  }
                  $message = $result | ConvertTo-Json -Depth 4 -Compress; 
                  $response.ContentType = 'application/json';
                 }
                 else 
                 {
                  # If no matching subdirectory/route is found generate a 404 message
                  $message = @("No Data") | ConvertTo-Json -Compress;
                  $response.ContentType = 'application/json';
                 }
               }
               "getstats"
               {
                if(Test-Path ".\build\txt\hivestats.txt")
                 {
                  $result = Get-Content ".\build\txt\hivestats.txt" | ConvertFrom-StringData
                  $Stat = @()
                  for($i=0; $i -lt $result.GPU.Count; $i++)
                  {
                   $GPU = @{"GPU$i" = @{
                                        hashrate = $result.GPU | Select -skip $i -First 1; 
                                        temperature = $result.TEMP | Select -skip $i -First 1;
                                        fans = $result.FAN | Select -skip $i -First 1;}
                                       }; 
                  $Stat += $GPU
                  }
                  $Stat += @{Algorithm = $result.ALGO}
                  $Stat += @{Uptime = $result.UPTIME}
                  $Stat += @{"Hash_Units" = $result.HSU}
                  $Stat += @{Accepted = $result.ACC}
                  $Stat += @{Rejected = $result.REJ}
                  $message = $Stat | ConvertTo-Json -Depth 4 -Compress;
                  $response.ContentType = 'application/json'; 
                 }
                 else 
                 {
                  # If no matching subdirectory/route is found generate a 404 message
                  $message = @("No Data") | ConvertTo-Json -Compress;
                  $response.ContentType = 'application/json';
                 }
               }
           default
           {
                  # If no matching subdirectory/route is found generate a 404 message
                  $message = @("No Data") | ConvertTo-Json -Compress;
                  $response.ContentType = 'application/json';
           }
       }
          # Convert the data to UTF8 bytes
          [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
          
          # Set length of response
          $response.ContentLength64 = $buffer.length
          
          # Write response out and close
          $output = $response.OutputStream
          $output.Write($buffer, 0, $buffer.length)
          $output.Close()
         }    
        }
       }
      }Finally{$listener.Stop()}
}
Start-Job $APIServer -Name "APIServer" -ArgumentList "$Dir" | OUt-Null
Write-Host "Starting API Server" -ForegroundColor "Yellow"
}
}