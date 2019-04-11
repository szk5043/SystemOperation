## gitlab-ci.yml配置简介

GitLab CI/CD功能基于每个项目根目录下的`.gitlab-ci.yml`配置文件来实现。


> 注意：`.gitlab-ci.yml`是一个`YAML`格式文件，因此，缩进应该使用空格，而不要使用`tab`。

简单案例分析：

```yaml
stages:
  - build
  - test
  - deploy

job 1:
  stage: build
  script:
    - mkdir .public
    - cp -r * .public
    - mv .public public
  artifacts:
    paths:
      - public
  only:
    - master

job 2:
  stage: test
  image: ruby:2.1 
  script: make test

job 4:
  stage: deploy
  when: manual
  script: make deploy
```

解释：

-  `stages`：`关键字`，`可选`，用于自定义任务流程。若缺失，默认流程为：`build > test > deploy`；

- `job 1`：任务名称，可自由定义，可包含空格； 
  -  `stage`：`关键字`，用于指定任务在什么`stage`运行；
  -  `script`：`关键字`，按顺序撰写该任务的`shell`脚本；
  -  `artifacts`：`关键字`，用于指定该任务执行完毕后，哪些目录或文件需要保留。所有内容会打包成一个`zip`压缩包，供下载或后续任务使用；
  -  `only`：`关键字`，用于指定以来的代码`分支`；
  -  `image`：`关键字`，`可选`，可制定一个`docker`镜像，用于执行该任务。若缺失，使用`Runner`配置配置；
  -  `when`：`关键字`， `可选`，用于指定任务触发的条件。若缺失，一旦有代码提交到该分支就会自动运行。可设置为手动触发；

配置文件还包含其他很多强大的功能，具体内容请参考[官方文档](https://docs.gitlab.com/ee/ci/yaml/README.html)。后续文章会结合案例说明，这里仅做简单介绍。
