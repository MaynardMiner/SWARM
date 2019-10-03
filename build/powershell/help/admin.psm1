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

function Global:Get-Bans {
    Write-Host "Doing Bans"
    Start-Sleep -S 3
    do {
        $Multi = $false
        if ( $(vars).Config.Bans ) { $Bans = $(vars).Config.Bans }else { $Bans = @() }
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $single = Read-Host -Prompt "Your current bans are:
        
$($Bans -join "`n")
        
Would you like to add to the list, or start a new one?

1 I would like to add to the Ban list
2 I would like to delete the current Bans, and start a new list.

Answer"
            $Check = Global:Confirm-Answer $single @("1", "2")
        }While ($Check -eq 1)
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
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
                        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
                        $ans2 = Read-Host -Prompt "Please select the miner you wish to set a ban for
$($Get -join "`n")

Number"
                        $Check = Global:Confirm-Answer $ans2 @(1 .. ($Num - 1))
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
                        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
                        $ans2 = Read-Host -Prompt "Please select the pool you wish to set a ban for

$($Get -join "`n")

Number"
                        $Check = Global:Confirm-Answer $ans2 @(1 .. ($Num - 1))
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
                        $Check = Global:Confirm-Answer $ans2 @(1 .. ($Num - 1))
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
                if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
                $ans3 = Read-Host -Prompt "Please select the miner you wish to set a ban for
$($Get -join "`n")

Number"
                $Check = Global:Confirm-Answer $ans3 @(1 .. ($Num - 1))
            }while ($Check -eq 1)
        }
        if ($ans1 -eq "4" -or $Multi -eq $true) {
            do {
                if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
                $List = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json

                $Num = 1
                $Algos = [ordered]@{ }
                $List.PSObject.Properties.Name | % { $Algos.Add("$Num", $_); $Num++ }
                $AlgoTable = @()
                $Algos.keys | % { $AlgoTable += "$($_) $($Algos.$_)" }
    
                $ans4 = Read-Host -Prompt "What Algorithm do you wish to prohibit?

$($AlgoTable -join "`n")
    
Number"
                $Check = Global:Confirm-Answer $ans4 @(1 .. ($Num - 1))
            }while ($Check -eq 1)
        }
        if ($multi -eq $false) {
            if ($ans3) { $Sel = $Table.$ans3 }else { $Sel = $Algos.$ans4 }
            do {
                if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
                switch ($single) {
                    "1" { $bans = @($Bans) + $Sel }
                    "2" { $bans = $Sel }
                }
                $Confirm = Read-Host -Prompt "You have chosen to ban the follwing:
    
$($Bans -join "`n")
    
Is this correct?

1 Yes
2 No

Answer"
                $Check = Global:Confirm-Answer $Confirm @("1", "2")
            }While ($Check -eq 1)
            if ($Confirm -ne "1") {
                Write-Host "okay lets try again"
                Start-Sleep -S 3
            }
            else { $Ban = $Sel }
        }
        else {
            switch ($single) {
                "1" { $bans = @($Bans) + "$($Algos.$ans4)`:$($Table.$ans2)" }
                "2" { $bans = "$($Algos.$ans4)`:$($Table.$ans2)" }
            }    
            do {
                $Confirm = Read-Host -Prompt "You have chosen to ban the follwing:

$($Bans -join "`n")

Is this correct?

1 Yes
2 No

Answer"
                $Check = Global:Confirm-Answer $Confirm @("1", "2")
            }while ($Check -eq 1)
            if ($Confirm -ne "1") {
                Write-Host "okay, lets try again"
                Start-Sleep -S 3
            }
            else { $Ban = $Sel }
        }
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("Bans")) { $(vars).config.Bans = $Bans } else { $(vars).config.Add("Bans", $Bans) }
}

function Global:Get-Ban_GLT {
    Write-Host "Doing Ban_GLT"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Ban_GLT         
        
[Yes or No]         

Default is `"Yes`". Disables GLT coin. Most users and statistics
has shown that GLT never pays out what it states that it should.
Reducing profit.

Global Token for Auto-Coin switching has shown
historically to be inaccurate. This is due to the nature of Global Token itself.
Users have requested that an option be made to ban all Global Tokens.

Do you wish SWARM to skip all Global Tokens for Auto_Coin

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1", "2")
    }While ($Check -eq 1)
    Switch ($ans) {
        "1" { $ans = "Yes" }
        "2" { $ans = "No" }
    }
    if ($(vars).config.ContainsKey("Ban_GLT")) { $(vars).config.Ban_GLT = $ans } else { $(vars).config.Add("Ban_GLT", $ans) }
}

function Global:Get-PoolBanCount {
    Write-Host "Doing PoolBanCount"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "PoolBanCount    
        
[0-10]             

Default is 2. Number of strikes/bad benchmarks required before
miner is banned from using pool.
                                    
SWARM will disable an algorithm from a pool
after x bad benchmarks, where x is PoolBanCount parameter

How many benchmarks need to be bad before SWARM bans a pool?

Answer"
    
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans.
            
Is this correct

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("PoolBanCount")) { $(vars).config.PoolBanCount = $ans } else { $(vars).config.Add("PoolBanCount", $ans) }
}

function Global:Get-AlgoBanCount {
    Write-Host "Doing AlgoBanCount"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "AlgoBanCount    
        
[0-10]             

Default is 2. Number of strikes/bad benchmarks required before
miner is banned from algorithm.
                                    
SWARM will disable an algorithm from a miner
after x bad benchmarks, where x is AlgoBanCount parameter

How many benchmarks need to be bad before SWARM bans a pool?

Answer"
    
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans.
            
Is this correct

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("AlgoBanCount")) { $(vars).config.AlgoBanCount = $ans } else { $(vars).config.Add("AlgoBanCount", $ans) }
}

function Global:Get-Threshold {
    Write-Host "Doing Threshold"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Threshold     

[.0001 - 100000]	    

Expressed in BTC/day. Default is .02. If the total daily profits of a
particular algo/coin exceed the -Threshold argument, it will be removed
from database calculation. This is to prevent mining on a particular
coin/algorithm in which the pool is having issues with. It only needs
to be specified if you wish it to be different than .02 btc/day

Please enter new threshold"
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered $ans as new threshold. 
            
Is this correct

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1","2")
        }While ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("Threshold")) { $(vars).config.Threshold = $ans } else { $(vars).config.Add("Threshold", $ans) }
}

function Global:Get-Rejections {
    Write-Host "Doing Rejections"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Rejections 	    
        
[0-100]	    

Default is 50. This the % of rejections required for SWARM to 
consider background miner as timing out.

Please enter new rejection percent"
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered a rejection percent of $ans

Is This Correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)
    }While ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("Rejections")) { $(vars).config.Rejections = $ans } else { $(vars).config.Add("Rejections", $ans) }
}

function Global:Get-Optional {
    Write-Host "Doing Optional"
    Start-Sleep -S 3
    do {
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $Num = 1
        $table = [ordered]@{ }
        $Get = @()
        $Get += Get-ChildItem ".\miners\optional_and_old" | Foreach {
            "$Num $($_.BaseName)";
            $table.Add("$Num", "$($_.BaseName)")
            $Num++;
        }
        $ans = Read-Host -Prompt "Please select an optional/old miners you wish to add.

Comma seperate your answers i.e 1,2,3

$($Get -join "`n")

Answer"
        $ans = $ans.split(",")
        $ans = $ans | % { $Table.$_ } 
        do {
            if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
            $Confirm = Read-Host -Prompt "You have entered the following miners
        
$($ans -join "`n")
        
Is this correct?

1 Yes
2 No

Answer"
            $Check = Global:Confirm-Answer $Confirm @("1", "2")
        }While ($Check -eq 1)
    }while ($Confirm -ne "1")
    if ($(vars).config.ContainsKey("Optional")) { $(vars).config.Optional = $ans } else { $(vars).config.Add("Optional", $ans) }
}

function Global:Get-XNSub {
    Write-Host "Doing XNSub"
    Start-Sleep -S 3
    do{
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $ans = Read-Host -Prompt "Xnsub          
    
[Yes or No]            

Default is `"No`". Will add #xnsub for ASIC to signify Extranonce.Subscribe
method. Not all cgminer / ASICS / Pools may support this.

Do you wish to add #xnsub for ASIC

1 Yes
2 No

Answer"
        $Check = Global:Confirm-Answer $ans @("1","2")
    }While($Check -eq 1)
    switch($ans){
        "1" {$ans = "Yes"}
        "2" {$ans = "No"}
    }
    if ($(vars).config.ContainsKey("XNSub")) { $(vars).config.XNSub = $ans } else { $(vars).config.Add("XNSub", $ans) }
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
        if($IsWindows){Clear-Host} elseif($IsLinux){$Host.UI.Write("`e[3;J`e[H`e[2J")}
        $Confirm = Read-Host -Prompt "Do You Wish To Continue?
    
1 Yes
2 No

Answer"
        $check = Global:Confirm-Answer $Confirm @("1", "2")
        Switch($Confirm){
            "1" {$(vars).continue = $true}
            "2" {$(vars).continue = $false}
        }
    }while ($check -eq 1)
}