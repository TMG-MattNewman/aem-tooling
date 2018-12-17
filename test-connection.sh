#!/usr/bin/env bash

ROOTPAGE='libs/cq/core/content/welcome.html'
TIMEOUT=1
env='http://localhost:4502/'
auth='admin:admin'

while getopts  "e:u:v" OPTION
do
    case $OPTION in
        e) env=$OPTARG; envProvided=1;;
        u) auth=$OPTARG; authProvided=1;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

# if either env or auth haven't been provided
if [[ ${envProvided} -eq 0 || ${authProvided} -eq 0 ]]; then
    echo "Error: either env (-e) or auth (-u) not provided."
    exit 1;
fi

# check access to env using username & password
connectStatus=$(curl --write-out %{http_code} --silent --output /dev/null -I --user $auth -L --connect-timeout $TIMEOUT $env$ROOTPAGE)
if [[ ! "$connectStatus" == "200" ]]; then
    echo "couldn't connect to aem: curl -IL --connect-timeout $TIMEOUT --user $auth $env$ROOTPAGE"
    exit 1;
fi
