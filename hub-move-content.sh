#!/usr/bin/env bash

targetProvided=0
destinationProvided=0

DEFAULT_ENV='http://localhost:4502/'
LOCALHOST='http://localhost:4502/'
ROOTPAGE='libs/cq/core/content/welcome.html'
TIMEOUT=2

INDEX_CONTENT_NODE_TYPE='nt:unstructured'
INDEX_CONTENT_RESOURCE_TYPE='foundation/components/parsys'

env=${DEFAULT_ENV}
auth='admin:admin'

# get input/args:
#   -t = path/to/page (required)
#   -d = path/to/page (required)
#   -e = env (optional - default to training)
#   -u = username:password (optional - default to admin:admin)
#   -l = use localhost as env
#   -v = verbose output


while getopts  "t:d:e:u:lv" OPTION
do
    case $OPTION in
        t) targetPath=$OPTARG; targetProvided=1;;
        d) destinationPage=$OPTARG; destinationProvided=1;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        l) local=1;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

# if only 1 arg, assume its the path
if [[ ${targetProvided} -eq 0 || ${destinationProvided} -eq 0 ]]; then
    echo "Error: either target (-t) or destination (-d) arguments not provided."
    exit 1;
fi

-F:operation=move
