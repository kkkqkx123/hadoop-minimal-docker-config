#!/bin/bash

echo "PageRank MapReduce任务执行脚本"
echo "================================"

# 检查参数
if [ $# -lt 2 ]; then
    echo "使用方法: $0 <输入文件> <输出目录> [最大迭代次数]"
    echo "示例: $0 wiki-vertices.txt /output/pagerank 10"
    exit 1
fi

INPUT_FILE=$1
OUTPUT_DIR=$2
MAX_ITERATIONS=${3:-10}

echo "输入文件: $INPUT_FILE"
echo "输出目录: $OUTPUT_DIR"
echo "最大迭代次数: $MAX_ITERATIONS"

# 检查Hadoop集群状态
echo "检查Hadoop集群状态..."
docker-compose exec master jps

if [ $? -ne 0 ]; then
    echo "Hadoop集群未运行，请先启动集群！"
    exit 1
fi

echo ""
echo "上传输入数据到HDFS..."
docker-compose exec master hdfs dfs -mkdir -p /input
docker-compose exec master hdfs dfs -put -f exp3/dataset/$INPUT_FILE /input/

echo ""
echo "清理已存在的输出目录..."
docker-compose exec master hdfs dfs -rm -r -f $OUTPUT_DIR

echo ""
echo "运行PageRank计算..."
docker-compose exec master hadoop jar exp3/pagerank.jar PageRankDriver /input/$INPUT_FILE $OUTPUT_DIR $MAX_ITERATIONS

if [ $? -eq 0 ]; then
    echo ""
    echo "PageRank计算完成！"
    echo "查看结果："
    echo "docker-compose exec master hdfs dfs -cat $OUTPUT_DIR/iteration*/part-r-* | head -20"
else
    echo ""
    echo "PageRank计算失败！"
    exit 1
fi