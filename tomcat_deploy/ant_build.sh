#!/bin/bash
#ant build project
#Usage:
#2017年8月8日08:39:43
#max

#==========================初始化变量==============================#
. /etc/init.d/functions

codedir=/server/procode             #本地存放源代码和sql文件目录
pkgdir=/server/softpkg              #本地存放tomcat和jdk软件包目录
scripts=/server/scripts             #本地所有脚本存放路径
jdbcfile=/server/softpkg/jdbc.properties     #jdbc模板
flags=1

DesWarDir=/myinstall/tomcat7-1/webapps/ROOT/resources/upload/project/build
#==========================位置参数================================#
giturl=$1                           #项目地址
wardir=$2                           #生成war包后，存放war的目录
group_id=$3                         
dbip=172.24.2.170

jdbc_dbname=${group_id}_db
jdbc_username=user_${group_id}
jdbc_password='123456'

  pkgname_path=$(basename "$giturl" |cut -d. -f1)
  #进入源码包存放目录
  cd "$codedir"

  if [ -e $pkgname_path ]
  then
    rm -rf $pkgname_path 
  fi

  #git获取到项目源码
  git clone $giturl &&\

  #进入项目目录
  if [ -d "$pkgname_path" ]
  then
    cd "$pkgname_path"
    action "正在进入项目目录" /bin/true
  else
    action "正在进入项目目录" /bin/false
    exit 1
  fi

  #待修改，不确定是否成功
  if [ -e ./webapp/WEB-INF/classes/jdbc.properties ];then
        rm -f ./webapp/WEB-INF/classes/jdbc.properties
  fi
  #resources目录下的jdbc文件，编译的时候会把resources目录的所有文件考到classes目录下
  if [ -e ./resourses/jdbc.properties ];then
        rm -f ./resourses/jdbc.properties
        cp  $pkgdir/jdbc.properties ./webapp/WEB-INF/classes/
  fi


  sed -i "3s#127.0.0.1#$dbip#g" ./webapp/WEB-INF/classes/jdbc.properties >/dev/null 2>&1
  sed -i "3s#test2#$jdbc_dbname#g" ./webapp/WEB-INF/classes/jdbc.properties >/dev/null 2>&1
  sed -i "4s#root#$jdbc_username#g" ./webapp/WEB-INF/classes/jdbc.properties >/dev/null 2>&1
  sed -i "5s#root#$jdbc_password#g" ./webapp/WEB-INF/classes/jdbc.properties >/dev/null 2>&1
 
  cat  ./webapp/WEB-INF/classes/jdbc.properties
 
  #拷贝build.xml、build.properties和jdbc.properties文件
  cp "$pkgdir"/build.xml ./
  cp "$pkgdir"/build.properties ./
  #判断是否拷贝成功
  if [ -e build.xml ]
  then
    action "正在拷贝build.xml" /bin/true
  else
    action "正在拷贝build.xml" /bin/false
    exit 2
  fi

  if [ -e build.properties ]
  then
    action "正在拷贝build.properties" /bin/true
  else
    action "正在拷贝build.properties" /bin/false
    exit 1
  fi

 # cp $jdbcfile  ${codedir}/${pkgname_path}/webapp/WEB-INF/classes

  #对build.properties文件进行编辑
  sed -i "s#protemp#$pkgname_path#" build.properties
  sed -i "s#jdbctemp#$Now#" build.properties
  sed -i "s#hometemp#$PWD#" build.properties

  #执行ant对项目进行打包
  /opt/apache-ant-1.9.4/bin/ant >/dev/null

  #判断ant执行结果
  flags=$(echo $?)

  if [ "$flags" -eq 0 ]
  then
    echo "Success:${pkgname_path}.war"
  else
    echo "Failed"
    exit 1
  fi

  #进入war包存放的目录
  cd ./dist
  
  #创建存放war包目录
  mkdir -p $wardir

  #将项目生成的war包存放在wardir目录下
  cp -r ${pkgname_path}.war $wardir

  #删除项目包
  cd /
  rm -rf ${codedir}/${pkgname_path}
  cp -r $wardir $DesWarDir 
