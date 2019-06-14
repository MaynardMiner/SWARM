function Global:Get-Bans {
    Write-Host "Doing Bans"
    Start-Sleep -S 3
    do {
        $Multi = $false
        if( $(vars).Config.Bans ){ $Bans = $(vars).Config.Bans }else{ $Bans = @() }
    do {
        Clear-Host
        $single = Read-Host -Prompt "Your current bans are:
        
$($Bans -join "`n")
        
Would you like to add to the list, or start a new one?

1 I would like to add to the Ban list
2 I would like to delete the current Bans, and start a new list.

Answer"
        $Check = Global:Confirm-Answer $single @("1","2")
    }While($Check -eq 1)
        do {
            clear-host
            $ans1 = Read-Host -Prompt "It appears a miner/algorithm/pool is giving you trouble.

Please specify what you wish to ban

1 I wish to ban an algorithm on miner.
2 I wish to ban an algorithm from a pool.
3 I wish to ban an algorithm on device group (AMD,NVIDIA,CPU,etc.).
4 I wish to ban an algorithm entirely.
5 I wish to ban an miner entirely.

Answer"
            $Check = Global:Confirm-Answer $ans1 @(1 .. 5)
        }while ($Check -eq 1)
        if ($ans1 -in 1 .. 3) {
            $Multi = $true
            switch ($ans1) {
                "1" {
                    $Num = 1
                    $table = [ordered]@{ }
                    $Get = @()
                    $Get += Get-ChildItem ".\miners\cpu" | Foreach {
                        "$Num $($_.BaseName)";
                        $table.Add("$Num", "$($_.BaseName)")
                        $Num++;
                    }   
                    $Get += Get-ChildItem ".\miners\gpu\amd" | Foreach {
                        "$Num $($_.BaseName)-1";
                        $table.Add("$Num", "$($_.BaseName)-1")
                        $Num++;
                    }
                    $Get += Get-ChildItem ".\miners\gpu\nvidia" | Foreach {
                        "$Num $($_.BaseName)-1";
                        $table.Add("$Num", "$($_.BaseName)-1");
                        $Num++;
                        "$Num $($_.BaseName)-2";
                        $table.Add("$Num", "$($_.BaseName)-2")
                        $Num++;
                        "$Num $($_.BaseName)-3";
                        $table.Add("$Num", "$($_.BaseName)-3")
                        $Num++;      
                    }
                    do {
                        clear-host
                        $ans2 = Read-Host -Prompt "Please select the miner you wish to set a ban for
$($Get -join "`n")

Number"
                        $Check = Global:Confirm-Answer $ans2 @(1 .. ($Num-1))
                    }while ($Check -eq 1)
                }
                "2" {
                    $Num = 1
                    $table = [ordered]@{ }
                    $Get = @()
                    $Get += Get-ChildItem ".\algopools" | Foreach {
                        "$Num $($_.BaseName)";
                        $table.Add("$Num", "$($_.BaseName)")
                        $Num++;
                    }
                    do {
                        clear-host
                        $ans2 = Read-Host -Prompt "Please select the pool you wish to set a ban for

$($Get -join "`n")

Number"
                        $Check = Global:Confirm-Answer $ans2 @(1 .. ($Num-1))
                    }while ($Check -eq 1)
                }
                "3" {
                    $Num = 1
                    $table = [ordered]@{ }
                    $Get = @()
                    $(vars).config.Type | % { $Get += "$Num $($_)"; $table.Add("$Num", "$($_)"); $Num++ }
                    do {
                        $ans2 = Read-Host -Prompt "Please select the device group you wish to set a ban for
                        
$($Get -join "`n")

Number"
                        $Check = Global:Confirm-Answer $ans2 @(1 .. ($Num-1))
                    }While ($check -eq 1)
                }
            }
        }
            if ($ans1 -eq "5") {
                $Num = 1
                $table = [ordered]@{ }
                $Get = @()
                $Get += Get-ChildItem ".\miners\cpu" | Foreach {
                    "$Num $($_.BaseName)";
                    $table.Add("$Num", "$($_.BaseName)")
                    $Num++;
                }   
                $Get += Get-ChildItem ".\miners\gpu\amd" | Foreach {
                    "$Num $($_.BaseName)-1";
                    $table.Add("$Num", "$($_.BaseName)-1")
                    $Num++;
                }
                $Get += Get-ChildItem ".\miners\gpu\nvidia" | Foreach {
                    "$Num $($_.BaseName)-1";
                    $table.Add("$Num", "$($_.BaseName)-1");
                    $Num++;
                    "$Num $($_.BaseName)-2";
                    $table.Add("$Num", "$($_.BaseName)-2")
                    $Num++;
                    "$Num $($_.BaseName)-3";
                    $table.Add("$Num", "$($_.BaseName)-3")
                    $Num++;      
                }
                do {
                    clear-host
                    $ans3 = Read-Host -Prompt "Please select the miner you wish to set a ban for
$($Get -join "`n")

Number"
                    $Check = Global:Confirm-Answer $ans3 @(1 .. ($Num-1))
                }while ($Check -eq 1)
            }
            if($ans1 -eq "4" -or $Multi -eq $true) {
            do{
                Clear-Host
            $List = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json

            $Num = 1
            $Algos = [ordered]@{ }
            $List.PSObject.Properties.Name | % { $Algos.Add("$Num", $_); $Num++ }
            $AlgoTable = @()
            $Algos.keys | % { $AlgoTable += "$($_) $($Algos.$_)" }
    
            $ans4 = Read-Host -Prompt "What Algorithm do you wish to prohibit?

$($AlgoTable -join "`n")
    
Number"
                $Check = Global:Confirm-Answer $ans4 @(1 .. ($Num-1))
        }while($Check -eq 1)
    }
    if($multi -eq $false){
        if($ans3){$Sel = $Table.$ans3}else{$Sel = $Algos.$ans4}
        do{
            Clear-Host
            switch($single) {
                "1"{$bans = @($Bans) + $Sel}
                "2"{$bans = $Sel}
            }
            $Confirm = Read-Host -Prompt "You have chosen to ban the follwing:
    
$($Bans -join "`n")
    
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1","2")
        }While($Check -eq 1)
        if($Confirm -ne "1"){
            Write-Host "okay lets try again"
            Start-Sleep -S 3
        }
        else{$Ban = $Sel}
    }
    else {
        switch($single) {
            "1"{$bans = @($Bans) + "$($Algos.$ans4)`:$($Table.$ans2)"}
            "2"{$bans = "$($Algos.$ans4)`:$($Table.$ans2)"}
        }    
        do{
        $Confirm = Read-Host -Prompt "You have chosen to ban the follwing:

$($Bans -join "`n")

Is this correct?

1 Yes
2 No

Answer"
       $Check = Global:Confirm-Answer $Confirm @("1","2")
        }while($Check -eq 1)
        if($Confirm -ne "1") {
            Write-Host "okay, lets try again"
            Start-Sleep -S 3
        }
        else {$Ban = $Sel}
    }
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("Bans")) { $(vars).config.Bans = $Bans } else { $(vars).config.Add("Bans", $Bans) }
}

function Global:Get-Admin { 
    switch ($(vars).input) {
        "21" { Global:Get-Bans }
        "22" { Global:Get-Ban_GLT }
        "23" { Global:Get-PoolBanCount }
        "24" { Global:Get-AlgoBanCount }
        "25" { Global:Get-Threshold }
        "26" { Global:Get-Rejections }
        "27" { Global:Get-Optional }
        "28" { Global:Get-XNSub }
    }

    do {
        clear-host
        $(vars).continue = Read-Host -Prompt "Do You Wish To Continue?
    
1 Yes
2 No

Answer"
        $check = Global:Confirm-Answer $(vars).continue @("1", "2")
    }while ($check -eq 1)
}