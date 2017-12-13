#!/bin/bash
#auto install and config tomcat
#2017年7月13日08:06:48
#max
#=============================定义初始化变量===========================#
. /etc/init.d/functions

codedir=/server/procode             #本地存放源代码和sql文件目录
pkgdir=/server/softpkg              #本地存放tomcat和jdk软件包目录
wardir=/server/project              #生成war包后，存放war的目录
ipinfo=/server/.ipinfo/ip.txt       #本地存放分发过密钥的IP地址和端口
scripts=/server/scripts             #本地所有脚本存放路径
rpmdir=/server/yum                  #本地rpm包存放路径
jdkdir=/webapps/jdk                 #远程存放jdk的目录
tomcat_pro=/webapps/tomcat          #远程存放tomcat程序的父目录
resoftpkg=/webapps/softpkg          #远程存放jdk压缩包和脚本的目录
expect_rpm=expect-5.44.1.15-5.el6_4.x86_64.rpm  #expect软件包名
create_grant_dbuser=create_mysqluser.exp   #远程自动化操作数据库脚本
sshkey=/server/scripts/sshkey_deploy/nps_deploy_sshkey.sh
Spasswd=`awk -F "\"" 'NR==8{print $2}' /server/scripts/sshkey_deploy/nps_deploy_sshkey.exp`

ip=$1                               #位置参数1记录ip
start_port=$2                       #位置参数2记录tomcat启动端口
shutdown_port=$[$2+100]             #位置参数3记录tomcat关闭端口
warpkg=$3
tomcat_name=tomcat$2
Passwd=$4


ssh root@$ip "mkdir -p $jdkdir >/dev/null 2>&1"
ssh root@$ip "mkdir -p $tomcat_pro >/dev/null 2>&1"
ssh root@$ip "mkdir -p $resoftpkg >/dev/null 2>&1"

#=============================定义======函数===========================#
deploy_sshkey() {
   
   sed -i "s#$Spasswd#$Passwd#g" /server/scripts/sshkey_deploy/nps_deploy_sshkey.exp
   sh $sshkey $ip
}

jdk_install(){
 
  #此步骤用于修改目标服务器的环境变量
  #ssh root@$ip '. /etc/profile && echo "PATH=$PATH" >>/etc/bashrc'
  jre=jdk.tar.gz 
  #检测目标服务器是否存在JRE环境
  ssh root@$ip '. /etc/profile && java -version' >/dev/null 2>&1
  flags_jre=$(echo $?)
  flags_jdk=0
  if [ "$flags_jre" -eq 0 ]
  then
    action "检测目标服务器是否存在jre环境" /bin/true 
    
    #检测是否存在JDK环境
    ssh root@$ip '. /etc/profile && javac -version' >/dev/null 2>&1
    flags_jdk=$(echo $?)
    if [ "$flags_jdk" -eq 0 ]
    then
      action "检测目标服务器是否存在jdk环境" /bin/true 
    else
      action "检测目标服务器是否存在jdk环境" /bin/false 
    fi
  else
    action "检测目标服务器是否存在jre环境" /bin/false
  fi
  
  #不存在环境下载并安装JDK
  if [ "$flags_jre" -ne 0 -o "$flags_jdk" -ne 0 ]
  then
    #情况1：不存在
    #创建远程目录
    ssh root@$ip mkdir -p $jdkdir           #存放jdk的目录
    ssh root@$ip mkdir -p $tomcat_pro       #存放tomcat程序的父目录
    ssh root@$ip mkdir -p $resoftpkg
    action "正在传输JDK到目标服务器" /bin/true

    #传输JDK源码包
    scp $pkgdir/$jre root@$ip:$resoftpkg
    flags_scp=$(echo $?)
    if [ "$flags_scp" -eq 0 ]
    then
      action "传输JDK源码包成功" /bin/true 
    else
      action "传输JDK源码包成功" /bin/false 
    fi
    
    #对源码包进行解压缩
    ssh root@$ip tar -zxf $resoftpkg/$jre -C $jdkdir
    flags_ssh=$(echo $?) 
    if [ "$flags_ssh" -eq 0 ]
    then
      action "解压JDK源码包成功" /bin/true 
    else
      action "解压JDK源码包成功" /bin/false 
    fi
   
    #对JDK进行环境变量配置
    ssh root@$ip 'echo JAVA_HOME=/webapps/jdk >>/etc/profile'
    ssh root@$ip 'echo export JAVA_HOME >>/etc/profile'
    ssh root@$ip 'echo JRE_HOME=/webapps/jdk/jre >>/etc/profile'
    ssh root@$ip 'echo export JRE_HOME >>/etc/profile'
    ssh root@$ip 'echo export CLASSPATH=.:\$JAVA_HOME/lib:\$JRE_HOME/lib:\$CLASSPATH >>/etc/profile'
    ssh root@$ip 'echo export PATH=\$PATH:\$JAVA_HOME/bin:\$JRE_HOME/bin >>/etc/profile'
    #使目标服务器环境变量生效
    ssh root@$ip 'echo ". /etc/profile" >./effect && sh ./effect && rm -rf ./effect'
    
    #检测是否成功
    ssh root@$ip '. /etc/profile && java -version' >/dev/null
    flags_jre=$(echo $?)
    flags_jdk=0
    if [ "$flags_jre" -eq 0 ]
    then
      #检测是否存在JDK环境
      ssh root@$ip '. /etc/profile && javac -version' >/dev/null
      flags_jdk=$(echo $?)
      if [ "$flags_jdk" -eq 0 ]
      then
        action "成功配置JDK环境" /bin/true
      else
        action "成功配置JDK环境" /bin/false
      fi
    else
      action "成功配置JDK环境" /bin/false
    fi
  fi
}

tomcat_install(){
 
  War_name=`basename $warpkg|awk -F "." '{print $1}'`
  if [ ! -f ${warpkg} ];then
	  echo "${War_name}.war not exist"
          exit 2
  fi

  cp -a $wardir/tomcat $wardir/$tomcat_name
  cp $warpkg  $wardir/$tomcat_name/webapps/

  sed -i "10s#tomcat_group01#$tomcat_name#g" $wardir/$tomcat_name/init.d/tomcat
  #进入wardir目录
  cd "$wardir"

  #修改tomcat server.xml文件（启动端口，关闭端口，war包项目路径）
  sed -i "s#8005#$shutdown_port#" $wardir/$tomcat_name/conf/server.xml
  sed -i "s#8080#$start_port#" $wardir/$tomcat_name/conf/server.xml
  sed -i "s#XXX#$War_name1#" $wardir/$tomcat_name/conf/server.xml

  #对tomcat目录进行压缩
  tar -zcf $tomcat_name.tar.gz $tomcat_name  

  #判断端口号有没有被占用
 # lsof -i:$start_port
 # flags=$(echo $?)
 # if [ "$flags" -ne 0 ]
 # then
 #   action "正在检测tomcat端口是否可用" /bin/true
 #   action "tomcat端口可用" /bin/true
 # else
 #   action "tomcat端口可用" /bin/false
 #   exit 1
 # fi

  #复制tomcat到目标服务器 
  scp $wardir/$tomcat_name.tar.gz root@$ip:$tomcat_pro
  flags=$(echo $?)
  if [ "$flags" -eq 0 ]
  then
    action "复制tomcat到目标服务器" /bin/true
  else
    action "复制tomcat到目标服务器" /bin/false
    exit 1
  fi
  
  flags=$(ssh root@$ip "tar zxf $tomcat_pro/$tomcat_name.tar.gz -C $tomcat_pro" ; echo $?)
  if [ "$flags" -eq 0 ]
  then
    action "对tomcat压缩包进行解压缩" /bin/true
  else
    action "对tomcat压缩包进行解压缩" /bin/false
    exit 1
  fi
   
  flags=$(ssh root@$ip "cp -a  $tomcat_pro/$tomcat_name/init.d/tomcat /etc/init.d/$tomcat_name";echo $?)
  if [ "$flags" -eq 0 ]
  then
    action "对tomcat压缩包进行解压缩" /bin/true
  else
    action "对tomcat压缩包进行解压缩" /bin/false
    exit 1
  fi
  
if [ `ssh root@$ip service iptables status >/dev/null 2>&1;echo $?` -eq 0 ];then
 ssh root@$ip "sed -i '/lo/a -A INPUT -p tcp -m state --state NEW -m tcp --dport $start_port -j ACCEPT' /etc/sysconfig/iptables"
 ssh root@$ip "service iptables restart"
fi

 
  ssh root@$ip "service $tomcat_name start" && \
  if [ `ssh root@$ip "echo $?"` -eq 0 ]
  then
    action "$tomcat_name服务启动" /bin/true
    echo "S-u-c-c-e-s-s"
  else
    action "$tomcat_name服务已经启动" /bin/false
    echo "F-a-i-l-e-d"
    exit 1
  fi
  #加入开机启动
  ssh root@$ip "chkconfig  $tomcat_name on"
  #删除已经处理的tomcat程序包（复制模板之后的包）
  rm -rf $wardir/$tomcat_name*
  #删除远程的tomcat压缩包
  ssh root@$ip "rm -rf $tomcat_pro/${tomcat_name}.tar.gz"
  
}

#=============================函数测==试区域===========================#
deploy_sshkey
jdk_install
tomcat_install
