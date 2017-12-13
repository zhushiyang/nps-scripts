#!/bin/bash

. /etc/init.d/functions

sshkey=/server/scripts/sshkey_deploy/nps_deploy_sshkey.sh
php_dir=/server/scripts/php_deploy/nps_php.sh
mysql_dir=/server/scripts/mysql_deploy/nps_mysql.sh
renginx_dir=/softpkg/nginx
nginx_dir=/server/project
code_dir=/server/procode
ip=$1
sql=$2
groupname=${3}
LisPort=$4
Nginx_pkg=$5
nginx_conf=$nginx_dir/nginx_${groupname}/conf/nginx.conf


deploy_sshkey() {

   sh $sshkey $ip

}

php_install() {

   sh $php_dir $ip

}


mysql_install() {

   sh $mysql_dir $sql $groupname

}


nginx_install() {

   if [ `ssh root@$ip id www >/dev/null 2>&1;echo $?` -eq 1 ];then
      ssh root@$ip "useradd www -s /sbin/nologin -M"
   fi  
   ssh root@$ip "mkdir -p $renginx_dir"
   root_dir=$( basename $Nginx_pkg|awk -F '.' '{print $1}') 

   cp -a $nginx_dir/nginx $nginx_dir/nginx_${groupname}
   tar zxf $code_dir/$Nginx_pkg -C $code_dir

      if [ `echo $?` -eq 0 ];then            
         action "释放${Nginx_pkg}源码包" /bin/true
      else
         action "释放${Nginx_pkg}源码包" /bin/false
         exit 1
      fi

   cp -a $code_dir/$root_dir/* $nginx_dir/nginx_${groupname}/html
   rm -rf $code_dir/$root_dir    

   sed -i "s#neuvideo#$groupname#g" $nginx_dir/nginx_${groupname}/html/system/dbConn.php
   sed -i "s#LISTENPORT#$LisPort#g"  $nginx_conf
   sed -i "s#FATHERDIR#$renginx_dir/nginx_${groupname}#g"  $nginx_conf
   sed -i "s#IPADDR#$ip#g"  $nginx_conf 
 
      if [ `echo $?` -eq 0 ];then
         action "生成nginx_${groupname}配置文件" /bin/true
      else
         action "生成nginx_${groupname}配置文件" /bin/false
         exit 2
      fi  

   cd $nginx_dir
   tar zcf nginx_${groupname}.tar.gz  nginx_${groupname}
 
      if [ `echo $?` -eq 0 ];then
         action "创建nginx_${groupname}压缩包" /bin/true
      else
         action "创建nginx_${groupname}压缩包" /bin/false
         exit 3
      fi

   scp $nginx_dir/nginx_${groupname}.tar.gz root@$ip:$renginx_dir

      if [ `ssh root@$ip "echo $?"` -eq 0 ];then
         action "上传nginx_${groupname}压缩包到主机$ip" /bin/true
      else
         action "创建nginx_${groupname}压缩包到主机$ip" /bin/false
         exit 4
      fi
   rm -rf $nginx_dir/nginx_${groupname}*
   ssh root@$ip tar zxf $renginx_dir/nginx_${groupname}.tar.gz -C $renginx_dir
   ssh root@$ip "$renginx_dir/nginx_${groupname}/sbin/nginx -p $renginx_dir/nginx_${groupname} -t  >/dev/null 2>&1"
   
      if [ `ssh root@$ip "echo $?"` -eq 0 ];then
         action "检查nginx_${groupname}配置文件语法" /bin/true
      else
         action "检查nginx_${groupname}配置文件语法" /bin/false
         exit 5
      fi

   ssh root@$ip $renginx_dir/nginx_${groupname}/sbin/nginx -p $renginx_dir/nginx_${groupname}
      if [ `ssh root@$ip "echo $?"` -eq 0 ];then
         action "启动nginx_${groupname}" /bin/true
      else
         action "启动nginx_${groupname}" /bin/false
         exit 6
      fi
   ssh root@$ip "service php-fpm restart >/dev/null 2>&1"

      if [ `ssh root@$ip "echo $?"` -eq 0 ];then
         action "启动php-fpm" /bin/true
      else
         action "启动php-fpm" /bin/false
         exit 7
      fi
   ssh root@$ip "rm -rf $renginx_dir/nginx_${groupname}.tar.gz"
   rm -rf $nginx_dir/nginx_$groupname
}

#====================函数调用集===================#

deploy_sshkey
php_install
mysql_install
nginx_install
