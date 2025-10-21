#!/bin/bash

# Hadoop Docker 快速初始化脚本
# 一键检查和创建挂载目录

echo "=========================================="
echo "Hadoop Docker 快速初始化"
echo "=========================================="

# 检查挂载目录
echo "检查挂载目录..."
missing_dirs=()

for dir in /tmp/hadoop-volumes/namenode /tmp/hadoop-volumes/datanode1 /tmp/hadoop-volumes/datanode2 /tmp/hadoop-volumes/yarnlogs; do
    if [ ! -d "$dir" ]; then
        missing_dirs+=("$dir")
        echo "❌ 缺失: $dir"
    else
        echo "✅ 存在: $dir"
    fi
done

# 如果有缺失的目录，创建它们
if [ ${#missing_dirs[@]} -gt 0 ]; then
    echo
echo "创建缺失的挂载目录..."
    for dir in "${missing_dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
        echo "✅ 创建: $dir"
    done
fi

echo
echo "✅ 挂载目录初始化完成！"
echo
echo "现在可以启动 Hadoop Docker 集群："
echo "  docker-compose up -d"
echo