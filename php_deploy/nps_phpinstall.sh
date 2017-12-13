ls | while read line
do
  package=$(echo $line |sed -n '/.rpm$/p')
  if [ -n "$package" ]
  then
    rpm -ivh $package --nodeps --force
    shift
  else
    :
    shift
  fi
done
