#!/bin/bash
. /opt/new-server/scripts/conf/functions.conf
. /opt/new-server/scripts/conf/variables.conf

if [ $# -ne 2 ];then
  echo_color red "USage: $0 10.0.0.8 22"
  exit 1
fi

echo_color red "hello world"
echo $SSH_PORT
echo $REMOTE_HOST:$SSH_PORT
