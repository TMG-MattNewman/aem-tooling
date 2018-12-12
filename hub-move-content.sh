#!/usr/bin/env bash

fromProvided=0
toProvided=0

DEFAULT_ENV='http://localhost:4502/'
LOCALHOST='http://localhost:4502/'
ROOTPAGE='libs/cq/core/content/welcome.html'
TIMEOUT=2

env=${DEFAULT_ENV}
auth='admin:admin'
operation='move'

# get input/args:
#   -t = path/to/page (required)
#   -d = path/to/page (required)
#   -e = env (optional - default to training)
#   -u = username:password (optional - default to admin:admin)
#   -c = copy content rather than moving it
#   -l = use localhost as env
#   -v = verbose output


while getopts  "f:t:e:u:clv" OPTION
do
    case $OPTION in
        f) from=$OPTARG; fromProvided=1;;
        t) to=$OPTARG; toProvided=1;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        c) copy=1;;
        l) local=1;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

# if only 1 arg, assume its the path
if [[ ${fromProvided} -eq 0 || ${toProvided} -eq 0 ]]; then
    echo "Error: either from (-t) or to (-d) arguments not provided."
    exit 1;
fi

# if local flag is there, use localhost
if [[ ${local} ]]; then
    env=${LOCALHOST}
fi

# if copy flag is there, change operation to copy instead of move
if [[ ${copy} ]]; then
    operation='copy'
fi

# create backup package
BACKUP_PARAMS="-p ${from} -e ${env} -u ${auth} -t content-moving"
if [[ ${verbose} ]]; then
  BACKUP_PARAMS+=" -v"
fi

if [[ ${verbose} ]]; then
    echo "from=${from}"
    echo "to=${to}"
    echo "env=${env}"
    echo "auth=${auth}"
    echo "copy=${copy}"
    echo "local=${local}"
fi

# backup both to and from pages ...
./hub-backup.sh ${BACKUP_PARAMS}
# as the last -p param will be the one used, just add it to the end and re-run
BACKUP_PARAMS+=" -p ${to}"
./hub-backup.sh ${BACKUP_PARAMS}

# now need to delete from node in case it already exists
curl -X DELETE --user $auth ${env}${to}

# now need to add a forward slash to 'to'
if [[ ! ${to} =~ ^/ ]]; then
    to="/${to}"
fi

# move/copy node from from to dest
operationResult=$(curl --user $auth -iL --connect-timeout $TIMEOUT -F:operation=${operation} -F:dest=${to} ${env}${from})
if [[ ! ${operationResult} =~ 201 ]]; then
    echo "failed to move or copy content: curl --user $auth -L --connect-timeout $TIMEOUT -F:operation=${operation} -F:dest=${to} ${env}${from}"
    exit 1;
fi
