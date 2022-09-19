function Global:Update-HiveTagging {
    if ([string]$(arg).API_Key -ne "") {
        $Miner_Pool = "No Pool";
        $Profit_Day = 0;
        $Miner_Name = "Conserve";
        $Coin_Name = $null;
        $AddTags = @();

        $(vars).BestActiveMiners | Where-Object { $_.Type -notlike "*ASIC*" -and $_.Type -ne "CPU" -and $_.Type -like "*1*" } | ForEach-Object {
            $Miner_Pool = $_.MinerPool;
            $Miner_Name = $_.Name.Replace("-1", "");
            if ($(arg).Auto_Coin -eq "Yes" -and $_.Coin) {
                $Coin_Name = $_.Symbol;
            }
        }

        $IsBenchmarking = $null -ne ($(vars).BestActiveMiners | Where-Object { $_.Profit_Day -eq "bench" })

        if (!$IsBenchmarking) {
            $(vars).BestActiveMiners | ForEach-Object {
                $Profit_Day += $_.Profit_Day
            }    
        }
        else {
            $Profit_Day = "bench"
        }

        log "SWARM Is Tagging Worker With Information" -ForeGroundColor Cyan;

        $API = @{
            Method      = "GET";
            Uri         = "";
            ContentType = "application/json";
            Headers     = @{Authorization = "Bearer $($(arg).API_Key)" };
            Body        = $null;
        }

        $Tag_List = @();
        $Tag_List += "Conserve"
        $Tag_List += "No Pool"
        $Tag_List += (Get-ChildItem "miners\gpu\amd" | Where-Object name -like "*ps1*").BaseName;
        $Tag_List += (Get-ChildItem "miners\gpu\nvidia" | Where-Object name -like "*ps1*").BaseName;
        $Tag_List += (Get-ChildItem "miners\optional_and_old" | Where-Object name -like "*ps1*").BaseName;
        $Tag_List += (Get-ChildItem "pools\pplns" | Where-Object name -like "*ps1*").BaseName;
        $Tag_List += (Get-ChildItem "pools\pps" | Where-Object name -like "*ps1*").BaseName;
        $Tag_List += (Get-ChildItem "pools\prop" | Where-Object name -like "*ps1*").BaseName;

        $miner_tagid = $null;
        $pool_tagid = $null;
        $coin_tagid = $null;
        $remove_coin = $null;
        $Worker_TagIDs = @();
        $Tag_Ids = @{};

        ## Get Current Tag List
        $API.Uri = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags?token=$($(arg).API_Key)";
        $API.Method = "GET";
        $API.Body = $Null;
        try { 
            $Tags = Invoke-RestMethod @API -TimeoutSec 10 -ErrorAction Stop;
        }
        catch { 
            log "WARNING: Failed to Get Tags From HiveOS" -ForegroundColor Yellow; 
            log "Message from HiveOS: $($_.Exception.Message)" -ForeGround Yellow;
            return;
        }

        ## Get Current Worker
        $API.Uri = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/workers/$($Global:Config.hive_params.Id)?token=$($(arg).API_Key)";
        $API.Method = "GET"
        $API.Body = $Null;
        try { 
            $Worker = Invoke-RestMethod @API -TimeoutSec 10 -ErrorAction Stop 
        }
        catch { 
            log "WARNING: Failed to Contact HiveOS for Worker Information" -ForegroundColor Yellow; 
            log "Message from HiveOS: $($_.Exception.Message)" -ForeGround Yellow;
            return;
        }

        ## Create new profit tag
        $New_Profit_Day = "$($Global:Config.hive_params.Worker) Profit: BENCHMARKING"
        if ($Profit_Day -ne "bench") {
            $Profit_Day = [math]::Round($Profit_Day, 6)
            $New_Profit_Day = "$($Global:Config.hive_params.Worker) Profit: $Profit_Day BTC\Day"
        }
        ## Patch old profit tag or add to list of tags to create
        $Old_Profit_Tag = ($Tags.data | Where-Object name -like "*$($Global:Config.hive_params.Worker) Profit:*").id
        if ($Old_Profit_Tag) {
            $API.Method = "PATCH";
            $API.Uri = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags/$Old_Profit_Tag"
            $API.Body = @{ name = $New_Profit_Day; color = 11; } | ConvertTo-Json -Compress;
            try { 
                $Set_Tag = Invoke-RestMethod @API -TimeoutSec 10 -ErrorAction Stop 
            }
            catch { 
                log "WARNING: Failed to Update Profit Tag From HiveOS" -ForegroundColor Yellow; 
                log "Message from HiveOS: $($_.Exception.Message)" -ForeGround Yellow;
                return;
            }    
            $Profit_Tag = $Old_Profit_Tag;
        } 
        else {
            $AddTags += @{ name = $New_Profit_Day; color = 11; };
        }

        ## Create new coin tag
        $Old_Coin_Tag = ($Tags.data | Where-Object name -like "*$($Global:Config.hive_params.Worker) Coin: *").id
        if ($Coin_Name) {
            $New_Coin_Name = "$($Global:Config.hive_params.Worker) Coin: " + $Coin_Name;
            ## Patch old coin tag or add to list of tags to create
            if($Old_Coin_Tag) {
                $API.Method = "PATCH";
                $API.Uri = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags/$Old_Coin_Tag"
                $API.Body = @{ name = $New_Coin_Name; color = 6; } | ConvertTo-Json -Compress;
                try { 
                    $Set_Tag = Invoke-RestMethod @API -TimeoutSec 10 -ErrorAction Stop 
                }
                catch { 
                    log "WARNING: Failed to Update Coin Tag From HiveOS" -ForegroundColor Yellow; 
                    log "Message from HiveOS: $($_.Exception.Message)" -ForeGround Yellow;
                    return;
                }    
                $Coin_Tag = $Old_Coin_Tag;    
            }
            else {
                $AddTags += @{ name = $New_Coin_Name; color = 6; };
            }    
        }
        elseif($Old_Coin_Tag) {
            $remove_coin = $Old_Coin_Tag
        }

        ## Assign an ID to already created Tags.
        $set_tags = $Tags.data | Where-Object { $_.name -in $Tag_List }
        foreach ($tag in $set_tags) {
            if(!$Tag_Ids.$($tag.name)) {
            $Tag_Ids.Add("$($tag.name)", "$($tag.id)")
            }
        }
        $Miner_Tag = $Tag_Ids.$Miner_Name
        $Pool_Tag = $Tag_Ids.$Miner_Pool

        ## If miner and pool tags don't exist, create
        ## Add New Profit Tag
        if (!$Miner_Tag) {
            $AddTags += @{ name = $Miner_Name; color = 17 };
        }
        if (!$Pool_Tag) {
            $AddTags += @{ name = $Miner_Pool; color = 8 };
        }

        ## Add tags- Get their id
        if ($AddTags.Count -gt 0) {
            $API.Body = @{ data = $AddTags } | ConvertTo-Json -Compress
            $API.Uri = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/tags/multi?token=$($(arg).API_Key)";
            $API.Method = "POST";
            try { 
                $New_tags = Invoke-RestMethod @API -TimeoutSec 10 -ErrorAction Stop 
            }
            catch { 
                log "WARNING: Failed To Update New Tags From HiveOS" -ForegroundColor Yellow; 
                log "Message from HiveOS: $($_.Exception.Message)" -ForeGround Yellow;
                return;
            }    

            $New_Miner_Tag = $New_tags.data | Where-Object name -eq $Miner_Name;
            $New_Pool_Tag = $New_tags.data | Where-Object name -eq $Pool_Tag;
            $New_Profit_Tag = $New_tags.data | Where-Object name -eq $New_Profit_Day;
            $New_Coin_Tag = $New_tags.data | Where-Object name -eq $New_Coin_Name;

            if ($New_Miner_Tag) {
                $Miner_Tag = $New_Miner_Tag.Id;
            }
            if ($New_Pool_Tag) {
                $Pool_Tag = $New_Pool_Tag.Id;
            }
            if ($New_Profit_Tag) {
                $Profit_Tag = $New_Profit_Tag.Id;
            }
            if ($New_Coin_Tag) {
                $Coin_Tag = $New_Coin_Tag.Id;
            }
        }

        ## Remove Old Tags, But only SWARM tags.
        foreach ($tag in $Worker.tag_ids) {
            if ($tag -notin $Set_Tags.id -and $tag -notin $Old_Profit_Tag -and $tag -notin $remove_coin) {
                $Worker_TagIDs += $tag;
            }
        }

        ## Add New Tags
        if($Profit_Tag) { $Worker_TagIDs += $Profit_Tag; }
        if($Pool_Tag) { $Worker_TagIDs += $Pool_Tag; }
        if($Miner_Tag) { $Worker_TagIDs += $Miner_Tag; }
        if($Coin_Tag) { $Worker_TagIDs += $Coin_Tag;}
        $API.Method = "PATCH"
        $API.Uri = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/workers/$($Global:Config.hive_params.Id)"
        $API.Body = @{ tag_ids = $Worker_TagIDs } | ConvertTo-Json -Compress;
        try { 
            $Worker_Post = Invoke-RestMethod @API -TimeoutSec 10 -ErrorAction Stop 
        }
        catch { 
            log "WARNING: Failed To update tags" -ForegroundColor Yellow; 
            log "Message from HiveOS: $($_.Exception.Message)" -ForeGround Yellow;
            return;
        }
    }
}