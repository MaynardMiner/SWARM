class pool {
    [string]$Symbol
    [string]$Algorithm
    [double]$Price
    [string]$Protocol
    [string]$Pool_Host
    [string]$Port
    [string]$User1
    [string]$User2
    [string]$User3
    [string]$Pass1
    [string]$Pass2
    [string]$Pass3
    [double]$Previous

    pool(){}

    pool([string]$Symbol, [string]$Algorithm, [double]$Price, [string]$Protocol,
         [string]$Pool_Host, [string]$Pool_Port, [string]$User1, [string]$User2,
         [string]$User3, [string]$Pass1, [string]$Pass2, [string]$Pass3,
         [double]$Previous) {
            [string]$this.Symbol = $Symbol
            [string]$this.Algorithm = $Algorithm
            [double]$this.Price = $Price
            [string]$this.Protocol = $Protocol
            [string]$this.Pool_Host = $Pool_Host
            [string]$this.Port = $Pool_Port
            [string]$this.User1 = $User1
            [string]$this.User2 = $User2
            [string]$this.User3 = $User3
            [string]$this.Pass1 = $Pass1
            [string]$this.Pass2 = $Pass2
            [string]$this.Pass3 = $Pass3
            [double]$this.Previous = $Previous        
         }
}