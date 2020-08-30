# Pay Per Last N Shares (PPLNS) Pools

## Explanation of PPLNS Pools
Pay Per Last N Share or commonly known as PPLNS is another popular payment method, which offers payment to miners as a % of shares they contribute to the total shares (N).
Usually the amount of shares submitted during a round (the time it takes to find 1 block) is variable due to luck. However under PPLNS it considers a fixed amount of shares (N), that is not constrained by the round boundaries. In this case N shares represents a fixed amount of shares that is not based on luck. Often N is set as twice the difficulty. For this payment structure, as you mine you earn shares meaning the more hashes you do the more shares you earn.
You only get paid out once a block is actually found (not if it is only statistically probable). Using the lottery example, if you commit 1 ticket (share) to a total of 10 (N) tickets in your pool than your payout will be 10% if your pool is able to win the lottery (find a block).
Using this system actually favors constant loyal pool members over pool hoppers because miners aren’t incentivized to “quick mine” by mining on round with low amounts of shares.

source: [medium](https://medium.com/luxor/mining-pool-payment-methods-pps-vs-pplns-ac699f44149f#:~:text=Pay%20Per%20Last%20N%20Shares,is%20variable%20due%20to%20luck)