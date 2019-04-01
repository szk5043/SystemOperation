#!/bin/sh

# job name format: name - env - node
#                  $1        $2    $3   $4    $5             $6
#         uyizhan-backend    -    test  -   node|nosync single_service_name

####### configure global variable  
export NAME=$1
export ENV=$3
export DATA=$5
export NODE=$5
export SINGLE_SERVICE_NAME=$6
export IMAGE_SERVER='172.25.200.9'
export PACKAGE_VERSION='1.0'

if [[ $ENV == "dev" || $ENV == "test" ]];then
  IMAGE_VERSION="latest"
elif [[ $ENV == "staging" || $ENV == "prod" ]];then
  export IMAGE_VERSION=$IMAGE_VERSION
fi

######## Execute different environment scripts
. /share/script/env/$ENV/bin.sh

