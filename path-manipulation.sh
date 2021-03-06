#!/usr/bin/env bash

# get input/args:
#   -p = path/to/thing (required)
#   -j = append /jcr:content
#   -v = verbose output

while getopts  "p:jxsv" OPTION
do
    case $OPTION in
        p) path=$OPTARG;;
        j) appendJcrContent=1;;
        x) extractPagePath=1;;
        s) stripPagePath=1;;
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

# strip path back to just jcr:content (useful for backing up whole pages when moving content nodes)
if [[ ${extractPagePath} && ${path} =~ (^.*/jcr:content)/.+$ ]]; then
    path=${BASH_REMATCH[1]}
fi

# strip path back to remove /content/telegraph and jcr:content
if [[ ${stripPagePath} && ${path} =~ content ]]; then
    path=${path//content\/telegraph\/}
    path=${path//\/jcr:content/}
fi

echo "$path"
