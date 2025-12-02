#!/bin/bash

echo "编译PageRank计算程序..."

# 使用hadoop-pseudo容器中的Java环境编译
echo "编译Java源文件..."
docker-compose -f hadoop-pseudo/docker-compose-pseudo.yml exec hadoop-pseudo javac -cp "/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/yarn/*" -d /tmp /home/docker-compose/hadoop/exp3/*.java

if [ $? -ne 0 ]; then
    echo "编译失败！"
    exit 1
fi

echo "编译成功！"

# 创建JAR包
echo "创建JAR包..."
docker-compose -f hadoop-pseudo/docker-compose-pseudo.yml exec hadoop-pseudo jar cf /home/docker-compose/hadoop/exp3/pagerank.jar -C /tmp .

if [ $? -ne 0 ]; then
    echo "JAR包创建失败！"
    exit 1
fi

echo "JAR包创建成功：pagerank.jar"

# 清理临时文件
echo "清理临时文件..."
docker-compose -f hadoop-pseudo/docker-compose-pseudo.yml exec hadoop-pseudo rm -rf /tmp/*.class

echo "编译完成！"
echo ""
echo "使用方法："
echo "1. 准备数据: bash prepare_data.sh"
echo "2. 运行PageRank: bash run_pagerank.sh processed/pagerank_input.txt /output/pagerank 10"
echo "3. 查看结果: docker-compose -f hadoop-pseudo/docker-compose-pseudo.yml exec hadoop-pseudo hdfs dfs -cat /output/pagerank/iteration*/part-r-* | head -20"