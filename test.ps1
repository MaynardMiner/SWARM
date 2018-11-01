
    param(
     
    )
$Method = "miners"
$Name = "t-rex"
$Param = "NVIDIA1"
$SubParam = "commands"
$Algo = "x16r"
$Command = "-i 10"

if(Test-Path ".\config\$Method\$Name.json"){$Config = Get-Content ".\config\$Method\$Name.json" | ConvertFrom-Json}
if($Config)
{
 switch($Method)
 {
  "miners"
   {
    $Config.$Param.$SubParam.$Algo = $Command
   }

 }

}
else
{
 $Message = "Could not fine $method $Name config"
 $Message | Out-File ".\build\txt\configcom.txt"
 Write-Host "$Message" -ForegroundColor Red
}