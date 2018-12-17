#!/usr/bin/env bash

TIMEOUT=1
fullZipUrl=''
fullZipUrlSupplied=0
auth='admin:admin'

while getopts  "z:e:u:v" OPTION
do
    case $OPTION in
        z) fullZipUrl=$OPTARG; fullZipUrlSupplied=1;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ${fullZipUrlSupplied} -eq 0 ]]; then
    echo "fullZipUrlSupplied is required for building package!"
    exit 1;
fi

# build package
if [[ ${verbose} ]]; then
    echo "building package: curl --fail --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${fullZipUrl}\?cmd\=build"
fi
buildPackage=$(curl --fail --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${fullZipUrl}\?cmd\=build)
if [[ ! "$buildPackage" == "200" ]]; then
    echo "failed to build package: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${fullZipUrl}.zip\?cmd\=build"
    exit 1;
fi

# e.g: curl --fail --silent --output /dev/null -i --user admin:admin --connect-timeout 1 -X POST http://localhost:4502/crx/packmgr/service/.json/etc/packages/my_packages/test.zip\?cmd\=build
