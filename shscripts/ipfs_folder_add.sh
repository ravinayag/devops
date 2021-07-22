#!/usr/bin/env bash

set -e

if [[ -z $1 ]]; then
    echo "usage: $0 <provide-the-path, ex : /home/test/folder   >"
    exit 1
fi

echo -e "\e[32m>> Copying the files from the directory... {$1} \e[0m"

for file in $1/*
do
           echo
           echo -e "\e[32m>> Publishing files... $file to IPFS...\e[0m"
           hash=`cat $file | ipfs add -q`
           echo "http://127.0.0.1:8001/ipfs/$hash"
           echo Filename: $file , IPFS Hash: $hash >> ipfs_bulkadd.log
done
