#!/bin/bash
# Hadoop Docker 自定义代码测试脚本
# 用于验证Hadoop环境是否准备好执行自定义代码

set -e

echo "🧪 Hadoop Docker 自定义代码测试脚本"
echo "======================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查服务状态
check_services() {
    echo -e "\n${YELLOW}📋 检查Hadoop服务状态...${NC}"
    
    # 检查master节点
    echo "检查master节点进程:"
    docker-compose exec master jps | grep -E "(NameNode|ResourceManager|JobHistoryServer)" || {
        echo -e "${RED}❌ master节点服务异常${NC}"
        return 1
    }
    
    # 检查worker节点
    echo "检查worker1节点进程:"
    docker-compose exec worker1 jps | grep -E "(DataNode|NodeManager)" || {
        echo -e "${RED}❌ worker1节点服务异常${NC}"
        return 1
    }
    
    echo "检查worker2节点进程:"
    docker-compose exec worker2 jps | grep -E "(DataNode|NodeManager)" || {
        echo -e "${RED}❌ worker2节点服务异常${NC}"
        return 1
    }
    
    echo -e "${GREEN}✅ 所有服务运行正常${NC}"
}

# 测试HDFS
test_hdfs() {
    echo -e "\n${YELLOW}📁 测试HDFS功能...${NC}"
    
    # 创建测试目录
    docker-compose exec master hdfs dfs -mkdir -p /test || {
        echo -e "${RED}❌ HDFS目录创建失败${NC}"
        return 1
    }
    
    # 创建测试文件
    echo "Hello Hadoop Docker Test" | docker-compose exec -T master tee /tmp/test.txt
    
    # 上传文件
    docker-compose exec master hdfs dfs -put /tmp/test.txt /test/ || {
        echo -e "${RED}❌ 文件上传失败${NC}"
        return 1
    }
    
    # 验证文件
    docker-compose exec master hdfs dfs -cat /test/test.txt | grep "Hello Hadoop Docker Test" || {
        echo -e "${RED}❌ 文件内容验证失败${NC}"
        return 1
    }
    
    # 清理
    docker-compose exec master hdfs dfs -rm -r /test
    docker-compose exec master rm /tmp/test.txt
    
    echo -e "${GREEN}✅ HDFS功能正常${NC}"
}

# 测试YARN
test_yarn() {
    echo -e "\n${YELLOW}🧶 测试YARN功能...${NC}"
    
    # 检查ResourceManager
    docker-compose exec master yarn node -list | grep RUNNING || {
        echo -e "${RED}❌ YARN节点状态异常${NC}"
        return 1
    }
    
    echo -e "${GREEN}✅ YARN功能正常${NC}"
}

# 测试Python Streaming
test_python_streaming() {
    echo -e "\n${YELLOW}🐍 测试Python Streaming...${NC}"
    
    # 创建mapper
    cat > /tmp/test_mapper.py << 'EOF'
#!/usr/bin/env python3
import sys
for line in sys.stdin:
    words = line.strip().split()
    for word in words:
        print(f"{word}\t1")
EOF

    # 创建reducer
    cat > /tmp/test_reducer.py << 'EOF'
#!/usr/bin/env python3
import sys
from collections import defaultdict

word_count = defaultdict(int)
for line in sys.stdin:
    word, count = line.strip().split('\t')
    word_count[word] += int(count)

for word, count in word_count.items():
    print(f"{word}\t{count}")
EOF

    # 创建测试数据
    echo "hello world hello hadoop" | docker-compose exec -T master tee /tmp/streaming_test.txt
    
    # 上传到HDFS
    docker-compose exec master hdfs dfs -mkdir -p /streaming_input
    docker-compose exec master hdfs dfs -put /tmp/streaming_test.txt /streaming_input/
    
    # 复制脚本到容器
    docker cp /tmp/test_mapper.py hadoop-master:/tmp/
    docker cp /tmp/test_reducer.py hadoop-master:/tmp/
    
    # 执行权限
    docker-compose exec master chmod +x /tmp/test_mapper.py /tmp/test_reducer.py
    
    # 执行streaming作业
    docker-compose exec master hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \
        -files /tmp/test_mapper.py,/tmp/test_reducer.py \
        -mapper 'python3 /tmp/test_mapper.py' \
        -reducer 'python3 /tmp/test_reducer.py' \
        -input /streaming_input \
        -output /streaming_output || {
        echo -e "${RED}❌ Python Streaming执行失败${NC}"
        return 1
    }
    
    # 验证结果
    docker-compose exec master hdfs dfs -cat /streaming_output/part-* | grep -E "(hello|world|hadoop)" || {
        echo -e "${RED}❌ Streaming结果验证失败${NC}"
        return 1
    }
    
    # 清理
    docker-compose exec master hdfs dfs -rm -r /streaming_input /streaming_output
    rm -f /tmp/test_mapper.py /tmp/test_reducer.py /tmp/streaming_test.txt
    
    echo -e "${GREEN}✅ Python Streaming功能正常${NC}"
}

# 测试Java MapReduce
test_java_mapreduce() {
    echo -e "\n${YELLOW}☕ 测试Java MapReduce...${NC}"
    
    # 创建测试数据
    echo "apple banana apple orange banana apple" | docker-compose exec -T master tee /tmp/java_test.txt
    
    # 上传到HDFS
    docker-compose exec master hdfs dfs -mkdir -p /java_input
    docker-compose exec master hdfs dfs -put /tmp/java_test.txt /java_input/
    
    # 使用内置的wordcount示例
    docker-compose exec master hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
        wordcount /java_input /java_output || {
        echo -e "${RED}❌ Java MapReduce执行失败${NC}"
        return 1
    }
    
    # 验证结果
    docker-compose exec master hdfs dfs -cat /java_output/part-* | grep -E "(apple|banana|orange)" || {
        echo -e "${RED}❌ Java MapReduce结果验证失败${NC}"
        return 1
    }
    
    # 清理
    docker-compose exec master hdfs dfs -rm -r /java_input /java_output
    docker-compose exec master rm /tmp/java_test.txt
    
    echo -e "${GREEN}✅ Java MapReduce功能正常${NC}"
}

# 显示使用说明
show_usage() {
    echo -e "\n${YELLOW}📖 使用说明${NC}"
    echo "======================================"
    echo "此脚本验证Hadoop Docker环境是否准备好执行自定义代码"
    echo ""
    echo "可选参数:"
    echo "  --hdfs-only    只测试HDFS功能"
    echo "  --yarn-only    只测试YARN功能"
    echo "  --python-only  只测试Python Streaming"
    echo "  --java-only    只测试Java MapReduce"
    echo "  --help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./test-custom-code.sh"
    echo "  ./test-custom-code.sh --python-only"
    echo "  ./test-custom-code.sh --hdfs-only --yarn-only"
}

# 主函数
main() {
    # 检查是否在正确的目录
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}❌ 请在docker-compose.yml所在目录运行此脚本${NC}"
        exit 1
    fi
    
    # 解析参数
    TEST_HDFS=true
    TEST_YARN=true
    TEST_PYTHON=true
    TEST_JAVA=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --hdfs-only)
                TEST_YARN=false
                TEST_PYTHON=false
                TEST_JAVA=false
                shift
                ;;
            --yarn-only)
                TEST_HDFS=false
                TEST_PYTHON=false
                TEST_JAVA=false
                shift
                ;;
            --python-only)
                TEST_HDFS=false
                TEST_YARN=false
                TEST_JAVA=false
                shift
                ;;
            --java-only)
                TEST_HDFS=false
                TEST_YARN=false
                TEST_PYTHON=false
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 未知参数: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo -e "\n${GREEN}🚀 开始测试Hadoop Docker自定义代码环境...${NC}"
    
    # 执行测试
    check_services
    
    if [ "$TEST_HDFS" = true ]; then
        test_hdfs
    fi
    
    if [ "$TEST_YARN" = true ]; then
        test_yarn
    fi
    
    if [ "$TEST_PYTHON" = true ]; then
        test_python_streaming
    fi
    
    if [ "$TEST_JAVA" = true ]; then
        test_java_mapreduce
    fi
    
    echo -e "\n${GREEN}🎉 所有测试完成！Hadoop Docker环境已准备好执行自定义代码。${NC}"
    echo -e "${YELLOW}💡 提示：参考 docs/coding/在hadoop-docker上执行自定义代码指南.md 获取详细使用说明${NC}"
}

# 运行主函数
main "$@"