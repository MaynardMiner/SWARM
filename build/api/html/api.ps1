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

function Get-APIServer {
    if ($API -eq "Yes") {

        $Runspace = [runspacefactory]::CreateRunspace()
        $Runspace.Open()

        $APIServer = {
            param($WorkingDir, $Port, $Remote, $APIPassword)
            [cultureinfo]::CurrentCulture = 'en-US'
            Set-Location $WorkingDir            
            if (Test-Path ".\build\pid\api_pid.txt") { $AFID = Get-Content ".\build\pid\api_pid.txt"; $AID = Get-Process -ID $AFID -ErrorAction SilentlyContinue }
            if ($AID) { Stop-Process $AID -ErrorAction SilentlyContinue }
            $PID | Set-Content ".\build\pid\api_pid.txt"
            $listener = New-Object System.Net.HttpListener
            Write-Host "Listening ..."
            if ($Remote -eq "yes") {
                if ($APIPassword -ne "No") {
                    [string]$Prefix = "http://+:$Port/$APIPassword/"
                }
                else { $Prefix = "http://+:$Port/" }
            }
            else { [string]$Prefix = "http://localhost:$Port/" }
   
            # Run until you send a GET request to /end
            $listener.Prefixes.Add($Prefix) 
            $listener.Start()
            while ($listener.IsListening) {
                $context = $listener.GetContext() 
   
                # Capture the details about the request
                $request = $context.Request
   
                # Setup a place to deliver a response
                $response = $context.Response
      
                # Break from loop if GET request sent to /end
                if ($request.Url -match '/end') { break }
                else {
                    # Split request URL to get command and options
                    $requestvars = [String]$request.Url -split "/"
                    if ($Remote -eq "Yes" -and $APIPassword -ne "No") { $GET = $requestvars[4] }
                    elseif ($Remote -eq "Yes" -and $APIPassword -eq "No") { $GET = $requestvars[3] }
                    else { $GET = $requestvars[3] }
                    $requestcom = $GET -split "`&" | Select-Object -First 1
                    $requestargs = $GET -replace "$requestcom", ""
                    $requestargs = $requestargs -replace "`&", " "
                    if ($requestcom) {
                        switch ($requestcom) {
                            "summary" {
                                if (Test-Path ".\build\txt\profittable.txt") {
                                    $result = @()
                                    $getsummary = Get-Content ".\build\txt\profittable.txt" | ConvertFrom-Json;
                                    $Types = $getsummary.type | Select-Object -Unique
                                    $Types | ForEach-Object {
                                        $MinersOn = $false
                                        $Selected = $getsummary | Where-Object Type -eq $_
                                        $Selected | ForEach-Object { if ($_.Profits -ne $null) { $MinersOn = $true } }
                                        if ($MinersOn -eq $true) { $Selected = $Selected | Sort-Object -Property Profits -Descending }
                                        else { $Selected = $Selected | Sort-Object -Property Pool_Estimate -Descending }                
                                        $result += @{"$($_)" = @($Selected) }
                                    }
                                    $message = $result | ConvertTo-Json -Depth 4 -Compress; 
                                    $response.ContentType = 'application/json';
                                }
                                else {
                                    # If no matching subdirectory/route is found generate a 404 message
                                    $message = @("No Data") | ConvertTo-Json -Compress;
                                    $response.ContentType = 'application/json';
                                }
                            }
                            "getstats" {
                                if (Test-Path ".\build\txt\hivestats.txt") {
                                    $result = Get-Content ".\build\txt\hivestats.txt" | ConvertFrom-StringData
                                    $Stat = @()
                                    for ($i = 0; $i -lt $result.GPUKHS.Count; $i++) {
                                        $GPU = @{"GPU$i" = @{
                                                hashrate    = $result.GPUKHS | Select-Object -skip $i -First 1; 
                                                temperature = $result.GPUTEMP | Select-Object -skip $i -First 1;
                                                fans        = $result.GPUFAN | Select-Object -skip $i -First 1;
                                            }
                                        }; 
                                        $Stat += $GPU
                                    }
                                    for ($i = 0; $i -lt $result.CPUKHS.Count; $i++) {
                                        $CPU = @{"CPU$i" = @{
                                                hashrate    = $result.CPUKHS | Select-Object -skip $i -First 1; 
                                                temperature = $result.CPUTEMP | Select-Object -skip $i -First 1;
                                                fans        = $result.CPUFAN | Select-Object -skip $i -First 1;
                                            }
                                        };
                                        $Stat += $CPU
                                    }
                                    for ($i = 0; $i -lt $result.ASICKHS.Count; $i++) {
                                        $ASIC = @{"ASIC" = @{
                                                hashrate = $result.ASICKHS | Select-Object -skip $i -First 1; 
                                            }
                                        };
                                        $Stat += $ASIC
                                    }
                                    $Stat += @{Algorithm = $result.ALGO }
                                    $Stat += @{Uptime = $result.UPTIME }
                                    $Stat += @{"Hash_Units" = $result.HSU }
                                    $Stat += @{Accepted = $result.ACC }
                                    $Stat += @{Rejected = $result.REJ }
                                    $message = $Stat | ConvertTo-Json -Depth 4 -Compress;
                                    $response.ContentType = 'application/json'; 
                                }
                                else {
                                    # If no matching subdirectory/route is found generate a 404 message
                                    $message = @("No Data") | ConvertTo-Json -Compress;
                                    $response.ContentType = 'application/json';
                                }
                            }
                            "getbest" {
                                if (Test-Path ".\build\txt\bestminers.txt") {
                                    $result = @()
                                    $getbest = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-Json
                                    $Types = $getbest.type | Select-Object -Unique
                                    $Types | ForEach-Object {
                                        $MinersOn = $false
                                        $Selected = $getbest | Where-Object Type -eq $_
                                        $Selected | ForEach-Object { if ($_.Profits -ne $null) { $MinersOn = $true } }
                                        if ($MinersOn -eq $true) { $Selected = $Selected | Sort-Object -Property Profits -Descending }
                                        else { $Selected = $Selected | Sort-Object -Property Pool_Estimate -Descending }                
                                        $result += @{"$($_)" = @($Selected) }
                                    }
                                    $message = $result | ConvertTo-Json -Depth 4 -Compress; 
                                    $response.ContentType = 'application/json';
                                }
                                else {
                                    # If no matching subdirectory/route is found generate a 404 message
                                    $message = @("No Data") | ConvertTo-Json -Compress;
                                    $response.ContentType = 'application/json';
                                }   
                            }
                            "get" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\get.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            "version" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\version.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            "clear_profits" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\clear_profits.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            "clear_watts" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\clear_watts.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            "benchmark" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\benchmark.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            default {
                                # If no matching subdirectory/route is found generate a 404 message
                                $message = @("No Data") | ConvertTo-Json -Compress;
                                $response.ContentType = 'application/json';
                                $message = $result | ConvertTo-Json -Depth 4 -Compress; 
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
                        $response = $null
                        $message = $null
                        $getbest = $null
                        $GET = $null
                        $requestvars = $null
                        $requestcom = $null
                    }
                }
            }
        }

        $Posh_Api = [powershell]::Create()
        $Posh_Api.Runspace = $Runspace
        $Posh_Api.AddScript($APIServer) | Out-Null
        $Posh_Api.AddArgument($WorkingDir) | Out-Null
        $Posh_Api.AddArgument($Port) | Out-Null
        $Posh_Api.AddArgument($Remote) | Out-Null
        $Posh_Api.AddArgument($APIPassword) | Out-Null
        $Posh_Api
        #Start-Job $APIServer -Name "APIServer" -ArgumentList $WorkingDir, $Port, $Remote, $APIPassword | OUt-Null
        Write-Host "Starting API Server" -ForegroundColor "Yellow"
    }
}