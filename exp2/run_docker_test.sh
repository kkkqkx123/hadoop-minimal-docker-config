#!/bin/bash

echo "在Hadoop Docker环境中运行倒排索引MapReduce测试..."

# 设置Hadoop类路径
export HADOOP_CLASSPATH=$(hadoop classpath)

# 清理之前的输出
echo "清理之前的输出..."
hdfs dfs -test -d /exp2 && hdfs dfs -rm -r /exp2

# 创建HDFS目录结构
echo "创建HDFS目录结构..."
hdfs dfs -mkdir -p /exp2/input
hdfs dfs -mkdir -p /exp2/temp
hdfs dfs -mkdir -p /exp2/output

# 上传测试数据到HDFS
echo "上传测试数据到HDFS..."
hdfs dfs -put doc1.txt /exp2/input/
hdfs dfs -put doc2.txt /exp2/input/
hdfs dfs -put doc3.txt /exp2/input/

echo "测试数据已上传到HDFS，检查内容："
hdfs dfs -ls /exp2/input/
echo

# 执行第一轮MapReduce
echo "===== 执行第一轮MapReduce（统计词频）====="
hadoop jar invertedindex.jar InvertedIndexDriver1 /exp2/input /exp2/temp

if [ $? -ne 0 ]; then
    echo "第一轮MapReduce运行失败！"
    exit 1
fi

echo "第一轮MapReduce完成，检查中间结果..."
hdfs dfs -cat /exp2/temp/part-r-00000

echo
echo "预期第一轮输出："
echo "bird--doc1.txt	1"
echo "bird--doc3.txt	1"
echo "blue--doc2.txt	1"
echo "fish --doc1.txt	1"
echo "fish--doc1.txt	1"
echo "fish--doc2.txt	2"
echo "fish--doc3.txt	1"
echo "one--doc1.txt	1"
echo "one--doc3.txt	1"
echo "red--doc2.txt	1"
echo "red--doc3.txt	1"
echo "three--doc1.txt	1"
echo "three--doc3.txt	1"
echo "two--doc1.txt	1"
echo "two--doc3.txt	1"
echo "yellow--doc3.txt	2"

# 执行第二轮MapReduce
echo
echo "===== 执行第二轮MapReduce（合并文档信息）====="
hadoop jar invertedindex.jar InvertedIndexDriver2 /exp2/temp /exp2/output

if [ $? -ne 0 ]; then
    echo "第二轮MapReduce运行失败！"
    exit 1
fi

echo "第二轮MapReduce完成，检查最终结果..."
hdfs dfs -cat /exp2/output/part-r-00000

echo
echo "预期第二轮输出："
echo "bird	doc3.txt-->1 doc1.txt-->1"
echo "blue	doc2.txt-->1"
echo "fish	doc1.txt-->1 doc2.txt-->2 doc3.txt-->1"
echo "one	doc1.txt-->1 doc3.txt-->1"
echo "red	doc2.txt-->1 doc3.txt-->1"
echo "three	doc1.txt-->1 doc3.txt-->1"
echo "two	doc1.txt-->1 doc3.txt-->1"
echo "yellow	doc3.txt-->2"

# 验证结果
echo
echo "===== 结果验证 ====="
echo "请将实际输出与预期输出进行比较，验证倒排索引的正确性。"

# 下载结果到本地
echo
echo "下载结果到本地输出目录..."
hdfs dfs -get /exp2/output/part-r-00000 ./output/result.txt

echo
echo "===== 测试完成 ====="
echo "最终结果已保存到：./output/result.txt"