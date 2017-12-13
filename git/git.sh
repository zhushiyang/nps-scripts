#!/bin/bash

#安全设置
set -u

#定义变量
url_add=$1
groupname=$2
#将要复制的项目目录
modu_dir=$3
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

#进入到项目目录
cd "${pro_dir}/${groupname}/$(basename $modu_dir)"

#判断是否存在resourses目录和jdbc.properties
pwd


#对git进程进行判断，如果已经存在，则杀死进程重新运行

#ps -ef |grep -w "/server/scripts/git/git.sh $url_add"

#flags=$(echo $?)

#if [ $flags -eq 0 ]
#then
#  gitpid=$(ps -ef |grep -w "/server/scripts/git/git.sh $url_add" | awk 'print $1')
#  kill -9 $gitpid
#fi

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
