#!/bin/bash
# YARN功能详细测试脚本

set -e

echo "=== YARN功能详细测试 ==="

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
if [ ! -f "$HADOOP_HOME/bin/yarn" ]; then
    test_failed "请在master容器中运行此脚本: docker exec -it master bash"
    exit 1
fi

echo "1. 检查YARN集群状态..."

# 获取节点列表
echo "   执行: yarn node -list -all"
node_list=$(yarn node -list -all 2>/dev/null)

if [ $? -eq 0 ]; then
    test_passed "YARN节点列表获取成功"
    
    # 统计节点数量
    total_nodes=$(echo "$node_list" | grep -c "Total nodes:")
    running_nodes=$(echo "$node_list" | grep -c "RUNNING")
    
    test_info "总节点数: $total_nodes"
    test_info "运行中节点数: $running_nodes"
    
    if [ "$running_nodes" -ge 2 ]; then
        test_passed "NodeManager数量符合要求 (≥2)"
    else
        test_failed "NodeManager数量不足 (需要≥2，实际:$running_nodes)"
    fi
else
    test_failed "无法获取YARN节点列表"
    exit 1
fi

echo ""
echo "2. 检查YARN集群指标..."

# 获取集群指标
echo "   执行: yarn cluster -metrics"
cluster_metrics=$(yarn cluster -metrics 2>/dev/null)

if [ $? -eq 0 ]; then
    test_passed "YARN集群指标获取成功"
    
    # 提取关键指标
    apps_submitted=$(echo "$cluster_metrics" | grep "appsSubmitted" | awk -F'=' '{print $2}' | tr -d ' ')
    apps_completed=$(echo "$cluster_metrics" | grep "appsCompleted" | awk -F'=' '{print $2}' | tr -d ' ')
    memory_total=$(echo "$cluster_metrics" | grep "totalMB" | awk -F'=' '{print $2}' | tr -d ' ')
    memory_used=$(echo "$cluster_metrics" | grep "usedMB" | awk -F'=' '{print $2}' | tr -d ' ')
    
    test_info "应用提交数: ${apps_submitted:-0}"
    test_info "应用完成数: ${apps_completed:-0}"
    test_info "总内存: ${memory_total:-0} MB"
    test_info "已用内存: ${memory_used:-0} MB"
else
    test_failed "无法获取YARN集群指标"
fi

echo ""
echo "3. 检查队列状态..."

# 获取队列信息
echo "   执行: yarn queue -status default"
queue_status=$(yarn queue -status default 2>/dev/null)

if [ $? -eq 0 ]; then
    test_passed "默认队列状态获取成功"
    
    # 提取队列信息
    queue_state=$(echo "$queue_status" | grep "State" | awk -F':' '{print $2}' | tr -d ' ')
    queue_capacity=$(echo "$queue_status" | grep "Capacity" | awk -F':' '{print $2}' | tr -d ' ')
    queue_used=$(echo "$queue_status" | grep "Used Capacity" | awk -F':' '{print $2}' | tr -d ' ')
    
    test_info "队列状态: $queue_state"
    test_info "队列容量: $queue_capacity"
    test_info "已用容量: $queue_used"
    
    if [ "$queue_state" = "RUNNING" ]; then
        test_passed "默认队列为运行状态"
    else
        test_warning "默认队列状态异常: $queue_state"
    fi
else
    test_failed "无法获取默认队列状态"
fi

echo ""
echo "4. 测试简单MapReduce作业..."

# 准备测试数据
echo "   准备测试数据..."
mkdir -p /tmp/yarn-test
echo "hello world hello yarn" > /tmp/yarn-test/input.txt
echo "yarn resource manager test" >> /tmp/yarn-test/input.txt
echo "map reduce job execution" >> /tmp/yarn-test/input.txt

# 上传到HDFS
echo "   上传数据到HDFS..."
if hdfs dfs -mkdir -p /yarn-test-input 2>/dev/null && \
   hdfs dfs -put /tmp/yarn-test/input.txt /yarn-test-input/ 2>/dev/null; then
    test_passed "测试数据上传成功"
else
    test_failed "测试数据上传失败"
    exit 1
fi

# 提交WordCount作业
echo "   提交WordCount作业..."
job_output=$(yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /yarn-test-input /yarn-test-output 2>&1)
job_exit_code=$?

if [ $job_exit_code -eq 0 ]; then
    test_passed "WordCount作业提交成功"
    
    # 获取应用ID
    app_id=$(echo "$job_output" | grep "Submitted application" | awk '{print $3}')
    if [ -n "$app_id" ]; then
        test_info "应用ID: $app_id"
        
        # 等待作业完成
        echo "   等待作业完成..."
        sleep 5
        
        # 检查作业状态
        app_status=$(yarn application -status $app_id 2>/dev/null | grep "State" | head -1 | awk -F':' '{print $2}' | tr -d ' ')
        if [ "$app_status" = "FINISHED" ]; then
            test_passed "作业成功完成"
            
            # 检查最终结果
            echo "   验证输出结果..."
            if hdfs dfs -cat /yarn-test-output/part-r-00000 2>/dev/null; then
                test_passed "输出结果验证成功"
            else
                test_failed "无法读取输出结果"
            fi
        else
            test_failed "作业状态异常: $app_status"
        fi
    fi
else
    test_failed "WordCount作业提交失败"
    echo "错误信息: $job_output"
fi

echo ""
echo "5. 测试YARN应用管理..."

# 列出所有应用
echo "   列出所有应用..."
if yarn application -list 2>/dev/null; then
    test_passed "应用列表获取成功"
else
    test_failed "无法获取应用列表"
fi

# 获取应用统计
echo "   获取应用统计信息..."
app_stats=$(yarn application -list -appStates FINISHED 2>/dev/null | tail -n +3)
if [ $? -eq 0 ]; then
    finished_apps=$(echo "$app_stats" | grep -c "FINISHED" 2>/dev/null || echo "0")
    test_info "已完成应用数: $finished_apps"
fi

echo ""
echo "6. 测试NodeManager信息..."

# 获取NodeManager详细信息
echo "   获取NodeManager详细信息..."
nm_info=$(yarn node -status $(yarn node -list 2>/dev/null | grep "RUNNING" | head -1 | awk '{print $1}') 2>/dev/null)
if [ $? -eq 0 ]; then
    test_passed "NodeManager详细信息获取成功"
    
    # 提取NodeManager信息
    nm_state=$(echo "$nm_info" | grep "Node State" | awk -F':' '{print $2}' | tr -d ' ')
    nm_health=$(echo "$nm_info" | grep "Node Health" | awk -F':' '{print $2}' | tr -d ' ')
    
    test_info "NodeManager状态: $nm_state"
    test_info "NodeManager健康: $nm_health"
else
    test_warning "无法获取NodeManager详细信息"
fi

echo ""
echo "7. 测试资源调度..."

# 检查资源分配
echo "   检查资源分配情况..."
scheduler_info=$(yarn scheduler 2>/dev/null)
if [ $? -eq 0 ]; then
    test_passed "调度器信息获取成功"
    
    # 显示队列资源使用情况
    echo "$scheduler_info" | grep -A 10 "Queue Name" | head -20
else
    test_failed "无法获取调度器信息"
fi

echo ""
echo "8. 清理测试数据..."

# 清理HDFS数据
echo "   清理HDFS测试数据..."
if hdfs dfs -rm -r /yarn-test-input /yarn-test-output 2>/dev/null; then
    test_passed "HDFS测试数据清理成功"
else
    test_warning "HDFS测试数据清理失败"
fi

# 清理本地数据
echo "   清理本地临时文件..."
rm -rf /tmp/yarn-test

echo ""
echo "9. 性能指标检查..."

# 获取集群利用率
echo "   获取集群利用率..."
cluster_util=$(yarn cluster -utilization 2>/dev/null)
if [ $? -eq 0 ]; then
    test_passed "集群利用率获取成功"
    echo "$cluster_util"
else
    test_warning "无法获取集群利用率"
fi

echo ""
echo "=== YARN功能测试完成 ==="
echo "所有测试已执行完毕，请检查是否有失败项"
echo "如有失败，请查看YARN日志获取详细信息"
echo "日志位置: $HADOOP_HOME/logs/"
echo ""
echo "Web UI访问地址:"
echo "  ResourceManager: http://localhost:8088"
echo "  NodeManager(worker1): http://localhost:8042"
echo "  NodeManager(worker2): http://localhost:8043"