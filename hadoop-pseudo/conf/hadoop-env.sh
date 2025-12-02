# OpenJDK 8 版本的JAVA_HOME (适配apache/hadoop:3.3.6镜像)
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.212.b04-0.el7_6.x86_64/jre
export SHELL=/bin/bash

# JVM性能优化参数
export HADOOP_HEAPSIZE_MAX=512
export HADOOP_HEAPSIZE_MIN=256
export HADOOP_OPTS="$HADOOP_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseContainerSupport"

# NameNode JVM参数（单节点模式增加内存）
export HADOOP_NAMENODE_OPTS="-Xmx512m -Xms384m $HADOOP_NAMENODE_OPTS"

# DataNode JVM参数（单节点模式增加内存）
export HADOOP_DATANODE_OPTS="-Xmx384m -Xms256m $HADOOP_DATANODE_OPTS"

# ResourceManager JVM参数（单节点模式增加内存）
export YARN_RESOURCEMANAGER_OPTS="-Xmx512m -Xms384m $YARN_RESOURCEMANAGER_OPTS"

# NodeManager JVM参数（单节点模式增加内存）
export YARN_NODEMANAGER_OPTS="-Xmx384m -Xms256m $YARN_NODEMANAGER_OPTS"