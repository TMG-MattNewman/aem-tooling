#!/usr/bin/env bash

LOCALHOST='http://localhost:4502/'
TIMEOUT=2
env='http://aem-docker-training.aws-preprod.telegraph.co.uk:4502/'
auth='admin:admin'
operation='copy'
fromProvided=0
toProvided=0

# get input/args:
#   -f = full/path/to/node (required)
#   -t = full/path/to/node (required)
#   -e = env (optional - default to training)
#   -u = username:password (optional - default to admin:admin)
#   -d = content being moved is from a duplicate page of the original
#   -m = move content rather than copying it
#   -l = use localhost as env
#   -v = verbose output

while getopts  "f:t:e:u:dmlv" OPTION
do
    case $OPTION in
        f) from=$OPTARG; fromProvided=1;;
        t) to=$OPTARG; toProvided=1;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        d) fromDuplicate=1;;
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

if [[ ${fromDuplicate} ]]; then
    from=${from/\//2/}

    # if 2/ isn't present then its probably a top-level directory so add 2 at the end
    if [[ ! ${from} =~ 2/ ]]; then
        from+=2
    fi
fi

fromPath=$(./path-manipulation.sh -p ${from} -j)
toPath=$(./path-manipulation.sh -p ${to} -j)

fromPath="${fromPath}/par"
toPath="${toPath}/par"

backupFromPath=$(./path-manipulation.sh -p ${fromPath} -x)
backupToPath=$(./path-manipulation.sh -p ${toPath} -x)

# create backup package
BACKUP_PARAMS="-p ${backupFromPath} -e ${env} -u ${auth} -o hub-moving"
MOVE_PARAMS="-u ${auth} -e ${env} -f ${fromPath} -t /${toPath}"
DELETE_PARAMS="-u $auth -e ${env} -p /${backupToPath}/*"

if [[ ${verbose} ]]; then
    MOVE_PARAMS+=" -v"
    BACKUP_PARAMS+=" -v"
    DELETE_PARAMS+=" -v"
    echo "fromPath=${fromPath}"
    echo "backupFromPath=${backupFromPath}"
    echo "toPath=${toPath}"
    echo "backupToPath=${backupToPath}"
    echo "BACKUP_PARAMS=${BACKUP_PARAMS}"
    echo "MOVE_PARAMS=${MOVE_PARAMS}"
    echo "DELETE_PARAMS=${DELETE_PARAMS}"
fi

# backup both to and from pages ...
#./hub-backup.sh ${BACKUP_PARAMS}
# as the last -p param will be the one used, just add it to the end and re-run
#BACKUP_PARAMS+=" -p ${backupToPath}"
#./hub-backup.sh ${BACKUP_PARAMS}

# now need to delete the target (to) node in case it already exists
./delete-node.sh ${DELETE_PARAMS}

# move/copy node from from to dest
./copy-node.sh ${MOVE_PARAMS}
