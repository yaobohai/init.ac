---
layout:     post
title:      "Java学习笔记-Apollo配置中心接入Springboot"
subtitle:   "Java"
date:       2025-04-27
author:     "博海"
header-img: "img/post-white-room.png"
tags:
- Java
---
# 简介

Apollo（阿波罗）是携程框架部门研发的开源配置管理中心，可在页面中管理应用的配置，具体可参考apollo的github

具体工作流程如下所示：

1、用户在配置中心对配置进行修改并发布  

2、配置中心通知Apollo客户端有配置更新  

3、Apollo客户端从配置中心拉取最新的配置、更新本地配置并通知到应用  

<!--more-->

# 部署Apollo

## 所需资源

- 一台无配置要求的MySQL5.7环境
- 一台2c2g的Docker环境

## 数据库准备

### 创建数据库及授权

```shell
CREATE USER 'apollo'@'%' identified BY 'xxxxxxxxxx';
CREATE DATABASE IF NOT EXISTS ApolloConfigDB DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS ApolloPortalDB DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON ApolloConfigDB.* TO apollo@"%"; 
GRANT ALL PRIVILEGES ON ApolloPortalDB.* TO apollo@"%"; 
```

上述创建了 `apollo` 的数据库用户，密码为`xxxxxxxxxx` [注意改为自己的密码] ;同时也创建了 `ApolloConfigDB` 和 `ApolloPortalDB` 库

### 导入部署SQL

```shell
ApolloConfigDB库导入: https://github.com/apolloconfig/apollo/blob/master/scripts/sql/apolloconfigdb.sql
ApolloPortalDB库导入: https://github.com/apolloconfig/apollo/blob/master/scripts/sql/apolloportaldb.sql
```

导入后，还需手动执行SQL来更改 `ApolloConfigDB` 库中的apollo eureka地址；如下：

```shell
// 将 http://192.168.60.229:8080 替换为你的eureka公网或内网地址
UPDATE `ApolloConfigDB`.`ServerConfig` SET `Value` = 'http://192.168.60.229:8080/eureka/' WHERE `Id` = 1
```

### 快速部署

注意部署过程中还需修改部分敏感配置：`SPRING_DATASOURCE_URL` 与 `SPRING_DATASOURCE_PASSWORD` 将 xxx替换为自己的参数

```shell
version=latest
docker pull apolloconfig/apollo-configservice:${version}
docker rm -f apollo-configservice
docker run --net=host \
    -e SPRING_DATASOURCE_URL="jdbc:mysql://xxxx:3306/ApolloConfigDB?characterEncoding=utf8" \
    -e SPRING_DATASOURCE_USERNAME=apollo -e SPRING_DATASOURCE_PASSWORD=xxxx \
    -d -v /data/apollo/configservice/logs:/opt/logs --name apollo-configservice apolloconfig/apollo-configservice:${version}
    
version=latest
docker pull apolloconfig/apollo-adminservice:${version}
docker rm -f apollo-adminservice
docker run -p 8090:8090 \
    -e SPRING_DATASOURCE_URL="jdbc:mysql://xxxx:3306/ApolloConfigDB?characterEncoding=utf8" \
    -e SPRING_DATASOURCE_USERNAME=apollo -e SPRING_DATASOURCE_PASSWORD=xxxx \
    -d -v /data/apollo/adminservice/logs:/opt/logs --name apollo-adminservice apolloconfig/apollo-adminservice:${version}

version=latest
docker pull apolloconfig/apollo-portal:${version}
docker rm -f apollo-portal
docker run -p 8070:8070 \
    -e SPRING_DATASOURCE_URL="jdbc:mysql://xxxx:3306/ApolloPortalDB?characterEncoding=utf8" \
    -e SPRING_DATASOURCE_USERNAME=apollo -e SPRING_DATASOURCE_PASSWORD=xxxxx \
    -e APOLLO_PORTAL_ENVS=dev \
    -e DEV_META=http://192.168.60.229:8080 \
    -e SPRING.PROFILES.ACTIVE=github \
    -d -v /data/apollo/portal/logs:/opt/logs --name apollo-portal apolloconfig/apollo-portal:${version}    
```

启动后，访问apollo的eureka地址 (http://IP:8080/) 看 `APOLLO-ADMINSERVICE`、`APOLLO-CONFIGSERVICE` 是否都已成功注册； 


接着 访问apollo的UI界面 (http://IP:8070)  进行创建应用以及名称

# 代码接入

在上述章节，准备好apollo的部署后，即可开始代码的接入。

## 引入依赖

```xml
        <dependency>
            <groupId>com.ctrip.framework.apollo</groupId>
            <artifactId>apollo-client</artifactId>
            <version>1.1.0</version>
        </dependency>
```

## 新建类


```java
package com.bohai.helloworld;

import com.ctrip.framework.apollo.ConfigService;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ApolloApplocation {
    @RestController
    @RequestMapping(path = "/config/")
    public class ApolloConfigurationController {

        @RequestMapping(path = "/{key}")
        public String getConfigForKey(@PathVariable("key") String key){
            return key+"的值为:"+ConfigService.getAppConfig().getProperty( key, "undefined");
        }
    }
}
```

## 启动类

```java
package com.bohai.helloworld;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class HelloworldApplication {

    public static void main(String[] args) {
        SpringApplication.run(HelloworldApplication.class, args);
    }
}
```

## 添加配置

配置 src/main/resources/application.properties 增加

```text
app.id =                                     # Apollo 中的应用appid
apollo.meta =                                # Apollo 的eureka地址
apollo.bootstrap.enabled = true              # Apollo 是否启用
apollo.bootstrap.eagerLoad.enabled = false   # Apollo 不加载提到初始化日志系统之前
```

关于配置 `apollo.bootstrap.eagerLoad.enabled` 如果设置为 false，那么将打印出 Apollo 的日志信息，但是由于打印 Apollo 日志信息需要日志先启动，启动后无法对日志配置进行修改，所以 Apollo 不能管理应用的日志配置，如果设置为 true，那么 Apollo 可以管理日志的配置，但是不能打印出 Apollo 的日志信息


## 测试访问

```shell
curl http://127.0.0.1:8080/config/{name}
```

将 {name} 替换为在apollo中增加的key配置名称，正常情况下会返回在apollo中的values


```shell
curl http://127.0.0.1:8080/config/name

name的值为:bohai
```