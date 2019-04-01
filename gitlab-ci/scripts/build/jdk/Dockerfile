FROM 172.25.200.9/runner/jdk:v1-alpine
MAINTAINER Wesley <zhengkai.shen@ebianque.cn>

ARG PACKAGE_NAME
ENV PACKAGE_NAME $PACKAGE_NAME

COPY $PACKAGE_NAME/target/$PACKAGE_NAME-1.0.jar /mnt/
