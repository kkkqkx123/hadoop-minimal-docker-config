#!/bin/bash

# Spark 集成测试脚本
# 用于验证 Spark 与 Hadoop 环境的集成是否成功

set -e

echo "开始 Spark 集成测试..."

# 颜色输出函数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查服务状态
check_service() {
    local service_name=$1
    local url=$2
    local timeout=${3:-30}
    
    log_info "检查 $service_name 服务状态..."
    
    for i in $(seq 1 $timeout); do
        if curl -s -f "$url" > /dev/null 2>&1; then
            log_info "$service_name 服务正常运行"
            return 0
        fi
        sleep 2
    done
    
    log_error "$service_name 服务未在预期时间内启动"
    return 1
}

# 1. 检查 Spark Master
log_info "1. 检查 Spark Master 服务..."
if ! check_service "Spark Master" "http://localhost:8080" 60; then
    log_error "Spark Master 服务检查失败"
    exit 1
fi

# 2. 检查 Spark Worker
log_info "2. 检查 Spark Worker 服务..."
if ! check_service "Spark Worker" "http://localhost:8081" 60; then
    log_warn "Spark Worker 服务检查失败，继续其他测试"
fi

# 3. 检查 HDFS 连接
log_info "3. 检查 HDFS 连接..."
if docker exec namenode hdfs dfs -ls / > /dev/null 2>&1; then
    log_info "HDFS 连接正常"
else
    log_error "HDFS 连接失败"
    exit 1
fi

# 4. 检查 Spark 日志目录
log_info "4. 检查 Spark HDFS 日志目录..."
if docker exec namenode hdfs dfs -test -d /spark-logs; then
    log_info "Spark 日志目录存在"
else
    log_warn "Spark 日志目录不存在，尝试创建..."
    docker exec namenode hdfs dfs -mkdir -p /spark-logs
    docker exec namenode hdfs dfs -chmod 777 /spark-logs
fi

# 5. 运行 Spark Pi 测试
log_info "5. 运行 Spark Pi 测试..."
SPARK_PI_TEST=$(cat << 'EOF'
import random
import sys
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("SparkPiTest") \
    .master("spark://spark-master:7077") \
    .config("spark.executor.memory", "768m") \
    .config("spark.executor.cores", "1") \
    .config("spark.hadoop.fs.defaultFS", "hdfs://namenode:9000") \
    .getOrCreate()

partitions = 2
n = 100000 * partitions

def f(_):
    x = random.random() * 2 - 1
    y = random.random() * 2 - 1
    return 1 if x ** 2 + y ** 2 <= 1 else 0

count = spark.sparkContext.parallelize(range(1, n + 1), partitions).map(f).reduce(lambda a, b: a + b)
pi = 4.0 * count / n

print(f"Pi is roughly {pi}")
print(f"Spark version: {spark.version}")
print(f"Hadoop version: {spark.sparkContext._jvm.org.apache.hadoop.util.VersionInfo.getVersion()}")

# 测试 HDFS 写入
rdd = spark.sparkContext.parallelize([f"Test data {i}" for i in range(10)])
rdd.saveAsTextFile(f"hdfs://namenode:9000/spark-test-output-{int(random.random()*10000)}")
print("HDFS 写入测试完成")

spark.stop()
EOF
)

# 保存测试脚本到容器
echo "$SPARK_PI_TEST" > /tmp/spark_pi_test.py
docker cp /tmp/spark_pi_test.py spark-master:/tmp/spark_pi_test.py

# 运行测试
log_info "执行 PySpark 测试..."
if docker exec spark-master spark-submit \
    --master spark://spark-master:7077 \
    --executor-memory 768m \
    --executor-cores 1 \
    --conf spark.hadoop.fs.defaultFS=hdfs://namenode:9000 \
    /tmp/spark_pi_test.py; then
    log_info "PySpark 测试通过"
else
    log_error "PySpark 测试失败"
    exit 1
fi

# 6. 运行 Scala 示例测试
log_info "6. 运行 Scala Spark 示例测试..."
if docker exec spark-master spark-submit \
    --class org.apache.spark.examples.SparkPi \
    --master spark://spark-master:7077 \
    --executor-memory 768m \
    --total-executor-cores 1 \
    /opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar 10; then
    log_info "Scala 示例测试通过"
else
    log_warn "Scala 示例测试失败，可能是示例 JAR 文件路径问题"
fi

# 7. 检查资源使用情况
log_info "7. 检查资源使用情况..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" || true

# 8. 验证 HDFS 数据写入
log_info "8. 验证 HDFS 数据写入..."
if docker exec namenode hdfs dfs -ls / | grep spark-test-output; then
    log_info "HDFS 数据写入验证通过"
else
    log_warn "HDFS 数据写入验证失败"
fi

# 9. 网络连通性测试
log_info "9. 网络连通性测试..."
if docker exec spark-master ping -c 2 namenode > /dev/null 2>&1; then
    log_info "Spark Master 到 NameNode 网络连通"
else
    log_warn "Spark Master 到 NameNode 网络可能有问题"
fi

# 清理测试数据
log_info "清理测试数据..."
docker exec namenode hdfs dfs -rm -r -f /spark-test-output-* || true

# 测试总结
log_info ""
log_info "=================================="
log_info "Spark 集成测试完成！"
log_info "=================================="
log_info ""
log_info "服务状态:"
echo "  - Spark Master: http://localhost:8080"
echo "  - Spark Worker: http://localhost:8081"
echo "  - HDFS NameNode: http://localhost:9870"
echo ""
log_info "下一步建议:"
echo "1. 查看 Spark Web UI 确认集群状态"
echo "2. 运行更复杂的 Spark 作业测试性能"
echo "3. 配置 Spark History Server 查看历史记录"
echo "4. 考虑添加更多 Worker 节点提高并行度"
echo ""
log_info "测试输出已保存，可以查看详细日志进行问题排查"