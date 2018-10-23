

function set-nicehash {

$Commands = @(
 @{
   time = 0
   commands = @(
   @{id= 1
     method= "subscribe"
     params= [array]"nhmp.usa.nicehash.com:3200","34HKWdzLxWBduUfJE9JxaFhoXnfC6gmePG.testrig"
    }
   )
  }
 @{
   time = 2
   commands = @(  
   @{id = 1
     method = "algorithm.add"
     params = [array]"equihash"
    }
   )
  }
  @{
    time = 3
    commands = @(
    @{id = 1
     method = "worker.add"
     params = [array]"equihash","0"
     }
    )
   }
  @{
    time = 10
    commands = @(
    @{id = 1
      method = "worker.print.speed"
      params = [array]"0"
     }    
    @{
      id = 1
      method = "worker.print.speed"
      params = @()
     }
    )
  }
)

$Commands | ConvertTo-Json -Depth 4

}
