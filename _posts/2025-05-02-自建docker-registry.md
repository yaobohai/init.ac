---
layout:     post
title:      "自建docker-registry"
subtitle:   "Docker"
date:       2025-05-02
author:     "博海"
header-img: "img/1450094558.jpg"
tags:
- Docker
---

## 简述

国内已无法正常访问docker hub官方源，我们可以找台**海外**服务器自建registry，缓存镜像registry到国外服务器进行正常下载

必要条件：

- 域名&证书 一只
- 海外服务器 一只


*以下操作均在海外服务器中运行*

## 启动registry

```
docker rm -f docker-registry-docker
docker run -itd --name=docker-registry-docker \
--restart=always \
-e TZ=Asia/Shanghai \
-p 5000:5000 \
-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
-v /data/docker-registry/data:/var/lib/registry registry:latest

docker rm -f docker-registry-k8s
docker run -itd --name=docker-registry-k8s \
--restart=always \
-e TZ=Asia/Shanghai \
-p 5001:5000 \
-e REGISTRY_PROXY_REMOTEURL=https://registry.k8s.io \
-v /data/docker-registry/data:/var/lib/registry registry:latest

# 配置详解
REGISTRY_PROXY_REMOTEURL: 为指定上游远程镜像仓库为官方镜像仓库

```
## 配置反向代理

```
upstream docker-registry {  
          server <本机IP>:5000;
          server <本机IP>:5001;
}

server {
    listen              443 ssl;
    server_name         <你的域名>;
    ssl_certificate     /etc/nginx/ssl/ssl.cerm;
    ssl_certificate_key /etc/nginx/ssl/ssl.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;
     
    proxy_set_header Host   $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    client_max_body_size 0;              
    chunked_transfer_encoding on;
    add_header 'Docker-Distribution-Api-Version' 'registry/2.0' always;

    location / {
       auth_basic off;
       proxy_set_header Host         $http_host;
       proxy_set_header X-Real-IP    $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
       proxy_read_timeout  900;
       proxy_pass http://docker-registry;
  }


    location /_ping {
       auth_basic off;
       proxy_pass http://docker-registry;
    }
    
    location /v2/_ping {
       auth_basic off;
       proxy_pass http://docker-registry;
    }
     
    location /v2/_catalog {
       auth_basic off;
       proxy_pass http://docker-registry;
    }

    access_log  /etc/nginx/logs/docker-registry.access.log;
    error_log   /etc/nginx/logs/docker-registry.error.log;
}
```

至此，将域名解析至nginx的机器。并在需要下载镜像的docker客户端(国内机器)配置：

```
# 编辑或添加
$ vim /etc/docker/daemon.json
{
    "registry-mirrors": ["https://registry的地址"]
}

# 生效配置
$ systemctl reload docker

# 测试下载镜像
$ docker pull nginx:alpine3.19-perl
```

