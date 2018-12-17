#!/usr/bin/env bash

TIMEOUT=1
INDEX_CONTENT_NODE_TYPE='nt:unstructured'
INDEX_CONTENT_RESOURCE_TYPE='foundation/components/parsys'

path=''
pathSupplied=0
auth='admin:admin'

while getopts  "p:e:u:v" OPTION
do
    case $OPTION in
        p) path=$OPTARG; pathSupplied=1;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

if [[ ${pathSupplied} -eq 0 ]]; then
    echo "path is required for adding a node to a page!"
    exit 1;
fi

if [[ ${verbose} -eq 1 ]]; then
    echo "adding content node: curl --silent --data jcr:primaryType=$INDEX_CONTENT_NODE_TYPE --data sling:resourceType=$INDEX_CONTENT_RESOURCE_TYPE --user $auth -iL --connect-timeout $TIMEOUT $env$path/par"
fi

# add content parsys node
addContentNode=$(curl --write-out %{http_code} --silent --output /dev/null --data jcr:primaryType=$INDEX_CONTENT_NODE_TYPE --data sling:resourceType=$INDEX_CONTENT_RESOURCE_TYPE --user $auth -iL --connect-timeout $TIMEOUT $env$path/par)
if [[ ! "$addContentNode" == "200" ]]; then
    echo "failed to add content node! using: curl -iL --user $auth --data jcr:primaryType=${INDEX_CONTENT_NODE_TYPE} --data sling:resourceType=${INDEX_CONTENT_RESOURCE_TYPE} --connect-timeout $TIMEOUT $env$path/par"
    exit 1;
fi
