#!/bin/bash
"""
Shell脚本测试框架
用于测试Shell脚本的MapReduce逻辑
"""

# 测试配置
TEST_DIR="test_temp"
INPUT_FILE="$TEST_DIR/test_input.txt"
MAPPER_OUTPUT="$TEST_DIR/mapper_output.txt"
SORTED_OUTPUT="$TEST_DIR/sorted_output.txt"
REDUCER_OUTPUT="$TEST_DIR/reducer_output.txt"
REPORT_FILE="shell_test_report.txt"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 创建测试目录
create_test_environment() {
    echo "🛠️  创建测试环境..."
    
    # 清理旧测试
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
    
    mkdir -p "$TEST_DIR"
    
    # 创建mapper脚本
    cat > "$TEST_DIR/mapper.sh" << 'EOF'
#!/bin/bash
# WordCount Mapper - Shell版本
while read line; do
    for word in $line; do
        echo -e "$word\t1"
    done
done
EOF
    
    # 创建reducer脚本
    cat > "$TEST_DIR/reducer.sh" << 'EOF'
#!/bin/bash
# WordCount Reducer - Shell版本
prev_word=""
prev_count=0

while read line; do
    word=$(echo "$line" | cut -f1)
    count=$(echo "$line" | cut -f2)
    
    if [ "$word" = "$prev_word" ]; then
        prev_count=$((prev_count + count))
    else
        if [ -n "$prev_word" ]; then
            echo -e "$prev_word\t$prev_count"
        fi
        prev_word="$word"
        prev_count=$count
    fi
done

# 输出最后一个单词
if [ -n "$prev_word" ]; then
    echo -e "$prev_word\t$prev_count"
fi
EOF
    
    # 添加执行权限
    chmod +x "$TEST_DIR/mapper.sh"
    chmod +x "$TEST_DIR/reducer.sh"
    
    echo "✅ 测试环境创建完成"
}

# 清理测试环境
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# 测试mapper
test_mapper() {
    echo "📋 测试mapper功能..."
    
    # 创建测试输入
    cat > "$INPUT_FILE" << EOF
hello world hello hadoop
this is a test
hadoop is great
EOF
    
    # 运行mapper
    cat "$INPUT_FILE" | "$TEST_DIR/mapper.sh" > "$MAPPER_OUTPUT"
    
    # 验证输出
    local mapper_lines=$(wc -l < "$MAPPER_OUTPUT")
    echo "Mapper输出: $mapper_lines 行"
    
    # 检查格式
    local format_errors=0
    while read line; do
        if ! echo "$line" | grep -q $'^[^\t]*\t[0-9]*$'; then
            echo "❌ 格式错误: $line"
            format_errors=$((format_errors + 1))
        fi
    done < "$MAPPER_OUTPUT"
    
    if [ $format_errors -eq 0 ]; then
        echo "✅ Mapper格式正确"
        return 0
    else
        echo "❌ Mapper格式错误: $format_errors 处"
        return 1
    fi
}

# 测试reducer
test_reducer() {
    echo "📋 测试reducer功能..."
    
    # 创建排序后的mapper输出
    cat > "$SORTED_OUTPUT" << EOF
hadoop	1
hadoop	1
hello	1
hello	1
is	1
is	1
this	1
test	1
world	1
EOF
    
    # 运行reducer
    cat "$SORTED_OUTPUT" | "$TEST_DIR/reducer.sh" > "$REDUCER_OUTPUT"
    
    # 验证输出
    local reducer_lines=$(wc -l < "$REDUCER_OUTPUT")
    echo "Reducer输出: $reducer_lines 行"
    
    # 检查格式
    local format_errors=0
    while read line; do
        if ! echo "$line" | grep -q $'^[^\t]*\t[0-9]*$'; then
            echo "❌ 格式错误: $line"
            format_errors=$((format_errors + 1))
        fi
    done < "$REDUCER_OUTPUT"
    
    if [ $format_errors -eq 0 ]; then
        echo "✅ Reducer格式正确"
        return 0
    else
        echo "❌ Reducer格式错误: $format_errors 处"
        return 1
    fi
}

# 测试完整流程
test_complete_pipeline() {
    echo "🔗 测试完整MapReduce流程..."
    
    # 创建测试数据
    cat > "$INPUT_FILE" << EOF
hello world hello hadoop
this is a test file for word count
hadoop is great for big data processing
hello hadoop users welcome to hadoop world
EOF
    
    # 运行完整流程
    cat "$INPUT_FILE" | "$TEST_DIR/mapper.sh" | sort | "$TEST_DIR/reducer.sh" > "$REDUCER_OUTPUT"
    
    # 验证结果
    echo "完整流程输出:"
    cat "$REDUCER_OUTPUT"
    
    # 检查期望的结果
    local expected_words=("a" "big" "count" "data" "file" "for" "great" "hadoo" "hello" "is" "processing" "test" "this" "to" "users" "welcome" "world")
    local passed=0
    
    for word in "${expected_words[@]}"; do
        if grep -q "^$word	" "$REDUCER_OUTPUT"; then
            passed=$((passed + 1))
        else
            echo "❌ 缺失单词: $word"
        fi
    done
    
    echo "找到 $passed/${#expected_words[@]} 个期望单词"
    
    if [ $passed -gt 0 ]; then
        echo "✅ 完整流程测试通过"
        return 0
    else
        echo "❌ 完整流程测试失败"
        return 1
    fi
}

# 测试边界情况
test_edge_cases() {
    echo "⚠️ 测试边界情况..."
    
    local test_cases=(
        ""
        "   "
        "hello"
        "hello hello hello"
        "HELLO hello Hello"
        "test123 test!@# test..."
        "a b c d e"
        "verylongword anotherverylongword"
    )
    
    local passed=0
    local total=${#test_cases[@]}
    
    for test_input in "${test_cases[@]}"; do
        echo -e "\n  测试输入: '$test_input'"
        
        # 创建临时输入文件
        echo "$test_input" > "$INPUT_FILE"
        
        # 运行测试
        if cat "$INPUT_FILE" | "$TEST_DIR/mapper.sh" | sort | "$TEST_DIR/reducer.sh" > /tmp/edge_test.out 2>/dev/null; then
            echo "  ✅ 处理成功"
            passed=$((passed + 1))
        else
            echo "  ❌ 处理失败"
        fi
    done
    
    echo "边界测试通过: $passed/$total"
    
    if [ $passed -eq $total ]; then
        echo "✅ 边界情况测试通过"
        return 0
    else
        echo "❌ 边界情况测试失败"
        return 1
    fi
}

# 测试性能
test_performance() {
    echo "⚡ 测试性能..."
    
    # 生成大数据集
    local large_data=""
    for i in {1..1000}; do
        large_data+="hello world "
    done
    
    echo "测试数据: $(echo "$large_data" | wc -w) 个单词"
    
    # 测试mapper性能
    local start_time=$(date +%s.%N)
    echo "$large_data" | "$TEST_DIR/mapper.sh" > /tmp/perf_test.out
    local mapper_time=$(echo "$(date +%s.%N) - $start_time" | bc)
    
    # 测试reducer性能
    start_time=$(date +%s.%N)
    sort /tmp/perf_test.out | "$TEST_DIR/reducer.sh" > /tmp/perf_result.out
    local reducer_time=$(echo "$(date +%s.%N) - $start_time" | bc)
    
    local total_time=$(echo "$mapper_time + $reducer_time" | bc)
    local word_count=$(echo "$large_data" | wc -w)
    local throughput=$(echo "scale=2; $word_count / $total_time" | bc)
    
    echo "性能结果:"
    echo "  Mapper时间: ${mapper_time}s"
    echo "  Reducer时间: ${reducer_time}s"
    echo "  总时间: ${total_time}s"
    echo "  处理速度: ${throughput} 单词/秒"
    
    # 性能要求（可根据需要调整）
    local min_throughput=500
    if (( $(echo "$throughput > $min_throughput" | bc -l) )); then
        echo "✅ 性能测试通过"
        return 0
    else
        echo "⚠️  性能较低 (${throughput} < ${min_throughput})"
        return 1
    fi
}

# 测试内存使用
test_memory_usage() {
    echo "📋 测试内存使用..."
    
    # 生成大数据集
    local large_data=""
    for i in {1..5000}; do
        large_data+="hello world hadoop test "
    done
    
    local word_count=$(echo "$large_data" | wc -w)
    echo "测试数据: $word_count 个单词"
    
    # 运行测试并监控内存
    echo "$large_data" | "$TEST_DIR/mapper.sh" | sort | "$TEST_DIR/reducer.sh" > /tmp/memory_test.out 2>/dev/null
    
    # 检查输出合理性
    local output_lines=$(wc -l < /tmp/memory_test.out)
    local unique_words=4  # hello, world, hadoop, test
    
    if [ $output_lines -eq $unique_words ]; then
        echo "✅ 内存使用测试通过"
        return 0
    else
        echo "❌ 内存使用异常: 输出 $output_lines 行，期望 $unique_words 行"
        return 1
    fi
}

# 测试错误处理
test_error_handling() {
    echo "📋 测试错误处理..."
    
    # 测试各种错误情况
    local test_cases=(
        ""
        "   "
        $'hello\tworld'
        $'hello\nworld'
        "hello123 hello456"
        "HELLO hello Hello"
    )
    
    local passed=0
    local total=${#test_cases[@]}
    
    for test_input in "${test_cases[@]}"; do
        echo -e "\n  测试输入: '$test_input'"
        
        echo "$test_input" > "$INPUT_FILE"
        
        # 运行测试，不应崩溃
        if cat "$INPUT_FILE" | "$TEST_DIR/mapper.sh" > /tmp/error_test.out 2>/dev/null; then
            echo "  ✅ Mapper处理成功"
            passed=$((passed + 1))
        else
            echo "  ❌ Mapper处理失败"
        fi
    done
    
    echo "错误处理测试通过: $passed/$total"
    
    if [ $passed -eq $total ]; then
        echo "✅ 错误处理测试通过"
        return 0
    else
        echo "❌ 错误处理测试失败"
        return 1
    fi
}

# 生成测试报告
generate_report() {
    echo "📊 生成测试报告..."
    
    local tests=(
        "mapper:test_mapper"
        "reducer:test_reducer"
        "pipeline:test_complete_pipeline"
        "edge_cases:test_edge_cases"
        "performance:test_performance"
        "memory:test_memory_usage"
        "error_handling:test_error_handling"
    )
    
    local total_tests=${#tests[@]}
    local passed_tests=0
    local failed_tests=0
    
    # 清空报告文件
    > "$REPORT_FILE"
    
    echo "Shell MapReduce 本地Mock测试报告" >> "$REPORT_FILE"
    echo "=================================" >> "$REPORT_FILE"
    echo "测试时间: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    for test_info in "${tests[@]}"; do
        local test_name="${test_info%%:*}"
        local test_func="${test_info##*:}"
        
        echo "运行测试: $test_name" | tee -a "$REPORT_FILE"
        
        if $test_func; then
            echo "✅ $test_name: PASSED" >> "$REPORT_FILE"
            passed_tests=$((passed_tests + 1))
        else
            echo "❌ $test_name: FAILED" >> "$REPORT_FILE"
            failed_tests=$((failed_tests + 1))
        fi
        
        echo "" >> "$REPORT_FILE"
    done
    
    # 生成摘要
    echo "" >> "$REPORT_FILE"
    echo "测试摘要" >> "$REPORT_FILE"
    echo "========" >> "$REPORT_FILE"
    echo "总测试数: $total_tests" >> "$REPORT_FILE"
    echo "通过: $passed_tests" >> "$REPORT_FILE"
    echo "失败: $failed_tests" >> "$REPORT_FILE"
    echo "成功率: $((passed_tests * 100 / total_tests))%" >> "$REPORT_FILE"
    
    echo "测试报告已保存到: $REPORT_FILE"
    
    # 显示摘要
    echo ""
    echo "测试摘要:"
    echo "总测试数: $total_tests"
    echo "通过: $passed_tests"
    echo "失败: $failed_tests"
    echo "成功率: $((passed_tests * 100 / total_tests))%"
    
    return $failed_tests
}

# 主函数
main() {
    echo "🧪 Shell MapReduce 本地Mock测试"
    echo "================================"
    
    # 设置错误处理
    set -e
    trap cleanup EXIT
    
    # 创建测试环境
    create_test_environment
    
    # 运行测试并生成报告
    if generate_report; then
        echo ""
        echo -e "${GREEN}🎉 所有Shell测试通过！可以安全部署到Docker环境${NC}"
        echo "💡 建议: 在Docker环境中使用小数据集进行最终验证"
        exit 0
    else
        echo ""
        echo -e "${RED}⚠️  部分测试失败，请先修复问题再部署${NC}"
        echo "🔧 提示: 检查测试报告获取详细信息"
        exit 1
    fi
}

# 运行主函数
main "$@"