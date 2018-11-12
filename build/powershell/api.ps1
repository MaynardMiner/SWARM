# Create a listener on port 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:4099/') 
$listener.Start()
'Listening ...'


# Run until you send a GET request to /end
while ($true) {
    $context = $listener.GetContext() 

    # Capture the details about the request
    $request = $context.Request

    # Setup a place to deliver a response
    $response = $context.Response
   
    # Break from loop if GET request sent to /end
    if ($request.Url -match '/end$') { 
        break 
    } else {

        # Split request URL to get command and options
        $requestvars = ([String]$request.Url).split("/");        

        # If a request is sent to http:// :8000/wmi
        if ($requestvars[3] -eq "summary") {
         if(Test-Path ".\build\txt\bestminers.txt")
         {
         $result = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-JSon;
         $message = $result | ConvertTo-Json -Depth 4 -Compress; 
         $response.ContentType = 'application/json';
         }
       } else {

            # If no matching subdirectory/route is found generate a 404 message
            $message = "This is not the page you're looking for.";
            $response.ContentType = 'text/html' ;
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
 
#Terminate the listener
$listener.Stop()