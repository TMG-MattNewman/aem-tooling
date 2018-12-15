#!/usr/bin/env bash

DEFAULT_ENV='http://aem-docker-training.aws-preprod.telegraph.co.uk:4502/'
LOCALHOST='http://localhost:4502/'
ROOTPAGE='libs/cq/core/content/welcome.html'
TIMEOUT=2

env=${DEFAULT_ENV}
auth='admin:admin'
operation='copy'
fromProvided=0
toProvided=0

# get input/args:
#   -t = full/path/to/node (required)
#   -d = full/path/to/node (required)
#   -e = env (optional - default to training)
#   -u = username:password (optional - default to admin:admin)
#   -m = move content rather than copying it
#   -l = use localhost as env
#   -v = verbose output

while getopts  "f:t:e:u:clv" OPTION
do
    case $OPTION in
        f) from=$OPTARG; fromProvided=1;;
        t) to=$OPTARG; toProvided=1;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        m) move=1;;
        l) local=1;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

# if both to and from path haven't been provided
if [[ ${fromProvided} -eq 0 || ${toProvided} -eq 0 ]]; then
    echo "Error: either from (-t) or to (-d) arguments not provided."
    exit 1;
fi

# if local flag is there, use localhost
if [[ ${local} ]]; then
    env=${LOCALHOST}
fi

# if copy flag is there, change operation to copy instead of move
if [[ ${move} ]]; then
    operation='move'
fi

fromPath=$(./aem-path-adapter.sh -p ${from} -j)
toPath=$(./aem-path-adapter.sh -p ${to} -j)

fromPath="${fromPath}/par"
toPath="${toPath}/par"

backupFromPath=$(./aem-path-adapter.sh -p ${fromPath} -x)
backupToPath=$(./aem-path-adapter.sh -p ${toPath} -x)

# create backup package
BACKUP_PARAMS="-p ${backupFromPath} -e ${env} -u ${auth} -o hub-moving"
if [[ ${verbose} ]]; then
  BACKUP_PARAMS+=" -v"
fi

if [[ ${verbose} ]]; then
    echo "from=${from}"
    echo "fromPath=${fromPath}"
    echo "backupFromPath=${backupFromPath}"
    echo "to=${to}"
    echo "toPath=${toPath}"
    echo "backupToPath=${backupToPath}"
    echo "env=${env}"
    echo "auth=${auth}"
    echo "move=${move}"
    echo "local=${local}"
fi

# backup both to and from pages ...
./hub-backup.sh ${BACKUP_PARAMS}
# as the last -p param will be the one used, just add it to the end and re-run
BACKUP_PARAMS+=" -p ${backupToPath}"
./hub-backup.sh ${BACKUP_PARAMS}

# now need to delete the target (to) node in case it already exists
curl --silent --fail --show-error -i --output /dev/null --user $auth -F":operation=delete" -F":applyTo=/${backupToPath}/jcr:content/*" ${env}

# move/copy node from from to dest
operationResult=$(curl --silent --user $auth -iL --connect-timeout $TIMEOUT -F:operation=${operation} -F:dest=/${toPath} ${env}${fromPath})
if [[ ! ${operationResult} =~ 201 ]]; then
    echo "failed to move or copy content: curl --user $auth -L --connect-timeout $TIMEOUT -F:operation=${operation} -F:dest=/${toPath} ${env}${fromPath}"
    exit 1;
fi
