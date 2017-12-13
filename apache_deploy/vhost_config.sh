#!/bin/bash

Port=$1
groupname=$2
pkgname=$3
httpd_conf=/etc/httpd/conf/httpd.conf
vhost_dir=/var/www/webapps


#将工程的webapp目录下的所有文件移动到上级目录
mv $vhost_dir/$groupname/$pkgname/webapp/* $vhost_dir/$groupname/$pkgname
rm -rf $vhost_dir/$groupname/$pkgname/webapp

IF_PORT=`grep "Listen $Port" $httpd_conf >/dev/null 2>&1;echo $?`
if [ $IF_PORT -eq 0 ];then
   echo "当前端口：$Port 已被占用"
   exit 1
else
sed -i "/\bListen 80\b/a Listen $Port" $httpd_conf

cat >>$httpd_conf<<EOF

<VirtualHost *:$Port>
    DocumentRoot $vhost_dir/$groupname
    ErrorLog $log_dir/error_log
    CustomLog $log_dir/access_log common
<Directory "$vhost_dir/$groupname">
    Options Indexes FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>
</VirtualHost>
EOF
fi
