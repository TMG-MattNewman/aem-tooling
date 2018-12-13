#!/usr/bin/env bash

DEFAULT_ENV='http://aem-docker-training.aws-preprod.telegraph.co.uk:4502/'
LOCALHOST='http://localhost:4502/'
ROOTPAGE='crx/packmgr/index.jsp'
PACKAGE_GROUP='hub-migration'
PACKAGE_PATH="/etc/packages/${PACKAGE_GROUP}/"
CRX_CREATE_PATH="crx/packmgr/service/.json${PACKAGE_PATH}"
CRX_UPDATE_PATH='crx/packmgr/update.jsp'
TIMEOUT=2

outputDir='hub-packages'
path=''
pathSupplied=0
outputDirSupplied=0
env=${LOCALHOST}
auth='admin:admin'

while getopts  "p:o:e:u:ilv" OPTION
do
    case $OPTION in
        p) path=$OPTARG; pathSupplied=1;;
        o) outputDir=$OPTARG; outputDirSupplied=1;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        l) local=1;;
        i) inverted=1;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ! ${path} ]]; then
    echo 'path is a required param for backup!'
    exit 1;
fi

# if env does not end with a forward slash add one
if [[ ! ${env} =~ /$ ]]; then
    echo "adding / to env"
    env="${env}/"
fi

# TODO: use path manipulation instead
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
createPackage=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}\?cmd\=create -d packageName=${packageName} -d groupName=${PACKAGE_GROUP})
if [[ ! "$createPackage" == "200" ]]; then
    echo "failed to create package: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}\?cmd\=create -d packageName=${packageName} -d groupName=${PACKAGE_GROUP}"
    exit 1;
fi

# add filters
addFilters=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_UPDATE_PATH} -F path=${packageZip} -F packageName=${packageName} -F groupName=${PACKAGE_GROUP} -F filter="[{\"root\" : \"/${path}\", \"rules\": []}]" -F '_charset_=UTF-8')
if [[ ! "$addFilters" == "200" ]]; then
    echo "failed to add filters: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_UPDATE_PATH} -F path=${packageZip} -F packageName=${packageName} -F groupName=${PACKAGE_GROUP} -F filter=\"[{\"root\" : \"/${path}\", \"rules\": []}]\" -F '_charset_=UTF-8'"
    exit 1;
fi

# build package
buildPackage=$(curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}.zip\?cmd\=build)
if [[ ! "$buildPackage" == "200" ]]; then
    echo "failed to build package: curl --write-out %{http_code} --silent --output /dev/null -i --user $auth --connect-timeout $TIMEOUT -X POST ${env}${CRX_CREATE_PATH}${packageName}.zip\?cmd\=build"
    exit 1;
fi

if [[ ${env} =~ docker-(.*)\.aws ]]; then
    packageName=${BASH_REMATCH[1]}-${packageName}
fi

# Define a timestamp function
datetime() {
  date '+%Y-%m-%d__%H-%M-%S'
}

# make a directory to store the downloaded zip files
mkdir -p ${outputDir}

# download package and suppress download stats
curl --silent --fail --show-error --user ${auth} ${env}etc/packages/${PACKAGE_GROUP}/${packageName}.zip > ./${outputDir}/${packageName}.$(datetime).zip
