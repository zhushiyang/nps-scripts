#!/bin/bash

#远程httpd项目目录
vhost_dir=/var/www/webapps

#远程服务器IP
ip=$1

#git地址
filepath=$2

#组名用来以组名来当做项目的根目录
groupname=$3

#本地和远程目录，用来存放压缩好的zip包
gitpkg=/gitpkg


if [ ! -d $gitpkg ];then
	mkdir -p $gitpkg
fi

#创建远程目录
ssh root@$ip "mkdir -p $gitpkg>/dev/null 2>&1"


pkg_name=$(basename $filepath|awk -F '.' '{print $1}')
ser_name=$(basename $filepath|awk -F '_' '{print $1}')


ssh root@$ip "rm -rf $vhost_dir/$groupname/*"
if [ `ssh root@$ip echo $?` -eq 0 ];then
	echo "删除远程项目成功"
else
	echo "删除远程项目失败"
	exit 1
fi

cd $gitpkg
if [ -d $pkg_name ];then
	rm -rf  $pkg_name
fi

cp $filepath .

scp ${pkg_name}.zip root@$ip:$gitpkg

if [ `echo $?` -eq 0 ];then
        echo "上传工程成功"
else
        echo "上传工程失败"
	exit 2
fi

#判断上次错误是否有残留文件
ssh root@$ip "if [ -e /tmp/$pkg_name ] ; then rm -rf /tmp/$pkg_name ; fi ;"

ssh root@$ip "unzip $gitpkg/${pkg_name}.zip -d /tmp >/dev/null 2>&1"

if [ `ssh root@$ip echo $?` -eq 0 ];then
        echo "解压工程成功"
else
        echo "解压工程失败"
        exit 3
fi
#判断是否存在原始文件
ssh root@$ip "if [ -e $vhost_dir/$groupname/$ser_name ] ; then rm -rf $vhost_dir/$groupname/$ser_name ; fi ;"

ssh root@$ip "mkdir -p $vhost_dir/$groupname/$ser_name"

ssh root@$ip "mv /tmp/$pkg_name/* $vhost_dir/$groupname/$ser_name"

#将工程的webapp目录下的所有文件移动到上级目录
ssh root@$ip "mv $vhost_dir/$groupname/$ser_name/webapp/* $vhost_dir/$groupname/$ser_name"
ssh root@$ip "rm -rf $vhost_dir/$groupname/$ser_name/webapp"

if [ `ssh root@$ip echo $?` -eq 0 ];then
         echo "移动${pkg_name}成功"
else
         echo "移动${pkg_name}失败"
         exit 5
fi

ssh root@$ip "rm -rf  /tmp/$pkg_name"
if [ `ssh root@$ip echo $?` -eq 0 ];then
         echo "清理文件成功"
else
         echo "清理文件失败"
         exit 6
fi

ssh root@$ip "service httpd restart"
if [ `ssh root@$ip echo $?` -eq 0 ];then
        echo "重启httpd服务成功"
        echo "S-u-c-c-e-s-s"
else
        echo "重启httpd服务失败"
        echo "F-a-i-l-e-d" 
        exit 4
fi
