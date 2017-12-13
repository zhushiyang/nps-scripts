#!/bin/bash

. /etc/init.d/functions

php_dir=/server/scripts/php_deploy/nps_php.sh
reapa_dir=/softpkg/apache
procode=/server/procode
httpd_rpm=/server/rpmpkg
httpd_conf=/etc/httpd/conf/httpd.conf
vhost_con=/server/scripts/apache_deploy/vhost_config.sh
sshkey=/server/scripts/sshkey_deploy/nps_deploy_sshkey.sh
log_dir=/webapps/www/webapps/logs
vhost_dir=/var/www/webapps
git_pro=/git_pro
ip=$1
Port=$2
groupname=${3}
filepath=$4

deploy_sshkey() {

   sh $sshkey $ip

}


php_install() {

   sh $php_dir $ip

}


apache_vhost() {
  
         pkg_name=$( basename $filepath | awk -F '.' '{print $1}')
         ser_name=$( basename $filepath | awk -F '_' '{print $1}')
         
         scp $vhost_con root@$ip:$reapa_dir

                  
 
         if [ ! -d $git_pro ];then
		mkdir -p $git_pro 
         fi
         ssh root@$ip "mkdir -p $git_pro"
         ssh root@$ip "mkdir -p ${vhost_dir}/${groupname}/${ser_name}"
         ssh root@$ip "mkdir -p $log_dir"
         ssh root@$ip "touch $log_dir/error.log"
         ssh root@$ip "touch $log_dir/access_log"
         cd $git_pro
         if [ -d $pkg_name ];then
         	rm -rf $pkg_name
	 fi 

	 cp $filepath .

         scp $git_pro/${pkg_name}.zip root@$ip:$git_pro
         if [ `echo $?` -eq 0 ];then
                echo "上传$pkg_name成功"
         else
                echo "上传$pkg_name失败"
                exit 3
         fi
         
         ssh root@$ip "if [ -e /tmp/$pkg_name ] ; then rm -rf /tmp/$pkg_name ; fi ;"

         ssh root@$ip "unzip ${git_pro}/${pkg_name}.zip -d /tmp >/dev/null 2>&1" 
                   
         if [ `ssh root@$ip echo $?` -eq 0 ];then
                echo "解压${pkg_name}.zip成功"
         else
                echo "解压${pkg_name}.zip失败"
                
                exit 4
         fi
         
         ssh root@$ip "if [ -e $vhost_dir/$groupname/$ser_name ] ; then rm -rf $vhost_dir/$groupname/$ser_name ; fi ;"
         
         ssh root@$ip "mkdir -p $vhost_dir/$groupname/$ser_name"        

         ssh root@$ip "mv /tmp/$pkg_name/* $vhost_dir/$groupname/$ser_name"
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
         ssh root@$ip "chown apache.apache -R $vhost_dir/$groupname"
         ssh root@$ip "sh $reapa_dir/vhost_config.sh $Port $groupname $ser_name"
         ssh root@$ip "service httpd restart >/dev/null 2>&1"
          if [ `ssh root@$ip echo $?` -eq 0 ];then

             action "启动Apache服务" /bin/true
             echo "S-u-c-c-e-s-s" 
          else

             action "启动Apache服务" /bin/false
             echo "F-a-i-l-e-d"
             
             exit 2
          fi

         ssh root@$ip "rm -rf $reapa_dir/*"

}

apache_install() {

   ssh root@$ip mkdir -p $reapa_dir

   Status=$(ssh root@$ip rpm -qa|grep httpd>/dev/null 2>&1;echo $?)
  
      if [ $Status -eq 0 ];then

          echo  "Apache服务已经安装，正在部署虚拟主机"
          sleep 1
          apache_vhost          

      else
  
          echo "Apache服务未安装，即将安装Apache服务"
          sleep 1
          scp $httpd_rpm/httpd2.2.tar.gz root@$ip:$reapa_dir
          ssh root@$ip "tar zxf $reapa_dir/httpd2.2.tar.gz -C $reapa_dir"
          ssh root@$ip "cd $reapa_dir;rpm -ivh apr-util-ldap-1.3.9-3.el6_0.1.x86_64.rpm"
          ssh root@$ip "cd $reapa_dir;rpm -ivh httpd-tools-2.2.15-59.el6.centos.x86_64.rpm"
          ssh root@$ip "cd $reapa_dir;rpm -ivh httpd-2.2.15-59.el6.centos.x86_64.rpm"

          if [ `ssh root@$ip echo $?` -eq 0 ];then
             
               action "Apache安装" /bin/true
               sleep 1
               echo  "Apache服务已经安装，正在部署虚拟主机"
               sleep 1
               apache_vhost
          else 
             
               action "Apache安装" /bin/false
               exit 2

          fi

      fi

}

#===================函数集调用===================#
deploy_sshkey
#sh /server/scripts/mysql_deploy/nps_mysql.sh $sql $groupname
php_install
apache_install
