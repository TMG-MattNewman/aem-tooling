#!/usr/bin/env bash

PACKAGE_MANAGER='crx/packmgr/index.jsp'
packageGroup='my_packages'
PACKAGE_PATH="/etc/packages/${packageGroup}/"
CRX_CREATE_PATH="crx/packmgr/service/.json${PACKAGE_PATH}"
TIMEOUT=2

path=''
pathSupplied=0
env='http://localhost:4502/'
auth='admin:admin'

while getopts  "p:e:u:v" OPTION
do
    case $OPTION in
        p) path=$OPTARG; pathSupplied=1;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ! ${path} ]]; then
    echo 'path is a required param for backup!'
    exit 1;
fi

# TODO: use path manipulation instead
# if path starts with a forward slash, strip it, because one exists at the end of $env
if [[ ${path} =~ ^/ ]]; then
    path="${path:1}"
fi

# check access to env using username & password
connectStatus=$(curl --write-out %{http_code} --silent --output /dev/null -I --user $auth -L --connect-timeout $TIMEOUT $env$ROOTPAGE)
if [[ ! "$connectStatus" == "200" ]]; then
    echo "couldn't connect to package manager using: curl -IL --user $auth $env$ROOTPAGE"
    exit 1;
fi

# some regex stripping of path
packageNameStripped=${path//content\/telegraph\/}
packageNameStripped=${packageNameStripped//\/jcr:content/}
packageName=${packageNameStripped//\//-}

if [[ ${inverted} ]]; then
    packageName=${packageName}.converted
fi

packageZip=${PACKAGE_PATH}${packageName}.zip

if [[ ${verbose} ]]; then
    echo "packageNameStripped=${packageNameStripped}"
    echo "packageName=${packageName}"
    echo "packageZip=${packageZip}"
    echo "outputDir=${outputDir}"
fi

# create package
if [[ ${verbose} ]]; then
    echo "creating package"
fi
createPackage=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}\?cmd\=create -d packageName=${packageName} -d groupName=${packageGroup})
if [[ ! "$createPackage" == "200" ]]; then
    echo "failed to create package: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}\?cmd\=create -d packageName=${packageName} -d groupName=${packageGroup}"
    exit 1;
fi

# add filters
if [[ ${verbose} ]]; then
    echo "adding filters"
fi
addFilters=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_UPDATE_PATH} -F path=${packageZip} -F packageName=${packageName} -F groupName=${packageGroup} -F filter="[{\"root\" : \"/${path}\", \"rules\": []}]" -F '_charset_=UTF-8')
if [[ ! "$addFilters" == "200" ]]; then
    echo "failed to add filters: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_UPDATE_PATH} -F path=${packageZip} -F packageName=${packageName} -F groupName=${packageGroup} -F filter=\"[{\"root\" : \"/${path}\", \"rules\": []}]\" -F '_charset_=UTF-8'"
    exit 1;
fi

# build package
if [[ ${verbose} ]]; then
    echo "building package"
fi
buildPackage=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}.zip\?cmd\=build)
if [[ ! "$buildPackage" == "200" ]]; then
    echo "failed to build package: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}.zip\?cmd\=build"
    exit 1;
fi
