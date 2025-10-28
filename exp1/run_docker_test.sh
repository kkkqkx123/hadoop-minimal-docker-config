#!/bin/bash

echo "在Hadoop Docker环境中运行学生成绩Top10排序测试..."

# 设置Hadoop类路径
export HADOOP_CLASSPATH=$(hadoop classpath)

# 测试1：使用test_data1.txt
echo
echo "===== 测试1：高分段学生成绩 ====="
hdfs dfs -test -d output1 && hdfs dfs -rm -r output1

hadoop jar top10.jar Top10Driver test_data1.txt output1

if [ $? -ne 0 ]; then
    echo "测试1运行失败！"
    exit 1
fi

echo "测试1完成，检查结果..."
hdfs dfs -cat output1/part-r-00000

echo
echo "预期输出："
cat expected_output1.txt

# 测试2：使用test_data2.txt
echo
echo "===== 测试2：中分段学生成绩 ====="
hdfs dfs -test -d output2 && hdfs dfs -rm -r output2

hadoop jar top10.jar Top10Driver test_data2.txt output2

if [ $? -ne 0 ]; then
    echo "测试2运行失败！"
    exit 1
fi

echo "测试2完成，检查结果..."
hdfs dfs -cat output2/part-r-00000

# 测试3：使用test_data3.txt
echo
echo "===== 测试3：超高分段学生成绩 ====="
hdfs dfs -test -d output3 && hdfs dfs -rm -r output3

hadoop jar top10.jar Top10Driver test_data3.txt output3

if [ $? -ne 0 ]; then
    echo "测试3运行失败！"
    exit 1
fi

echo "测试3完成，检查结果..."
hdfs dfs -cat output3/part-r-00000

# 测试4：使用原始数据集
echo
echo "===== 测试4：原始数据集 ====="
hdfs dfs -test -d output4 && hdfs dfs -rm -r output4

hadoop jar top10.jar Top10Driver dataset/top10input.txt output4

if [ $? -ne 0 ]; then
    echo "测试4运行失败！"
    exit 1
fi

echo "测试4完成，检查结果..."
hdfs dfs -cat output4/part-r-00000

echo
echo "===== 所有测试完成 ====="
echo "请检查输出结果是否符合预期。"