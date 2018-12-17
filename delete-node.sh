#!/usr/bin/env bash

env=''
auth=''

# get input/args:
#   -p = full/path/to/node (required)
#   -e = env (optional - default to training)
#   -u = username:password (optional - default to admin:admin)
#   -v = verbose output

while getopts  "p:e:u:v" OPTION
do
    case $OPTION in
        p) path=$OPTARG;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

curl --silent --fail --show-error -i --output /dev/null --user ${auth} -F":operation=delete" -F":applyTo=${path}" ${env}
