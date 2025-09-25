说明：此配置面向学习/开发环境，采用 root 用户和内置 SSH 免密，便于开箱即用；生产环境请改为专用用户与更严格的安全策略。

---

# 目录结构

建议按如下结构创建本地目录：

```
hadoop-docker/
├─ docker-compose.yml
├─ Dockerfile
├─ scripts/
│  └─ entrypoint.sh
└─ conf/
   ├─ core-site.xml
   ├─ hdfs-site.xml
   ├─ yarn-site.xml
   ├─ mapred-site.xml
   ├─ hadoop-env.sh
   └─ workers
```

---

# 1) docker-compose.yml

```yaml
version: "3.9"

services:
  master:
    build: .
    container_name: master
    hostname: master
    environment:
      - HADOOP_ROLE=master
      # 以 root 启动各守护进程（Hadoop 3 脚本在 root 下需要这些变量）
      - HDFS_NAMENODE_USER=root
      - HDFS_DATANODE_USER=root
      - HDFS_SECONDARYNAMENODE_USER=root
      - HDFS_ZKFC_USER=root
      - YARN_RESOURCEMANAGER_USER=root
      - YARN_NODEMANAGER_USER=root
    ports:
      - "9870:9870"   # NameNode Web UI
      - "8088:8088"   # ResourceManager Web UI
      - "19888:19888" # JobHistory Web UI
      - "10020:10020" # JobHistory RPC
      - "8020:8020"   # HDFS NN RPC (fs.defaultFS)
      - "22:22"       # SSH（可选）
    volumes:
      - namenode:/hadoop/dfs/namenode
      - yarnlogs:/tmp/hadoop-yarn
    depends_on:
      - worker1
      - worker2
    networks:
      - hadoop

  worker1:
    build: .
    container_name: worker1
    hostname: worker1
    environment:
      - HADOOP_ROLE=worker
      - HDFS_DATANODE_USER=root
      - YARN_NODEMANAGER_USER=root
    ports:
      - "9864:9864"   # DataNode Web UI（worker1）
      - "8042:8042"   # NodeManager Web UI（worker1）
    volumes:
      - datanode1:/hadoop/dfs/datanode
    networks:
      - hadoop

  worker2:
    build: .
    container_name: worker2
    hostname: worker2
    environment:
      - HADOOP_ROLE=worker
      - HDFS_DATANODE_USER=root
      - YARN_NODEMANAGER_USER=root
    ports:
      - "9865:9864"   # DataNode Web UI（worker2 映射到宿主 9865）
      - "8043:8042"   # NodeManager Web UI（worker2 映射到宿主 8043）
    volumes:
      - datanode2:/hadoop/dfs/datanode
    networks:
      - hadoop

volumes:
  namenode:
  datanode1:
  datanode2:
  yarnlogs:

networks:
  hadoop:
    driver: bridge
```

---

# 2) Dockerfile

> 基于 Java 11（Temurin），安装 OpenSSH、rsync 等；下载 Hadoop 3.3.6（你也可以改为 3.4.x），拷贝配置与启动脚本。为简化起见，在镜像里生成同一套 root SSH key，实现 master 免密 SSH 到各 worker。

```dockerfile
FROM eclipse-temurin:11-jdk-jammy

ARG HADOOP_VERSION=3.3.6
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

# 基础工具与 SSH
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openssh-server rsync curl ca-certificates net-tools procps vim less python3 && \
    rm -rf /var/lib/apt/lists/*

# Hadoop
RUN curl -fsSL https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
     -o /tmp/hadoop.tgz && \
    mkdir -p /opt && \
    tar -xzf /tmp/hadoop.tgz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm /tmp/hadoop.tgz

# 数据目录
RUN mkdir -p /hadoop/dfs/namenode /hadoop/dfs/datanode /tmp/hadoop-yarn && \
    mkdir -p ${HADOOP_HOME}/logs

# SSH 配置（演示用：镜像内置同一套 root key）
RUN mkdir -p /var/run/sshd /root/.ssh && \
    ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    printf "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n" > /root/.ssh/config && \
    sed -ri 's/#?PermitRootLogin .*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config && \
    sed -ri 's/#?PasswordAuthentication .*/PasswordAuthentication no/g' /etc/ssh/sshd_config

# 拷贝配置与脚本
COPY conf/core-site.xml ${HADOOP_HOME}/etc/hadoop/core-site.xml
COPY conf/hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
COPY conf/yarn-site.xml ${HADOOP_HOME}/etc/hadoop/yarn-site.xml
COPY conf/mapred-site.xml ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
COPY conf/hadoop-env.sh ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
COPY conf/workers ${HADOOP_HOME}/etc/hadoop/workers

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 暴露常用端口（compose 里会映射）
EXPOSE 22 8020 9870 9864 8088 8042 19888 10020

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

---

# 3) scripts/entrypoint.sh

> 启动 SSH；若为 master：等待 worker SSH 可用、首次自动格式化 NameNode（仅当数据目录未初始化）、启动 HDFS 与 YARN、启动 MapReduce JobHistory；最后保持日志前台以防容器退出。

```bash
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
```

---

# 4) Hadoop 配置文件（conf/）

## conf/workers

> 指定 YARN/DFS 的 worker 主机名（与 compose 中 hostname 一致）

```
worker1
worker2
```

## conf/hadoop-env.sh

> 指定 Java 路径（Temurin 11 在 Ubuntu 上通常是这个）

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

## conf/core-site.xml

```xml
<?xml version="1.0"?>
<configuration>
  <!-- HDFS 入口（与 compose 中 master 的 8020 端口一致） -->
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://master:8020</value>
  </property>

  <!-- Hadoop 运行时临时目录 -->
  <property>
    <name>hadoop.tmp.dir</name>
    <value>/tmp/hadoop-${user.name}</value>
  </property>

  <!-- 允许跨主机主机名解析（docker 内部 DNS 已处理，一般不必改） -->
  <property>
    <name>ipc.client.fallback-to-simple-auth-allowed</name>
    <value>true</value>
  </property>
</configuration>
```

## conf/hdfs-site.xml

```xml
<?xml version="1.0"?>
<configuration>
  <!-- NameNode 与 DataNode 数据目录 -->
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///hadoop/dfs/namenode</value>
  </property>

  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///hadoop/dfs/datanode</value>
  </property>

  <!-- 两个 worker，副本系数设为 2 -->
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>

  <!-- demo 环境禁用本地文件权限检查，减少权限问题 -->
  <property>
    <name>dfs.permissions.enabled</name>
    <value>false</value>
  </property>
</configuration>
```

## conf/yarn-site.xml

```xml
<?xml version="1.0"?>
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>master</value>
  </property>

  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>

  <property>
    <name>yarn.log-aggregation-enable</name>
    <value>true</value>
  </property>

  <!-- YARN Web UI 8088 默认即可；NodeManager Web UI 在 8042（各 worker 已映射端口） -->
</configuration>
```

## conf/mapred-site.xml

```xml
<?xml version="1.0"?>
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>

  <property>
    <name>mapreduce.jobhistory.address</name>
    <value>master:10020</value>
  </property>

  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>master:19888</value>
  </property>
</configuration>
```

---

# 5) 启动与验证

在 `hadoop-docker/` 目录下执行：

```bash
# 1) 构建镜像
docker compose build

# 2) 启动（后台）
docker compose up -d

# 3) 查看容器与端口
docker compose ps
```

等待 10\~20 秒（首次会自动格式化 NameNode 并拉起各进程）后：

* 访问 NameNode Web UI：[http://localhost:9870](http://localhost:9870)
* 访问 ResourceManager UI：[http://localhost:8088](http://localhost:8088)
* 访问 JobHistory UI：[http://localhost:19888](http://localhost:19888)
* 访问各 DataNode/NodeManager：

  * worker1：DN UI [http://localhost:9864](http://localhost:9864) ，NM UI [http://localhost:8042](http://localhost:8042)
  * worker2：DN UI [http://localhost:9865](http://localhost:9865) ，NM UI [http://localhost:8043](http://localhost:8043)

**命令行验证：**

```bash
# 进入 master
docker exec -it master bash

# 查看 HDFS 状态
hdfs dfsadmin -report

# 创建测试目录并放入样例文件
hdfs dfs -mkdir -p /input
hdfs dfs -put $HADOOP_HOME/etc/hadoop/*.xml /input

# 运行 MapReduce WordCount（输出到 /output）
yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /input /output

# 查看结果
hdfs dfs -cat /output/part-r-00000 | head
```

---

# 6) 常见操作

* **停止集群：**

  ```bash
  docker compose down
  ```
* **清空全部数据（慎用，会重置并触发重新 format）：**

  ```bash
  docker compose down -v
  ```

---

# 7) 注意与扩展

1. **SSH 免密**：为方便演示，在镜像构建阶段为 root 生成了一套固定密钥并写入 `authorized_keys`。这让 master 能通过内置密钥免密 SSH 到 worker。

   * 生产环境请为每个容器/用户生成独立密钥，并通过安全手段（如 build args/secret 或启动时注入）分发公钥；关闭 root SSH 或禁用密码登录（本镜像已禁用密码登录）。
2. **规模扩展**：增加 worker 只需：

   * 在 `docker-compose.yml` 中复制出 `worker3` 服务（注意端口映射），
   * 在 `conf/workers` 列表追加 `worker3`，
   * 重新 `docker compose up -d --build`。
3. **版本切换**：在 Dockerfile 的 `ARG HADOOP_VERSION` 改为需要的版本（例如 3.4.x），同时确保 `hadoop-env.sh` 的 `JAVA_HOME` 与该版本的 Java 兼容。
4. **端口与网络**：Docker 内通过服务名（master/worker1/worker2）互相解析，无需手工改 hosts。需要在宿主访问 UI 时才映射端口。
5. **日志与历史服务器**：已启用日志聚合与 JobHistory，YARN 任务完成后可在 `19888` 查看历史任务。
