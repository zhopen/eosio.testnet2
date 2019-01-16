#$1 批量处理次数

#set -x


#export cleos='docker exec -it eosio /opt/eosio/bin/cleos --url http://10.252.166.12:8888 --wallet-url http://10.252.166.12:18888 '
#export cleos='cleos --url http://localhost:8888 --wallet-url http://172.30.0.100:8888 '
#cleos="docker exec -it eosio cleos --url http://localhost:8888 --wallet-url http://10.252.166.12:18888 "
cleos="cleos --wallet-url http://10.252.166.12:18888 --url http://localhost:8888"
START_MS=`date +%s%N`
echo “start pressing”
START_BALANCE=`$cleos get currency balance  eosio.token alice eos | awk -F. '{print $1}'`


ACCOUNTS_FILE=./accounts.txt
LOG_FILE=./press.log
rm ./$LOG_FILE

for((i=0;i<$1;i++));
do
echo "-----------------"
#xargs -a $ACCOUNTS_FILE -n 1 -I '#' -P 1000   $cleos push action eosio.token transfer '[ "#", "#to", "1.0000 EOS", "" ]' -p "#"@active  >$LOG_FILE 2>&1
xargs -a $ACCOUNTS_FILE -n 1 -I '#' -P 1000   $cleos push action eosio.token transfer '[ "alice", "#", "1.0000 EOS", "" ]' -p alice@active  >$LOG_FILE 2>&1
done

END_BALANCE=`$cleos get currency balance  eosio.token alice eos | awk -F. '{print $1}'`
TRANSFER_TOTAL=`expr $START_BALANCE - $END_BALANCE`
echo '成功转账的代币数:' $TRANSFER_TOTAL

END_MS=`date +%s%N`
DURATION=`expr \( $END_MS - $START_MS \) / 1000000`
echo "运行时长ms:"  $DURATION

ACCOUNT_TOTAL=`wc -l < accounts.txt`
TRANSACTION_TOTAL=`expr $ACCOUNT_TOTAL \* $1`
echo "总共发起交易数:" $TRANSACTION_TOTAL 
echo "每秒交易数tps:" `expr  $TRANSACTION_TOTAL \* 1000 / $DURATION`
echo "每秒成功交易数tps:" `expr $TRANSFER_TOTAL \* 1000 / $DURATION` 

