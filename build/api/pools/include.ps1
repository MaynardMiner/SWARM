function Get-CoinShares {

    . .\build\api\pools\zergpool.ps1;
    . .\build\api\pools\nlpool.ps1;    
    . .\build\api\pools\ahashpool.ps1;
    . .\build\api\pools\blockmasters.ps1;
    . .\build\api\pools\hashrefinery.ps1;
    . .\build\api\pools\phiphipool.ps1;
    . .\build\api\pools\fairpool.ps1;

    $type | % {$global:Share_Table.Add("$($_)",@{})}

    ##For now
    switch ($Poolname) {
        "zergpool" {Get-ZergpoolData}
        "nlpool" {Get-NlPoolData}        
        "ahashpool" {Get-AhashpoolData}
        "blockmasters" {Get-BlockMastersData}
        "hashrefinery" {Get-HashRefineryData}
        "phiphipool" {Get-PhiphipoolData}
        "fairpool" {Get-FairpoolData}
    }
}