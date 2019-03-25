## lifesongs LNMP docker deploy
### 1、Basic configure
更改时区、系统语言
```sh
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
date -R
sudo echo 'LANG="en_US.UTF-8"' >> /etc/profile;source /etc/profile
```
kernel性能调优
```sh
cat >> /etc/sysctl.conf<<EOF
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.neigh.default.gc_thresh1=4096
net.ipv4.neigh.default.gc_thresh2=6144
net.ipv4.neigh.default.gc_thresh3=8192
EOF
```
> 数值根据实际环境自行配置，最后执行`sysctl -p`保存配置。

###  2、Install docker && docker-compose
更新ali apt源
```sh
cp /etc/apt/sources.list /etc/apt/sources.list.bak

cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
EOF
```
安装 docker
```sh
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common  -y
#安装包依赖

curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
#安装证书(阿里docker镜像源)

sudo add-apt-repository \
   "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
#安装镜像源(阿里docker镜像源)

sudo apt-get update  
#更新镜像索引

apt-cache madison docker-ce
#查看可安装的版本

apt-get -y install docker-ce=18.06.3~ce~3-0~ubuntu
```
Install docker-compose
```shell
pip install docker-compose
```

### 3、Add data disk
add disk
```shell
parted /dev/vdb
mklabel gpt
mkpart primary 1049K -1
quit
#分区
mkfs -t ext4 /dev/vdb1
#格式化文件系统
mkdir -p /mnt/vdb
#创建挂载目录
vim /etc/fstab
/dev/vdb1 /mnt/vdb ext4 defaults 0 2
#配置开机自启动
```
### 4、配置服务
创建服务目录
```shell
mkdir -p /opt/deploy/docker/{mysql/conf,nginx/{conf,certs},php/conf}
# 创建应用服务目录
mkdir -p /mnt/vdb/data/{mp3,mysql_data,www}
# 创建应用服务数据目录
ln -s /mnt/vdb/data/mysql_data /opt/deploy/docker/mysql/data
ln -s /mnt/vdb/data/mp3 /opt/deploy/docker/nginx/mp3
ln -s /mnt/vdb/data/www /opt/deploy/docker/nginx/www
# 创建应用服务数据目录软链
```
数据库容器初始化脚本
```shell
cat install_db.sh 
#!/bin/bash

echo "please ensure Docker installed; Docker image mysql:5.7.25 pulled from image repository; Backup file dir created; "

MYSQL_VERSION=5.7.25
MYSQL_DOCKER_IMAGE=mysql:$MYSQL_VERSION

MYSQL_CNF_DIR=/opt/deploy/docker/mysql/conf
DB_BACKUP_DIR=/opt/deploy/docker/mysql/backup
DB_DATA_DIR=/opt/deploy/docker/mysql/data

TEST_DATABASE_PORT=3306
DATABASE_PASSWORD='111qqq...^_^'

#echo 'start to prepare dev database'
# 1. stop and remove container
docker ps -a | grep 'lifesongs-mysql' && docker rm -f 'lifesongs-mysql' || true
echo 'stop and remove container lifesongs-mysql successfully...'

# 2. start container
docker run -t -d --name lifesongs-mysql --restart unless-stopped -v $MYSQL_CNF_DIR:/etc/mysql/conf.d -v $DB_DATA_DIR:/var/lib/mysql -p 3306:3306 -e TZ='Asia/Hong_Kong' -e MYSQL_ROOT_PASSWORD="$DATABASE_PASSWORD" $MYSQL_DOCKER_IMAGE
# waiting container to startup
while ! docker exec lifesongs-mysql /usr/bin/mysql -u root --password=$DATABASE_PASSWORD; do sleep 3; done
echo 'start container lifesongs-mysql successfully...'

# 3. restore prod database to dev env
cat $DB_BACKUP_DIR/wordpress.sql | docker exec -i lifesongs-mysql /usr/bin/mysql -u root --password=$DATABASE_PASSWORD
echo 'restore database to dev successfully...'
echo 'done'
```
修改wordpress数据库配置
```shell
vim wp-config.php
define( 'WPCACHEHOME', '/mnt/vdb/data/www/wordpress/wp-content/plugins/wp-super-cache/' );
#修改wordpress插件目录位置

```



