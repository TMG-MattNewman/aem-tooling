#!/usr/bin/env bash

DEFAULT_ENV='http://aem-docker-training.aws-preprod.telegraph.co.uk:4502/'
LOCALHOST='http://localhost:4502/'
ROOTPAGE='libs/cq/core/content/welcome.html'
TIMEOUT=1

HUB_RENDERER='telegraph/core/commons/renderers/hubRenderer'
HUB_TEMPLATE='/apps/telegraph/core/commons/templates/hubTemplate'

INDEX_RENDERER='telegraph/core/commons/renderers/indexRenderer'
INDEX_TEMPLATE='/apps/telegraph/core/commons/templates/indexTemplate'

INDEX_CONTENT_NODE_TYPE='nt:unstructured'
INDEX_CONTENT_RESOURCE_TYPE='foundation/components/parsys'

PATH_PARAMS=''

path=''
env=${DEFAULT_ENV}
auth='admin:admin'

# get input/args:
#   -p = path/to/page (required)
#   -e = env (optional - default to training)
#   -u = username:password (optional - default to admin:admin)
#   -l = use localhost as env
#   -i = invert process (change index back to hub)
#   -v = verbose output


while getopts  "p:e:u:ilv" OPTION
do
    case $OPTION in
        p) path=$OPTARG;;
        e) env=$OPTARG;;
        l) local=1;;
        u) auth=$OPTARG;;
        i) invert=1;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

# if only 1 arg, assume its the path
if [[ $# == 1 ]]; then
    path=$1;
fi

# if env does not end with a forward slash add one
if [[ ! ${env} =~ /$ ]]; then
    env="${env}/"
fi

# get/setup the path
PATH_PARAMS+="-p ${path} -j"
path=$(./path-manipulation.sh ${PATH_PARAMS})

# if local flag is there, use localhost
if [[ ${local} ]]; then
    env=${LOCALHOST}
fi

# if you want to switch back
if [[ ${invert} ]]; then
    tempRenderer=${INDEX_RENDERER}
    tempTemplate=${INDEX_TEMPLATE}
    INDEX_RENDERER=${HUB_RENDERER}
    INDEX_TEMPLATE=${HUB_TEMPLATE}
    HUB_RENDERER=${tempRenderer}
    HUB_TEMPLATE=${tempTemplate}
fi

# create backup package
BACKUP_PARAMS="-p ${path} -e ${env} -u ${auth} -c -a -b -d"

if [[ ${verbose} ]]; then
    BACKUP_PARAMS+=" -v"
    echo "env=${env}"
    echo "path=${path}"
    echo "INDEX_RENDERER=${INDEX_RENDERER}"
    echo "INDEX_TEMPLATE=${INDEX_TEMPLATE}"
    echo "HUB_RENDERER=${HUB_RENDERER}"
    echo "HUB_TEMPLATE=${HUB_TEMPLATE}"
fi

./test-connection.sh -e ${env} -u ${auth} || exit 1;

# check page exists and is a hubTemplate
pageJson=$(curl --silent --user $auth -L --connect-timeout $TIMEOUT $env$path.1.json)
# curl -i --user $auth $env$path
if [[ ! "$pageJson" =~ ${HUB_RENDERER} ]]; then
    echo "page doesn't seem to be a hub page... $path ::curl --user $auth -L --connect-timeout $TIMEOUT $env$path.1.json"
    exit 1;
fi


# create/download backup package
./package.sh ${BACKUP_PARAMS}


# TODO:
# store nodes seen - where ... google doc?
# post the json response to something that ingests it??
# flag/output new ones


# update the nodes in AEM
updateStatus=$(curl --write-out %{http_code} --silent --output /dev/null -i --data cq:template=$INDEX_TEMPLATE --data sling:resourceType=$INDEX_RENDERER --user $auth -L --connect-timeout $TIMEOUT $env$path)
if [[ ! "$updateStatus" == "200" ]]; then
    echo "failed to update! using: curl -L --user $auth --data cq:template=${INDEX_TEMPLATE} --data sling:resourceType=${INDEX_RENDERER} --connect-timeout $TIMEOUT $env$path"
    exit 1;
fi

# if inverting, then content is already there, don't need to create a new node
if [[ ${invert} ]]; then
    exit 0;
fi

# add content parsys node
./add-content-node.sh -p ${path} -e ${env} -${auth}
