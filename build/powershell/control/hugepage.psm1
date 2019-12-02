function Global:Start-Hugepage_Check { 

    ## Run HiveOS hugepages commmand if algo is randomx
    if ($Islinux -and (test-path "/hive/bin")) { ## Is a HiveOS rig
        if (
            "randomx" -in $(vars).BestActiveMiners.Algo -and ## One of the miners is about to mine randomX
            $(vars).HugePages -eq $false ## Not set yet
        ) {
            log "Setting HiveOS hugepages for RandomX" -ForegroundColor Cyan;
            Invoke-Expression "hugepages -rx";
            $(vars).HugePages = $true;
        }

        elseif (
            "randomx" -notin $(vars).BestActiveMiners.Algo -and ## No miner is going to mine randomX
            $(vars).HugePages -eq $true ## Is set
        ) {
            log "Setting hugepages back to default" -ForegroundColor Cyan;
            Invoke-expression "hugepages -r";
            $(vars).HugePages = $false;
        }
    }
    
}