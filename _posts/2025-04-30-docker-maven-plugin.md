---
layout:     post
title:      "Java笔记-构建springboot容器制品"
subtitle:   "Java"
date:       2025-04-30
author:     "博海"
header-img: "img/post-white-room.png"
tags:
- Java
---

## 前言介绍

本文介绍如何通过docker-maven-plugin插件把Springboot项目构建成docker镜像，该插件是由Spotify公司开发并开源，Java boys可以通过简单的引入即可完成将项目构建为Docker制品。

文中所使用到的软件版本：

```shell
- Docker 27.5.1
- Java 1.8.0_441
- Maven 3.3.9
- docker-maven-plugin 0.4.10
```

## 引入插件

在maven的settings.xml配置中，加入docker registry镜像仓库的信息。

```settings.xml
    <servers>
        ...
        <server>
            <id>docker-registry-aliyun</id>
            <username>镜像仓库的用户</username>
            <password>镜像仓库的密码</password>
            <configuration>
                <email>这里配置一个管理员邮箱</email>
            </configuration>
        </server>
    </servers>
```

### 总工程配置

在总工程的pom.xml文件的properties节点、build节点中，加入plugin相关信息。

```xml
    <properties>
        ...
        <!--docker编译相关-插件版本-->
        <docker-maven-plugin.version>0.4.10</docker-maven-plugin.version>
        <!--docker编译相关-docker仓库地址-->
        <docker.registry>registry.cn-hangzhou.aliyuncs.com</docker.registry>
    </properties>
        ...
    <!--docker编译相关-构建插件-->
    <build>
        <pluginManagement>
            <plugins>
                ...
                <plugin>
                    <groupId>com.spotify</groupId>
                    <artifactId>docker-maven-plugin</artifactId>
                    <version>${docker-maven-plugin.version}</version>
                </plugin>
                ...
            </plugins>
        </pluginManagement>
    </build>
```

### 子工程配置

在子工程,也就是我们的微服务项目的pom.xml文件的profiles节点中，加入docker-maven-plugin相关信息插件。

```xml
    <profiles>
         <!--docker编译相关-->
         <profile>
             <id>docker</id>
             <activation>
                 <property>
                     <name>docker</name>
                 </property>
             </activation>
             <build>
                 <plugins>
                     <plugin>
                         <groupId>com.spotify</groupId>
                         <artifactId>docker-maven-plugin</artifactId>
                         <executions>
                             <!-- 构建动作列表 -->
                             <execution>
                                 <!-- 构建镜像动作 -->
                                 <id>build-image</id>
                                 <phase>package</phase>
                                 <goals>
                                     <goal>build</goal>
                                 </goals>
                                 <configuration>
                                     <dockerDirectory>${project.basedir}</dockerDirectory>
                                     <!-- 这里的xxx替换为需要推送的镜像仓库namespace -->
                                     <imageName>${docker.registry}/xxx/${project.artifactId}  <!-- 镜像名 -->
                                     </imageName>
                                     <imageTags>
                                         <!-- 镜像tag，支持多个tag -->
                                         <imageTag>${project.version}</imageTag> 
                                     </imageTags>
                                     <buildArgs>
                                         <!-- 构建出jar包制品位置 -->
                                         <JAR_FILE>target/${project.build.finalName}.jar</JAR_FILE>
                                     </buildArgs>
                                     <forceTags>true</forceTags>
                                     <labels>
                                         <label>VERSION=${project.version}</label>
                                     </labels>
                                     <resources>
                                         <resource>
                                             <targetPath>/</targetPath>
                                             <directory>${project.build.directory}</directory>
                                             <include>${project.artifactId}-${project.version}-shaded.jar
                                             </include>
                                         </resource>
                                     </resources>
                                 </configuration>
                             </execution>
                             <execution>
                                 <!-- 推送镜像动作 将构建好的镜像制品推送到镜像仓库 -->
                                 <id>push-image</id>
                                 <phase>deploy</phase>
                                 <goals>
                                     <goal>push</goal>
                                 </goals>
                                 <configuration>
                                     <!-- 对应maven settings.xml的server id -->
                                     <serverId>docker-registry-aliyun</serverId> 
                                     <imageName>
                                          <!--需要push到仓库的镜像，目前只支持一个,这里的xxx替换为需要推送的镜像仓库namespace -->
                                         ${docker.registry}/xxx/${project.artifactId}:${project.version}
                                     </imageName>
                                     <registryUrl>https://${docker.registry}</registryUrl>
                                     <!-- 失败重试次数以及超时时间 -->
                                     <retryPushCount>3</retryPushCount>
                                     <retryPushTimeout>60</retryPushTimeout>
                                 </configuration>
                             </execution>
                         </executions>
                     </plugin>
                 </plugins>
             </build>
         </profile>
    </profiles>
```

在子工程的目录中，准备好编译需要的dockerfile以及启动jar程序需要的脚本

Dockerfile:

```dockerfile
FROM openjdk:8u191-jre-alpine3.9

EXPOSE 8080
ARG JAR_FILE

WORKDIR /opt/app

ADD ${JAR_FILE} /opt/app/app.jar
ADD docker-entrypoint.sh /opt/app/

RUN chmod +x /opt/app/docker-entrypoint.sh
CMD ["sh", "/opt/app/docker-entrypoint.sh"]
```

启动脚本 docker-entrypoint.sh :

这里放开了容器的jvm内存相关参数，方便通过环境变量配置

```shell
#!/bin/sh
java $JAVA_JAR -jar -Xmx${Xmx} -Xms${Xms} -Xmn${Xmn} -Xss1024k -XX:LargePageSizeInBytes=${Xml} \
             /opt/app/app.jar
```

所有文件都配置好后，相关的目录结构如下所示:

```shell
➜  docker-demo-app git:(master) tree -aL 2
.
# 总工程pom
├── pom.xml     
# 子工程a                           
├── docker-demo-app-rest                   
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── pom.xml
│   └── src
# 子工程b
├── docker-demo-app-service                
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── pom.xml
│   └── src
```

## 编译制品

