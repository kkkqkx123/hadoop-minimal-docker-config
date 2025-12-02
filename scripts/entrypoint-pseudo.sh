#!/bin/bash
set -euo pipefail

# 确保使用bash
export SHELL=/bin/bash

# 显式设置JAVA_HOME
export JAVA_HOME=/usr/local/openjdk-11

# 设置Hadoop配置目录
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop

# 启动 SSHD（并生成主机 host keys）
/usr/sbin/sshd

# Hadoop 日志目录保证存在
mkdir -p "${HADOOP_HOME}/logs"
touch "${HADOOP_HOME}/logs/.keep"

ROLE="${HADOOP_ROLE:-master}"

if [[ "$ROLE" == "master" ]]; then
  echo "[entrypoint] Role: master (pseudo-distributed mode)"

  # 首次格式化 NameNode（根据是否已有 current 目录判断）
  if [[ ! -d "/hadoop/dfs/namenode/current" ]]; then
    echo "[entrypoint] Formatting NameNode..."
    "${HADOOP_HOME}/bin/hdfs" namenode -format -force -nonInteractive
  fi

  echo "[entrypoint] Starting HDFS in pseudo-distributed mode..."
  
  # 启动NameNode
  echo "[entrypoint] Starting NameNode..."
  bash -c "${HADOOP_HOME}/bin/hdfs --daemon start namenode"
  
  # 启动DataNode（在同一节点上）
  echo "[entrypoint] Starting DataNode..."
  bash -c "${HADOOP_HOME}/bin/hdfs --daemon start datanode"
  
  # 启动SecondaryNameNode
  echo "[entrypoint] Starting SecondaryNameNode..."
  bash -c "${HADOOP_HOME}/bin/hdfs --daemon start secondarynamenode"

  # 根据环境变量决定是否启动YARN和MapReduce
  if [[ "${ENABLE_YARN:-false}" == "true" ]]; then
    echo "[entrypoint] Starting YARN..."
    echo "[entrypoint] Starting ResourceManager..."
    bash -c "${HADOOP_HOME}/bin/yarn --daemon start resourcemanager"
    
    echo "[entrypoint] Starting NodeManager..."
    bash -c "${HADOOP_HOME}/bin/yarn --daemon start nodemanager"
    
    if [[ "${ENABLE_MAPREDUCE:-false}" == "true" ]]; then
      echo "[entrypoint] Starting MR JobHistory..."
      bash -c "${HADOOP_HOME}/bin/mapred --daemon start historyserver"
    fi
  fi
  
  echo "[entrypoint] Hadoop services started successfully"
else
  echo "[entrypoint] Role: worker (not supported in pseudo-distributed mode)"
fi

# 保持前台
tail -F "${HADOOP_HOME}/logs/"* 2>/dev/null || tail -f /dev/null