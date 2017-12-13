#!/bin/bash
git_pro=/git_pro_build

git_url=$1

#zip的随机ID
zip_dirID=$2

#存放zip包的路径
zip_dir=/myinstall/tomcat7-1/webapps/ROOT/resources/upload/project/build/$2

pkg_name_src=$(basename $git_url|awk -F '.' '{print $1}')
pkg_name_dec=${pkg_name_src}_`date|md5sum|cut -c 1-6` 

if [ ! -d $git_pro ];then
        mkdir -p $git_pro
fi

if [ ! -d $zip_dir ];then
        mkdir -p $zip_dir
fi


cd $git_pro

if [ -d $pkg_name_src ];then
     rm -rf $pkg_name_src
fi

git clone $git_url
mv $pkg_name_src $pkg_name_dec

zip -r $git_pro/${pkg_name_dec}.zip $pkg_name_dec >/dev/null 2>&1
if [ `echo $?` -eq 0 ];then
	echo "压缩${pkg_name_dec}成功"
else
	echo "压缩${pkg_name_dec}失败"
        exit 1
fi

cp  $git_pro/${pkg_name_dec}.zip $zip_dir

#存放在warpkg/front一份
mkdir /warpkg/front/$2
cp  $git_pro/${pkg_name_dec}.zip /warpkg/front/$2

if [ `echo $?` -eq 0 ];then
        echo "Success:${pkg_name_dec}.zip"
else
        echo "Failed"
        exit 2
fi
