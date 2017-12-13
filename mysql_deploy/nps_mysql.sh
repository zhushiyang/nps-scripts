#!/bin/bash

. /etc/init.d/functions

sshkey=/server/scripts/sshkey_deploy/nps_deploy_sshkey.sh
dbip="172.24.2.170"
code_dir="/server/procode"
rpm_dir=/server/rpmpkg
expect_rpm="expect-5.44.1.15-5.el6_4.x86_64.rpm"
mysql_rpm=mysql.tar.gz
pkg=/softpkg/pkg
scripts=/server/scripts

admin_user="root"
admin_passwd="toor"
adminroot_passwd="toor"
sql_name=$1
group_name="$2"
#rdm_id="$3"
group_dbname="${group_name}_db"
group_dbuser="user_${group_name}"
group_dbpasswd=\'123456\'

deploy_sshkey() {

   sh $sshkey $dbip 

}


mysql_install() {
   
   #去掉sql文件名中的sql,创建sql目录和pkg目录
   sqldir=`basename $sql_name | awk -F '.' '{print $1}'`
   ssh root@$dbip "mkdir -p /softpkg/sql/$sqldir"

   ssh root@$dbip "mkdir -p  $pkg"
 
   scp $sql_name root@$dbip:/softpkg/sql/$sqldir>/dev/null 2>&1  

   #检测Mysql服务是否安装
   if [ `ssh root@$dbip rpm -qa mysql|grep mysql >/dev/null;echo $?` -eq 0 ];then
     
     echo  "Mysql服务已经安装......."
     
     sleep 1 
  
   else
  #安装expect软件包   
     echo "数据库主机：$dbip 没有安装Mysql服务,将立即安装"

  #   scp $rpmdir/$expect_rpm root@$dbip:$pkg &&\
      scp $rpm_dir/$expect_rpm root@$dbip:$pkg &&\

     ssh root@$dbip yum install -y $pkg/$expect_rpm >/dev/null 2>&1
     if [ `ssh root@$dbip echo $?`  -eq 0 ];then
    
          action "安装expect软件包" /bin/true

     else
          
          action "已存在expect软件包" /bin/true
          
     fi

   #安装mysql数据库
     scp $rpm_dir/$mysql_rpm root@$dbip:$pkg &&\
     ssh root@$dbip "tar xf $pkg/$mysql_rpm -C $pkg;rpm -ivh $pkg/mysql/* --nodeps --force"
     if [ `ssh root@$dbip echo $?`  -eq 0 ];then

          action "安装mysql数据库" /bin/true

     else

          action "安装mysql数据库" /bin/false

          exit 2

     fi
     
   fi

  #检测Mysql服务是否启动
   if [ `ssh root@$dbip ps -ef|grep mysqld|grep -v grep >/dev/null;echo $?` -eq 1 ];then
 
     echo "正在启动Mysql服务..."

     sleep 1

     ssh root@$dbip service mysqld start >/dev/null 2>&1
     if [ `ssh root@$dbip echo $?`  -eq 0 ];then

        action "启动Mysql服务" /bin/true

     else

        action "启动Mysql服务" /bin/false

        exit 3

     fi       
     
     #安装并启动数据库之后修改root用户密码
     ssh root@$dbip mysqladmin -u$admin_user password "$admin_passwd"

   fi

}


import_sql() {

     ssh root@$dbip "mysql -u$admin_user -p$admin_passwd $group_dbname</softpkg/sql/$sqldir/`basename $sql_name`"

     if [ `ssh root@$dbip echo $?`  -eq 0 ];then

        action "导入数据库$sqldir" /bin/true

     else

        action "导入数据库$sqldir" /bin/false

        exit 4

     fi

}




cdb_sql_install() {

  #检测数据库是否创建
   
   RET_VAL=$(mysql -h$dbip -u$admin_user -p$adminroot_passwd -e "select count(SCHEMA_NAME) from information_schema.SCHEMATA where SCHEMA_NAME='${group_dbname}';" --skip-column-names|grep -v [+-]+)
   if [ $RET_VAL -gt 0 ];then
     echo "数据库${group_dbname}已经创建，正在删除数据库...."
	 mysql -h$dbip -u$admin_user -p$adminroot_passwd -e "drop database ${group_dbname};"
     sleep 1
   fi

     ssh root@$dbip "mysql -u$admin_user -p$admin_passwd -e 'create database ${group_dbname};'"

     if [ `ssh root@$dbip echo $?` -eq 0 ];then

        action "创建${group_dbname}数据库" /bin/true

     else

        action "创建${group_dbname}数据库" /bin/false

        exit 5

     fi

     sleep 1

   #导入数据库表
     import_sql
}


create_user() {

  #创建用户并授予权限

  scp $scripts/mysql_deploy/create_mysqluser.exp root@$dbip:/softpkg/pkg &&\

  ssh  root@$dbip expect $pkg/create_mysqluser.exp \"$group_dbuser\" \"$group_dbpasswd\" $group_dbuser $group_dbname \'\'$group_dbpasswd\'\'>/dev/null 2>&1
     if [ `ssh root@$dbip echo $?` -eq 0 ];then

        action "创建${group_dbuser}用户" /bin/true

     else

        action "创建${group_dbuser}用户" /bin/false

        exit 5

     fi

}



# grant all privileges on *.* to 'root'@'%' identified by 'toor' with grant option;
# flush privileges;

#======================函数调用集======================#
deploy_sshkey

mysql_install

cdb_sql_install

create_user

RET_VAL2=$(mysql -h$dbip -u$admin_user -p$adminroot_passwd -e "select count(SCHEMA_NAME) from information_schema.SCHEMATA where SCHEMA_NAME='${group_dbname}';" --skip-column-names|grep -v [+-]+)
if [ $RET_VAL2 -gt 0 ];then
	echo "S-u-c-c-e-s-s"
else
	echo "F-a-i-l-e-d"
fi
