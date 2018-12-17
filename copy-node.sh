#!/usr/bin/env bash

env=''
auth='admin:admin'
operation='copy'
fromProvided=0
toProvided=0
TIMEOUT=1

# get input/args:
#   -f = full/path/to/node (required)
#   -t = full/path/to/node (required)
#   -e = env (optional - default to training)
#   -u = username:password (optional - default to admin:admin)
#   -m = move content rather than copying it
#   -v = verbose output

while getopts  "f:t:e:u:mv" OPTION
do
    case $OPTION in
        f) from=$OPTARG; fromProvided=1;;
        t) to=$OPTARG; toProvided=1;;
        e) env=$OPTARG;;
        u) auth=$OPTARG;;
        m) move=1;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done

# if both to and from path haven't been provided
if [[ ${fromProvided} -eq 0 || ${toProvided} -eq 0 ]]; then
    echo "Error: either from (-t) or to (-d) arguments not provided."
    exit 1;
fi

# if copy flag is there, change operation to copy instead of move
if [[ ${move} ]]; then
    operation='move'
fi

if [[ ${verbose} ]]; then
    echo "curl --silent --user $auth -iL --connect-timeout $TIMEOUT -F:operation=${operation} -F:dest=${to} ${env}${from}"
fi

# move/copy node from from to dest
operationResult=$(curl --silent --user $auth -iL --connect-timeout $TIMEOUT -F:operation=${operation} -F:dest=${to} ${env}${from})
if [[ ! ${operationResult} =~ 201 ]]; then
    echo "failed to move or copy content: curl --user $auth -iL --connect-timeout $TIMEOUT -F:operation=${operation} -F:dest=${to} ${env}${from}"
    exit 1;
fi
