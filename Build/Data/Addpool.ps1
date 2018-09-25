echo '{"command":"addpool", "parameter":"stratum+tcp://equihash.mine.zergpool.com:2142,3PVTDiFSQo9rur1JA5XHdU7oPwo4PEgVYN.ASIC_Z9_Mini_03,x"}' | nc localhost 4028

echo '{"command":"switchpool", "parameter":"1"}' | nc localhost 4028

echo '{"command":"removepool", "parameter":"0"}' | nc localhost 4028

echo '{"command":"pools", "parameter":"0"}' | nc localhost 4028
