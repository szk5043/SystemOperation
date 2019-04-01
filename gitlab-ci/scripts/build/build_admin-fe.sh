#!/bin/sh

main(){
  build_fe_package
  echo password | docker -D login -u admin  --password-stdin $IMAGE_SERVER > /dev/null 2>&1
  echo "*****Harbor Login Succeeded...***** "
  build_nginx_image admin-fe
  }

main "$@"
