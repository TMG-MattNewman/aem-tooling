#!/usr/bin/env bash

# add content parsys node
addContentNode=$(curl --write-out %{http_code} --silent --output /dev/null -i --data jcr:primaryType=$INDEX_CONTENT_NODE_TYPE --data sling:resourceType=$INDEX_CONTENT_RESOURCE_TYPE --user $auth -L --connect-timeout $TIMEOUT $env$path/par)
if [[ ! "$updateStatus" == "200" ]]; then
    echo "failed to add content node! using: curl -L --user $auth --data jcr:primaryType=${INDEX_CONTENT_NODE_TYPE} --data sling:resourceType=${INDEX_CONTENT_RESOURCE_TYPE} --connect-timeout $TIMEOUT $env$path/par"
    exit 1;
fi
