#!/bin/sh

##########start & stop mysql container
########### database ###########
start_db() {
  echo "installing uyizhan $ENV db..."
  ssh $REMOTE_MS_SERVER "/bin/bash /opt/deploy/scripts/start_db.sh "
  echo "uyizhan $ENV db is ready."
}

sync_db() {
  echo "sync uyizhan $ENV db from $ENV db"
  ssh $REMOTE_MS_SERVER "/bin/bash /opt/deploy/scripts/sync_db.sh "
  echo "uyizhan $ENV db is sync."
}

recovery_db() {
  echo "recovery uyizhan $ENV db from $ENV db"
  ssh $REMOTE_MS_SERVER "/bin/bash /opt/deploy/scripts/recovery_db.sh "
  echo "uyizhan $ENV db is recovery."
}



deply_mysql(){
  if [ $ENV == "test" ];then
    if [ $DATA == "recovery" ];then
      recovery_db
    elif [ $DATA == "norecovery" ];then
      echo "databases not no recovery..."
    fi
  elif [ $ENV == "dev" ]; then
    if [ $DATA == "sync" ];then
      sync_db
    elif [ $DATA == "nosync" ];then
      echo "databases not sync..."
    fi
  fi
}
