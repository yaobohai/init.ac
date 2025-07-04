---
layout:     post
title:      "Github Actions妙用技能(第一章)-构建CI镜像仓库"
subtitle:   "MicroED"
date:       2025-05-07
author:     "博海"
header-img: "img/1450094558.jpg"
tags:
- MicroED
---

## 前言

最近经常有需求来构建各种各样的N个 Docker 镜像使用，不过国内网络和各种编译环境搞得比较头疼，于是尝试通过专业的 CI 平台来避免，经过筛选，最终选择了 Github Actions 来满足。比如本博客就通过 Actions 来完成自动化的 CI、CD

这里列举下Github Actions的优点：

- 代码托管在Github,无需自建Git、对CI有着天然的优势
- **免费的Ci runner使用**（runner 可以理解为执行CI的节点）
- runner可以使用各种各样的环境（如选择 Centos、Ubuntu、MacOS、Node.js、Py...等等作为runner的基础环境）
- 如果Github的runner无法满足需求。也可以将Runner私有化部署在本地


## 初始化Git仓库

新建一个 Git Repo 专门存储我们用来Ci的代码以及Dockerfile等

编写触发编译动作的脚本`build.sh`，来适配我们的需求

```shell
#!/usr/bin/env bash

build_app=$1
alias_app=$2
build_version=$3
build_repo=${build_repo_addr}/${build_repo_name}

# 如果想在构建完成后来执行webhook通知动作等等，那么定义一个notice方法即可
function notice() {
  notice_title="来自Github Actions构建的 ${alias_app} ${build_result}通知"
  notice_body="构建应用: ${build_app} for $(uname -m)\n\n发布名称: ${alias_app}\n\n构建版本: ${build_repo}/${alias_app}:${build_version}"
  
  # 这里来写你的webhook触发指令
  # curl https://xxxx.xxxx.xxxx
  
}

function launch() {
  echo "start build: ${build_repo}/${alias_app}:${build_version} for $(uname -m)"
    
    # 查找本地是否有
    if [[ -d ./${build_app} ]];then
        cd ./${build_app}
        if [[ -f actions.sh ]];then
          sh actions.sh
        fi
    else
        echo "app ${build_app} does not exist.";exit 1
    fi
  fi
  docker build . -t ${build_repo}/${alias_app}:${build_version}
  if [[ $? == 0 ]];then
    docker push ${build_repo}/${alias_app}:${build_version}
    # 将构建完成的镜像在runner中清理掉
    if [[ $? == 0 ]];then
        docker rmi ${build_repo}/${alias_app}:${build_version}
    fi
  else
    # 这里的return留给我们后面使用构建成功失败的通知使用
    return 1
  fi
}

function main() {
    launch
  
    # 如果要使用构建通知，这里来引用 notice 方法即可
    if [[ $? == 0 ]];then
      build_result="构建成功"
    else
      build_result="构建失败"
    fi
    #notice
}

main
```


### 编写CI工作流文件

在仓库中新建文件 `.github/workflows/builder.yml` 内容按如下所写

```yaml
name: Builder
on: [push]
run-name: ${{ github.event.commits[0].message }}
jobs:
  build-frpc-amd64:
    # 构建节点
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Launch Builder
        # 根据Git commit来匹配关键字触发流程
        if: ${{ contains(github.event.head_commit.message, 'flask-demo') }}
        run: |
          # 定义推送的镜像命名空间
          export build_repo_name='xxxx'
          # 定义推送的镜像仓库地址
          export build_repo_addr='registry.cn-hangzhou.aliyuncs.com'
          # 定义推送的镜像仓库登录凭证
          docker login --username=${{ secrets.ALIYUN_USERNAME }} --password=${{ secrets.ALIYUN_PASSWORD }} ${build_repo_addr}
          # 构建参数定义：/bin/bash build.sh 目录名 镜像名 镜像版本
          /bin/bash build.sh flask-demo flask-demo 1.0.0-SNAPSHOT
```

根据上述描述文件的定义，那么就完成了一个服务的编译构建逻辑。下面我们对


## 开始一个编译任务

在仓库中新建我们要构建的服务目录，这里以flask-demo来举例。

目录结构如下：

```shell
➜  builder git:(develop) ✗ tree -aL 1 flask-demo 
flask-demo
├── Dockerfile
└── main.py

0 directories, 2 files
➜  builder git:(develop) ✗ 

```

`main.py` 是我们要运行的程序代码,内容：

```shell
from flask import Flask

app = Flask(__name__)


@app.route('/', methods=['GET'])
def main():
    return "Hello World"


if __name__ == '__main__':
    app.run()
```

`Dockerfile` 是要将代码打包为镜像的描述文件,内容：

```dockerfile
FROM python:3.7-alpine

WORKDIR /

RUN pip3 install Flask
ADD main.py /
CMD ["python3", "main.py"]
```


这样就完成了我们第一个编译工程的定义，下面把代码提交上去，看看结果，注意git commit内容中要包含我们前面在工作流文件`.github/workflows/builder.yml`中，定义的`flask-demo`关键字，也就是`        if: ${{ contains(github.event.head_commit.message, 'flask-demo') }}` 这段逻辑。

