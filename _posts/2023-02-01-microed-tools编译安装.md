---
layout:     post
title:      "MicroED-Tools编译安装"
subtitle:   "MicroED"
date:       2023-02-01
author:     "博海"
header-img: "img/1450094558.jpg"
tags:
- MicroED
% include toc.html html=content %
---

## 前言

帮同学编译MicroED工具，该工具用作连续的电子衍射图像序列或者是MicroED扫描转换城Super Marty View (SMV) 格式的工具，编译过程中略显繁琐，本文记录一下过程

希望能帮助到大家作为参考

环境信息：

```shell
- Ubuntu X64位
- tiff-4.5.0.zip
- microed-tools-0.1.0-dev.8.tar.gz
- 注意⚠️：编译需要具有sudo权限
```

下载工具：

```shell
tiff:
https://download.osgeo.org/libtiff/tiff-4.5.0.zip

microed-tools: 
https://cryoem.ucla.edu/downloads/snapshots
```

## 1. 安装tiff

### 1.1 安装依赖包

```shell
sudo apt-get install libxslt-dev flex libarchive-dev libnlopt-dev cmake apt-get install libtiff-dev
sudo apt-get install pandoc
```

### 1.2 安装libtiff

```shell
# 解压
unzip tiff-4.5.0.zip && cd tiff-4.5.0/

# 开始配置
sudo cmake -DCMAKE_INSTALL_PREFIX:PATH="/usr/local/libtiff" -
DCMAKE_INSTALL_RPATH:PATH="/usr/local/libtiff/lib" -
DBUILD_SHARED_LIBS:BOOL=ON -Djbig:BOOL=OFF -Djpeg:BOOL=OFF -
Djpeg12:BOOL=OFF -Dlibdeflate:BOOL=OFF -Dlzma:BOOL=OFF -Dold-
jpeg:BOOL=OFF -Dpixarlog:BOOL=OFF -Dwebp:BOOL=OFF -Dzlib:BOOL=OFF -Dzstd:BOOL=OFF 

// 编译
sudo cmake --build . --parallel

# 安装
sudo cmake --install .
```

### 1.3 校验安装

```shell
/usr/local/libtiff/bin/tiffinfo  # 返回版本等信息
```

## 2.安装mircoed-tools

### 2.1 开始编译

```shell
# 创建编译时的⽬录
mkdir build && cd build
```

编辑 `CMakeLists.txt` ⽂件，在⾥⾯添加tiff的路径，来指定`tiff`包路径

```shell
vim ../microed-tools-0.1.0-dev.8/CMakeLists.txt （⾸⾏添加以下内容）

# libtiff path
find_path(TIFF_INCLUDE_DIR NAMES tiff.h HINTS
/usr/local/libtiff/include)
find_library(TIFF_LIBRARY NAMES tiff HINTS /usr/local/libtiff/lib)

if(TIFF_INCLUDE_DIR AND TIFF_LIBRARY)
        message(STATUS "Found libtiff: ${TIFF_LIBRARY}")        include_directories(${TIFF_INCLUDE_DIR})
else()
        message(ERROR "libtiff not found")
endif()
```

开始编译配置

```shell
cmake ../microed-tools-0.1.0-dev.8
```

完成后，开始编译

```shell
cmake --build . 
```

如果在build阶段遇到如下报错：

```shell
[  1%] Generating README
[  1%] Built target text
[  1%] Generating ../SMV.5
error : Unknown IO error
warning: failed to load external entity
"http://cdn.docbook.org/release/xsl/current/manpages/docbook.xsl"cannot parse
http://cdn.docbook.org/release/xsl/current/manpages/docbook.xsl
gmake[2]: *** [doc/CMakeFiles/man.dir/build.make:76: SMV.5] Error 4
gmake[1]: *** [CMakeFiles/Makefile2:962: doc/CMakeFiles/man.dir/all]Error 2
gmake: *** [Makefile:166: all] Error 2
```

我们只需要禁⽤掉⽂档的⽣成，仅仅只编译代码：

```shell
vim doc/CMakeFiles/man.dir/build.make 注释掉76、80、84⾏的代码
```

![禁用文档生成](../../../../img/in-post/2023-02-01/microed-tools-build-01.png "禁用文档生成")

注释后重试编译即可通过

### 2.2 制品准备

创建 `mircoed-tools` 的程序⽬录

```shell
sudo mkdir /usr/local/mircoed-tools
```

将编译好的程序移动到程序⽬录中

```shell
sudo mv src/{dm2smv,ht2wavelength,img2px,dumpframe,idoc2smv,mrc2smv,ser2smv,t iff2smv,tvips2smv} /usr/local/mircoed-tools/
```

接着加⼊到系统path中，实现不需要输⼊路径也可打开程序

```shell
echo 'PATH=$PATH:/usr/local/mircoed-tools' >> /etc/profile
```

### 2.3 环境验证

新打开⼀个终端，输⼊`mrc2smv` 命令来验证程序是否可⽤即可。