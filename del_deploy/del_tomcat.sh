#!/bin/bash

. /etc/init.d/functions

reip=$1
tomcat_name=tomcat$2

######删除nginx项目开始######

#关闭tomcat
ssh root@$reip "service $tomcat_name stop"

if [ `ssh root@$reip echo $?` -eq 0 ];then
    action "关闭$tomcat_name" /bin/true
else
    action "关闭$tomcat_name" /bin/false
    echo "Failed"
    exit 1
fi

#删除tomcat
ssh root@$reip "rm -rf /webapps/tomcat/$tomcat_name"
ssh root@$reip "rm -f /etc/init.d/$tomcat_name"
if [ `ssh root@$reip echo $?` -eq 0 ];then
    action "删除 $tomcat_name" /bin/true
else
    action "删除 $tomcat_name" /bin/false
    exit 2
fi



