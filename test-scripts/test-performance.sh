#!/bin/bash
# Hadoop集群性能测试脚本

set -e

echo "=== Hadoop集群性能测试 ==="

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_passed() {
    echo -e "${GREEN}✓ $1${NC}"
}

test_failed() {
    echo -e "${RED}✗ $1${NC}"
}

test_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

test_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 检查是否在master容器中
if [ ! -f "$HADOOP_HOME/bin/hadoop" ]; then
    test_failed "请在master容器中运行此脚本: docker exec -it master bash"
    exit 1
fi

# 创建测试数据目录
mkdir -p /tmp/perf-test

echo "1. HDFS I/O性能测试 (TestDFSIO)..."

# 清理之前的测试数据
echo "   清理之前的测试数据..."
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -clean 2>/dev/null || true

# 写性能测试
echo "   执行HDFS写性能测试..."
echo "   测试参数: 10个文件, 每个100MB"
write_test_start=$(date +%s)

write_output=$(hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -write -nrFiles 10 -fileSize 100MB 2>&1)
write_exit_code=$?
write_test_end=$(date +%s)
write_duration=$((write_test_end - write_test_start))

if [ $write_exit_code -eq 0 ]; then
    test_passed "HDFS写性能测试完成 (耗时: ${write_duration}s)"
    
    # 提取写性能指标
    write_throughput=$(echo "$write_output" | grep "Throughput" | grep "MB/sec" | head -1 | awk '{print $2}')
    write_avg_time=$(echo "$write_output" | grep "Average" | head -1 | awk '{print $3}')
    
    test_info "写吞吐量: ${write_throughput:-N/A} MB/sec"
    test_info "平均执行时间: ${write_avg_time:-N/A}"
else
    test_failed "HDFS写性能测试失败"
fi

# 读性能测试
echo "   执行HDFS读性能测试..."
read_test_start=$(date +%s)

read_output=$(hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -read -nrFiles 10 -fileSize 100MB 2>&1)
read_exit_code=$?
read_test_end=$(date +%s)
read_duration=$((read_test_end - read_test_start))

if [ $read_exit_code -eq 0 ]; then
    test_passed "HDFS读性能测试完成 (耗时: ${read_duration}s)"
    
    # 提取读性能指标
    read_throughput=$(echo "$read_output" | grep "Throughput" | grep "MB/sec" | tail -1 | awk '{print $2}')
    read_avg_time=$(echo "$read_output" | grep "Average" | tail -1 | awk '{print $3}')
    
    test_info "读吞吐量: ${read_throughput:-N/A} MB/sec"
    test_info "平均执行时间: ${read_avg_time:-N/A}"
else
    test_failed "HDFS读性能测试失败"
fi

# 清理测试数据
echo "   清理HDFS I/O测试数据..."
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -clean 2>/dev/null || true

echo ""
echo "2. TeraSort基准测试..."

# 生成测试数据
echo "   生成TeraSort测试数据 (100万条记录)..."
teragen_start=$(date +%s)

teragen_output=$(hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar teragen 1000000 /terasort-input 2>&1)
teragen_exit_code=$?
teragen_end=$(date +%s)
teragen_duration=$((teragen_end - teragen_start))

if [ $teragen_exit_code -eq 0 ]; then
    test_passed "TeraGen数据生成完成 (耗时: ${teragen_duration}s)"
    
    # 验证输入数据大小
    input_size=$(hdfs dfs -du -s -h /terasort-input 2>/dev/null | awk '{print $1}')
    test_info "输入数据大小: $input_size"
else
    test_failed "TeraGen数据生成失败"
    exit 1
fi

# 执行排序
echo "   执行TeraSort排序..."
terasort_start=$(date +%s)

terasort_output=$(hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar terasort /terasort-input /terasort-output 2>&1)
terasort_exit_code=$?
terasort_end=$(date +%s)
terasort_duration=$((terasort_end - terasort_start))

if [ $terasort_exit_code -eq 0 ]; then
    test_passed "TeraSort排序完成 (耗时: ${terasort_duration}s)"
    
    # 验证输出数据
    output_size=$(hdfs dfs -du -s -h /terasort-output 2>/dev/null | awk '{print $1}')
    test_info "输出数据大小: $output_size"
else
    test_failed "TeraSort排序失败"
fi

# 验证排序结果
echo "   验证TeraSort排序结果..."
teravalidate_start=$(date +%s)

teravalidate_output=$(hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar teravalidate /terasort-output /terasort-validate 2>&1)
teravalidate_exit_code=$?
teravalidate_end=$(date +%s)
teravalidate_duration=$((teravalidate_end - teravalidate_start))

if [ $teravalidate_exit_code -eq 0 ]; then
    test_passed "TeraValidate验证完成 (耗时: ${teravalidate_duration}s)"
    
    # 检查验证结果
    if echo "$teravalidate_output" | grep -q "SUCCESS"; then
        test_passed "排序验证成功 - 数据已正确排序"
    else
        test_warning "排序验证结果异常"
    fi
else
    test_failed "TeraValidate验证失败"
fi

echo ""
echo "3. WordCount性能测试..."

# 准备测试数据
echo "   准备WordCount测试数据..."
cat > /tmp/wordcount-input.txt << EOF
Hadoop is an open-source software framework used for distributed storage and processing of big data.
It provides massive storage for any kind of data, enormous processing power and the ability to handle virtually limitless concurrent tasks.
Hadoop is designed to scale up from single servers to thousands of machines, each offering local computation and storage.
The core of Apache Hadoop consists of a storage part, known as Hadoop Distributed File System (HDFS), and a processing part which is a MapReduce programming model.
Hadoop splits files into large blocks and distributes them across nodes in a cluster.
It then transfers packaged code into nodes to process the data in parallel.
This approach takes advantage of data locality, where nodes manipulate the data they have access to.
This allows the dataset to be processed faster and more efficiently than it would be in a more conventional supercomputer architecture.
EOF

# 创建多个输入文件副本
for i in {1..10}; do
    cp /tmp/wordcount-input.txt /tmp/wordcount-input-$i.txt
done

# 上传到HDFS
echo "   上传WordCount测试数据到HDFS..."
if hdfs dfs -mkdir -p /wordcount-input 2>/dev/null; then
    for i in {1..10}; do
        hdfs dfs -put /tmp/wordcount-input-$i.txt /wordcount-input/ 2>/dev/null
    done
    test_passed "WordCount测试数据上传成功"
else
    test_failed "WordCount测试数据上传失败"
fi

# 执行WordCount
echo "   执行WordCount作业..."
wordcount_start=$(date +%s)

wordcount_output=$(hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /wordcount-input /wordcount-output 2>&1)
wordcount_exit_code=$?
wordcount_end=$(date +%s)
wordcount_duration=$((wordcount_end - wordcount_start))

if [ $wordcount_exit_code -eq 0 ]; then
    test_passed "WordCount作业完成 (耗时: ${wordcount_duration}s)"
    
    # 验证输出结果
    if hdfs dfs -ls /wordcount-output/_SUCCESS 2>/dev/null; then
        test_passed "WordCount作业成功标记验证通过"
        
        # 显示词频统计结果（前20个）
        echo "   词频统计结果（前20个）:"
        hdfs dfs -cat /wordcount-output/part-r-* 2>/dev/null | head -20
    else
        test_warning "WordCount作业成功标记未找到"
    fi
else
    test_failed "WordCount作业失败"
fi

echo ""
echo "4. 集群资源利用率测试..."

# 并行提交多个作业
echo "   并行提交多个作业测试资源调度..."

# 启动后台作业
for i in {1..3}; do
    (
        hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 10 100 > /tmp/pi-job-$i.log 2>&1
    ) &
    job_pids[$i]=$!
done

# 等待所有作业完成
echo "   等待所有并行作业完成..."
for i in {1..3}; do
    wait ${job_pids[$i]}
    if [ $? -eq 0 ]; then
        test_passed "并行作业 $i 完成"
    else
        test_failed "并行作业 $i 失败"
    fi
done

echo ""
echo "5. 网络I/O性能测试..."

# 测试DataNode间数据传输
echo "   测试DataNode间数据传输性能..."

# 创建大文件并复制到不同位置
echo "   创建测试文件并验证分布式存储..."
dd if=/dev/zero of=/tmp/network-test.dat bs=1M count=50 2>/dev/null

if hdfs dfs -put /tmp/network-test.dat /network-test.dat 2>/dev/null; then
    # 获取文件块信息
    block_info=$(hdfs fsck /network-test.dat -files -blocks 2>/dev/null)
    if [ $? -eq 0 ]; then
        test_passed "网络I/O测试文件创建成功"
        
        # 显示块分布信息
        blocks_count=$(echo "$block_info" | grep -c "blk_")
        test_info "文件块数量: $blocks_count"
        
        echo "$block_info" | grep "DatanodeInfoWithStorage" | head -5
    fi
    
    # 清理测试文件
    hdfs dfs -rm /network-test.dat 2>/dev/null
fi

# 清理本地文件
rm -f /tmp/network-test.dat

echo ""
echo "6. 清理所有测试数据..."

# 清理HDFS测试数据
hdfs dfs -rm -r /terasort-input /terasort-output /terasort-validate 2>/dev/null || true
hdfs dfs -rm -r /wordcount-input /wordcount-output 2>/dev/null || true

# 清理本地测试数据
rm -f /tmp/wordcount-input*.txt /tmp/wordcount-input.txt
rm -f /tmp/pi-job-*.log
rm -rf /tmp/perf-test

echo ""
echo "=== 性能测试完成 ==="
echo ""
echo "性能测试总结:"
echo "1. HDFS I/O性能测试:"
echo "   - 写吞吐量: ${write_throughput:-N/A} MB/sec"
echo "   - 读吞吐量: ${read_throughput:-N/A} MB/sec"
echo ""
echo "2. TeraSort基准测试:"
echo "   - 数据生成耗时: ${teragen_duration}s"
echo "   - 排序耗时: ${terasort_duration}s"
echo "   - 验证耗时: ${teravalidate_duration}s"
echo ""
echo "3. WordCount性能测试:"
echo "   - 作业执行耗时: ${wordcount_duration}s"
echo ""
echo "注意: 性能结果会因硬件配置、集群负载等因素而异"
echo "建议多次测试取平均值以获得更准确的性能评估"