#!/bin/sh
########### build backend java packages
# echo "`pwd`" = /builds/uyz  
build_java_package() {
  echo "build backend packages start..."
  ln -s /share/env/java/repository /root/.m2/repository
  mvn clean package -Dmaven.test.skip=true
  echo -e "\033[32m $NAME \033[0m build done."
}

#############build jdk image  with jar packages###############
# echo "`pwd`"  = /builds/uyz/uyizhan
build_jdk_image() {
  local NAME=$1
  echo "build $NAME image start ..."
  docker image build --build-arg PACKAGE_NAME=$NAME -f /share/script/build/jdk/Dockerfile -t $IMAGE_SERVER/be/$NAME:$IMAGE_VERSION .  > /dev/null
  docker push $IMAGE_SERVER/be/$NAME:$IMAGE_VERSION  > /dev/null 
  echo -e "push \033[32m $NAME:$IMAGE_VERSION \033[0m image succeed..."
  echo "---------------------"  
}

########### build frontend  
# echo "`pwd`" = /builds/uyz/admin-fe,/builds/uyz/uyz-he
#
build_fe_package() {
  echo "build $NAME package start ..."
  rm -rf node_modules
  rm -rf dist/*
  cnpm install
  cnpm run build-$ENV
  echo -e "\033[32m $NAME \033[0m build done."
}

#############build nginx image  with admin-fe packages###############
# echo "`pwd`" = /builds/uyz/admin-fe
build_nginx_image() {
  local NAME=$1
  echo "build $NAME image start ..."
  docker image build --build-arg PACKAGE_NAME=$NAME -f /share/script/build/nginx/Dockerfile -t $IMAGE_SERVER/fe/$NAME:$IMAGE_VERSION . > /dev/null
  docker push $IMAGE_SERVER/fe/$NAME:$IMAGE_VERSION    > /dev/null 
  echo -e "push \033[32m $NAME:$IMAGE_VERSION \033[0m image succeed..."
}

###########copy & remove configure
copy_config(){
  echo "copy env config to $REMOTE_SERVER"
  write_env_file
  if [[ $ENV == 'staging' || $ENV == 'prod' ]];then
    write_reverse_config
  fi
  #write env,image server,image version to docker compose env file
  ssh root@$REMOTE_SERVER "rm -rf /opt/deploy/*"
  # remove remote server configure
  scp -r /share/env_conf/$ENV/* root@$REMOTE_SERVER:/opt/deploy
  # copy env configure to remote server
  echo "copy done..."
}

copy_voting_config(){
  echo "copy env config to $VOTING_SERVER"
  write_env_file
  write_reverse_config
  ssh root@$VOTING_SERVER "rm -rf /opt/deploy/*"
  scp -r /share/env_conf/$ENV/voting/* root@$VOTING_SERVER:/opt/deploy
   # copy env configure to voting server  
}
##########start & stop service container
########### start container at remote server
stop_container(){
  local NAME=$1	
  echo -e "stop \033[32m $NAME \033[0m container with $REMOTE_SERVER"	
  ssh root@$REMOTE_SERVER "cd /opt/deploy/docker_compose/$NAME && docker-compose down && docker network prune -f && docker image prune -af "
  echo "start done..."
}

start_container(){
  local NAME=$1	
  echo -e "start \033[32m $NAME \033[0m container with $REMOTE_SERVER"	
  ssh root@$REMOTE_SERVER "cd /opt/deploy/docker_compose/$NAME && docker-compose up -d --force-recreate"
  echo "start done..."
}

########### start container at voting server

start_voting_container(){
  local NAME=$1	
  echo -e "start \033[32m $NAME \033[0m container with $VOTING_SERVER"	
  ssh root@$VOTING_SERVER "/bin/bash /opt/deploy/script/start_voting_service.sh $NAME $ENV $VOTING_NODE $IMAGE_VERSION"
  echo "start done..."
}

##########write remote server address to nginx reverse configure 
write_reverse_config() {
  echo "write $REMOTE_SERVER to nginx reverse-proxy configure"
  sed -i "s/[0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}/${REMOTE_SERVER}/g" /share/env_conf/$ENV/configure/nginx-reverse-proxy/conf/*.conf
  if [[ $ENV == "staging" || $ENV == "prod" ]];then
    sed -i "s/[0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}/${VOTING_SERVER}/g" /share/env_conf/$ENV/voting/configure/nginx-reverse-proxy/conf/*.conf
    echo "write done ..."
  fi
}

#########write env,image server,image version to docker compose env file 
write_env_file() {
  echo "write $ENV,$IMAGE_SERVER,$IMAGE_VERSION,$FLUENTD_ADDRESS to docker compose env file"
  if [[ $ENV == "dev" || $ENV == "test" ]] ;then
    FLUENTD_ADDRESS="172.25.10.9:24224"
  elif [[ $ENV == "staging" || $ENV == "prod" ]] ;then
    if [ $NAME == "uyizhan-backend" ] ;then
      FLUENTD_ADDRESS="172.20.30.212:24224"
    elif [[ $NAME == "uyizhan-admin-fe" || $NAME == "uyizhan-h5-fe" ]] ;then
      FLUENTD_ADDRESS="172.20.30.211:24224"
    fi
  fi
  
echo -e "ENV=$ENV\nIMAGE_SERVER=$IMAGE_SERVER\nIMAGE_VERSION=$IMAGE_VERSION\nFLUENTD_ADDRESS=$FLUENTD_ADDRESS\nNODE=$NODE" > /share/env_conf/$ENV/docker_compose/$NAME/.env
echo -e "NODE=$NODE" > /share/env_conf/$ENV/docker_compose/nginx-reverse-proxy/.env

if [[ $ENV == "staging" || $ENV == "prod" ]] ;then
  if [ $NODE == "node1" ] ;then
  	VOTING_NODE="voting1"
  elif [ $NODE == "node2" ] ;then
  	VOTING_NODE="voting2"
  fi
  echo -e "ENV=$ENV\nIMAGE_SERVER=$IMAGE_SERVER\nIMAGE_VERSION=$IMAGE_VERSION\nFLUENTD_ADDRESS=$FLUENTD_ADDRESS\nVOTING_NODE=$VOTING_NODE" > /share/env_conf/$ENV/voting/docker_compose/uyizhan-backend/.env
  echo -e "VOTING_NODE=$VOTING_NODE" > /share/env_conf/$ENV/voting/docker_compose/nginx-reverse-proxy/.env
fi	  
}

###########################backend service checking ###########################################
service_check() {
  CHECK_URL=$REMOTE_SERVER':8100/station/banners/2' 
  START_TIME=$(date +%s) 
  echo "service $CHECK_URL is checking... "
  sleep 150

  while :
    do    
      HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' ${CHECK_URL})
      if [ $HTTP_CODE == '200' ];then
        echo -e "service $CHECK_URL is \033[32m ${HTTP_CODE} \033[0m"
        return ${HTTP_CODE}
      fi

      sleep 5

      END_TIME=$(date +%s)
      USE_TIME=$(( $END_TIME - $START_TIME ))

      if [ $USE_TIME -ge 600 ];then
	echo "service start is use time ${USE_TIME}s ..."
        echo "time out..."
        exit 1
      fi

  done
}

###########################confugre nginx reverse proxy server###########################################
configure_reverse_proxy () {
  service_check 
  echo -e "configure api server -----> \033[32m ${REMOTE_SERVER} \033[0m"  
  if [ ${HTTP_CODE} == '200' ];then
    ssh root@$REVERSE_PROXY_SERVER "sed -i 's/[0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}/${REMOTE_SERVER}/g' /opt/deploy/configure/nginx-reverse-proxy/conf/api.conf && docker restart uyizhan-reverse-proxy"
  fi
}

