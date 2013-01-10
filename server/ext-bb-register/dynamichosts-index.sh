#!/bin/bash

#I live in the directory, so..
cd $(dirname $0)

index=index.inc

ls -1|grep -v -e ".sh$" -e $index |awk '{print "include '$PWD'/" $1}' > $index

echo "done with index"
cat $index

