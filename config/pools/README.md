# Pools Configuration

## bans.json
* Global Algorithms Bans For All pools/miners/devices are added here.

## pool-algos.json

Example:

```
  "cryptonight-lite": {
    "alt_names": [
      "cryptonight-lite",
      "aeon"
    ],
    "exclusions": [
      "add pool or miner here",
      "comma seperated"
    ]
  },
```

### [Hashtable] "algorithm name"
* This is a hashtable of the algorithm, and its options.
    The name of the hashtable is the official name of
    the algorithm in SWARM.

### [String[Array]] "alt_names"
* This is a list of names that pools may call the algorithm
  If the pool uses a different name than SWARM- add their
  name here.

### [String[Array]] "exclusions"
* This is the current specific exclusions for the algorithm
  ``-Bans`` parameter automatically add items here.
    * Device: NVIDIA1,AMD1, etc.
    * Pool: zergpool,nlpool, etc.
    * Miner: t-rex-1,cc-mtp-2, etc.
