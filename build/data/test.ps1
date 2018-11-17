param (
[Parameter(Mandatory=$false)]
[String]$IP = ""
)

$Port = 4028
$timeout = 10
$request = @{
  command = "addpool"
  parameter = "stratum+tcp://equihash.mine.zergpool.com:2142,3PVTDiFSQo9rur1JA5XHdU7oPwo4PEgVYN.ASIC_Z9_Mini_03,x"
 }
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
   