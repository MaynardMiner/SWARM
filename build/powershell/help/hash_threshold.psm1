function Global:Get-HashThreshold {
    Write-Host "Doing Hashrate_Threshold"
    Start-Sleep -S 3
    do {
        $Check = 1
        if ($IsWindows) { Clear-Host } elseif ($IsLinux) { $Host.UI.Write("`e[3;J`e[H`e[2J") }
        $ans = Read-Host -Prompt "
Hashrate_Threshold

[Percent]        

Hashrate threshold attempts to prevent constant switching
from one miner to another when the algorithm is the same.
If Hashrate_Threshold is greater than 0, SWARM will reduce
the hashrate of the algorithm from all other miners capable
of mining it EXCEPT the miner that is currently mining it.

This means that a miner must greater than x% faster than 
the current miner in order to switch. This does factor
in rejection percentage, if user has specified to do so.

Default is 10

Please specify a percentage you would like to use.

Answer"

        try {
            $Check = 0;
            $get = [Convert]::ToInt32($ans)
        }
        catch {
            Write-Host "$ans is not an integer!"
            Start-Sleep -S 3
            $Check = 1;
        }
    }While ($Check -eq 1)
    if ($(vars).config.ContainsKey("Hashrate_Threshold")) { $(vars).config.Hashrate_Threshold = $get } else { $(vars).config.Add("Hashrate_Threshold", $get) }
}

function Global:Get-HashrateThreshold { 
    switch ($(vars).input) {
        "51" { Global:Get-HashThreshold }
    }
    do {
        if ($IsWindows) { Clear-Host } elseif ($IsLinux) { $Host.UI.Write("`e[3;J`e[H`e[2J") }
        $Confirm = Read-Host -Prompt "Do You Wish To Continue?
    
1 Yes
2 No

Answer"
        $check = Global:Confirm-Answer $Confirm @("1", "2")
        Switch ($Confirm) {
            "1" { $(vars).continue = $true }
            "2" { $(vars).continue = $false }
        }
    }while ($check -eq 1)
}
