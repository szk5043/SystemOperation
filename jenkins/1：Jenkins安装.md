## 一、Jenkins安装

### 1、Docker方式安装Jenkins

创建相关工作目录

```shell
mkdir -p /opt/deploy/jenkins/jenkins_home    #创建工作目录
chown -R 777 /opt/deploy/jenkins/jenkins_home   #修改权限，否则报错Wrong volume permissions
```

启动容器，并挂在目录

```shell
docker run --name jenkins \
	-p 8080:8080 \
	-p 50000:50000 \
	-v /opt/deploy/jenkins/jenkins_home:/var/jenkins_home \
	jenkins:2.60.3-alpine
```

初始化安装，查看初始密码

```shell
cat /opt/deploy/jenkins/jenkins_home/secrets/initialAdminPassword
```

### 2、手动安装插件

需要pipeline, git, gitlab相关的插件