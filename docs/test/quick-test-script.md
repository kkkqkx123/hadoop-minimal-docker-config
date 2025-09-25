# Hadoop集群快速测试脚本

这是一个简化的快速测试脚本，用于快速验证Docker部署的Hadoop集群是否正常工作。

## 使用方法

### 1. 一键快速测试脚本

创建文件 `quick-test-hadoop.sh`：

```bash
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
```

### 2. 使用方法

```bash
# 赋予执行权限
chmod +x quick-test-hadoop.sh

# 运行测试
./quick-test-hadoop.sh
```

## 预期输出

正常运行时的输出示例：

```
=== Hadoop集群快速测试 ===
1. 检查容器状态...
✓ 容器运行正常
2. 检查Web UI端口...
✓ NameNode Web UI 正常 (端口: 9870)
✓ ResourceManager Web UI 正常 (端口: 8088)
3. 检查HDFS状态...
✓ HDFS正常 - DataNode数量: 2
4. 检查YARN状态...
✓ YARN正常 - NodeManager数量: 2
5. 文件操作测试...
✓ HDFS文件操作正常
6. MapReduce作业测试...
✓ MapReduce作业执行正常

=== 快速测试完成 ===
如需详细测试，请查看完整测试指南
```

## 故障排查

如果测试失败，请按以下步骤排查：

### 1. 容器未运行
```bash
# 查看容器状态
docker-compose ps

# 重启容器
docker-compose restart

# 查看日志
docker-compose logs
```

### 2. Web UI无法访问
```bash
# 检查端口占用
netstat -tlnp | grep 9870
netstat -tlnp | grep 8088

# 检查防火墙
sudo ufw status
```

### 3. HDFS/YARN状态异常
```bash
# 进入master容器检查
docker exec -it master bash

# 检查进程
jps

# 查看日志
tail -f $HADOOP_HOME/logs/*.log
```

### 4. 作业执行失败
```bash
# 检查资源使用情况
docker stats

# 检查YARN资源
yarn cluster -metrics

# 查看作业日志
yarn logs -applicationId <application_id>
```

## 高级测试选项

### 性能测试
如果需要更详细的性能测试，可以使用以下命令：

```bash
# HDFS读写性能测试
docker exec master hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -write -nrFiles 10 -fileSize 100MB

# TeraSort测试
docker exec master hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar teragen 1000000 /terasort-input
docker exec master hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar terasort /terasort-input /terasort-output
```

### 持续监控
```bash
# 实时监控资源使用
docker stats

# 监控日志
docker-compose logs -f
```

## 注意事项

1. **资源需求**: 确保宿主机至少有4GB可用内存
2. **网络配置**: 确保Docker网络配置正确
3. **数据清理**: 测试完成后可清理测试数据
4. **日志管理**: 定期清理日志文件避免磁盘空间不足

这个快速测试脚本可以帮助您快速验证Hadoop集群的基本功能是否正常。如果所有测试都通过，说明您的Docker Hadoop部署运行良好。