#!/bin/bash
#目录清理：
#        远程主机：停止httpd服务,删除httpd.conf配置文件
#        远程主机：清空/var/www/webapps/*目录
#        远程主机：恢复初始化配置文件

REMOTE_HOST=172.24.2.168
SSH_PORT=22

#远程主机httpd配置文件
HTTP_CONF=/etc/httpd/conf/httpd.conf

#本地httpd初始化文件
CONF_INIT=/server/scripts/apache_deploy/httpd.conf

#远程主机要清理的目录
CLEAR_DIR=/var/www/webapps


#远程执行命令，参数1是要执行的命令
function SSH_CMD(){
  REMOTE_CMD=$1
  ssh -p$SSH_PORT root@$REMOTE_HOST $REMOTE_CMD
  
  RESULT=`ssh -p$SSH_PORT root@$REMOTE_HOST echo $?`
  if [ $RESULT -ne 0 ];then
     echo "执行命令:【$REMOTE_CMD】失败"
     exit 1
  fi

}

#上传本地文件到远程主机，参数1：本地文件；参数2：远程主机目录
function SSH_UPLOAD(){
  FILE_NAME=$1
  REMOTE_DIR=$2
  scp -P$SSH_PORT $FILE_NAME root@${REMOTE_HOST}:$REMOTE_DIR
  
  RESULT=`ssh -p$SSH_PORT root@$REMOTE_HOST echo $?`
  if [ $RESULT -ne 0 ];then
     echo "上传文件:【$FILE_NAME】失败"
     exit 1
  fi  
}


SSH_CMD "service httpd stop"
SSH_CMD "rm -f $HTTP_CONF"
SSH_CMD "rm -rf $CLEAR_DIR"
SSH_UPLOAD $CONF_INIT $HTTP_CONF
echo "S-u-c-c-e-s-s"
