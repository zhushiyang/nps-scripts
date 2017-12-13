#!/bin/bash

USER=$1
PASSWD=$2
URL=$3
PRONAME=$4


curl -u $USER:$PASSWD -X POST "${URL}projects/bulk_delete?keys=$PRONAME"
