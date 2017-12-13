#!/bin/bash

. /etc/init.d/functions

groupname=$1
db_user=root
db_passwd=toor

mysql -u$db_user -p$db_passwd -e "drop database $groupname"
if [ `echo $?` -eq 0 ];then
action "删除数据库$groupname" /bin/true
else
action "删除数据库$groupname" /bin/false
exit 1
fi

mysql -u$db_user -p$db_passwd -e "drop user $groupname@'%'"
mysql -u$db_user -p$db_passwd -e "drop user $groupname@'localhost'"
