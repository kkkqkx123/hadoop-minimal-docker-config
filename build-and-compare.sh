#!/bin/bash

# Hadoop Docker镜像构建和对比脚本

echo "=== Hadoop Docker镜像构建和优化对比 ==="
echo

# 创建必要的目录
echo "1. 创建数据目录..."
mkdir -p /tmp/hadoop-volumes/{namenode,datanode1,datanode2,yarnlogs}

# 构建标准优化版本
echo "2. 构建标准优化版本..."
docker build -t hadoop:optimized .

# 构建多阶段构建版本
echo "3. 构建多阶段构建版本..."
docker build -f Dockerfile.multistage -t hadoop:multistage .

# 构建Alpine Linux版本
echo "4. 构建Alpine Linux版本..."
docker build -f Dockerfile.alpine -t hadoop:alpine .

# 显示镜像大小对比
echo
echo "=== 镜像大小对比 ==="
echo "标准优化版本:"
docker images hadoop:optimized --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

echo "多阶段构建版本:"
docker images hadoop:multistage --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

echo "Alpine Linux版本:"
docker images hadoop:alpine --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

echo
echo "=== 基准镜像对比 ==="
echo "OpenJDK 11-slim基础镜像:"
docker images openjdk:11-slim --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

echo "Alpine Linux基础镜像:"
docker images alpine:3.18 --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

echo
echo "=== 构建完成 ==="
echo "可以使用以下命令启动集群:"
echo "docker-compose up -d"
echo
echo "或者使用特定版本:"
echo "docker-compose -f docker-compose-multistage.yml up -d"
echo "docker-compose -f docker-compose-alpine.yml up -d"