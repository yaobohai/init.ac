---
layout:     post
title:      "Apple Container 上手体验"
subtitle:   "Apple"
date:       2025-06-22
author:     "博海"
header-img: "img/1450094558.jpg"
render_with_liquid: false
tags:
- Apple
- Container
- Docker
---

## 简介

Apple Container是一款强大的mac平台的cli工具，可在 macOS 上运行 Linux 容器，特别针对 Apple Silicon 进行了优化。

该 CLI 设计为开发者友好，命令风格与 Docker CLI 类似。对于已经熟悉 Docker CLI 的用户，Container CLI 应该会非常熟悉，并且为 macOS 用户提供了更原生的体验。

本文将介绍 Container CLI、如何快速上手，以及如何在 macOS 上运行 Linux 容器

## Container CLI 快速上手

要在 macOS 上体验原生 Linux 容器解决方案，可以直接使用 Container CLI，而无需直接操作 Containerization Framework。
需要说明的是，Container CLI 依赖于 macOS 26 beta 的新特性和增强功能。你也可以在 macOS 15.5 或更高版本上使用，但 macOS 15 上发现的问题不会被修复，建议使用 macOS 26 beta 或更高版本以获得最佳体验。

你需要提前了解 macOS 15 的一些限制：

- 虚拟网络下容器间无法通信。
- 容器的 IP 地址无法从主机访问。

这里基于macOS 26进行安装测试

## 安装 Container CLI

从 [GitHub release](https://github.com/apple/container/releases) 页面 下载 Container CLI，当前最新版本为 0.1.0。这里也可以使用我已经下载好的文件地址（文件有效期未知 ~）:

```
https://download.init.ac/files/container-0.1.0-installer-signed.pkg
```

安装完成后，可通过以下命令启动服务：

```
$ container system start
```

该命令会启动容器服务，并在未安装默认内核时自动安装。默认内核由 Kata Containers 提供，是一种轻量级虚拟机容器运行方案。如启动日志：

```
Verifying apiserver is running...
No default kernel configured.
Install the recommended default kernel from [https://github.com/kata-containers/kata-containers/releases/download/3.17.0/kata-static-3.17.0-arm64.tar.xz]? [Y/n]: y
Installing kernel...
```

如果你的网络访问条件比较差，无法直接或不能很好的访问 Github 下载kata Containers,也可以按ctrl+c 中断，并修改默认的kernel地址，来为安装加速，如下所示：

```
# 设置kernel地址
$ defaults write com.apple.container.defaults kernel.url "https://download.init.ac/files/kata-static-3.17.0-arm64.tar.xz"

# 验证是否配置成功
$ defaults read com.apple.container.defaults kernel.url
```

配置成功后重新执行 `container system start` 即可。



## 子命令

Container CLI 提供了一系列用于管理容器的子命令，风格与 Docker CLI 类似。

### Registry 登录

现在可以开始体验 Container CLI。运行容器前需先拉取镜像，Container CLI 支持从 Docker Hub 及其他镜像仓库拉取镜像。

首先登录 Docker Hub：

```
container registry login --username <USERNAME> REGISTRY_HOST
```

也可以将 Docker Hub Registry 设置为默认仓库：

```
container registry default set REGISTRY_HOST
```

### 拉取镜像


可通过 `container images pull` 命令从 Docker Hub 或其他仓库拉取镜像。该命令与 Docker CLI 类似，但使用 container 前缀和 images pull 子命令，而 Docker CLI 支持 `docker pull` 和 `docker images pull`。

```
# Docker CLI

docker pull nginx:latest

docker images pull nginx:latest

# Container CLI

container images pull nginx:latest
```

### 运行容器

运行容器命令也与 Docker CLI 类似。

```
# Docker CLI
docker run --rm --name nginx-test nginx:latest
# Container CLI
container run --rm --name nginx-test nginx:latest
````

### Inspect 容器

通过 inspect 命令可查看容器的详细信息，包括配置、网络和状态。

```
# Docker CLI
docker inspect nginx-test
# Container CLI
container inspect nginx-test
```

### 列出容器

可通过 container ls 命令列出所有运行中的容器，类似于 docker ps。


```
# Docker CLI
docker ps
# Container CLI
container ls
```

### 容器内执行命令


可通过 exec 命令在运行中的容器内执行命令，类似于 docker exec。

```
# Docker CLI
container exec -it nginx-test bash
# Container CLI
container exec -it nginx-test bash
```

### 其他命令

其他容器管理子命令也与 Docker CLI 类似。但镜像相关操作需使用 images 子命令，如 container images ls、container images rm 等。Docker CLI 提供了更友好的命令如 docker rmi、docker pull、docker push 等。

更多命令可通过 container --help 或 container <subcommand> --help 查看详细用法。

### 更多

如果你也更喜欢使用 `docker` 命令来使用 `container`，那么只需要给你的环境文件加入docker到container的alias 即可，例如 `~/.zshrc`

```
vim ~/.zshrc

alias docker='/usr/local/bin/container'
```

```
docker
OVERVIEW: A container platform for macOS

USAGE: container [--debug] <subcommand>

docker images ls
NAME   TAG     DIGEST
nginx  latest  6784fb0834aa7dbbe12e3d74...
```


## 镜像构建

关于镜像构建，Container CLI 支持使用 container build 命令，且 Dockerfile 语法兼容 Docker CLI。可直接用相同的 Dockerfile 构建镜像。

```
# Docker CLI
docker build -t my-image:latest .
# Container CLI
container build -t my-image:latest .
```
## 网络

通过 container ls 输出可看到每个容器都有独立的 IP 地址，Mac可以直接访问该地址，这是对传统 Docker 网络模型的重要改进。无需为每个容器单独映射端口，网络体验更加无缝。

```
container ls

ID                                    IMAGE                           OS     ARCH   STATE    ADDR
f9f44eef-2b46-4bc0-84f5-12a0f56b40df  docker.io/library/nginx:latest  linux  arm64  running  192.168.64.2
```

## 卸载 Container CLI

要卸载 Container CLI，可以使用 `container system stop` 命令停止容器服务，然后删除 Container CLI 可执行文件。

```
container system stop

git clone https://github.com/apple/container.git
cd container
scripts/uninstall-container.sh -d
```

`-d` 选项会删除容器数据目录，包括容器镜像和容器。如果希望保留数据，可以使用 -k 选项，仅移除 Container CLI 可执行文件，便于后续重新安装。


## 参考

- [Container](https://github.com/apple/container)
- [乱世浮生-Apple Container 开箱实践](https://atbug.com/apple-container-hands-on/)