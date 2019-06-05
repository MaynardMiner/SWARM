function Global:Get-CoinShares {

    . .\build\api\pools\zergpool.ps1;
    . .\build\api\pools\nlpool.ps1;    
    . .\build\api\pools\ahashpool.ps1;
    . .\build\api\pools\blockmasters.ps1;
    . .\build\api\pools\hashrefinery.ps1;
    . .\build\api\pools\phiphipool.ps1;
    . .\build\api\pools\fairpool.ps1;
    . .\build\api\pools\blazepool.ps1;

    $(arg).Type | ForEach-Object { $global:Share_Table.Add("$($_)", @{ }) }

    ##For 
    $(arg).Poolname | % {
        switch ($_) {
            "zergpool" { Global:Get-ZergpoolData }
            "nlpool" { Global:Get-NlPoolData }        
            "ahashpool" { Global:Get-AhashpoolData }
            "blockmasters" { Global:Get-BlockMastersData }
            "hashrefinery" { Global:Get-HashRefineryData }
            "phiphipool" { Global:Get-PhiphipoolData }
            "fairpool" { Global:Get-FairpoolData }
            "blazepool" { Global:Get-BlazepoolData }
        }
    }
}