# Alpine Linux OpenJDK 11 版本的JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# 确保使用bash
export SHELL=/bin/bash

# 设置Hadoop配置目录
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop

# JVM性能优化参数 - 简化配置避免Alpine兼容性问题
export HADOOP_HEAPSIZE_MAX=512
export HADOOP_HEAPSIZE_MIN=256

# NameNode JVM参数 - 简化配置
export HADOOP_NAMENODE_OPTS="-Xmx384m -Xms256m"

# DataNode JVM参数  
export HADOOP_DATANODE_OPTS="-Xmx256m -Xms128m"

# ResourceManager JVM参数
export YARN_RESOURCEMANAGER_OPTS="-Xmx384m -Xms256m"

# NodeManager JVM参数
export YARN_NODEMANAGER_OPTS="-Xmx256m -Xms128m"