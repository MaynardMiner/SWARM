# Coin Pools

## PAYOUT SYSTEM
All coin pool are yiimp pools, which are PROP based.

## Why Coin Pools?
Coin pools gather information by the coin, not the algorithm port. This means that their pricing is more
specific, but more time/resource consuming.

## Known Issues With Using Coin Pools
* Coins can be activated/deactivated. SWARM only gathers statistics every 5 minutes.
* Volume and Hashrate are not factored. However, historical information will be much
  more precise and and accurate.
* Hard drive usage. There are hundreds of coins. SWARM will save all of them. This
  will result in heavy hard drive usage while doing so, due to the open-item format
  of statistics, rather than database. Open item however is preferred, as each can
  be opened, reviewed and edited within the stats folder.