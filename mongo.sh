docker run \
   --network testnet2 \
   --ip 172.30.0.200 \
   --name mongo \
   --publish 0.0.0.0:27017:27017 \
   --detach \
   mongo:4.0.4 



#docker run -it  --net testnet2 --rm mongo:4.0.4 mongo --host 172.30.0.200 test
