#!/bin/bash
# Hadoop集群快速测试脚本

echo "=== Hadoop集群快速测试 ==="

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_passed() {
    echo -e "${GREEN}✓ $1${NC}"
}

test_failed() {
    echo -e "${RED}✗ $1${NC}"
}

test_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 1. 检查容器状态
echo "1. 检查容器状态..."
if docker-compose ps | grep -q "Up"; then
    test_passed "容器运行正常"
else
    test_failed "容器未正常运行"
    exit 1
fi

# 2. 检查Web UI端口
echo "2. 检查Web UI端口..."
check_port() {
    local port=$1
    local name=$2
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port | grep -q "200"; then
        test_passed "$name Web UI 正常 (端口: $port)"
    else
        test_warning "$name Web UI 无法访问 (端口: $port)"
    fi
}

check_port 9870 "NameNode"
check_port 8088 "ResourceManager"

# 3. 检查HDFS状态
echo "3. 检查HDFS状态..."
if docker exec master hdfs dfsadmin -report 2>/dev/null | grep -q "Live datanodes"; then
    datanodes=$(docker exec master hdfs dfsadmin -report 2>/dev/null | grep "Live datanodes" | awk '{print $3}')
    test_passed "HDFS正常 - DataNode数量: $datanodes"
else
    test_failed "HDFS状态异常"
fi

# 4. 检查YARN状态
echo "4. 检查YARN状态..."
if docker exec master yarn node -list 2>/dev/null | grep -q "RUNNING"; then
    nodemanagers=$(docker exec master yarn node -list 2>/dev/null | grep -c "RUNNING")
    test_passed "YARN正常 - NodeManager数量: $nodemanagers"
else
    test_failed "YARN状态异常"
fi

# 5. 简单文件操作测试
echo "5. 文件操作测试..."
docker exec master bash -c "
    echo 'test data' > /tmp/test.txt 2>/dev/null &&
    hdfs dfs -mkdir -p /test 2>/dev/null &&
    hdfs dfs -put /tmp/test.txt /test/ 2>/dev/null &&
    hdfs dfs -cat /test/test.txt 2>/dev/null &&
    hdfs dfs -rm /test/test.txt 2>/dev/null &&
    hdfs dfs -rmdir /test 2>/dev/null
" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    test_passed "HDFS文件操作正常"
else
    test_failed "HDFS文件操作失败"
fi

# 6. MapReduce作业测试（可选）
echo "6. MapReduce作业测试..."
docker exec master bash -c "
    echo 'hello world hello hadoop' > /tmp/wordcount.txt &&
    hdfs dfs -mkdir -p /test-input 2>/dev/null &&
    hdfs dfs -put /tmp/wordcount.txt /test-input/ 2>/dev/null &&
    hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /test-input /test-output 2>/dev/null &&
    hdfs dfs -cat /test-output/part-r-00000 2>/dev/null &&
    hdfs dfs -rm -r /test-input /test-output 2>/dev/null
" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    test_passed "MapReduce作业执行正常"
else
    test_warning "MapReduce作业执行失败（可能需要更多资源）"
fi

echo ""
echo "=== 快速测试完成 ==="
echo "如需详细测试，请查看完整测试指南"