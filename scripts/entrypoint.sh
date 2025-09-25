#!/usr/bin/env bash
set -euo pipefail

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
    until ssh -o BatchMode=yes -o ConnectTimeout=2 "${host}" 'echo ok' >/dev/null 2>&1; do
      echo "  waiting for ${host} ssh..."
      sleep 2
    done
  done

  # 首次格式化 NameNode（根据是否已有 current 目录判断）
  if [[ ! -d "/hadoop/dfs/namenode/current" ]]; then
    echo "[entrypoint] Formatting NameNode..."
    "${HADOOP_HOME}/bin/hdfs" namenode -format -force -nonInteractive
  fi

  echo "[entrypoint] Starting HDFS..."
  "${HADOOP_HOME}/sbin/start-dfs.sh"

  echo "[entrypoint] Starting YARN..."
  "${HADOOP_HOME}/sbin/start-yarn.sh"

  echo "[entrypoint] Starting MR JobHistory..."
  "${HADOOP_HOME}/bin/mapred" --daemon start historyserver
else
  echo "[entrypoint] Role: worker (sshd only; daemons started via master)"
fi

# 保持前台
tail -F "${HADOOP_HOME}/logs/"* 2>/dev/null || tail -f /dev/null