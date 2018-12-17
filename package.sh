#!/usr/bin/env bash

PACKAGE_MANAGER='crx/packmgr/index.jsp'
CRX_UPDATE_PATH='crx/packmgr/update.jsp'
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

if [[ ! ${pathSupplied} ]]; then
    echo "a path is required for working with packages!"
    exit 1;
fi

if [[ ! ( ${create} || ${addFilter} || ${build} || ${download} ) ]]; then
    echo "one of create (c), addFilter (f), build (b) or download (d) is required."
    exit 1;
fi

# check access to env using username & password
./test-connection.sh -e ${env} -u ${auth} || exit 1;

packagePath="/etc/packages/${packageGroup}/"
createPath="crx/packmgr/service/.json${packagePath}"
updatePath=""

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

CREATE_PARAMS="-p ${env}${createPath} -u ${auth} -n ${packageName} -g ${packageGroup}"
ADD_FILTER_PARAMS=""

if [[ ${verbose} ]]; then
    echo "fullPath=${fullPath}"
    echo "packageName=${packageName}"
    echo "packageGroup=${packageGroup}"
    echo "packageZip=${packageZip}"
    CREATE_PARAMS+=" -v"
    ADD_FILTER_PARAMS+=" -v"
    echo "CREATE_PARAMS=${CREATE_PARAMS}"
    echo "ADD_FILTER_PARAMS=${ADD_FILTER_PARAMS}"
fi

if [[ ${create} ]]; then
    ./package-create.sh ${CREATE_PARAMS}
fi

if [[ ${addFilter} ]]; then
    ./package-add-filters.sh ${ADD_FILTER_PARAMS}
fi
