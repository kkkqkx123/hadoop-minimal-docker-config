#!/bin/bash

# Spark HDFS 初始化脚本
# 用于在 Hadoop 环境中创建 Spark 所需的 HDFS 目录和权限

set -e

echo "开始初始化 Spark 所需的 HDFS 目录..."

# 检查 Hadoop 是否可用
if ! docker exec namenode hdfs dfs -ls / > /dev/null 2>&1; then
    echo "错误: Hadoop HDFS 不可用，请确保 Hadoop 服务正在运行"
    exit 1
fi

# 创建 Spark 日志目录
echo "创建 Spark 日志目录..."
docker exec namenode hdfs dfs -mkdir -p /spark-logs || true
docker exec namenode hdfs dfs -chmod 777 /spark-logs || true

# 创建 Spark 临时目录
echo "创建 Spark 临时目录..."
docker exec namenode hdfs dfs -mkdir -p /tmp/spark || true
docker exec namenode hdfs dfs -chmod 777 /tmp/spark || true

# 创建 Spark 数据目录
echo "创建 Spark 数据目录..."
docker exec namenode hdfs dfs -mkdir -p /spark-data || true
docker exec namenode hdfs dfs -chmod 755 /spark-data || true

# 创建 Spark 检查点目录
echo "创建 Spark 检查点目录..."
docker exec namenode hdfs dfs -mkdir -p /spark-checkpoint || true
docker exec namenode hdfs dfs -chmod 755 /spark-checkpoint || true

# 创建 Spark 仓库目录
echo "创建 Spark 仓库目录..."
docker exec namenode hdfs dfs -mkdir -p /user/spark/warehouse || true
docker exec namenode hdfs dfs -chmod 755 /user/spark || true
docker exec namenode hdfs dfs -chmod 755 /user/spark/warehouse || true

# 验证目录创建
echo "验证 HDFS 目录创建状态..."
docker exec namenode hdfs dfs -ls -R / | grep -E "(spark-logs|tmp/spark|spark-data|spark-checkpoint|user/spark)" || true

# 检查目录权限
echo "检查目录权限..."
docker exec namenode hdfs dfs -ls -d /spark-logs /tmp/spark /spark-data /spark-checkpoint /user/spark || true

echo "Spark HDFS 目录初始化完成！"
echo ""
echo "已创建的目录:"
echo "  - /spark-logs      (权限: 777) - Spark 事件日志"
echo "  - /tmp/spark       (权限: 777) - Spark 临时文件"
echo "  - /spark-data      (权限: 755) - Spark 数据文件"
echo "  - /spark-checkpoint (权限: 755) - Spark 检查点"
echo "  - /user/spark/warehouse (权限: 755) - Spark SQL 仓库"
echo ""
echo "下一步:"
echo "1. 启动 Spark 服务: docker-compose -f docker-compose-spark.yml up -d"
echo "2. 验证 Spark 服务: curl http://localhost:8080"
echo "3. 运行测试应用: ./scripts/test-spark-integration.sh"