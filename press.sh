#$1 批量处理次数

#set -x


#export cleos='docker exec -it keosd /opt/eosio/bin/cleos --url http://172.30.0.101:8888 --wallet-url http://172.30.0.100:8888 '
export cleos='cleos --url http://172.30.101:8888 --wallet-url http://172.30.0.100:8888 '
START_SECOND=`date +%s`
echo “start pressing”
START_BALANCE=`$cleos get currency balance  eosio.token alice eos | awk -F. '{print $1}'`


ACCOUNTS_FILE=./accounts.txt
LOG_FILE=./press.log

for((i=0;i<$1;i++));
do
xargs -a $ACCOUNTS_FILE -n 1 -I '#' -P 1000   $cleos push action eosio.token transfer '[ "alice", "#", "1.0000 EOS", "" ]' -p alice@active  >$LOG_FILE 2>&1;
done

END_BALANCE=`$cleos get currency balance  eosio.token alice eos | awk -F. '{print $1}'`
TRANSFER_TOTAL=`expr $END_BALANCE - $START_BALANCE`
echo 'transfer count:' $TRANSFER_TOTAL

END_SECOND=`date +%s`
DURATION=`expr $END_SECOND - $START_SECOND`
echo "运行时长:"  $DURATION

ACCOUNT_TOTAL=`wc -l < accounts.txt`
TRANSACTION_TOTAL=`expr $ACCOUNT_TOTAL \* $1`
echo "trx requested:" `expr  $TRANSACTION_TOTAL / $DURATION`

echo "successful trx tps:" `expr $TRANSFER_TOTAL / $DURATION` 
