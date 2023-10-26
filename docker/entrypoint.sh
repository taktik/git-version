#!/bin/bash

## Read parameters

while getopts :f: flag
do
    case "${flag}" in
        f) GIT_VERSION_FILE=${OPTARG} ; shift ; shift ;;
		*) ;;
    esac
done

## Import and execute GIT version

source /git-version.sh

if [ "$GIT_VERSION_FILE" != "" ]; then
  git_version "$@" | tee "$GIT_VERSION_FILE"
else
  git_version "$@"
fi
