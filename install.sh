set -x

     #eosio/eos:v1.4.3  oesio/eos:v1.5.2
EOS_IMAGE=eosio/eos:v1.5.2
MY_CONTRACTS_DIR=/opt/eos/contracts
ROOT_DIR=/opt/eos/testnet2

#Create docker volume outside container
rm -rf $ROOT_DIR/../volume/
mkdir -p $ROOT_DIR/../volume/keosd   
mkdir -p $ROOT_DIR/../volume/nodeosd1
mkdir -p $ROOT_DIR/../volume/nodeosd2
#########################################################################
#Create docker network bridage 'testnet2'
#########################################################################
docker network create \
  --driver=bridge \
  --subnet=172.30.0.0/16 \
  --ip-range=172.30.0.0/24 \
  --gateway=172.30.0.1 \
  testnet2

#########################################################
#   install mongodb
#########################################################
#docker run \
#   --network testnet2 \
#   --ip 172.30.0.200 \
#   --name mongo \
#   --publish 0.0.0.0:27017:27017 \
#   --detach \
#   mongo:4.0.4
#sleep 2

##########################################################################
#keosd, firstly start keosd server
#########################################################################
docker run \
   --network testnet2 \
   --ip 172.30.0.100 \
   --name keosd \
   --publish 0.0.0.0:8888:8888 \
   --volume $ROOT_DIR/../volume/keosd/data-dir:/opt/eosio/bin/data-dir \
   --volume $MY_CONTRACTS_DIR:$MY_CONTRACTS_DIR \
   --detach \
   $EOS_IMAGE \
   /bin/bash -c \
   "keosd --http-server-address 0.0.0.0:8888 --http-validate-host false" 
sleep 1s  
cleos='docker exec -it keosd /opt/eosio/bin/cleos --url http://172.30.0.101:8888 --wallet-url http://172.30.0.100:8888'   
##Create wallet    
WALLET_PWD_FILE=$ROOT_DIR/../volume/keosd/data-dir/walletpasswd.txt
WALLET_PWD_FILE_IN_CONTAINER=/opt/eosio/bin/data-dir/walletpasswd.txt
$cleos wallet create --file $WALLET_PWD_FILE_IN_CONTAINER

$cleos wallet open 
$cleos wallet list
$cleos wallet unlock --password `cat $WALLET_PWD_FILE`
$cleos wallet list
  
##Loading the eosio Key
#The private blockchain launched in the steps above is created with a default initial key which must be loaded into the wallet.  
$cleos wallet import --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

#######################################################################
#Setup nodeosd1, Non produce
#######################################################################
docker run \
   --cpuset-cpus 0 \
   --network testnet2 \
   --ip 172.30.0.101 \
   --name nodeosd1 \
   --publish 0.0.0.0:18888:8888 \
   --volume $MY_CONTRACTS_DIR:$MY_CONTRACTS_DIR \
   --volume $ROOT_DIR/../volume/nodeosd1:/opt/eosio/bin/data-dir \
   --detach \
   $EOS_IMAGE \
   nodeos \
   --enable-stale-production \
   --http-server-address 0.0.0.0:8888 \
   --p2p-listen-endpoint 0.0.0.0:9876 \
   --p2p-peer-address 172.30.0.102:9876 \
   --p2p-peer-address 172.30.0.103:9876 \
   --data-dir /opt/eosio/bin/data-dir \
   --producer-name eosio \
   --plugin eosio::chain_plugin \
   --plugin eosio::chain_api_plugin \
   --plugin eosio::history_api_plugin \
   --plugin eosio::history_plugin \
   --plugin eosio::net_plugin \
   --plugin eosio::net_api_plugin \
   --access-control-allow-origin=* --contracts-console --http-validate-host=false --filter-on='*'
sleep 2s
#publish a system contract eosio.bios to nodeos1
CONTRACTS_DIR=/contracts
##To start additional nodes, you must first load the eosio.bios contract.
##This contract enables you to have direct control over the resource allocation of other accounts and to access other privileged API calls.
##Return to the second terminal window and run the following command to load the contract:
$cleos set contract eosio $CONTRACTS_DIR/eosio.bios -p eosio@active
   
################################################################################
##We will create two account to become a producer, using the account name [inita,initb].
##To create the account, we need to generate keys to associate with the account, and import those into our wallet.
##Run the create key command:
#$cleos create key --to-console
#Private key: 5JgbL2ZnoEAhTudReWH1RnMuQS6DBeLZt4ucV6t8aymVEuYg7sr
#Public key: EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg
##Now import the private key portion into your wallet. If successful, the matching public key will be reported. This should match the previously generated public key:
##But here we only import a key pairs above
$cleos wallet import --private-key 5JgbL2ZnoEAhTudReWH1RnMuQS6DBeLZt4ucV6t8aymVEuYg7sr
##Create the inita account that we will use to become a producer.
##The create account command requires two public keys, one for the account's owner key and one for its active key.
##In this example, the newly created public key is used twice, as both the owner key and the active key.
##Example output from the create command is shown:
$cleos create account eosio inita EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg
$cleos create account eosio initb EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg

#################################################################################
#Setup  Producer Node 'nodeosd2'
#################################################################################
docker run \
   --cpuset-cpus 1 \
   --network testnet2 \
   --ip 172.30.0.102 \
   --name nodeosd2 \
   --publish 0.0.0.0:28888:8888 \
   --volume $MY_CONTRACTS_DIR:$MY_CONTRACTS_DIR \
   --volume $ROOT_DIR/../volume/nodeosd2:/opt/eosio/bin/data-dir \
   --detach \
   $EOS_IMAGE \
   nodeos \
   --producer-name inita \
   --plugin eosio::chain_plugin \
   --plugin eosio::chain_api_plugin  \
   --plugin eosio::history_api_plugin \
   --plugin eosio::history_plugin \
   --plugin eosio::net_plugin  \
   --plugin eosio::net_api_plugin  \
   --http-server-address 0.0.0.0:8888 \
   --p2p-listen-endpoint 0.0.0.0:9876 \
   --p2p-peer-address 172.30.0.101:9876 \
   --p2p-peer-address 172.30.0.103:9876 \
   --data-dir /opt/eosio/bin/data-dir \
   --private-key [\"EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg\",\"5JgbL2ZnoEAhTudReWH1RnMuQS6DBeLZt4ucV6t8aymVEuYg7sr\"] \
   --access-control-allow-origin=* --contracts-console --http-validate-host=false --filter-on='*'
sleep 3s

################################################################################
#Setup Producer Node 'nodeosd3'
################################################################################
docker run \
   --network testnet2 \
   --ip 172.30.0.103 \
   --name nodeosd3 \
   --publish 0.0.0.0:38888:8888 \
   --volume $MY_CONTRACTS_DIR:$MY_CONTRACTS_DIR \
   --volume $ROOT_DIR/../volume/nodeosd3:/opt/eosio/bin/data-dir \
   --detach \
   $EOS_IMAGE \
   nodeos \
   --producer-name initb \
   --plugin eosio::chain_plugin \
   --plugin eosio::chain_api_plugin  \
   --plugin eosio::history_api_plugin \
   --plugin eosio::history_plugin \
   --plugin eosio::net_plugin  \
   --plugin eosio::net_api_plugin  \
   --http-server-address 0.0.0.0:8888 \
   --p2p-listen-endpoint 0.0.0.0:9876 \
   --p2p-peer-address 172.30.0.102:9876 \
   --p2p-peer-address 172.30.0.101:9876 \
   --data-dir /opt/eosio/bin/data-dir \
   --private-key [\"EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg\",\"5JgbL2ZnoEAhTudReWH1RnMuQS6DBeLZt4ucV6t8aymVEuYg7sr\"] \
   --access-control-allow-origin=* --contracts-console --http-validate-host=false --filter-on='*'
sleep 3s

#####指定生产者:inita,initb
$cleos push action eosio setprods '{ "schedule": [{"producer_name": "inita","block_signing_key": "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg"},{"producer_name": "initb","block_signing_key": "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg"}]}' -p eosio@active

################################################################################
#  Do some thing  for test
################################################################################
#TEST
#create three contract-type account 'alice' 'bob' 'hello'
#cleos create key --to-console
#Private key: 5HuXYXnPRxpkjmS6w9v3TNYzNqXAwHCwY3QESV9NnKQJMB2kDAX
#Public key: EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleos wallet import --private-key 5HuXYXnPRxpkjmS6w9v3TNYzNqXAwHCwY3QESV9NnKQJMB2kDAX
$cleos create account eosio bob    EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm 
$cleos create account eosio alice  EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm

#公司测试用账户
$cleso create account eosio admin          EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg

$cleso create account admin beijing        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin guangdong      EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin shanghai       EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin tianjin        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin chongqing      EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin liaoning       EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin jiangsu        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin hubei          EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin sichuan        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin shaanxi        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin hebei          EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin shanxi         EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin henan          EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin jilin          EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin heilongjiang   EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin neimenggu      EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin shandong       EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin anhui          EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin zhejiang       EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin fujian         EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin hunan          EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin guangxi        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin jiangxi        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin guizhou        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin yunnan         EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin xizang         EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin hainan         EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin gansu          EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin ningxia        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin qinghai        EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
$cleso create account admin xinjiang       EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm
#hello测试合约与账户. 测试用
$cleos create account eosio hello EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm -p eosio@active
$cleos set contract hello ../contracts/hello  -p hello@active
#eosio.token 系统合约与账户. 测试用
$cleos create account eosio eosio.token EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg
$cleos set contract eosio.token /contracts/eosio.token -p eosio.token@active
$cleos push action eosio.token create '[ "eosio", "1000000000.0000 EOS", 0, 0, 0]' -p eosio.token
$cleos push action eosio.token issue '[ "alice", "100000000.0000 EOS", "" ]' -p eosio@active


#Your can do some test using below  
#test contract "hello"
#$cleos set contract hello ../contracts/hello  -p hello@active
#$cleos push action hello hi '["bob"]' -p bob@active
#switch producer from eosio to inita
#cleos --wallet-url http://127.0.0.1:8899 push action eosio setprods '{ "schedule": [{"producer_name": "inita","block_signing_key": "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg"}]}' -p eosio@active
#cleois --wallet-url http://127.0.0.1:8899 push action eosio setprods '{ "schedule": [{"producer_name": "initb","block_signing_key": "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg"}]}' -p eosio@active

#cleos get table eosio.token alice accounts



#[root@eos kqjs]# cl wallet private_keys
#password: [[
#    "EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV",     ----used with account eosio
#    "5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3"
#  ],[
#    "EOS6hMjoWRF2L8x9YpeqtUEcsDKAyxSuM1APicxgRU1E3oyV5sDEg",     ----used with inta intb eosio.token
#    "5JgbL2ZnoEAhTudReWH1RnMuQS6DBeLZt4ucV6t8aymVEuYg7sr"
#  ],[
#    "EOS7HxPMkfyL69PqLXduP9YfuvVad8e3Nry6ryDGaJ2u8BKB2zUUm",       ----used with alice bob hello
#    "5HuXYXnPRxpkjmS6w9v3TNYzNqXAwHCwY3QESV9NnKQJMB2kDAX" 
#  ]
#]

