param (
[Parameter(Mandatory=$false)]
[String]$IP = ""
)

"-o stratum+tcp://pool.ckpool.org:3333 -u 1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i -p x --suggest-diff 32"
"stratum+tcp://sha256.usa.nicehash.com"

$request = '{"command":"summary","parameter":"0"}'
$IP = "localhost"
$Port = 4028
$timeout = 10
$request = @{command = "addpool"; parameter = "stratum+tcp://sha256.usa.nicehash.com:3334,1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i.test,x"}
$message = $request | ConvertTo-Json -Compress
try{
$response = Invoke-WebRequest "http://$($IP):$($Port)" -Method Post -Body $Message -UseBasicParsing -TimeoutSec $timeout
}
catch{
$response = "failed To Contact Host"
}

$response | Out-File ".\test2.txt"

$request = @{command = "switchpool"; parameter = "1";}
   $message = $request | ConvertTo-Json -Compress
   try{
   $response = Invoke-WebRequest "http://$($IP):$($Port)$($Message)" -UseBasicParsing -TimeoutSec $timeout
   }
   catch{
   $response = "failed To Contact Host"
   }
   
   $response | Out-File ".\test2.txt"

   $message = @{
    command = "switchpool"
    parameter = "1"
   }
   $message = $request | ConvertTo-Json -Compress
   try{
   $response = Invoke-WebRequest "http://$($IP):$($Port)$($Message)" -UseBasicParsing -TimeoutSec $timeout
   }
   catch{
   $response = "failed To Contact Host"
   }

   $response | Out-File ".\test3.txt"
   