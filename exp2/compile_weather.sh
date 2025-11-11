#!/bin/bash

echo "开始编译天气数据分析MapReduce程序..."

# 设置Hadoop类路径（使用硬编码路径避免转义问题）
HADOOP_CLASSPATH="/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/*"

# 编译Java文件
echo "正在编译Java文件..."
javac -cp "$HADOOP_CLASSPATH" -d . *.java

if [ $? -ne 0 ]; then
    echo "Java编译失败！"
    exit 1
fi

echo "Java文件编译成功！"

# 创建JAR文件
echo "正在创建JAR文件..."
jar cf weather-analysis.jar *.class

if [ $? -ne 0 ]; then
    echo "JAR文件创建失败！"
    exit 1
fi

echo "JAR文件创建成功：weather-analysis.jar"
echo "编译完成！"

# 列出生成的文件
echo "生成的文件："
ls -la *.jar *.class 2>/dev/null || echo "无.class文件（可能已被打包到JAR中）"