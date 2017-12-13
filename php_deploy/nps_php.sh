#!/bin/bash
#check and install php
#2017年7月13日16:19:36
#max
. /etc/init.d/functions

#=========================php基础环境变量配置=================================#
pkgdir=/server/softpkg              #本地存放软件包目录
resoftpkg=/webapps/softpkg          #远程存放jdk压缩包和脚本的目录
scripts=/server/scripts/php_deploy  #本地所有脚本存放路径
phpdir=php.tar.gz                   #php压缩包名
phpinstall=nps_phpinstall.sh        #php安装脚本
ip=$1                               #目标服务器的IP地址

#===========================php检测及安装=====================================#

#判断是否存在php环境
flags_php=$(ssh root@$1 'php -v >/dev/null 2>&1 ;echo $? ')

if [ $flags_php -eq 0 ]
then
  action "目标服务器存在php环境" /bin/true
else
  action "目标服务器存在php环境" /bin/false
  #在目标服务器创建php软件包存放目录
  ssh root@$1 mkdir -p $resoftpkg
  flags=$(ssh root@$ip 'echo $?')
  if [ $flags -eq 0 ]
  then
    action "目标服务器创建目录成功" /bin/true
  else
    action "目标服务器创建目录成功" /bin/false
    exit 1
  fi
  
  #拷贝本地php到目的服务器
  scp $pkgdir/$phpdir root@$ip:$resoftpkg 
  flags=$(ssh root@$ip 'echo $?')
  if [ $flags -eq 0 ]
  then
    action "拷贝php压缩包成功" /bin/true
  else
    action "拷贝php压缩包成功" /bin/false
    exit 1
  fi
  scp $scripts/$phpinstall root@$ip:$resoftpkg

  #对目标服务器的php包进行解压缩
  ssh root@$ip "tar -zxf $resoftpkg/$phpdir -C $resoftpkg"
  flags=$(ssh root@$ip 'echo $?')
  if [ $flags -eq 0 ]
  then
    action "对目标服务器php压缩包解压缩成功" /bin/true
  else
    action "对目标服务器php压缩包解压缩成功" /bin/false
    exit 1
  fi

  #讲脚本移动到和压缩包同一个目录
  ssh root@$ip "mv $resoftpkg/$phpinstall $resoftpkg/php"
  
  #对目标服务器php压缩包包含rpm包进行安装
  ssh root@$ip "cd $resoftpkg/php && sh $phpinstall"
  flags=$(ssh root@$ip 'echo $?')
  if [ $flags -eq 0 ]
  then
    action "对目标服务器php安装成功" /bin/true
    ssh root@$1 '. /etc/profile && php -v'
    flags_php=$(ssh root@$ip 'echo $?')
    if [ $flags_php -eq 0 ]
    then
      action "php环境安装完成" /bin/true
    else
      action "php环境安装完成" /bin/false
    fi
  else
    action "对目标服务器php安装成功" /bin/false
    exit 1 
  fi 
fi
