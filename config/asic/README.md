# USING ASIC Configuration file

```
    "ASICS": {
        "ASIC1": {
            "IP": "IP ADDRESS",
            "NickName": "NickName1"
        },
        "ASIC2": {
            "IP": "IP ADDRESS",
            "NickName": "NickName2"
        },
        "ASIC3": {
            "IP": "IP ADDRESS",
            "NickName": "NickName2"
        }
    }
```


## ASICS [HASHTABLE]

 ASICS are the list of ASIC miners you wish SWARM to control. There is no limit to the number of ASICS SWARM can control,
 even though only 3 ASICS are shown. You can continue to add to this list.


### ASIC[Number]    [HASHTABLE, SUBGROUP OF ASICS]
* Should be in sequential order.
* Must be ASIC followed by the number- ASIC1, ASIC2, ASIC3 etc.

### IP        [STRING]
* IP address of the ASIC in question. If you wish to use local host,
  simple use  "127.0.0.1"

### NickName    [STRING]
* The name you wish to signify for the ASIC WORKER.
* You CANNOT use the same nickname