#!/bin/bash

. /etc/init.d/functions

Pkg_dir=/server/softpkg
Pkg_name=postgresql9.1.tar.gz
Re_dir=/softpkg/pkg
ip=$1

#创建远程目录          
ssh root@$ip "mkdir -p $Re_dir >/dev/null 2>&1"

#上传postgresql软件包到目标服务器
scp $Pkg_dir/$Pkg_name root@$ip:$Re_dir
if [ `ssh root@$ip echo $?` -eq 0 ];then
        action "上传${Pkg_name}软件包" /bin/true
else
        action "上传${Pkg_name}软件包" /bin/false
        exit 1
fi

#解压postgresql软件包
ssh root@$ip "tar xf $Re_dir/$Pkg_name -C $Re_dir"
if [ `ssh root@$ip echo $?` -eq 0 ];then
        action "解压${Pkg_name}软件包" /bin/true
else
        action "解压${Pkg_name}软件包" /bin/false
        exit 2
fi

#安装postgresql
ssh root@$ip "cd $Re_dir/postgresql9.1;rpm -ivh * --nodeps --force"
if [ `ssh root@$ip echo $?` -eq 0 ];then
        action "安装${Pkg_name}" /bin/true
else
        action "安装${Pkg_name}" /bin/false
        exit 3
fi

