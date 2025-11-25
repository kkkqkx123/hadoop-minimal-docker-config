#!/bin/bash

# 单节点HDFS-Only模式启动脚本
# 仅启动HDFS服务，禁用MapReduce和YARN，最小化资源占用

set -e

echo "=========================================="
echo "启动单节点HDFS-Only模式（禁用MapReduce）"
echo "=========================================="

# 检查Docker环境
if ! command -v docker &> /dev/null; then
    echo "错误：未安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误：未安装docker-compose"
    exit 1
fi

# 创建必要目录
echo "创建数据目录..."
mkdir -p data notebooks logs

# 停止并移除现有容器
echo "清理现有容器..."
docker-compose -f docker-compose-hdfs-only.yml down --volumes --remove-orphans 2>/dev/null || true

# 启动HDFS-Only服务
echo "启动HDFS-Only服务..."
docker-compose -f docker-compose-hdfs-only.yml up -d

# 等待服务启动
echo "等待HDFS服务启动..."
sleep 30

# 检查服务状态
echo "检查服务状态..."
docker-compose -f docker-compose-hdfs-only.yml ps

# 验证HDFS功能
echo "验证HDFS功能..."
if docker exec hadoop-pseudo hdfs dfs -ls / >/dev/null 2>&1; then
    echo "✅ HDFS服务正常运行"
else
    echo "❌ HDFS服务异常，请检查日志"
    docker logs hadoop-pseudo
    exit 1
fi

# 显示服务访问信息
echo ""
echo "=========================================="
echo "HDFS-Only模式启动成功！"
echo "=========================================="
echo ""
echo "🌐 Web界面访问："
echo "   NameNode Web UI: http://localhost:9870"
echo "   DataNode Web UI:  http://localhost:9864"
echo "   Spark Master UI:  http://localhost:8080 (如果启用)"
echo ""
echo "📊 资源使用："
echo "   内存占用：约2GB (节省约1.5GB)"
echo "   CPU占用：约1.8核 (节省约2核)"
echo ""
echo "🔧 常用命令："
echo "   # 查看HDFS文件"
echo "   docker exec hadoop-pseudo hdfs dfs -ls /"
echo ""
echo "   # 上传文件到HDFS"
echo "   docker exec hadoop-pseudo hdfs dfs -put localfile /data/"
echo ""
echo "   # 从HDFS下载文件"
echo "   docker exec hadoop-pseudo hdfs dfs -get /data/remotefile localfile"
echo ""
echo "   # 查看容器日志"
echo "   docker logs hadoop-pseudo"
echo ""
echo "   # 停止服务"
echo "   docker-compose -f docker-compose-hdfs-only.yml down"
echo ""
echo "✨ 特点："
echo "   • 仅HDFS存储功能，无MapReduce计算框架"
echo "   • 最小化资源占用，适合开发测试"
echo "   • Spark Standalone可独立运行，通过HDFS API访问数据"
echo "   • 完全兼容现有HDFS工具和API"
echo "=========================================="