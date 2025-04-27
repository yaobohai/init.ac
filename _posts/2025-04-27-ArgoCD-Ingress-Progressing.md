---
layout: post
date:  2025-04-27
title: Ingress资源在argocd中一直处于Progressing状态
author: "博海"
header-img: "img/post-white-room.png"
tags:
- kubernetes
subtitle:   "kubernetes"
---

这个问题，其实需要分版本做不同的处理,是通过ArgoCD健康检查的自定义的资源检查来排除对Ingress的检查。

具体解决步骤如下：

``` shell
kubectl edit cm -n argocd argocd-cm
```

集群v1.20.0及以上添加:

```yaml
data:
  resource.customizations: |
    networking.k8s.io/Ingress:
        health.lua: |
          hs = {}
          hs.status = "Healthy"
          return hs
  resource.customizations.useOpenLibs.extensions_Ingress: "true"
```

集群v1.20.0以下添加:

```yaml
data:
  resource.customizations.health.extensions_Ingress: |
    hs = {}
    hs.status = "Healthy"
    hs.message = "SoulChild"
    return hs
  resource.customizations.useOpenLibs.extensions_Ingress: "true"
```

![](https://resource.static.tencent.itan90.cn/mac_pic/2022-12-05/9ZSxnI.png)


最后删除argo应用控制器;并重新同步应用

```shell
kubectl delete pod -n argocd argocd-application-controller-0
sleep 10
argocd app sync <Your APP> --force
```

![](https://resource.static.tencent.itan90.cn/mac_pic/2022-12-05/2MwR8V.png)

更多参考这三篇文章：

https://argo-cd.readthedocs.io/en/stable/operator-manual/health/#ingress
https://github.com/argoproj/argo-cd/issues/1704   
https://argoproj.github.io/argo-cd/operator-manual/health/#custom-health-checks  