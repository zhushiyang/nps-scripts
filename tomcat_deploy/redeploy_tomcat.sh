#!/bin/bash


ip=$1
Port=$2
tomcat_name=tomcat${Port}
warpkg=$3

War_name=`basename $warpkg|awk -F "." '{print $1}'`
root_dir=/webapps/tomcat/$tomcat_name/webapps


ssh root@$ip "service $tomcat_name stop"
ssh root@$ip "rm -rf $root_dir/${War_name}*"
if [ ! -f $warpkg ];then
echo "${War_name}.war is not exist"
exit 1
fi
scp $warpkg root@$ip:$root_dir
ssh root@$ip "service $tomcat_name start"

if [ `ssh root@$ip "echo $?"` -eq 0 ]
   then
      echo "S-u-c-c-e-s-s"
   else
      echo "F-a-i-l-e-d"
fi
