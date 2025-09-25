#!/bin/bash
# Hadoop集群完整测试套件 - 一键执行所有测试

set -e

echo "=========================================="
echo "    Hadoop集群完整测试套件"
echo "=========================================="
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
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

test_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否在master容器中
if [ ! -f "$HADOOP_HOME/bin/hadoop" ]; then
    test_failed "请在master容器中运行此脚本: docker exec -it master bash"
    test_info "脚本位置: $SCRIPT_DIR"
    exit 1
fi

# 检查脚本是否存在
check_scripts() {
    local missing_scripts=()
    local required_scripts=(
        "quick-test-hadoop.sh"
        "test-hdfs.sh"
        "test-yarn.sh"
        "test-performance.sh"
        "check-cluster-health.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        test_failed "缺少必要的测试脚本:"
        for script in "${missing_scripts[@]}"; do
            echo "  - $script"
        done
        exit 1
    fi
    
    test_passed "所有测试脚本检查完成"
}

# 显示测试菜单
show_menu() {
    echo "请选择要执行的测试:"
    echo ""
    echo "1) 快速测试 (推荐) - 验证基本功能"
    echo "2) 完整测试 - 执行所有测试项目"
    echo "3) 自定义测试 - 选择特定测试"
    echo "4) 仅健康检查 - 快速健康评估"
    echo "5) 退出"
    echo ""
}

# 执行快速测试
run_quick_test() {
    test_header "=== 执行快速测试 ==="
    echo ""
    
    cd "$SCRIPT_DIR"
    ./quick-test-hadoop.sh
    
    echo ""
    test_passed "快速测试完成"
}

# 执行完整测试
run_full_test() {
    test_header "=== 执行完整测试套件 ==="
    echo ""
    test_info "预计执行时间: 30-60分钟"
    echo ""
    
    cd "$SCRIPT_DIR"
    
    # 1. 快速测试
    test_header "1. 快速功能测试"
    ./quick-test-hadoop.sh
    echo ""
    
    # 2. 健康检查
    test_header "2. 集群健康检查"
    ./check-cluster-health.sh
    echo ""
    
    # 3. HDFS详细测试
    test_header "3. HDFS详细功能测试"
    ./test-hdfs.sh
    echo ""
    
    # 4. YARN详细测试
    test_header "4. YARN详细功能测试"
    ./test-yarn.sh
    echo ""
    
    # 5. 性能测试
    test_header "5. 性能基准测试"
    test_info "注意: 性能测试需要较长时间，请耐心等待..."
    ./test-performance.sh
    echo ""
    
    test_passed "完整测试套件执行完成"
}

# 执行自定义测试
run_custom_test() {
    test_header "=== 自定义测试选择 ==="
    echo ""
    
    local tests=(
        "快速测试 (quick-test-hadoop.sh)"
        "HDFS测试 (test-hdfs.sh)"
        "YARN测试 (test-yarn.sh)"
        "性能测试 (test-performance.sh)"
        "健康检查 (check-cluster-health.sh)"
    )
    
    local scripts=(
        "quick-test-hadoop.sh"
        "test-hdfs.sh"
        "test-yarn.sh"
        "test-performance.sh"
        "check-cluster-health.sh"
    )
    
    echo "请选择要执行的测试 (输入数字，多个选择用空格分隔):"
    for i in "${!tests[@]}"; do
        echo "$((i+1))) ${tests[$i]}"
    done
    echo ""
    
    read -p "输入选择 (例如: 1 3 5): " choices
    
    cd "$SCRIPT_DIR"
    
    for choice in $choices; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#tests[@]}" ]; then
            index=$((choice-1))
            test_header "执行: ${tests[$index]}"
            ./"${scripts[$index]}"
            echo ""
        else
            test_warning "无效的选择: $choice"
        fi
    done
    
    test_passed "自定义测试执行完成"
}

# 仅健康检查
run_health_check() {
    test_header "=== 集群健康检查 ==="
    echo ""
    
    cd "$SCRIPT_DIR"
    ./check-cluster-health.sh
    
    echo ""
    test_passed "健康检查完成"
}

# 生成测试报告
generate_report() {
    local report_file="/tmp/hadoop-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    test_header "=== 生成测试报告 ==="
    echo ""
    test_info "报告文件: $report_file"
    
    {
        echo "Hadoop集群测试报告"
        echo "===================="
        echo "生成时间: $(date)"
        echo "测试主机: $(hostname)"
        echo "Hadoop版本: $(hadoop version | head -1)"
        echo "Java版本: $(java -version 2>&1 | head -1)"
        echo ""
        echo "集群状态摘要:"
        echo "- NameNode: $(jps | grep -c NameNode)"
        echo "- DataNode: $(jps | grep -c DataNode)"
        echo "- ResourceManager: $(jps | grep -c ResourceManager)"
        echo "- NodeManager: $(jps | grep -c NodeManager)"
        echo ""
        echo "HDFS状态:"
        hdfs dfsadmin -report 2>/dev/null | head -10
        echo ""
        echo "YARN状态:"
        yarn node -list 2>/dev/null | head -5
        echo ""
        echo "详细测试结果请参考上述输出"
    } > "$report_file"
    
    test_passed "测试报告已生成: $report_file"
}

# 主程序
main() {
    # 检查脚本
    check_scripts
    
    echo ""
    test_info "当前时间: $(date)"
    test_info "Hadoop版本: $(hadoop version | head -1)"
    echo ""
    
    while true; do
        show_menu
        read -p "请输入选择 (1-5): " choice
        
        case $choice in
            1)
                run_quick_test
                generate_report
                break
                ;;
            2)
                run_full_test
                generate_report
                break
                ;;
            3)
                run_custom_test
                generate_report
                break
                ;;
            4)
                run_health_check
                break
                ;;
            5)
                test_info "退出测试"
                exit 0
                ;;
            *)
                test_failed "无效的选择，请输入1-5之间的数字"
                echo ""
                ;;
        esac
    done
    
    echo ""
    test_header "=== 测试执行完成 ==="
    echo ""
    test_info "测试建议:"
    echo "  1. 定期执行快速测试以确保集群正常运行"
    echo "  2. 每周执行一次健康检查"
    echo "  3. 每月执行一次完整测试和性能评估"
    echo "  4. 及时查看和处理测试报告中的异常项"
    echo ""
    test_passed "感谢您的使用！"
}

# 执行主程序
main "$@"