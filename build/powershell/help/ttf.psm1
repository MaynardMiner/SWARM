function Global:Get-MAXTTF {
    Write-Host "Doing max_TTF"
    Start-Sleep -S 3
    do {
        $Check = 1
        if ($IsWindows) { Clear-Host } elseif ($IsLinux) { $Host.UI.Write("`e[3;J`e[H`e[2J") }
        $ans = Read-Host -Prompt "
Max_TFF

[seconds]        

Will only affect Coin pools.
Auto_Coin must be Yes, or this will be ignored.
SWARM will calculate the time pool (not your miner) is finding
blocks, and will not select coins that has a block time find
above this value. By default, SWARM will ignore any coins that
is taking the pool a day or longer to find.

Default is 86400 (seconds)

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
    if ($(vars).config.ContainsKey("Max_TTF")) { $(vars).config.Max_TTF = $get } else { $(vars).config.Add("Max_TTF", $get) }
}

function Global:Get-TTF { 
    switch ($(vars).input) {
        "50" { Global:Get-MAXTTF }
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
