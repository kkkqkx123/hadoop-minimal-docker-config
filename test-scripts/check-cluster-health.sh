#!/bin/bash
# Hadoop集群健康检查脚本

set -e

echo "=== Hadoop集群健康检查 ==="

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

echo "1. 检查Java进程状态..."

# 获取Java进程列表
echo "   执行: jps"
jps_output=$(jps)

if [ $? -eq 0 ]; then
    test_passed "Java进程列表获取成功"
    
    # 检查关键进程
    namenode_count=$(echo "$jps_output" | grep -c "NameNode")
    datanode_count=$(echo "$jps_output" | grep -c "DataNode")
    resourcemanager_count=$(echo "$jps_output" | grep -c "ResourceManager")
    nodemanager_count=$(echo "$jps_output" | grep -c "NodeManager")
    secondarynamenode_count=$(echo "$jps_output" | grep -c "SecondaryNameNode")
    jobhistoryserver_count=$(echo "$jps_output" | grep -c "JobHistoryServer")
    
    test_info "NameNode进程: $namenode_count"
    test_info "DataNode进程: $datanode_count"
    test_info "ResourceManager进程: $resourcemanager_count"
    test_info "NodeManager进程: $nodemanager_count"
    test_info "SecondaryNameNode进程: $secondarynamenode_count"
    test_info "JobHistoryServer进程: $jobhistoryserver_count"
    
    # Master节点检查
    if [ "$namenode_count" -gt 0 ] && [ "$resourcemanager_count" -gt 0 ]; then
        test_passed "Master节点关键进程正常"
    else
        test_failed "Master节点关键进程缺失"
    fi
else
    test_failed "无法获取Java进程列表"
fi

echo ""
echo "2. 检查HDFS健康状况..."

# HDFS状态检查
echo "   执行: hdfs dfsadmin -report"
hdfs_report=$(hdfs dfsadmin -report 2>/dev/null)

if [ $? -eq 0 ]; then
    test_passed "HDFS状态报告获取成功"
    
    # 解析HDFS状态
    live_datanodes=$(echo "$hdfs_report" | grep "Live datanodes" | awk '{print $3}')
    dead_datanodes=$(echo "$hdfs_report" | grep "Dead datanodes" | awk '{print $3}')
    decommissioning_datanodes=$(echo "$hdfs_report" | grep "Decommissioning datanodes" | awk '{print $3}')
    
    total_capacity=$(echo "$hdfs_report" | grep "Configured Capacity:" | awk '{print $3}')
    used_capacity=$(echo "$hdfs_report" | grep "DFS Used:" | awk '{print $3}')
    remaining_capacity=$(echo "$hdfs_report" | grep "DFS Remaining:" | awk '{print $3}')
    
    test_info "Live DataNodes: $live_datanodes"
    test_info "Dead DataNodes: $dead_datanodes"
    test_info "Decommissioning DataNodes: ${decommissioning_datanodes:-0}"
    test_info "总容量: $total_capacity"
    test_info "已用容量: $used_capacity"
    test_info "剩余容量: $remaining_capacity"
    
    # 健康状态判断
    if [ "$dead_datanodes" -eq 0 ] && [ "$live_datanodes" -ge 2 ]; then
        test_passed "HDFS DataNode状态健康"
    else
        test_warning "HDFS DataNode状态异常"
    fi
    
    # 容量检查
    if [ -n "$total_capacity" ] && [ "$total_capacity" != "0" ]; then
        test_passed "HDFS容量正常"
    else
        test_warning "HDFS容量异常"
    fi
else
    test_failed "无法获取HDFS状态报告"
fi

echo ""
echo "3. 检查YARN健康状况..."

# YARN节点检查
echo "   执行: yarn node -list -all"
yarn_nodes=$(yarn node -list -all 2>/dev/null)

if [ $? -eq 0 ]; then
    test_passed "YARN节点列表获取成功"
    
    # 解析YARN节点状态
    total_nodes=$(echo "$yarn_nodes" | grep -c "Total nodes:")
    running_nodes=$(echo "$yarn_nodes" | grep -c "RUNNING")
    lost_nodes=$(echo "$yarn_nodes" | grep -c "LOST")
    unhealthy_nodes=$(echo "$yarn_nodes" | grep -c "UNHEALTHY")
    
    test_info "总节点数: $total_nodes"
    test_info "运行中节点: $running_nodes"
    test_info "丢失节点: $lost_nodes"
    test_info "不健康节点: $unhealthy_nodes"
    
    # 健康状态判断
    if [ "$lost_nodes" -eq 0 ] && [ "$unhealthy_nodes" -eq 0 ] && [ "$running_nodes" -ge 2 ]; then
        test_passed "YARN NodeManager状态健康"
    else
        test_warning "YARN NodeManager状态异常"
    fi
else
    test_failed "无法获取YARN节点列表"
fi

# YARN集群指标
echo "   执行: yarn cluster -metrics"
yarn_metrics=$(yarn cluster -metrics 2>/dev/null)

if [ $? -eq 0 ]; then
    test_passed "YARN集群指标获取成功"
    
    # 解析关键指标
    apps_submitted=$(echo "$yarn_metrics" | grep "appsSubmitted" | awk -F'=' '{print $2}' | tr -d ' ')
    apps_completed=$(echo "$yarn_metrics" | grep "appsCompleted" | awk -F'=' '{print $2}' | tr -d ' ')
    apps_failed=$(echo "$yarn_metrics" | grep "appsFailed" | awk -F'=' '{print $2}' | tr -d ' ')
    apps_killed=$(echo "$yarn_metrics" | grep "appsKilled" | awk -F'=' '{print $2}' | tr -d ' ')
    
    test_info "提交的应用: ${apps_submitted:-0}"
    test_info "完成的应用: ${apps_completed:-0}"
    test_info "失败的应用: ${apps_failed:-0}"
    test_info ** 被杀死的应用: ${apps_killed:-0}"
    
    if [ "${apps_failed:-0}" -eq 0 ] && [ "${apps_killed:-0}" -eq 0 ]; then
        test_passed "YARN应用状态健康"
    else
        test_warning "YARN应用存在失败或被杀死的实例"
    fi
else
    test_failed "无法获取YARN集群指标"
fi

echo ""
echo "4. 检查日志文件状态..."

# 检查日志目录
echo "   检查Hadoop日志目录..."
if [ -d "$HADOOP_HOME/logs" ]; then
    test_passed "日志目录存在: $HADOOP_HOME/logs"
    
    # 统计日志文件
    log_count=$(find "$HADOOP_HOME/logs" -name "*.log" 2>/dev/null | wc -l)
    test_info "日志文件数量: $log_count"
    
    # 检查最近的错误日志
    echo "   检查最近错误日志..."
    recent_errors=$(find "$HADOOP_HOME/logs" -name "*.log" -exec grep -l "ERROR" {} \; 2>/dev/null | head -3)
    if [ -n "$recent_errors" ]; then
        test_warning "发现包含ERROR的日志文件:"
        for log_file in $recent_errors; do
            test_info "  - $(basename "$log_file")"
        done
    else
        test_passed "未发现最近的ERROR日志"
    fi
else
    test_failed "日志目录不存在"
fi

echo ""
echo "5. 检查网络连接状态..."

# 检查到worker节点的网络连接
echo "   检查到worker1的网络连接..."
if ping -c 1 worker1 2>/dev/null; then
    test_passed "worker1网络连接正常"
else
    test_failed "worker1网络连接异常"
fi

echo "   检查到worker2的网络连接..."
if ping -c 1 worker2 2>/dev/null; then
    test_passed "worker2网络连接正常"
else
    test_failed "worker2网络连接异常"
fi

# 检查SSH连接（用于启动守护进程）
echo "   检查SSH连接..."
if ssh -o ConnectTimeout=5 worker1 "echo 'SSH test'" 2>/dev/null; then
    test_passed "worker1 SSH连接正常"
else
    test_warning "worker1 SSH连接可能有问题"
fi

if ssh -o ConnectTimeout=5 worker2 "echo 'SSH test'" 2>/dev/null; then
    test_passed "worker2 SSH连接正常"
else
    test_warning "worker2 SSH连接可能有问题"
fi

echo ""
echo "6. 检查磁盘空间..."

# 检查本地磁盘空间
echo "   检查本地磁盘空间..."
disk_usage=$(df -h / 2>/dev/null | tail -1)
if [ $? -eq 0 ]; then
    test_passed "本地磁盘空间检查完成"
    test_info "磁盘使用情况: $disk_usage"
    
    # 检查磁盘使用率
    disk_percent=$(echo "$disk_usage" | awk '{print $5}' | tr -d '%')
    if [ "$disk_percent" -lt 80 ]; then
        test_passed "磁盘使用率正常 (${disk_percent}%)"
    elif [ "$disk_percent" -lt 90 ]; then
        test_warning "磁盘使用率较高 (${disk_percent}%)"
    else
        test_failed "磁盘使用率过高 (${disk_percent}%)"
    fi
else
    test_failed "无法检查本地磁盘空间"
fi

# 检查HDFS空间使用情况
echo "   检查HDFS空间使用情况..."
if hdfs dfs -df -h 2>/dev/null; then
    test_passed "HDFS空间使用检查完成"
else
    test_warning "无法检查HDFS空间使用"
fi

echo ""
echo "7. 检查配置一致性..."

# 检查核心配置文件
echo "   检查核心配置文件..."
config_files=("core-site.xml" "hdfs-site.xml" "yarn-site.xml" "mapred-site.xml")
for config_file in "${config_files[@]}"; do
    if [ -f "$HADOOP_HOME/etc/hadoop/$config_file" ]; then
        test_passed "配置文件存在: $config_file"
    else
        test_failed "配置文件缺失: $config_file"
    fi
done

echo ""
echo "8. 综合健康评估..."

# 汇总健康状态
echo "   综合健康状态汇总:"
echo "   ===================="

# 这里可以添加一个综合评分系统
echo "   ✅ Java进程状态: $(test "${namenode_count:-0}" -gt 0 ] && echo "正常" || echo "异常")"
echo "   ✅ HDFS状态: $(test "${dead_datanodes:-0}" -eq 0 ] && echo "健康" || echo "异常")"
echo "   ✅ YARN状态: $(test "${lost_nodes:-0}" -eq 0 ] && echo "健康" || echo "异常")"
echo "   ✅ 网络连接: $(ping -c 1 worker1 2>/dev/null && ping -c 1 worker2 2>/dev/null && echo "正常" || echo "异常")"
echo "   ✅ 磁盘空间: $(test "${disk_percent:-100}" -lt 90 ] && echo "充足" || echo "不足")"

echo ""
echo "=== 集群健康检查完成 ==="
echo ""
echo "建议:"
echo "1. 定期检查日志文件中的ERROR和WARN信息"
echo "2. 监控磁盘空间使用情况"
echo "3. 关注失败的YARN应用"
echo "4. 保持DataNode和NodeManager的正常运行"
echo ""
echo "如发现异常，请查看详细日志: $HADOOP_HOME/logs/"