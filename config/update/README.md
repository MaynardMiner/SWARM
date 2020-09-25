# Update Configs

## What Are Update Configs For?
They are used to set the current versions, links, and exectubles for each miner in SWARM.
They can be edited while SWARM is running, SWARM checks these files each loop.

## Example Of A Miner Config:
```
  "claymore-amd": {
    "name": "claymore-amd",
    "type": "amd",
    "AMD1": ".\\bin\\claymore-amd-1\\ethdcrminer64",
    "AMD2": ".\\bin\\claymore-amd-2\\ethdcrminer64",
    "AMD3": ".\\bin\\claymore-amd-3\\ethdcrminer64",
    "minername": "ethdcrminer64",
    "version": "15.0",
    "optional": "No",
    "uri": "https://github.com/MaynardMiner/MM.Compiled-Miners/releases/download/v5.0/Claymore-Linux-AMD.tar.gz"
  },
```

### Name [string]
The name of the file the configs are stored in. Used for internal reference.

### Miner [hashtable]
The data container for the miner information. Is named after the miner itself.

### Miner : Name [string]
The name of the miner.

### Miner : Type [string]
The platform type (AMD,NVIDIA,CPU)

### Miner: AMD1,NVIDIA1,NVIDIA2,NVIDIA3,CPU [string]
These are the reference paths for each miner, as SWARM will create one
miner for each device group. Miner are stored in the bin folder, and the
directory is usually named after the miner itself.

### Miner: MinerName [string]
The name of the executable file. This is what SWARM uses to launch the miner,
and is also what SWARM uses to detect within a .zip folder where the main directory
of the miner is at (in cases like a folder within a folder).

### Miner : Version [string]
This is the version of the miner. If this changes- SWARM will attempt to download
the miner from the uri.

### Miner : Optional [string]
This denotes whether or not the miner is a default miner or an optional miner.
See ``-Optional`` argument.

### Miner : uri [string]
This is the download link. Note the following:
* Miner must be contained in a folder when unzipped.
* Recommended to use tar.gz for linux, .zip for windows.
