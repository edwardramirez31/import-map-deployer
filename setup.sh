#!/bin/bash

re=^[A-Za-z_-]+.json$

jsonFile=""
while ! [[ "${jsonFile?}" =~ ${re} ]]
do
  read -p "🔷 Enter the file name where import map JSON is stored in S3 (import-map.json): " jsonFile
done

re=^[A-Za-z0-9_-]+$
urlRegex=^https\.\S*
environments=""
read -p "🔷 Enter the environments separated by comma (EX: prod,dev,staging): " environments

IFS=, read -a ip1 <<< "$environments"
for i in "${ip1[@]}"; do
    envBucketName=""
    while ! [[ "${envBucketName?}" =~ ${re} ]]
    do
      read -p "🔷 Enter the $i environment S3 bucket name: " envBucketName
    done
    resourceArn="arn:aws:s3:::$envBucketName/$jsonFile"
    bucketLocation="s3://$envBucketName/$jsonFile"
    newValue="{ '"${i}"' : '"${bucketLocation}"'}"
    cat <<< $(jq ".locations += { \"$i\" : \"$bucketLocation\"}" config.json) > config.json
    urlSafeList=""
    while ! [[ "${urlSafeList?}" =~ ${urlRegex} ]]
    do
      read -p "🔷 Enter the $i environment url that you use to get import map file (EX: https://zxfwe23sd.cloudfront.net/): " urlSafeList
    done
    cat <<< $(jq ".urlSafeList += [\"$urlSafeList\"]" config.json) > config.json
    sed -i '25i\\t\t\t\t\t\t- "'$resourceArn'"' serverless.yml
done
