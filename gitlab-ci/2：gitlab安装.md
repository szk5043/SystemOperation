

##  GitLab安装

### 创建gitlab工作目录
```shell
mkdir -p /opt/deploy/docker/gitlab/{config,logs}  
#创建gitlab工作目录
mkdir -p /mnt/vdc/gitlab_data/backups
ln -s /mnt/vdc/gitlab_data /opt/deploy/docker/gitlab/data
#将gitlab数据目录软链到另外一块磁盘
```

### 启动gitlab容器 
```shell
docker run --detach \
 --hostname gitlab \
 --publish 30080:80 \
 --publish 30022:22 \
 --name gitlab \
 --restart always \
 --volume /opt/deploy/docker/gitlab/config:/etc/gitlab \
 --volume /opt/deploy/docker/gitlab/logs:/var/log/gitlab \
 --volume /opt/deploy/docker/gitlab/data:/var/opt/gitlab \
 gitlab/gitlab-ce:10.7.3-ce.0
 #将30080和30022映射到宿主机，通过Nginx反向代理将80和22端口暴露出去
```
### 修改访问URL和项目URL
```shell
vim /opt/deploy/docker/gitlab/config/gitlab.rb
external_url 'http://gitlab.xxx.com'

vim /opt/deploy/docker/gitlab/data/gitlab-rails/etc/gitlab.yml
  ## GitLab settings
  gitlab:
    ## Web server settings (note: host is the FQDN, do not include http://)
    host: gitlab.xxx.com
    port: 80
    https: false
```

### GitLab数据备份及恢复
```shell
docker exec -t gitlab gitlab-rake gitlab:backup:create
#创建gitlab备份，gitlab-rake不会备份配置文件
tar zcvf gitlab_config.tar.gz /opt/deploy/docker/gitlab/config
#备份gitlab配置文件，文件目录在于您的映射目录
```
```shell
docker exec -it gitlab gitlab-rake gitlab:backup:restore  
#从某个备份文件恢复，文件路径默认一定是/var/opt/gitlab/backups，也就是/opt/deploy/docker/gitlab/data/backups
```

[文档：gitlab备份与恢复](https://docs.gitlab.com/ee/raketasks/backup_restore.html)  
[文档：gitlab docker install](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/docker/README.md)