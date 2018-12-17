#!/usr/bin/env bash

TIMEOUT=1
path=''
pathSupplied=0
name=''
nameSupplied=0
auth='admin:admin'
packageGroup='my_packages'

while getopts  "p:n:g:e:u:v" OPTION
do
    case $OPTION in
        p) path=$OPTARG; pathSupplied=1;;
        n) name=$OPTARG; nameSupplied=1;;
        g) packageGroup=$OPTARG;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ! ${nameSupplied} || ! ${nameSupplied} ]]; then
    echo "path and packageName are required parameters for creating a package!"
    exit 1;
fi

# create package
if [[ ${verbose} ]]; then
    echo "creating package: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${path}\?cmd\=create -d packageName=${name} -d groupName=${packageGroup}"
fi
createPackage=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${path}\?cmd\=create -d packageName=${name} -d groupName=${packageGroup})
if [[ ! "$createPackage" == "200" ]]; then
    echo "failed to create package: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${path}\?cmd\=create -d packageName=${path} -d groupName=${packageGroup}"
    exit 1;
fi
