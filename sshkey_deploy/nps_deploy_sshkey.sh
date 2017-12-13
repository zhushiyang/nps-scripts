#!/bin/bash

. /etc/init.d/functions

ip=$1
ipinfo=/server/.ipinfo/ip.txt
scripts=/server/scripts/sshkey_deploy 

#创建隐藏目录

if [ ! -e /server/.ipinfo  ];then
   mkdir -p /server/.ipinfo
fi

#生成密钥对

if [ ! -e /root/.ssh/id_rsa.pub ];then

    ssh-keygen -t rsa -f /root/.ssh/id_rsa -P "" >/dev/null 2>&1

fi
 
touch $ipinfo

if [ `grep $ip $ipinfo>/dev/null 2>&1;echo $?` -eq 1 ];then
  
      expect $scripts/nps_deploy_sshkey.exp $ip >/dev/null 2>&1

        if [ `echo $?` -eq 0 ];then

             echo "$ip">>$ipinfo

             action "主机：$ip 分发密钥" /bin/true
        fi
    
             sleep 1
else

             sleep 1

             echo "web主机：$ip 已经分发过密钥啦"
        

fi

