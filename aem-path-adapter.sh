#!/usr/bin/env bash

# get input/args:
#   -p = path/to/thing (required)
#   -j = append /jcr:content
#   -v = verbose output


while getopts  "p:jv" OPTION
do
    case $OPTION in
        p) path=$OPTARG;;
        j) appendJcrContent=1;;
        v) verbose=1;;
        *) exit 1;; # illegal option
    esac
done


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
if [[ ${appendJcrContent} && ! ${path} =~ /jcr:content$ ]]; then
    path="${path}/jcr:content"
fi

echo "$path"
