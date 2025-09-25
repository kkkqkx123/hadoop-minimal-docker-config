#!/bin/bash
# 测试Alpine Linux bash兼容性

echo "=== Alpine Linux Bash Compatibility Test ==="
echo "Shell: $SHELL"
echo "Bash version: $BASH_VERSION"
echo "JAVA_HOME: $JAVA_HOME"
echo "HADOOP_HOME: $HADOOP_HOME"
echo ""

# 测试基本的变量操作
echo "Testing basic variable operations..."
TEST_VAR="hello world"
echo "Test variable: ${TEST_VAR}"
echo "Substring test: ${TEST_VAR:0:5}"
echo ""

# 测试数组操作（如果支持）
echo "Testing array operations..."
TEST_ARRAY=("item1" "item2" "item3")
echo "Array length: ${#TEST_ARRAY[@]}"
echo "First element: ${TEST_ARRAY[0]}"
echo ""

# 测试Hadoop环境
echo "Testing Hadoop environment..."
if [[ -d "$HADOOP_HOME" ]]; then
    echo "Hadoop directory exists: $HADOOP_HOME"
    echo "Hadoop version:"
    "$HADOOP_HOME/bin/hadoop" version 2>/dev/null || echo "Hadoop version check failed"
else
    echo "Hadoop directory not found: $HADOOP_HOME"
fi
echo ""

echo "=== Test completed ==="