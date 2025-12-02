export JAVA_HOME=/usr/local/openjdk-11
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