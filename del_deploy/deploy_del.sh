#!/bin/bash


localfile=/server/scripts/del_deploy/delete.sh
db_file=/server/scripts/del_deploy/del_mysql.sh
redir=/softpkg/del

web_type=$1
ip=$2
groupname=$3
port=$4
dbip=172.24.2.170

ssh root@$ip "mkdir -p $redir"
ssh root@$dbip "mkdir -p $redir"

scp $localfile root@$ip:$redir
scp $db_file root@$dbip:$redir

ssh root@$ip "$redir/delete.sh $web_type $groupname $port"
ssh root@$dbip  "sh $redir/del_mysql.sh $groupname"
