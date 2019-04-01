#!/bin/sh

main() {
  build_java_package
  echo password | docker -D login -u admin  --password-stdin $IMAGE_SERVER > /dev/null 2>&1
  echo "*****Harbor Login Succeeded...***** "
  if [ ${SINGLE_SERVICE_NAME} ];then
    build_jdk_image ${SINGLE_SERVICE_NAME}
  elif [ ! ${SINGLE_SERVICE_NAME} ];then
    build_jdk_image discovery              
    build_jdk_image gateway                 
  fi 
}

main "$@"

