function Get-StatsCgminer {
    $Hash_Table = @{HS = 1;KHS = 1000;MHS = 1000000;GHS = 1000000000;THS = 1000000000000;PHS = 1000000000000000}
    $Command = "summary|0"
    $Request = $Null; $Request = Get-TCP -Server $Server -Port $port -Message $Command
    if($Request)
     {
      $response = $Request -split "SUMMARY," | Select -Last 1
      $response = $Request -split "," | ConvertFrom-StringData
      if($response."HS 5s"){  $global:ARAW += [Double]$response."HS 5s"*$Hash_Table.HS}
      if($response."KHS 5s"){ $global:ARAW += [Double]$response."KHS 5s"*$Hash_Table.KHS}
      if($response."MHS 5s"){ $global:ARAW += [Double]$response."MHS 5s"*$Hash_Table.MHS}
      if($response."GHS 5s"){ $global:ARAW += [Double]$response."GHS 5s"*$Hash_Table.GHS}
      if($response."THS 5s"){ $global:ARAW += [Double]$response."MHS 5s"*$Hash_Table.THS}
      if($response."PHS 5s"){ $global:ARAW += [Double]$response."MHS 5s"*$Hash_Table.PHS}
      if($response."HS_5s"){  $global:ARAW += [Double]$response."HS_5s"*$Hash_Table.HS}
      if($response."KHS_5s"){ $global:ARAW += [Double]$response."KHS_5s"*$Hash_Table.KHS}
      if($response."MHS_5s"){ $global:ARAW += [Double]$response."MHS_5s"*$Hash_Table.MHS}
      if($response."GHS_5s"){ $global:ARAW += [Double]$response."GHS_5s"*$Hash_Table.GHS}
      if($response."THS_5s"){ $global:ARAW += [Double]$response."MHS_5s"*$Hash_Table.THS}
      if($response."PHS_5s"){ $global:ARAW += [Double]$response."MHS_5s"*$Hash_Table.PHS}
      Write-MinerData2;
      $global:AKHS += $global:ARAW / 1000
      $global:AREJ += $response.Rejected
      $global:AACC += $response.Accepted
      $global:BMinerREJ += $response.Rejected
      $global:BMinerACC += $response.Accepted
      $global:AAlgo += "$MinerAlgo"
      $global:AUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
     }
     else {Set-APIFailure; break}
    }