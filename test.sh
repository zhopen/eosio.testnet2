 
#Your can do some test using below  
test contract "hello"
cleos set contract hello ../contracts/hello  -p hello@active
cleos push action hello hi '["bob"]' -p bob@active

#switch producer from eosio to inita
cleos push action eosio setprods '{ "schedule": [{"producer_name": "inita","block_signing_key": "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg"}]}' -p eosio@active
cleos push action eosio setprods '{ "schedule": [{"producer_name": "initb","block_signing_key": "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg"}]}' -p eosio@active


#转账transfer
cleos push action eosio.token transfer '[ "alice", 'bob', "1.0000 EOS", "" ]' -p alice@active


#switch producer from eosio to inita
#cleos  push action eosio setprods '{ "schedule": [{"producer_name": "inita","block_signing_key": "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg"}]}' -p eosio@active
#cleos  push action eosio setprods '{ "schedule": [{"producer_name": "initb","block_signing_key": "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg"}]}' -p eosio@active
