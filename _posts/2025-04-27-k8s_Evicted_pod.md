---
layout: post
date:  2025-04-27
title: K8S集群产生大量的Evicted pod
author: "博海"
header-img: "img/post-white-room.png"
tags:
- kubernetes
---
暂无描述内容

<!--more-->

1、查看具有evicted的pod的事件

```
export namespace='production'
for pod_name in $(kubectl get po -n ${namespace}|grep 'ContainerStatusUnknown'|awk '{print $1}');do echo -e "${pod_name}: \n $(kubectl describe pod -n ${namespace} ${pod_name}|grep -Ew 'Node|Message'|grep -v 'Node-Selectors')";echo '' ;done
```

2、错误原因

```
demo-service-6fd4347-65f4b974c5-bz6mz:
 Node:           172.30.218.222/
Message:        Pod The node had condition: [DiskPressure].
```


3、根据错误提示，说明节点磁盘可能存在瓶颈，登录到指定的节点，通过 `df -hT` 查看磁盘使用情况

```
[root@lianhuan-prd-hd-nodepool-new-w8mte-orm9v /]# df -hT
Filesystem                         Type      Size  Used Avail Use% Mounted on
devtmpfs                           devtmpfs  122G     0  122G   0% /dev
tmpfs                              tmpfs     123G     0  123G   0% /dev/shm
tmpfs                              tmpfs     123G  132M  122G   1% /run
tmpfs                              tmpfs     123G     0  123G   0% /sys/fs/cgroup
/dev/sda1                          ext4       49G  3.6G   43G   8% /
tmpfs                              tmpfs     123G   36K  123G   1% /tmp
/dev/mapper/vgpaas-dockersys       ext4      442G   27G  393G   7% /var/lib/containerd
/dev/mapper/vgpaas-kubernetes      ext4       49G   41G  6.0G  88% /mnt/paas/kubernetes/kubelet
```

可以看到，文件系统 `/dev/mapper/vgpaas-kubernetes`  磁盘使用率超过了80%,在k8s中，使用率超过85%则会驱逐节点中的pod到其他节点。

4、查看具体的目录作用

```
[root@lianhuan-prd-hd-nodepool-new-w8mte-orm9v log]# cd /mnt/paas/kubernetes/kubelet
[root@lianhuan-prd-hd-nodepool-new-w8mte-orm9v kubelet]# du -sh *
4.0K    cpu_manager_state
4.0K    device-plugins
16K     lost+found
48K     plugins
4.0K    plugins_registry
4.0K    pod-resources
42G     pods


[root@lianhuan-prd-hd-nodepool-new-w8mte-orm9v kubelet]# ll pods/
total 144
drwxr-x--- 5 root root 4096 Feb  9 21:43 0b0b60cf-11d0-43ce-9497-b6b905fc282b
drwxr-x--- 5 root root 4096 Mar 16 09:21 140e0abd-d101-4933-ae08-b96fe457582e
[root@lianhuan-prd-hd-nodepool-new-w8mte-orm9v kubelet]# ll pods/0b0b60cf-11d0-43ce-9497-b6b905fc282b/containers/
total 12
drwxr-x--- 2 root root 4096 Feb  9 21:43 clear-log
drwxr-x--- 2 root root 4096 Feb  9 21:43 filebeat
drwxr-x--- 2 root root 4096 Mar 16 11:28 mas-user-service
```

根据排查，此文件系统可能为pod的容器工作目录。登录华为云k8s管理后台后发现集群文件系统分配不合理，重制集群后问题恢复。