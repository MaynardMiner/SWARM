# Wallet.json file

## Note [string]
  Note is not used. This is simply a notation on how to use file.

## Active Exchange Wallets [Hashtable]

### Note [string]
* Is not used. This is simply a notation on how to use file.

### AltWallets [Hashtable]
* Altwallet1 [hashtable]
  * You can only specify one coin.
  * When switching to the pool in the pools section
    it will use this wallet instead of BTC as default.
  * It will change c=BTC to c=Coin_Symbol
  * Used for Group 1 of devices (NVIDIA1,AMD1,CPU)
  * **Add Coin Symbole Here [string]**
    * The symbol of the coin.
    * **Address [string]**
      * Address for ``-Altwallet1`` parameter.
    * **Pools [string[]]**
      * An array of pools you will use for this altwallet
* Altwallet2 [hashtable]
  * You can only specify one coin.
  * When switching to the pool in the pools section
    it will use this wallet instead of BTC as default.
  * It will change c=BTC to c=Coin_Symbol
  * Used for Group 2 of devices (NVIDIA2)
  * **Add Coin Symbole Here [string]**
    * The symbol of the coin.
    * **Address [string]**
      * Address for ``-Altwallet2`` parameter.
    * **Pools [string[]]**
      * An array of pools you will use for this altwallet
* Altwallet3 [hashtable]
  * You can only specify one coin.
  * When switching to the pool in the pools section
    it will use this wallet instead of BTC as default.
  * It will change c=BTC to c=Coin_Symbol
  * Used for Group 3 of devices (NVIDIA3)
  * **Add Coin Symbole Here [string]**
    * The symbol of the coin.
    * **Address [string]**
      * Address for ``-Altwallet2`` parameter.
    * **Pools [string[]]**
      * An array of pools you will use for this altwallet
