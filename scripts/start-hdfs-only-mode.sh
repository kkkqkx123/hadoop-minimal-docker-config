#!/bin/bash

# HDFS-Only 模式启动脚本
# 仅启动HDFS服务，与Spark Standalone配合使用

set -e

echo "=========================================="
echo "启动 HDFS-Only + Spark Standalone 模式"
echo "=========================================="

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查Docker环境
echo -e "${YELLOW}检查Docker环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: Docker Compose未安装${NC}"
    exit 1
fi

# 创建必要的目录
echo -e "${YELLOW}创建数据目录...${NC}"
mkdir -p data/spark-logs data/spark-work data/spark-history notebooks

# 设置目录权限
chmod 755 data/spark-logs data/spark-work data/spark-history notebooks

# 启动HDFS-only模式
echo -e "${YELLOW}启动HDFS服务...${NC}"
docker-compose -f docker-compose-hdfs-only.yml up -d

# 等待HDFS启动
echo -e "${YELLOW}等待HDFS服务启动...${NC}"
sleep 30

# 检查HDFS状态
echo -e "${YELLOW}检查HDFS状态...${NC}"
if curl -s -f http://localhost:9870 > /dev/null; then
    echo -e "${GREEN}✓ NameNode启动成功${NC}"
else
    echo -e "${RED}✗ NameNode启动失败${NC}"
    exit 1
fi

if curl -s -f http://localhost:9864 > /dev/null; then
    echo -e "${GREEN}✓ DataNode启动成功${NC}"
else
    echo -e "${RED}✗ DataNode启动失败${NC}"
    exit 1
fi

# 初始化HDFS目录
echo -e "${YELLOW}初始化HDFS目录...${NC}"
./scripts/init-spark-hdfs.sh

# 启动Spark Standalone
echo -e "${YELLOW}启动Spark Standalone...${NC}"
docker-compose -f docker-compose-spark.yml up -d

# 等待Spark启动
echo -e "${YELLOW}等待Spark服务启动...${NC}"
sleep 20

# 检查Spark状态
echo -e "${YELLOW}检查Spark状态...${NC}"
if curl -s -f http://localhost:8080 > /dev/null; then
    echo -e "${GREEN}✓ Spark Master启动成功${NC}"
else
    echo -e "${RED}✗ Spark Master启动失败${NC}"
    exit 1
fi

if curl -s -f http://localhost:8081 > /dev/null; then
    echo -e "${GREEN}✓ Spark Worker启动成功${NC}"
else
    echo -e "${RED}✗ Spark Worker启动失败${NC}"
    exit 1
fi

# 显示状态信息
echo ""
echo "=========================================="
echo -e "${GREEN}HDFS-Only + Spark Standalone 模式启动成功！${NC}"
echo "=========================================="
echo ""
echo "服务访问地址:"
echo "  • HDFS NameNode UI: http://localhost:9870"
echo "  • HDFS DataNode UI:  http://localhost:9864"
echo "  • Spark Master UI:   http://localhost:8080"
echo "  • Spark Worker UI:   http://localhost:8081"
echo "  • Spark History:     http://localhost:18080"
echo ""
echo "资源使用对比:"
echo "  • HDFS-Only模式:     ~2GB内存"
echo "  • 完整Hadoop模式:    ~4GB内存"
echo "  • 节省资源:          ~2GB内存"
echo ""
echo "常用命令:"
echo "  • 查看运行状态:      docker-compose -f docker-compose-hdfs-only.yml ps"
echo "  • 查看日志:          docker-compose -f docker-compose-hdfs-only.yml logs [service]"
echo "  • 停止服务:          ./scripts/stop-hdfs-only-mode.sh"
echo ""
echo -e "${YELLOW}注意: 此模式已禁用MapReduce和YARN，仅保留HDFS存储服务${NC}"
echo "=========================================="