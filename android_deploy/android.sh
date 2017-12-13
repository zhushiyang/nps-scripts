#!/bin/bash
#安卓编译
#注意事项：
#1.编译服务器为172.24.2.137
#2.编译返回路径为/export/android/project
#编译所需位置参数2，1：giturl;2:GID
#max
#2017年9月18日21:08:07

#安全设置
set -u

#============初始化位置参数=================#
giturl=$1 #从git服务器获取到项目
gid=$2 #将apk存放到/export0/tomcat7-1/webapps/ROOT/resources/upload/project/build/下，以gid区分

#初始化变量
apksave=/myinstall/tomcat7-1/webapps/ROOT/resources/upload/project/build #apk存放路
proname=$(basename $giturl|cut -d '.' -f 1) #获取到项目名称
serverip=172.24.2.186 #android服务器地址
serandroid=/export0/android #服务器执行项目的地址
locandroid=/server/android #本地对项目压缩执行的地址
Time=$(date +%d%H%M%S) #区分不同项目的时间戳
flags_build=1
#首先进入本地安卓地址
cd "$locandroid"
echo "进入项目地址!"

#检测是否已存在项目，用于多次编译
if [ -e "$proname" ]
then
  echo "项目已存在，即将删除旧版本项目包!"
  rm -rf "$proname"
  #更新项目
  git clone "$giturl" >/dev/null 2>&1
else
  echo "正在下载项目，请稍等..."
  #从git服务器下载项目包
  git clone "$giturl" >/dev/null 2>&1
fi

#对项目进行压缩
echo "正在对项目进行压缩！"
zip -r "${proname}.zip" "$proname" >/dev/null 2>&1

#判断是否压缩成功
if [ -e "${proname}.zip" ]
then
  echo "正在拷贝项目到远程服务器！"
  scp "${proname}.zip" root@"$serverip":"$serandroid"
else
  exit 1
fi

#执行服务器端脚本，对项目进行编译
flag_scp=$(echo $?)
if [ "$flag_scp" -eq 0 ]
then
  #执行远程服务器上的脚本
  ssh root@"$serverip" "sh -x /export0/android/android.sh ${proname}.zip"
  flags_build=$(ssh root@$serverip "echo $?")
  echo "正在远程服务器编译，请耐心等待..."
fi

#判断ant执行结果
if [ "$flags_build" -eq 0 ]
then
  mkdir -p "${apksave}/${gid}"
  mv "${locandroid}/${proname}.apk" "${locandroid}/${proname}${Time}.apk"
  mv "${locandroid}/${proname}${Time}.apk" "${apksave}/${gid}"
  echo "Success:${proname}${Time}.apk"
else
  echo "Failed"
  exit 1
fi

