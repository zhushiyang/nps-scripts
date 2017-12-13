#!/bin/bash

#安全设置
set -u

#定义变量
url_add=$1
groupname=$2
#将要复制的项目目录
modu_dir=$3
#数据库的命名规则
group_id=$4

#根据组名创建jdbc.properties
dbip=172.24.2.170
jdbc_dbname=${group_id}_db
jdbc_username=user_${group_id}
jdbc_password='123456'

pro_dir=/server/procode

#判断是否存在以组名命名的目录
if [ -e $pro_dir/$groupname ]
then
  rm -rf $pro_dir/$groupname
  mkdir $pro_dir/$groupname
else
  mkdir $pro_dir/$groupname
fi

#复制项目到工作目录
cp -a "${modu_dir}" "${pro_dir}/${groupname}"
echo "复制项目到工作目录。"
#进入到项目目录
cd "${pro_dir}/${groupname}/$(basename $modu_dir)"
echo "进入项目目录。"
#判断是否存在resourses目录
if [ ! -d ./resourses ]
then
  echo "检测项目不存在resourses目录。"
  mkdir resourses
  echo "成功创建resourses目录。" 
fi

#有jdbc文件就删除
if [ -e ./resourses/jdbc.properties ]
then
  rm -rf ./resourses/jdbc.properties
  echo "已存在jdbc.properties文件，即将替换。"
fi

#复制模板文件
cp /server/softpkg/jdbc.properties ./resourses/   

#替换jdbc
sed -i "3s#127.0.0.1#$dbip#g" ./resourses/jdbc.properties >/dev/null 2>&1
sed -i "3s#test2#$jdbc_dbname#g" ./resourses/jdbc.properties >/dev/null 2>&1
sed -i "4s#root#$jdbc_username#g" ./resourses/jdbc.properties >/dev/null 2>&1
sed -i "5s#root#$jdbc_password#g" ./resourses/jdbc.properties >/dev/null 2>&1
echo "修改jdbc.properties文件信息成功。"

echo "正在提交项目到git。"

git init >/dev/null
git add . >/dev/null
git commit -a -m "项目模板" >/dev/null
git remote add origin $url_add >/dev/null
git push -u origin master >/dev/null

if [ `echo $?`  -eq 0 ];then
	echo "S-u-c-c-e-s-s"
else
	echo "F-a-i-l-e-d"
fi
cd /;rm -rf $pro_dir/$groupname
