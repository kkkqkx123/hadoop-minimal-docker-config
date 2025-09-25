#!/bin/bash
set -euo pipefail

# 确保使用bash
export SHELL=/bin/bash

# 显式设置JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# 设置Hadoop配置目录
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop

# 启动 SSHD（并生成主机 host keys）
/usr/sbin/sshd

# Hadoop 日志目录保证存在
mkdir -p "${HADOOP_HOME}/logs"
touch "${HADOOP_HOME}/logs/.keep"

ROLE="${HADOOP_ROLE:-worker}"

if [[ "$ROLE" == "master" ]]; then
  echo "[entrypoint] Role: master"

  # 等 worker ssh 可达（避免 start-dfs.sh 早于 ssh）
  for host in worker1 worker2; do
    echo "  waiting for ${host} ssh..."
    until ssh -o BatchMode=yes -o ConnectTimeout=2 "${host}" 'echo ok' >/dev/null 2>&1; do
      sleep 2
    done
    echo "  ${host} ssh is ready"
  done

  # 首次格式化 NameNode（根据是否已有 current 目录判断）
  if [[ ! -d "/hadoop/dfs/namenode/current" ]]; then
    echo "[entrypoint] Formatting NameNode..."
    "${HADOOP_HOME}/bin/hdfs" namenode -format -force -nonInteractive
  fi

  echo "[entrypoint] Starting HDFS..."
  # 手动启动各个服务，绕过start-dfs.sh的兼容性问题
  echo "[entrypoint] Starting NameNode..."
  bash -c "${HADOOP_HOME}/bin/hdfs --daemon start namenode"
  
  echo "[entrypoint] Starting DataNode on workers..."
  ssh worker1 "bash -c '${HADOOP_HOME}/bin/hdfs --daemon start datanode'"
  ssh worker2 "bash -c '${HADOOP_HOME}/bin/hdfs --daemon start datanode'"
  
  echo "[entrypoint] Starting SecondaryNameNode..."
  bash -c "${HADOOP_HOME}/bin/hdfs --daemon start secondarynamenode"

  echo "[entrypoint] Starting YARN..."
  echo "[entrypoint] Starting ResourceManager..."
  bash -c "${HADOOP_HOME}/bin/yarn --daemon start resourcemanager"
  
  echo "[entrypoint] Starting NodeManager on workers..."
  ssh worker1 "bash -c '${HADOOP_HOME}/bin/yarn --daemon start nodemanager'"
  ssh worker2 "bash -c '${HADOOP_HOME}/bin/yarn --daemon start nodemanager'"

  echo "[entrypoint] Starting MR JobHistory..."
  bash -c "${HADOOP_HOME}/bin/mapred --daemon start historyserver"
else
  echo "[entrypoint] Role: worker (sshd only; daemons started via master)"
fi

# 保持前台
tail -F "${HADOOP_HOME}/logs/"* 2>/dev/null || tail -f /dev/null