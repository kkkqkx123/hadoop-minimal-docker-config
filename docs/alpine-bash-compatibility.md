# Alpine Linux Bash 脚本兼容性修复

## 问题概述
Alpine Linux使用musl libc和busybox，与标准的glibc和bash环境存在兼容性问题，导致Hadoop脚本出现语法错误。

## 主要修复措施

### 1. Shell解释器指定
- 将所有脚本的shebang从`#!/usr/bin/env bash`改为`#!/bin/bash`
- 确保明确指定bash作为解释器，避免使用dash

### 2. 环境变量配置
- 在entrypoint.sh和hadoop-env-alpine.sh中添加`export SHELL=/bin/bash`
- 在docker-compose-alpine.yml中为所有服务添加`SHELL=/bin/bash`环境变量
- 设置`HADOOP_CONF_DIR`环境变量指向正确的配置目录

### 3. Hadoop服务启动方式
- 使用`bash -c`命令包装Hadoop命令，确保在bash环境中执行
- 替换原有的start-dfs.sh和start-yarn.sh批量启动方式
- 手动逐个启动NameNode、DataNode、SecondaryNameNode、ResourceManager、NodeManager

### 4. JVM参数简化
- 移除HADOOP_OPTS、HADOOP_NAMENODE_OPTS等参数中的复杂JVM选项
- 仅保留基本的内存设置（-Xmx, -Xms）
- 移除G1GC等可能在Alpine环境下不兼容的JVM参数

### 5. 脚本执行方式
- 在SSH远程执行时使用`bash -c`包装命令
- 确保所有Hadoop命令都在bash环境中执行

## 关键修改文件

### scripts/entrypoint.sh
- 修改shebang为`#!/bin/bash`
- 添加`export SHELL=/bin/bash`
- 使用`bash -c`包装所有Hadoop命令
- 优化SSH等待逻辑

### conf/hadoop-env-alpine.sh
- 添加`export SHELL=/bin/bash`
- 简化JVM参数配置
- 移除复杂的变量扩展

### docker-compose-alpine.yml
- 为master、worker1、worker2服务添加`SHELL=/bin/bash`环境变量

## 测试验证
创建了test-alpine-bash.sh脚本用于验证bash环境兼容性，包含：
- Shell版本检测
- 基本变量操作测试
- 数组操作测试
- Hadoop环境验证

## 注意事项
1. 确保Docker镜像中已安装bash（已在Dockerfile.alpine中包含）
2. 所有Hadoop相关脚本都需要在bash环境中执行
3. 避免使用复杂的bash特性，如参数扩展、关联数组等
4. 监控容器启动日志，及时发现兼容性问题