#!/bin/bash

. /etc/init.d/functions

reroot=/softpkg/nginx/
web_type=$1
groupname=$2
port=$3

nginx_ctl_sh="nginx_$groupname/sbin/nginx/-p $reroot/nginx_$groupname -s stop"
apache_webapp=/var/www/webapps/
apache_conf=/etc/httpd/conf/httpd.conf

######删除nginx项目开始######
del_nginx() {
#关闭nginx
$reboot/$nginx_ctl_sh
if [ `echo $?` -eq 0 ];then
    action "关闭nginx_$groupname" /bin/true
else
    action "关闭nginx_$groupname" /bin/false
    exit 1
fi

#删除nginx
rm -rf $reroot/nginx_$groupname
if [ `echo $?` -eq 0 ];then
    action "删除 nginx_$groupname" /bin/true
else
    action "删除 nginx_$groupname" /bin/false
    exit 2
fi
}

######删除apache项目开始######

del_apache() {
sed -i -e "/Listen $port/d"  -e "/\b$port\b/,+10d" $apache_conf

if [ `echo $?` -eq 0 ];then
    action "删除 $groupname" /bin/true
else
    action "删除 $groupname" /bin/false
    exit 3
fi

service httpd reload
}

######删除tomcat项目开始######

del_tomcat(){
######删除nginx项目开始######

#关闭tomcat
service $groupname stop

if [ `echo $?` -eq 0 ];then
    action "关闭$groupname" /bin/true
else
    action "关闭$groupname" /bin/false
    exit 1
fi

#删除tomcat
rm -rf /webapps/tomcat/$groupname
if [ `echo $?` -eq 0 ];then
    action "删除 $groupname" /bin/true
else
    action "删除 $groupname" /bin/false
    exit 2
fi

}


case $web_type in
	nginx)
              del_nginx;;
	apache)
	      del_apache;;
	tomcat)
              del_tomcat;;
        *)
              echo "输入的类型错误，仅支持apache、tomcat、apache三种类型";;
esac
