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


function Get-DeviceString {
    param(
    [Parameter(Mandatory=$false)]
    [String]$TypeDevices = "none",
    [Parameter(Mandatory=$false)]
    [String]$TypeCount
    )

   if($TypeDevices -ne "none")
   {
    $TypeDevices = $TypeDevices -replace (","," ")
    if($TypeDevices -match " "){$NewDevices = $TypeDevices -split " "}else{$NewDevices = $TypeDevices -split ""}
    $NewDevices = Switch($NewDevices){"a"{"10"};"b"{"11"};"c"{"12"};"e"{"13"};"f"{"14"};"g"{"15"};"h"{"16"};"i"{"17"};"j"{"18"};"k"{"19"};"l"{"20"};default{"$_"};}
    if($TypeDevices -match " "){$TypeGPU = $NewDevices}else{$TypeGPU = $NewDevices | ? {$_.trim() -ne ""}}
    $TypeGPU = $TypeGPU | % {iex $_}
   }
   else{
    $TypeGPU = @()
    $GetDevices = 0
    for($i=0; $i -lt $TypeCount; $i++){$TypeGPU += $GetDevices++}
   }

$TypeGPU
}




function Get-TCP {
     
  param(
      [Parameter(Mandatory = $false)]
      [String]$Server = "localhost", 
      [Parameter(Mandatory = $true)]
      [String]$Port, 
      [Parameter(Mandatory = $true)]
      [String]$Message, 
      [Parameter(Mandatory = $false)]
      [Int]$Timeout = 10 #seconds
  )

  try {
      $Client = New-Object System.Net.Sockets.TcpClient $Server, $Port
      $Stream = $Client.GetStream()
      $Writer = New-Object System.IO.StreamWriter $Stream
      $Reader = New-Object System.IO.StreamReader $Stream
      $client.SendTimeout = $Timeout * 1000
      $client.ReceiveTimeout = $Timeout * 1000
      $Writer.AutoFlush = $true

      $Writer.WriteLine($Message)
      $Response = $Reader.ReadLine()
  }
  catch { $Error.Remove($error[$Error.Count - 1])}
  finally {
      if ($Reader) {$Reader.Close()}
      if ($Writer) {$Writer.Close()}
      if ($Stream) {$Stream.Close()}
      if ($Client) {$Client.Close()}
  }

  $response
  
}

function Get-HTTP {
     
  param(
      [Parameter(Mandatory = $false)]
      [String]$Server = "localhost", 
      [Parameter(Mandatory = $true)]
      [String]$Port, 
      [Parameter(Mandatory = $false)]
      [String]$Message,
      [Parameter(Mandatory = $false)]
      [Int]$Timeout = 10 #seconds
  )

  try {
       $response = Invoke-WebRequest "http://$($Server):$($Port)$($Message)" -UseBasicParsing -TimeoutSec $timeout
      }
  catch {$Error.Remove($error[$Error.Count - 1])}
  $response
}


function Get-HashRate {
    param(
        [Parameter(Mandatory=$true)]
        [String]$Type,
        [Parameter(Mandatory=$false)]
        [String]$API,
        [Parameter(Mandatory=$false)]
        [Int]$Port
       )

    if($Type -eq "ASIC")
    {
      switch($API)
      {
        "cgminer"
        {
        $summary = "summary|0"
        $Master | foreach {try{$response = Get-TCP -Server "$($_)" -Port $Port -Message $summary -Timeout $timeout}catch{}}
        $response = $response -split "SUMMARY," | Select -Last 1
        $response = $response -split "," | ConvertFrom-StringData
        $Hash = [Double]$Response."MHS 5s"*1000000
        $Hash
        }
      }
    }
    else{
        $HashFile = Get-Content ".\build\txt\$Type-hash.txt"
        [Double]$HashFile 
        }
}

filter ConvertTo-Hash {
    $Hash = $_
    switch([math]::truncate([math]::log($Hash,[Math]::Pow(1000,1))))
    {
        0 {"{0:n2}  H" -f ($Hash / [Math]::Pow(1000,0))}
        1 {"{0:n2} KH" -f ($Hash / [Math]::Pow(1000,1))}
        2 {"{0:n2} MH" -f ($Hash / [Math]::Pow(1000,2))}
        3 {"{0:n2} GH" -f ($Hash / [Math]::Pow(1000,3))}
        4 {"{0:n2} TH" -f ($Hash / [Math]::Pow(1000,4))}
        Default {"{0:n2} PH" -f ($Hash / [Math]::Pow(1000,5))}
    }
}

filter ConvertTo-LogHash {
    $Hash = $_
    switch([math]::truncate([math]::log($Hash,[Math]::Pow(1000,1))))
    {
        0 {"{0:n2}  `nhs" -f ($Hash / [Math]::Pow(1000,0))}
        1 {"{0:n2} `nkhs" -f ($Hash / [Math]::Pow(1000,1))}
        2 {"{0:n2} `nmhs" -f ($Hash / [Math]::Pow(1000,2))}
        3 {"{0:n2} `nghs" -f ($Hash / [Math]::Pow(1000,3))}
        4 {"{0:n2} `nths" -f ($Hash / [Math]::Pow(1000,4))}
        Default {"{0:n2} `n PH" -f ($Hash / [Math]::Pow(1000,5))}
    }
}