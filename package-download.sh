#!/usr/bin/env bash

PACKAGE_MANAGER='crx/packmgr/index.jsp'

outputDir='downloads'
packageName=''
pathSupplied=0
outputDirSupplied=0
packageGroup='my_packages'
env='http://localhost:4502/'
auth='admin:admin'

while getopts  "p:o:g:e:u:v" OPTION
do
    case $OPTION in
        p) packageName=$OPTARG; packageNameSupplied=1;;
        o) outputDir=$OPTARG;;
        g) packageGroup=$OPTARG;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ! ${packageNameSupplied} ]]; then
    echo "packageName is a required parameter for downloading a package!"
    exit 1;
fi

# Define a timestamp function
datetime() {
  date '+%Y-%m-%d__%H-%M-%S'
}

# make a directory to store the downloaded zip files
mkdir -p ${outputDir}

# download package and suppress download stats
if [[ ${verbose} ]]; then
    echo "downloading package: curl --silent --fail --show-error --user ${auth} ${env}etc/packages/${packageGroup}/${packageName}.zip > ./${outputDir}/${packageName}.$(datetime).zip"
fi

curl --silent --fail --show-error --user ${auth} ${env}etc/packages/${packageGroup}/${packageName}.zip > ./${outputDir}/${packageName}.$(datetime).zip
