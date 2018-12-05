#$1 批量处理次数

#set -x


#export cleos='docker exec -it keosd /opt/eosio/bin/cleos --url http://172.30.0.101:8888 --wallet-url http://172.30.0.100:8888 '
export cleos='cleos --url http://127.0.0.1:8888 --wallet-url http://172.30.0.100:8888 '
START_SECOND=`date +%s`
echo “start pressing”
start_balance=`$cleos get currency balance  eosio.token alice eos | awk -F. '{print $1}'`

for((i=1;i<=$1;i++))
do
xargs -n 1 -I '#' -P 200  $cleos push action eosio.token transfer '[ "alice", "#", "1.0000 EOS", "" ]' -p alice@active <accounts.txt  >press.log 2>&1
done

sleep 1s
end_balance=`$cleos get currency balance  eosio.token alice eos | awk -F. '{print $1}'`
transfer_count=`expr $end_balance - $start_balance`
echo 'transfer count:' $transfer_count

END_SECOND=`date +%s`
duration=`expr $END_SECOND - $START_SECOND`
echo "运行时长:"  $duration

account_total=`wc -l < accounts.txt`
trx_total=`expr $account_total \* $1`
echo "trx tps:" `expr  $trx_total / $duration`

echo "successful trx tps:" `expr $transfer_count / $duration` 
