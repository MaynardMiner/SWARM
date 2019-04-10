function Get-StatsCgminer {
    $Hash_Table = @{HS = 1; KHS = 1000; MHS = 1000000; GHS = 1000000000; THS = 1000000000000; PHS = 1000000000000000 }
    $Command = "summary|0"
    $Request = Get-TCP -Server $Server -Port $port -Message $Command
    if ($Request) {
        $response = $Request -split "SUMMARY," | Select-Object -Last 1
        $response = $Request -split "," | ConvertFrom-StringData
        if ($response."HS 5s") { $global:RAW = [Double]$response."HS 5s" * $Hash_Table.HS }
        if ($response."KHS 5s") { $global:RAW = [Double]$response."KHS 5s" * $Hash_Table.KHS }
        if ($response."MHS 5s") { $global:RAW = [Double]$response."MHS 5s" * $Hash_Table.MHS }
        if ($response."GHS 5s") { $global:RAW = [Double]$response."GHS 5s" * $Hash_Table.GHS }
        if ($response."THS 5s") { $global:RAW = [Double]$response."MHS 5s" * $Hash_Table.THS }
        if ($response."PHS 5s") { $global:RAW = [Double]$response."MHS 5s" * $Hash_Table.PHS }
        if ($response."HS_5s") { $global:RAW = [Double]$response."HS_5s" * $Hash_Table.HS }
        if ($response."KHS_5s") { $global:RAW = [Double]$response."KHS_5s" * $Hash_Table.KHS }
        if ($response."MHS_5s") { $global:RAW = [Double]$response."MHS_5s" * $Hash_Table.MHS }
        if ($response."GHS_5s") { $global:RAW = [Double]$response."GHS_5s" * $Hash_Table.GHS }
        if ($response."THS_5s") { $global:RAW = [Double]$response."MHS_5s" * $Hash_Table.THS }
        if ($response."PHS_5s") { $global:RAW = [Double]$response."MHS_5s" * $Hash_Table.PHS }
        Write-MinerData2;
        $global:ASICKHS += $global:RAW / 1000
        $global:ASICHashRates[0] = $global:RAW / 1000
        $global:MinerREJ += $response.Rejected
        $global:MinerACC += $response.Accepted
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Set-APIFailure }
}