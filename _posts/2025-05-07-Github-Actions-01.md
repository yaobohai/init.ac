---
layout:     post
title:      "Github Actions妙用技能(第一章)-使用Actions来构建多应用的Docker镜像"
subtitle:   "Docker"
date:       2025-07-04
author:     "博海"
header-img: "img/1450094558.jpg"
render_with_liquid: false
tags:
- Docker
- Github
- CI/CD
---

## 前言

最近经常有需求来构建各种各样的N个 Docker 镜像使用，不过国内网络和各种编译环境搞得比较头疼，于是尝试通过专业的 CI 平台来避免，经过筛选，最终选择了 Github Actions 来满足。比如本博客就通过 Actions 来完成自动化的CI、CD。

这里列举下Github Actions的优点：

- 代码托管在Github,无需自建Git、对CI有着天然的优势
- **免费的Ci runner使用**（runner 可以理解为执行CI的节点）
- runner可以使用各种各样的环境（如选择 Centos、Ubuntu、MacOS、Node.js、Py...等等作为runner的基础环境）
- 如果Github的runner无法满足需求。也可以将Runner私有化部署在本地

下面我将通过几个章节，来带大家完成最佳实践：

- 初始化Git仓库
  - 新建Git仓库
  - 配置镜像仓库凭证
  - 编写触发编译的脚本
  - 编写CI工作流文件
- 编译环节
  - 简单的应用打包
  - 具有预编译脚本的打包


## 初始化Git仓库

### 新建Git仓库

新建一个 Git Repo 专门存储我们用来Ci的代码以及Dockerfile等

![actions_01](../../../../img/in-post/2025-07-04/actions_01.png)

### 配置镜像仓库凭证

在仓库的 `Settings--> Secrets and variables --> Actions` 中，添加`Repository secrets`，配置我们的镜像仓库凭证：

REGISTRY_USERNAME: 存储仓库登录用户  
REGISTRY_PASSWORD: 存储仓库登录密码

![actions_03](../../../../img/in-post/2025-07-04/actions_03.png)

### 编写触发编译的脚本

接着，把新建的 Git 工程克隆到本地，进行本地完成所有的操作。

新建触发编译动作的脚本: `build.sh`

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

  # 查找本地是否有需要编译的应用目录
  if [[ -d ./${build_app} ]];then
      cd ./${build_app}
      # 如果编译的应用目录内还具编译之前还要做一些其他动作的预编译脚本，先执行
      if [[ -f actions.sh ]];then
        sh actions.sh
      fi
  else
      echo "app ${build_app} does not exist.";exit 1
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
该脚本的作用，是引导构建的执行，下面会提供给工作流调用使用，脚本参数解释:

```shell
/bin/bash build.sh 应用文件夹名 要构建的镜像名称 TAG版本号
如：
/bin/bash build.sh flask-demo flask-demo 1.0.0-SNAPSHOT
```

### 编写CI工作流文件

在仓库中新建文件 `.github/workflows/builder.yml` 内容按如下所写

```yaml
name: Builder
on: [push]
run-name: ${{ github.event.commits[0].message }}
jobs:
  build-flask-demo-amd64:
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
          docker login --username=${{ secrets.REGISTRY_USERNAME }} --password=${{ secrets.REGISTRY_PASSWORD }} ${build_repo_addr}
          # 使用上面的build.sh
          /bin/bash build.sh flask-demo flask-demo 1.0.0-SNAPSHOT
```


根据上述描述文件的定义，将 `build_repo_name` 和 `build_repo_addr` 修改为你的实际docker镜像namespace内容 

比如: `registry.cn-hangzhou.aliyuncs.com/zhangsan/flask-demo` 是你的镜像地址，那么:

`zhangsan` 是 `build_repo_name` 的值  
`registry.cn-hangzhou.aliyuncs.com` 是 `build_repo_addr`的值  


这样搞，就完成了一个服务的编译构建逻辑。这个时候我们的目录结构如下所示

![actions_02](../../../../img/in-post/2025-07-04/actions_02.png)


## 编译环节

### 简单的应用打包

在仓库中新建我们要构建的服务目录，这里以flask-demo来举例。该应用一共有两个文件，一个是flask的应用`main.py`文件，一个是用于构建成docker镜像的`Dockerfile`

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

`Dockerfile` 

```dockerfile
FROM python:3.7-alpine

WORKDIR /

RUN pip3 install Flask
ADD main.py /
CMD ["python3", "main.py"]
```

完成后，目录结构如下:

![actions_04](../../../../img/in-post/2025-07-04/actions_04.png)


这样就完成了我们第一个应用的编译准备，下面把代码提交上去看看结果，注意git commit内容中要包含我们前面在工作流文件`.github/workflows/builder.yml`中，定义的`flask-demo`关键字，也就是`if: ${{ contains(github.event.head_commit.message, 'flask-demo') }}` 这段逻辑。

### 验证结果

提交代码之后，返回到 Github 的网页端，查看Actions 页面，就会出现一个已经在执行的任务

![actions_05](../../../../img/in-post/2025-07-04/actions_05.png)

如果你已经给Git仓库配置了镜像仓库的登录凭证，且修改了build_repo_addr、build_repo_name 那么在执行的任务里稍等片刻，即可完成对flask-demo这个应用的构建和推送

```shell
#9 naming to registry.cn-hangzhou.aliyuncs.com/bohai_repo/flask-demo:1.0.0-SNAPSHOT done
#9 DONE 0.3s
The push refers to repository [registry.cn-hangzhou.aliyuncs.com/bohai_repo/flask-demo]
2fdfb05dc4a5: Preparing
240cb8f95741: Preparing
ae2ed3079163: Preparing
aa3a591fc84e: Preparing
7f29b11ef9dd: Preparing
a1c2f058ec5f: Preparing
cc2447e1835a: Preparing
a1c2f058ec5f: Waiting
cc2447e1835a: Waiting
2fdfb05dc4a5: Pushed
aa3a591fc84e: Pushed
240cb8f95741: Pushed
ae2ed3079163: Pushed
7f29b11ef9dd: Pushed
a1c2f058ec5f: Pushed
cc2447e1835a: Pushed
1.0.0-SNAPSHOT: digest: sha256:6005f777adaa185580d91301c425a1aeb7e97610c6868e3fd6308057a1bfbfa2 size: 1786
Untagged: registry.cn-hangzhou.aliyuncs.com/bohai_repo/flask-demo:1.0.0-SNAPSHOT
Untagged: registry.cn-hangzhou.aliyuncs.com/bohai_repo/flask-demo@sha256:6005f777adaa185580d91301c425a1aeb7e97610c6868e3fd6308057a1bfbfa2
Deleted: sha256:bd62b8a842297522fabd6c159cda71c78a5df7b5c4dc90ddfaa847c7319d9acf
```

![actions_06](../../../../img/in-post/2025-07-04/actions_06.png)


### 具有预编译脚本的打包

如果docker镜像编译起来还略微复杂，比如会通过执行一系列动作，比如下载其他工具包等等的操作，那么可以在编译的目录中增加预编译脚本：`actions.sh` 来让编译镜像前先执行这个脚本，来完成打包。

## 更多

这里公开了文章演示的 Github 仓库，可参考：https://github.com/bohai-repo/builder_template