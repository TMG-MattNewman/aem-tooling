#!/usr/bin/env bash

DEFAULT_ENV='http://aem-docker-training.aws-preprod.telegraph.co.uk:4502/'
LOCALHOST='http://localhost:4502/'
ROOTPAGE='crx/packmgr/index.jsp'
PACKAGE_GROUP='my_packages'
PACKAGE_PATH="/etc/packages/${PACKAGE_GROUP}/"
CRX_CREATE_PATH="crx/packmgr/service/.json${PACKAGE_PATH}"
CRX_UPDATE_PATH='crx/packmgr/update.jsp'
TIMEOUT=2

path=''
env=${LOCALHOST}
auth='admin:admin'

# get input/args:
#   -p = path/to/page (required)
#   -e = env (optional - default to training)
#   -u = username:password (optional - default to admin:admin)
#   -l = use localhost as env
#   -v = verbose output

while getopts  "p:e:u:ilv" OPTION
do
    case $OPTION in
        p) path=$OPTARG;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        i) inverted=1;;
        v) verbose=1;;
        *) exit 1 # illegal option
    esac
done

# if env does not end with a forward slash add one
if [[ ! ${env} =~ /$ ]]; then
    echo "adding / to env"
    env="${env}/"
fi

# if path starts with a forward slash, strip it, because one exists at the end of $env
if [[ ${path} =~ ^/ ]]; then
    path="${path:1}"
fi

# check access to env using username & password
connectStatus=$(curl --write-out %{http_code} --silent --output /dev/null -I --user $auth -L --connect-timeout $TIMEOUT $env$ROOTPAGE)
if [[ ! "$connectStatus" == "200" ]]; then
    echo "env=${env}"
    echo "path=${path}"
    echo "couldn't connect to package manager using: curl -IL --user $auth $env$ROOTPAGE"
    exit 1;
fi

packageNameStripped=${path//content\/telegraph\/}
packageNameStripped=${packageNameStripped//\/jcr:content/}
packageName=${packageNameStripped//\//-}

if [[ ${inverted} ]]; then
    packageName=${packageName}.converted
fi

packageZip=${PACKAGE_PATH}${packageName}.zip

if [[ ${verbose} ]]; then
    echo packageNameStripped=${packageNameStripped}
    echo packageName=${packageName}
    echo packageZip=${packageZip}
fi

# create package
createPackage=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}\?cmd\=create -d packageName=${packageName} -d groupName=${PACKAGE_GROUP})
if [[ ! "$createPackage" == "200" ]]; then
    echo "failed to create package"
    echo "curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}\?cmd\=create -d packageName=${packageName} -d groupName=${PACKAGE_GROUP}"
    exit 1;
fi

# add filters
addFilters=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_UPDATE_PATH} -F path=${packageZip} -F packageName=${packageName} -F groupName=${PACKAGE_GROUP} -F filter="[{\"root\" : \"/${path}\", \"rules\": []}]" -F '_charset_=UTF-8')
if [[ ! "$addFilters" == "200" ]]; then
    echo "failed to add filters"
    echo "curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_UPDATE_PATH} -F path=${packageZip} -F packageName=${packageName} -F groupName=${PACKAGE_GROUP} -F filter=\"[{\"root\" : \"/${path}\", \"rules\": []}]\" -F '_charset_=UTF-8'"
    exit 1;
fi

# build package
buildPackage=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}.zip\?cmd\=build)
if [[ ! "$buildPackage" == "200" ]]; then
    echo "failed to build package"
    echo "curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}.zip\?cmd\=build"
    exit 1;
fi

# Define a timestamp function
datetime() {
  date '+%Y-%m-%d.%H:%M:%S'
}

# download package
curl --silent --user ${auth} ${env}${CRX_CREATE_PATH}${packageName}.zip > ${packageName}.$(datetime).zip
