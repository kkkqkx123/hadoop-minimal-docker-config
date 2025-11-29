#!/bin/bash

# Spark 环境变量配置
# 适用于与 Hadoop 伪分布式环境集成

# Java 配置 - 适配官方Spark镜像的Java 11路径
export JAVA_HOME=/opt/java/openjdk

# Hadoop 配置集成
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HADOOP_HOME=/opt/hadoop
export HADOOP_COMMON_HOME=/opt/hadoop
export HADOOP_HDFS_HOME=/opt/hadoop
export HADOOP_MAPRED_HOME=/opt/hadoop
export HADOOP_YARN_HOME=/opt/hadoop

# Spark 配置
export SPARK_HOME=/opt/spark
export SPARK_CONF_DIR=/opt/spark/conf
export SPARK_LOG_DIR=/opt/spark/logs
export SPARK_WORKER_DIR=/opt/spark/work
export SPARK_PID_DIR=/tmp/spark-pids

# 内存配置 - 基于容器资源限制
export SPARK_DAEMON_MEMORY=256m
export SPARK_WORKER_MEMORY=1g
export SPARK_DRIVER_MEMORY=512m
export SPARK_EXECUTOR_MEMORY=768m

# CPU 配置
export SPARK_WORKER_CORES=1
export SPARK_EXECUTOR_CORES=1

# 垃圾回收优化 - 适配Java 11
export SPARK_DAEMON_JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=80"
export SPARK_WORKER_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=80"

# 网络配置 - 适配 Docker 环境
export SPARK_MASTER_HOST=spark-master
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=8080
export SPARK_WORKER_PORT=8888
export SPARK_WORKER_WEBUI_PORT=8081

# 历史服务器配置
export SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=hdfs://namenode:9000/spark-logs -Dspark.history.fs.cleaner.enabled=true -Dspark.history.fs.cleaner.interval=1d -Dspark.history.fs.cleaner.maxAge=7d"

# 临时目录配置
export SPARK_LOCAL_DIRS=/tmp/spark-local
export SPARK_WORKER_DIR=/opt/spark/work

# 日志配置
export SPARK_LOG_DIR=/opt/spark/logs
export SPARK_LOG_MAX_FILES=5

# 安全配置 - 测试环境简化
export SPARK_PUBLIC_DNS=localhost
export SPARK_MASTER_OPTS="-Dspark.master.rest.enabled=true -Dspark.master.rest.port=6066"

# 资源发现配置
export SPARK_WORKER_RESOURCE_GPU_AMOUNT=0
export SPARK_WORKER_RESOURCE_GPU_DISCOVERY_SCRIPT=""

# Python 配置（可选）
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

# 类路径配置
export SPARK_CLASSPATH=/opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/lib/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/*