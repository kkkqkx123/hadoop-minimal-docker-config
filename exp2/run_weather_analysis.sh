#!/bin/bash

echo "=========================================="
echo "天气数据分析MapReduce任务执行脚本"
echo "功能：找出每个月的最高温度"
echo "=========================================="

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法: $0 <输出目录>"
    echo "示例: $0 /output/weather2024"
    exit 1
fi

OUTPUT_DIR=$1
INPUT_FILE="/input/weather.txt"
JAR_FILE="weather-analysis.jar"
DRIVER_CLASS="WeatherDriver"

echo "输入文件: $INPUT_FILE"
echo "输出目录: $OUTPUT_DIR"
echo "JAR文件: $JAR_FILE"
echo "主类: $DRIVER_CLASS"

# 检查Hadoop集群状态
echo "检查Hadoop集群状态..."
docker exec master hdfs dfsadmin -report | head -10

if [ $? -ne 0 ]; then
    echo "Hadoop集群未正常运行！"
    exit 1
fi

# 检查输入文件是否存在
echo "检查输入文件..."
docker exec master hdfs dfs -test -e $INPUT_FILE

if [ $? -ne 0 ]; then
    echo "输入文件不存在，正在上传..."
    docker exec master hdfs dfs -mkdir -p /input
    docker exec master hdfs dfs -put /home/exp2/weather.txt $INPUT_FILE
else
    echo "输入文件已存在"
fi

# 清理输出目录（如果存在）
echo "清理输出目录..."
docker exec master hdfs dfs -test -d $OUTPUT_DIR
if [ $? -eq 0 ]; then
    docker exec master hdfs dfs -rm -r $OUTPUT_DIR
    echo "已删除已存在的输出目录"
fi

# 执行MapReduce任务
echo "开始执行MapReduce任务..."
echo "执行命令: hadoop jar $JAR_FILE $DRIVER_CLASS $INPUT_FILE $OUTPUT_DIR"

docker exec master bash -c "cd /home/exp2 && hadoop jar $JAR_FILE $DRIVER_CLASS $INPUT_FILE $OUTPUT_DIR" > weather_result.log 2>&1

if [ $? -eq 0 ]; then
    echo "MapReduce任务执行成功！"
    echo "日志已保存到: weather_result.log"
else
    echo "MapReduce任务执行失败！"
    echo "请查看日志文件: weather_result.log"
    exit 1
fi

# 显示结果
echo "显示执行结果..."
echo "=========================================="
echo "每个月的最高温度："
echo "=========================================="

docker exec master hdfs dfs -cat $OUTPUT_DIR/part-r-* | head -20

echo "=========================================="
echo "任务执行完成！"
echo "完整结果保存在HDFS: $OUTPUT_DIR"
echo "执行日志保存在本地: weather_result.log"
echo "=========================================="