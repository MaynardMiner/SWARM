function Add-HiveResponse{
     Param(
     [Parameter(Mandatory=$false)]
     [string]$method,
     [Parameter(Mandatory=$false)]
     [string]$messagetype,
     [Parameter(Mandatory=$false)]
     [string]$data,
     [Parameter(Mandatory=$false)]
     [array]$payload,
     [Parameter(Mandatory=$false)]
     [string]$HiveID,
     [Parameter(Mandatory=$false)]
     [string]$HivePassword,
     [Parameter(Mandatory=$false)]
     [string]$CommandID
     )

     if($payload -ne $null)
     {
     $myresponse = @{
         method = $method
         rig_id = $HiveID
         jsonrpc = "2.0"
         id= "0"
         params = @{
          id = $command.result.id
          rig_id = $HiveID
          passwd = $HivePassword
          type = $messagetype
          data = $data
          payload = $payload
          }
         }
       }
     
     else{
       $myresponse = @{
         method = $method
         rig_id = $HiveID
         jsonrpc = "2.0"
         id= "0"
         params = @{
          id = $command.result.id
          rig_id = $HiveID
          passwd = $HivePassword
          type = $messagetype
          data = $data
          }
         }
       }
     
        $myresponse    

}

