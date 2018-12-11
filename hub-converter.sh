#!/usr/bin/env bash

DEFAULT_ENV='http://aem-docker-training.aws-preprod.telegraph.co.uk:4502/'
LOCALHOST='http://localhost:4502/'
ROOTPAGE='libs/cq/core/content/welcome.html'
TIMEOUT=2

HUB_RENDERER='telegraph/core/commons/renderers/hubRenderer'
HUB_TEMPLATE='/apps/telegraph/core/commons/templates/hubTemplate'

INDEX_RENDERER='telegraph/core/commons/renderers/indexRenderer'
INDEX_TEMPLATE='/apps/telegraph/core/commons/templates/indexTemplate'

INDEX_CONTENT_NODE_TYPE='nt:unstructured'
INDEX_CONTENT_RESOURCE_TYPE='foundation/components/parsys'

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
        *) exit 1 # illegal option
    esac
done

# if only 1 arg, assume its the path
if [[ $# == 1 ]]; then
    path=$1;
fi

# if path starts with a forward slash, strip it, because one exists at the end of $env
if [[ ${path} =~ ^/ ]]; then
    path="${path:1}"
fi

# if path ends with a forward slash, strip it
if [[ ${path} =~ /$ ]]; then
    path="${path: : -1}"
fi

# if path now only has a forward slash, then it was empty
if [[ ${path} == '/' ]]; then
    echo "path not supplied or invalid"
    exit 1;
fi

# prefix /content/telegraph if not there
if [[ ! ${path} =~ telegraph/ ]]; then
    path=content/telegraph/${path}
fi

# append /jcr:content if not there
if [[ ! ${path} =~ /jcr:content$ ]]; then
    path="${path}/jcr:content"
fi

# if env does not end with a forward slash add one
if [[ ! ${env} =~ /$ ]]; then
    env="${env}/"
fi

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
BACKUP_PARAMS="-p ${path} -e ${env} -u ${auth}"
if [[ ${invert} ]]; then
  BACKUP_PARAMS+=" -i"
fi
if [[ ${verbose} ]]; then
  BACKUP_PARAMS+=" -v"
fi

if [[ ${verbose} ]]; then
    echo "env=${env}"
    echo "path=${path}"
    echo "INDEX_RENDERER=${INDEX_RENDERER}"
    echo "INDEX_TEMPLATE=${INDEX_TEMPLATE}"
    echo "HUB_RENDERER=${HUB_RENDERER}"
    echo "HUB_TEMPLATE=${HUB_TEMPLATE}"
fi

# check access to env using username & password
connectStatus=$(curl --write-out %{http_code} --silent --output /dev/null -I --user $auth -L --connect-timeout $TIMEOUT $env$ROOTPAGE)
if [[ ! "$connectStatus" == "200" ]]; then
    echo "couldn't connect using: curl -L --user $auth $env"
    exit 1;
fi

# check page exists and is a hubTemplate
pageJson=$(curl --silent --user $auth -L --connect-timeout $TIMEOUT $env$path.1.json)
# curl -i --user $auth $env$path
if [[ ! "$pageJson" =~ ${HUB_RENDERER} ]]; then
    echo "page doesn't seem to be a hub page..."
    echo "curl --user $auth -L --connect-timeout $TIMEOUT $env$path.1.json"
    exit 1;
fi

./hub-backup.sh ${BACKUP_PARAMS}

# TODO:
# store nodes seen - where ... google doc?
# post the json response to something that ingests it??
# flag/output new ones


# update the nodes in AEM
updateStatus=$(curl --write-out %{http_code} --silent --output /dev/null -i --data cq:template=$INDEX_TEMPLATE --data sling:resourceType=$INDEX_RENDERER --user $auth -L --connect-timeout $TIMEOUT $env$path)
if [[ ! "$updateStatus" == "200" ]]; then
    echo "failed to update!"
    echo "using: curl -L --user $auth --data cq:template=${INDEX_TEMPLATE} --data sling:resourceType=${INDEX_RENDERER} --connect-timeout $TIMEOUT $env$path"
    exit 1;
fi

# if inverting, then content is already there, don't need to create a new node
if [[ ${invert} ]]; then
    exit 0;
fi

# add content parsys node
addContentNode=$(curl --write-out %{http_code} --silent --output /dev/null -i --data jcr:primaryType=$INDEX_CONTENT_NODE_TYPE --data sling:resourceType=$INDEX_CONTENT_RESOURCE_TYPE --user $auth -L --connect-timeout $TIMEOUT $env$path/par)
if [[ ! "$updateStatus" == "200" ]]; then
    echo "failed to add content node!"
    echo "using: curl -L --user $auth --data jcr:primaryType=${INDEX_CONTENT_NODE_TYPE} --data sling:resourceType=${INDEX_CONTENT_RESOURCE_TYPE} --connect-timeout $TIMEOUT $env$path/par"
    exit 1;
fi
