#!/usr/bin/env bash

PACKAGE_MANAGER='crx/packmgr/index.jsp'
PACKAGE_UPDATE_PATH='crx/packmgr/update.jsp'
PACKAGE_SERVICE_PATH='crx/packmgr/service/.json'
TIMEOUT=1

outputDir='downloads'
packageName=''
pathSupplied=0
outputDirSupplied=0
packageGroup='my_packages'
env='http://localhost:4502/'
auth='admin:admin'
create=0
addFilter=0
build=0
download=0

while getopts  "p:o:g:e:u:cabdv" OPTION
do
    case $OPTION in
        p) path=$OPTARG; pathSupplied=1;;
        c) create=1;;
        a) addFilter=1;;
        b) build=1;;
        d) download=1;;
        o) outputDir=$OPTARG;;
        g) packageGroup=$OPTARG;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ! ${pathSupplied} -eq 1 ]]; then
    echo "a path is required for working with packages!"
    exit 1;
fi

if [[ ! ( ${create} || ${addFilter} || ${build} || ${download} ) ]]; then
    echo "one of create (c), addFilter (f), build (b) or download (d) is required."
    exit 1;
fi

# check access to env using username & password
./test-connection.sh -e ${env} -u ${auth} || exit 1;

packagePath="etc/packages/${packageGroup}/"
createPath="${PACKAGE_SERVICE_PATH}/${packagePath}"

# if path starts with a forward slash, strip it, because one exists at the end of $env
if [[ ! ${env} =~ /$ ]]; then
    env="${env}/"
fi
if [[ ${path} =~ ^/ ]]; then
    path="${path:1}"
fi

fullPath=$(./path-manipulation.sh -p ${path} -j) # add all parts of the path needed for a page level filter
truncatedPackageName=$(./path-manipulation.sh -p ${fullPath} -s) # strip package name down to minimum useful
packageName=${truncatedPackageName//\//-} # replace \ with -
packageZip=${packagePath}${packageName}.zip

CREATE_PACKAGE_PARAMS="-p ${env}${createPath} -u ${auth} -n ${packageName} -g ${packageGroup}"
PACKAGE_ADD_FILTER_PARAMS="-e ${env} -u ${auth} -p ${fullPath} -n ${packageName} -g ${packageGroup}"
PACKAGE_BUILD_PARAMS="-z ${env}${PACKAGE_SERVICE_PATH}/${packageZip} -u ${auth}"
PACKAGE_DOWNLOAD_PARAMS="-z ${env}${packageZip} -u ${auth} -n ${packageName} -o ${outputDir}"

if [[ ${verbose} -eq 1 ]]; then
    echo "fullPath=${fullPath}"
    echo "packageName=${packageName}"
    echo "packageGroup=${packageGroup}"
    echo "packageZip=${packageZip}"
    CREATE_PACKAGE_PARAMS+=" -v"
    PACKAGE_ADD_FILTER_PARAMS+=" -v"
    PACKAGE_BUILD_PARAMS+=" -v"
    PACKAGE_DOWNLOAD_PARAMS+=" -v"
    echo "CREATE_PARAMS=${CREATE_PACKAGE_PARAMS}"
    echo "ADD_FILTER_PARAMS=${PACKAGE_ADD_FILTER_PARAMS}"
    echo "PACKAGE_BUILD_PARAMS=${PACKAGE_BUILD_PARAMS}"
    echo "PACKAGE_DOWNLOAD_PARAMS=${PACKAGE_DOWNLOAD_PARAMS}"
fi

if [[ ${create} -eq 1 ]]; then
    ./package-create.sh ${CREATE_PACKAGE_PARAMS}
fi

if [[ ${addFilter} -eq 1 ]]; then
    ./package-add-filter.sh ${PACKAGE_ADD_FILTER_PARAMS}
fi

if [[ ${build} -eq 1 ]]; then
    ./package-build.sh ${PACKAGE_BUILD_PARAMS}
fi

if [[ ${download} -eq 1 ]]; then
    ./package-download.sh ${PACKAGE_DOWNLOAD_PARAMS}
fi
