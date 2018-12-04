#cleos create key --to-console
#Private key: 5KHxR9khycedPcXdcHf6iEFwUNhNmJ7qUHfXmZ2Aoe8veEMYnES
#Public key: EOS6QnZ3MzUsf5ww5MW6nRdkXuDNhpHzDRVYdMScpBbgQGv2BwqcZ

#cleos wallet import --private-key 5KHxR9khycedPcXdcHf6iEFwUNhNmJ7qUHfXmZ2Aoe8veEMYnES

for ((i=0;i<$1;i++))
do
echo --------------------------
account_name=`head  /dev/urandom  |  tr -dc a-z  | head -c 5`
echo "$account_name">> accounts.txt
echo "Createing account:" $account_name
cleos create account eosio $account_name  EOS6QnZ3MzUsf5ww5MW6nRdkXuDNhpHzDRVYdMScpBbgQGv2BwqcZ
echo "created"
done


#cleos get accounts EOS6QnZ3MzUsf5ww5MW6nRdkXuDNhpHzDRVYdMScpBbgQGv2BwqcZ
