---
layout:     post
title:      "Java学习笔记-Spring的Actuator了解"
subtitle:   "Java"
date:       2025-04-27
author:     "博海"
header-img: "img/post-white-room.png"
tags:
- Java
---

Actuator是处于Springboot应用层的监控，这目前来说研发老司机与运维同学都会非常喜欢这个的东西；

对于研发来讲，可以在应用启动后拿到应用的各种数据，非常便于调试应用、分析应用的运行状况，并且不需要研发去实现这些监控功能引入也非常的简单；

对于运维来讲，可以监控应用的健康信息、统计应用的瞬时信息。发现应用挂掉了、发现瞬时信息不正常都可以发送报警信息， 也可以将信息拉到监控系统的数据系统中，再展示到漂亮的UI上实时监控应用的运行状态。这些actions 无疑将会大大保证系统的整体质量。

而集成了actuator的springboot应用会在约定的endpoints上暴露自己应用的内部信息，又强大又统一标准，满足复杂分布式系统的监控需求，一些endpoints简介如下：


<!--more-->

# 实现接入

## 增加依赖

在pom中引入依赖包

```xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
```

## 增加配置

配置 src/main/resources/application.yml 中增加

```shell
management:
  server:
    port: 8443
  endpoints:
    web:
      exposure:
        include: "*"
      base-path: /actuator
  endpoint:
    shutdown:
      enabled: true
    health:
      show-details: always
```

配置参数解释

```shell
management.server.port                        端点的访问端口 （可以不配置；与主程序使用统一端口）
management.endpoints.web.exposure.include     暴露的端点信息  (* 代表所有 可配置 health,info端点) 
management.endpoints.web.base-path            端点的访问路径
management.endpoint.shutdown.enabled          启用shutdown接口
management.endpoint.health.enabled            启用健康检查接口
```

## 启动工程

引入依赖并编写好配置之后，启动项目，访问 `http://127.0.0.1:8443/actuator`

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-04-23/xvZKuB.png)

可以看到 返回了很多的端点 uri；这些都是可被健康检查的指标。 例如我们访问一个 `actuator/health` 路径，可以进行健康检查:

```shell
$ curl http://127.0.0.1:8443/actuator/health

{"status":"UP","details":{"diskSpace":{"status":"UP","details":{"total":494384795648,"free":158250123264,"threshold":10485760}}}}
```

还有一些指标的信息可以进行监控 `http://127.0.0.1:8443/actuator/metrics`

```shell
curl http://127.0.0.1:8443/actuator/metrics

{"names":["jvm.memory.max","jvm.threads.states","process.files.max","jvm.gc.memory.promoted","system.load.average.1m","jvm.memory.used","jvm.gc.max.data.size","jvm.memory.committed","system.cpu.count","logback.events","tomcat.global.sent","jvm.buffer.memory.used","tomcat.sessions.created","jvm.threads.daemon","system.cpu.usage","jvm.gc.memory.allocated","tomcat.global.request.max","http.server.requests","tomcat.global.request","tomcat.sessions.expired","jvm.threads.live","jvm.threads.peak","tomcat.global.received","process.uptime","tomcat.sessions.rejected","process.cpu.usage","tomcat.threads.config.max","jvm.classes.loaded","jvm.classes.unloaded","tomcat.global.error","tomcat.sessions.active.current","tomcat.sessions.alive.max","jvm.gc.live.data.size","tomcat.threads.current","process.files.open","jvm.buffer.count","jvm.buffer.total.capacity","tomcat.sessions.active.max","tomcat.threads.busy","process.start.time"]}
```

除此之外，因为开启了shutdown接口 `management.endpoint.shutdown.enabled`，我们还可以优雅的通过调用接口的方式
来停止我们的程序。这对不停服的升级提供了不小的帮助

```shell
curl -X POST http://127.0.0.1:8443/actuator/shutdown

{"message":"Shutting down, bye..."}         
```

![](https://resource.static.tencent.itan90.cn/mac_pic/2023-04-23/YeZxW2.png)