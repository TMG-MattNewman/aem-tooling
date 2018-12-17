#!/usr/bin/env bash

TIMEOUT=1
zipUrl=''
zipUrlSupplied=0
name='content-package'
nameSupplied=0
auth='admin:admin'
packageGroup='my_packages'
outputDir='downloads'

while getopts  "z:n:o:u:v" OPTION
do
    case $OPTION in
        z) zipUrl=$OPTARG; zipUrlSupplied=1;;
        n) name=$OPTARG; nameSupplied=1;;
        o) outputDir=$OPTARG;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ${zipUrlSupplied} -eq 0 || ${nameSupplied} -eq 0 ]]; then
    echo "fullZipUrlSupplied is required for downloading package!"
    exit 1;
fi

# Define a timestamp function
datetime() {
  date '+%Y-%m-%d__%H-%M-%S'
}

# make a directory to store the downloaded zip files
mkdir -p ${outputDir}

# download package and suppress download stats
if [[ ${verbose} -eq 1 ]]; then
    echo "downloading package: curl --silent --fail --show-error --user ${auth} ${zipUrl} > ./${outputDir}/${name}.$(datetime).zip"
fi

curl --silent --fail --show-error --user ${auth} ${zipUrl} > ./${outputDir}/${name}.$(datetime).zip
