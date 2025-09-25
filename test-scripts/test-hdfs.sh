#!/bin/bash
# HDFS功能详细测试脚本

set -e

echo "=== HDFS功能详细测试 ==="

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

# 检查是否在master容器中
if [ ! -f "$HADOOP_HOME/bin/hdfs" ]; then
    test_failed "请在master容器中运行此脚本: docker exec -it master bash"
    exit 1
fi

echo "1. 检查HDFS集群状态..."
# 获取DataNode报告
echo "   执行: hdfs dfsadmin -report"
hdfs_report=$(hdfs dfsadmin -report 2>/dev/null)

if [ $? -eq 0 ]; then
    live_datanodes=$(echo "$hdfs_report" | grep "Live datanodes" | awk '{print $3}')
    dead_datanodes=$(echo "$hdfs_report" | grep "Dead datanodes" | awk '{print $3}')
    
    test_passed "HDFS集群状态查询成功"
    test_info "Live DataNodes: $live_datanodes"
    test_info "Dead DataNodes: $dead_datanodes"
    
    if [ "$live_datanodes" -ge 2 ]; then
        test_passed "DataNode数量符合要求 (≥2)"
    else
        test_failed "DataNode数量不足 (需要≥2，实际:$live_datanodes)"
    fi
else
    test_failed "无法获取HDFS集群状态"
    exit 1
fi

echo ""
echo "2. 测试HDFS文件系统操作..."

# 创建测试目录
echo "   创建测试目录: /test-hdfs"
if hdfs dfs -mkdir -p /test-hdfs 2>/dev/null; then
    test_passed "目录创建成功"
else
    test_failed "目录创建失败"
fi

# 测试文件上传
echo "   创建测试文件并上传..."
echo "This is a test file for HDFS functionality verification." > /tmp/hdfs-test.txt
echo "Line 2: Testing file operations." >> /tmp/hdfs-test.txt
echo "Line 3: Hadoop Distributed File System." >> /tmp/hdfs-test.txt

if hdfs dfs -put /tmp/hdfs-test.txt /test-hdfs/ 2>/dev/null; then
    test_passed "文件上传成功"
else
    test_failed "文件上传失败"
fi

# 验证文件存在
echo "   验证文件存在..."
if hdfs dfs -ls /test-hdfs/hdfs-test.txt 2>/dev/null; then
    test_passed "文件存在验证成功"
else
    test_failed "文件不存在"
fi

# 读取文件内容
echo "   读取文件内容..."
file_content=$(hdfs dfs -cat /test-hdfs/hdfs-test.txt 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$file_content" ]; then
    test_passed "文件读取成功"
    echo "   文件内容预览:"
    echo "   $(echo "$file_content" | head -n 1)"
else
    test_failed "文件读取失败"
fi

# 文件复制
echo "   测试文件复制..."
if hdfs dfs -cp /test-hdfs/hdfs-test.txt /test-hdfs/hdfs-test-copy.txt 2>/dev/null; then
    test_passed "文件复制成功"
else
    test_failed "文件复制失败"
fi

# 文件移动
echo "   测试文件移动..."
if hdfs dfs -mv /test-hdfs/hdfs-test-copy.txt /test-hdfs/hdfs-test-moved.txt 2>/dev/null; then
    test_passed "文件移动成功"
else
    test_failed "文件移动失败"
fi

# 文件权限测试
echo "   测试文件权限修改..."
if hdfs dfs -chmod 644 /test-hdfs/hdfs-test.txt 2>/dev/null; then
    test_passed "文件权限修改成功"
else
    test_failed "文件权限修改失败"
fi

# 文件统计信息
echo "   获取文件统计信息..."
file_stat=$(hdfs dfs -stat /test-hdfs/hdfs-test.txt 2>/dev/null)
if [ $? -eq 0 ]; then
    test_passed "文件统计信息获取成功"
    test_info "文件信息: $file_stat"
else
    test_failed "文件统计信息获取失败"
fi

echo ""
echo "3. 测试大文件操作..."

# 创建大文件（10MB）
echo "   创建10MB测试文件..."
dd if=/dev/zero of=/tmp/large-file.bin bs=1M count=10 2>/dev/null

if [ -f /tmp/large-file.bin ]; then
    test_passed "大文件创建成功"
    
    echo "   上传大文件到HDFS..."
    if hdfs dfs -put /tmp/large-file.bin /test-hdfs/ 2>/dev/null; then
        test_passed "大文件上传成功"
        
        # 验证文件大小
        file_size=$(hdfs dfs -du -h /test-hdfs/large-file.bin 2>/dev/null | awk '{print $1}')
        test_info "上传文件大小: $file_size"
    else
        test_failed "大文件上传失败"
    fi
else
    test_failed "大文件创建失败"
fi

echo ""
echo "4. 测试目录操作..."

# 创建嵌套目录
echo "   创建嵌套目录结构..."
if hdfs dfs -mkdir -p /test-hdfs/dir1/dir2/dir3 2>/dev/null; then
    test_passed "嵌套目录创建成功"
else
    test_failed "嵌套目录创建失败"
fi

# 递归列出目录
echo "   递归列出目录结构..."
if hdfs dfs -ls -R /test-hdfs 2>/dev/null; then
    test_passed "目录递归列出成功"
else
    test_failed "目录递归列出失败"
fi

# 计算目录大小
echo "   计算目录总大小..."
dir_size=$(hdfs dfs -du -s -h /test-hdfs 2>/dev/null | awk '{print $1}')
if [ $? -eq 0 ]; then
    test_passed "目录大小计算成功"
    test_info "目录总大小: $dir_size"
else
    test_failed "目录大小计算失败"
fi

echo ""
echo "5. 测试文件删除和清理..."

# 删除文件
echo "   删除测试文件..."
if hdfs dfs -rm /test-hdfs/hdfs-test-moved.txt 2>/dev/null; then
    test_passed "文件删除成功"
else
    test_failed "文件删除失败"
fi

# 强制删除目录
echo "   递归删除测试目录..."
if hdfs dfs -rm -r /test-hdfs 2>/dev/null; then
    test_passed "目录递归删除成功"
else
    test_failed "目录递归删除失败"
fi

# 清理本地临时文件
echo "   清理本地临时文件..."
rm -f /tmp/hdfs-test.txt /tmp/large-file.bin

echo ""
echo "6. 高级功能测试..."

# 测试文件追加（如果支持）
echo "   测试文件追加操作..."
echo "Initial content" > /tmp/append-test.txt
if hdfs dfs -put /tmp/append-test.txt / 2>/dev/null; then
    echo "Appended content" >> /tmp/append-test.txt
    if hdfs dfs -appendToFile /tmp/append-test.txt /append-test.txt 2>/dev/null; then
        test_passed "文件追加操作成功"
    else
        test_warning "文件追加操作不支持或失败"
    fi
    hdfs dfs -rm /append-test.txt 2>/dev/null
fi

# 测试文件校验和
echo "   测试文件校验和..."
echo "checksum test" > /tmp/checksum-test.txt
if hdfs dfs -put /tmp/checksum-test.txt / 2>/dev/null; then
    checksum=$(hdfs dfs -checksum /checksum-test.txt 2>/dev/null)
    if [ $? -eq 0 ]; then
        test_passed "文件校验和获取成功"
        test_info "校验和: $checksum"
    else
        test_warning "文件校验和获取失败"
    fi
    hdfs dfs -rm /checksum-test.txt 2>/dev/null
fi

# 清理本地文件
rm -f /tmp/append-test.txt /tmp/checksum-test.txt

echo ""
echo "=== HDFS功能测试完成 ==="
echo "所有测试已执行完毕，请检查是否有失败项"
echo "如有失败，请查看Hadoop日志获取详细信息"
echo "日志位置: $HADOOP_HOME/logs/"