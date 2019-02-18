$Command = @{oc_algo = "x16r"}
$Command = $Command | ConvertTo-Json -Compress
$Token = "token"
$Url = "https://api2.hiveos.farm/api/v2/farms//workers/?token=$Token"
$A = Invoke-RestMethod $Url -Method Patch -Body $Command -ContentType 'application/json'