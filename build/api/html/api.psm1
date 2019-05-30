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

        $Runspace = [runspacefactory]::CreateRunspace()
        $Runspace.Open()
        $Runspace.SessionStateProxy.SetVariable('config',$global:Config)

        $APIServer = {
            [cultureinfo]::CurrentCulture = 'en-US'
            Set-Location $global:Config.Params.WorkingDir            
            $listener = New-Object System.Net.HttpListener
            Write-Host "Listening ..."
            if ($global:Config.Params.Remote -eq "yes") {
                if ($global:Config.Params.APIPassword -ne "No") {
                    [string]$Prefix = "http://+:$($global:Config.Params.Port)/$($global:Config.Params.APIPassword)/"
                }
                else { $Prefix = "http://+:$($global:Config.Params.Port)/" }
            }
            else { [string]$Prefix = "http://localhost:$($global:Config.Params.Port)/" }
   
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
                    if ($global:Config.Params.Port -eq "Yes" -and $global:Config.Params.APIPassword -ne "No") { $GET = $requestvars[4] }
                    elseif ($global:Config.Params.Remote -eq "Yes" -and $global:Config.Params.APIPassword -eq "No") { $GET = $requestvars[3] }
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
                                        $Selected | ForEach-Object { if ($_.Profit -ne $null) { $MinersOn = $true } }
                                        if ($MinersOn -eq $true) { $Selected = $Selected | Sort-Object -Property Profit -Descending }
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
                            }
                            "getbest" {
                                if (Test-Path ".\build\txt\bestminers.txt") {
                                    $result = @()
                                    $getbest = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-Json
                                    $Types = $getbest.type | Select-Object -Unique
                                    $Types | ForEach-Object {
                                        $MinersOn = $false
                                        $Selected = $getbest | Where-Object Type -eq $_
                                        $Selected | ForEach-Object { if ($_.Profit -ne $null) { $MinersOn = $true } }
                                        if ($MinersOn -eq $true) { $Selected = $Selected | Sort-Object -Property Profit -Descending }
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
                                Invoke-Expression ".\build\powershell\scripts\get.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            "version" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\scripts\version.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            "clear_profits" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\scripts\clear_profits.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            "clear_watts" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\scripts\clear_watts.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
                                $getbest | ForEach-Object { $result += "$_`n" };
                                $message = $result | ConvertTo-Json;
                                $response.ContentType = 'application/json';
                            }
                            "benchmark" {
                                $result = @()
                                Invoke-Expression ".\build\powershell\scripts\benchmark.ps1$requestargs" | Tee-Object -Variable getbest | Out-Null;
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
                        [GC]::Collect()
                    }
                }
            }
        }

        $Posh_Api = [powershell]::Create()
        $Posh_Api.Runspace = $Runspace
        $Posh_Api.AddScript($APIServer) | Out-Null
        $Posh_Api
        Write-Host "Starting HTML Server" -ForegroundColor "Yellow"
    }