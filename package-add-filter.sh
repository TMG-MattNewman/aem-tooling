#!/usr/bin/env bash

CRX_UPDATE_PATH='crx/packmgr/update.jsp'
TIMEOUT=1
url=''
path=''
pathSupplied=0
name=''
nameSupplied=0
auth='admin:admin'
packageGroup='my_packages'
packageBasePath="/etc/packages/"

while getopts  "p:n:g:e:u:v" OPTION
do
    case $OPTION in
        p) path=$OPTARG; pathSupplied=1;;
        n) packageName=$OPTARG; nameSupplied=1;;
        g) packageGroup=$OPTARG;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ${pathSupplied} -eq 0 ]]; then
    echo "filter path is required for adding a filter to a package!"
    exit 1;
fi

if [[ ${nameSupplied} -eq 0 ]]; then
    packageName=${path}
fi

# if path starts with a forward slash, strip it, because one exists at the end of $env
if [[ ! ${env} =~ /$ ]]; then
    env="${env}/"
fi
if [[ ${packageName} =~ ^/ ]]; then
    packageName="${packageName:1}"
fi

packagePath="/etc/packages/${packageGroup}/"
pagePath=$(./path-manipulation.sh -p ${path} -j) # add all parts of the path needed for a page level filter
truncatedPackageName=$(./path-manipulation.sh -p ${packageName} -s) # strip package name down to minimum useful
packageName=${truncatedPackageName//\//-} # replace \ with -
packageZip=${packagePath}${packageName}.zip
url=${env}${CRX_UPDATE_PATH}

if [[ ${verbose} ]]; then
    echo "packageName=${packageName}"
    echo "group=${packageGroup}"
    echo "packageZip=${packageZip}"
    echo "url=${url}"
fi

# add filters
if [[ ${verbose} ]]; then
    echo "adding filters: \
    curl -i --connect-timeout $TIMEOUT \
    --user ${auth} \
    -X POST ${url} \
    -F path=${packageZip} \
    -F packageName=${packageName} \
    -F groupName=${packageGroup} \
    -F filter=\"[{\"root\" : \"/${pagePath}\", \"rules\": []}]\" \
    -F '_charset_=UTF-8'"
fi
addFilters=$(curl --write-out %{http_code} --silent --output /dev/null -i \
    --connect-timeout ${TIMEOUT} \
    --user ${auth} \
    -X POST ${url} \
    -F path=${packageZip} \
    -F packageName=${packageName} \
    -F groupName=${packageGroup} \
    -F filter="[ { \"root\" : \"/${pagePath}\", \"rules\": [] } ]" \
    -F '_charset_=UTF-8')
if [[ ! "$addFilters" == "200" ]]; then
    echo "failed to add filter!"
    exit 1;
fi

# e.g: curl -i --connect-timeout 1     --user admin:admin     -X POST http://localhost:4502/crx/packmgr/update.jsp     -F path=/etc/packages/my_packages/test.zip     -F packageName=test     -F groupName=my_packages     -F filter="[{"root" : "/content/telegraph/test/jcr:content", "rules": []}]"     -F '_charset_=UTF-8'
