# Spark 集成设计方案

## 概述

本文档描述了如何在当前 Hadoop 伪分布式环境中集成 Apache Spark，以替代传统的 MapReduce 计算框架。Spark 提供了更快的内存计算能力和更丰富的 API，特别适合迭代计算和交互式数据分析。

## 集成架构

### 总体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker 网络 (hadoop-network)          │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
            ┌───────▼───────┐   ┌───────▼───────┐
            │   Hadoop      │   │   Spark       │
            │   伪分布式     │   │   Standalone  │
            │   集群        │   │   集群        │
            └───────────────┘   └───────────────┘
                    │                   │
            ┌───────▼───────┐   ┌───────▼───────┐
            │   HDFS        │   │   Spark       │
            │   存储        │◄──┤   计算引擎     │
            └───────────────┘   └───────────────┘
```

### 组件关系

- **Hadoop**: 提供 HDFS 存储和 YARN 资源管理（可选）
- **Spark**: 提供内存计算能力，可直接访问 HDFS
- **集成方式**: Spark Standalone 模式，与 Hadoop 共享网络和数据存储

## 容器配置方案

### Spark 容器选择

基于研究和最佳实践，推荐以下容器镜像：

#### 方案一：官方 Spark 镜像（推荐）
```yaml
image: apache/spark:v3.5.3
```
- 优势：官方维护，版本稳定，社区支持好
- 特点：包含 Spark 3.5.3 和 Hadoop 3.3 客户端

#### 方案二：Bitnami Spark 镜像
```yaml
image: bitnami/spark:3.5.3
```
- 优势：配置简单，环境变量丰富
- 特点：非 root 用户运行，安全性好

### 资源配置建议

根据当前 Hadoop 容器配置（2.4G 内存，2.0 CPU），建议 Spark 资源配置：

```yaml
# Spark Master
spark-master:
  deploy:
    resources:
      limits:
        memory: 512M
        cpus: '0.5'
      reservations:
        memory: 256M
        cpus: '0.2'

# Spark Worker
spark-worker:
  deploy:
    resources:
      limits:
        memory: 1.5G
        cpus: '1.5'
      reservations:
        memory: 1G
        cpus: '1.0'
```

### 网络配置

Spark 容器需要与 Hadoop 容器在同一网络：

```yaml
networks:
  hadoop-network:
    external: true
```

## 核心配置文件

### spark-defaults.conf

```properties
# Spark 应用配置
spark.app.name=SparkOnHadoop
spark.master=spark://spark-master:7077
spark.submit.deployMode=client

# HDFS 集成配置
spark.hadoop.fs.defaultFS=hdfs://namenode:9000
spark.hadoop.dfs.replication=1

# 内存配置
spark.driver.memory=512m
spark.executor.memory=768m
spark.executor.cores=1
spark.executor.instances=1

# 序列化配置
spark.serializer=org.apache.spark.serializer.KryoSerializer
spark.kryo.registrationRequired=false

# 性能优化
spark.sql.adaptive.enabled=true
spark.sql.adaptive.coalescePartitions.enabled=true
spark.sql.adaptive.skewJoin.enabled=true
spark.sql.cbo.enabled=true

# 日志配置
spark.eventLog.enabled=true
spark.eventLog.dir=hdfs://namenode:9000/spark-logs
spark.history.fs.logDirectory=hdfs://namenode:9000/spark-logs

# 安全配置
spark.authenticate=false
spark.network.crypto.enabled=false
```

### spark-env.sh

```bash
#!/bin/bash

# Java 配置
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Hadoop 配置
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HADOOP_HOME=/opt/hadoop

# Spark 配置
export SPARK_HOME=/opt/spark
export SPARK_CONF_DIR=/opt/spark/conf
export SPARK_LOG_DIR=/opt/spark/logs
export SPARK_WORKER_DIR=/opt/spark/work

# 内存配置
export SPARK_DAEMON_MEMORY=256m
export SPARK_WORKER_MEMORY=1g
export SPARK_DRIVER_MEMORY=512m

# 垃圾回收配置
export SPARK_DAEMON_JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200"
export SPARK_WORKER_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

## 集成步骤

### 1. 创建 Spark 配置文件

```bash
# 创建 Spark 配置目录
mkdir -p conf/spark

# 复制 Hadoop 配置文件到 Spark 配置目录
cp conf/core-site.xml conf/spark/
cp conf/hdfs-site.xml conf/spark/
cp conf/yarn-site.xml conf/spark/
```

### 2. 更新 docker-compose.yml

```yaml
version: '3.8'

services:
  # 现有 Hadoop 服务...
  
  spark-master:
    image: apache/spark:v3.5.3
    container_name: spark-master
    hostname: spark-master
    environment:
      - SPARK_MODE=master
      - SPARK_RPC_AUTHENTICATION_ENABLED=no
      - SPARK_RPC_ENCRYPTION_ENABLED=no
      - SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED=no
      - SPARK_SSL_ENABLED=no
    ports:
      - "8080:8080"  # Spark Master Web UI
      - "7077:7077"  # Spark Master RPC
    volumes:
      - ./conf/spark:/opt/spark/conf
      - ./data/spark-logs:/opt/spark/logs
      - ./data/spark-work:/opt/spark/work
    networks:
      - hadoop-network
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.2'
    depends_on:
      - namenode
      - datanode

  spark-worker:
    image: apache/spark:v3.5.3
    container_name: spark-worker
    hostname: spark-worker
    environment:
      - SPARK_MODE=worker
      - SPARK_MASTER_URL=spark://spark-master:7077
      - SPARK_WORKER_MEMORY=1g
      - SPARK_WORKER_CORES=1
      - SPARK_RPC_AUTHENTICATION_ENABLED=no
      - SPARK_RPC_ENCRYPTION_ENABLED=no
      - SPARK_LOCAL_STORAGE_ENCRYPTION_ENABLED=no
      - SPARK_SSL_ENABLED=no
    ports:
      - "8081:8081"  # Spark Worker Web UI
    volumes:
      - ./conf/spark:/opt/spark/conf
      - ./data/spark-logs:/opt/spark/logs
      - ./data/spark-work:/opt/spark/work
    networks:
      - hadoop-network
    deploy:
      resources:
        limits:
          memory: 1.5G
          cpus: '1.5'
        reservations:
          memory: 1G
          cpus: '1.0'
    depends_on:
      - spark-master

networks:
  hadoop-network:
    external: true
```

### 3. 初始化 HDFS 目录

```bash
# 创建 Spark 日志目录
docker exec namenode hdfs dfs -mkdir -p /spark-logs
docker exec namenode hdfs dfs -chmod 777 /spark-logs
```

### 4. 验证集成

```bash
# 检查 Spark Master Web UI
curl http://localhost:8080

# 检查 Spark Worker Web UI
curl http://localhost:8081

# 运行测试应用
docker exec spark-master spark-submit \
  --class org.apache.spark.examples.SparkPi \
  --master spark://spark-master:7077 \
  --executor-memory 768m \
  --total-executor-cores 1 \
  /opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar 10
```

## 性能优化建议

### 内存优化

1. **动态内存管理**
```properties
spark.dynamicAllocation.enabled=true
spark.dynamicAllocation.minExecutors=1
spark.dynamicAllocation.maxExecutors=2
spark.dynamicAllocation.executorIdleTimeout=60s
```

2. **内存分配策略**
```properties
spark.memory.fraction=0.6
spark.memory.storageFraction=0.5
spark.sql.adaptive.coalescePartitions.minPartitionNum=1
```

### CPU 优化

1. **并行度设置**
```properties
spark.default.parallelism=2
spark.sql.shuffle.partitions=2
```

2. **调度优化**
```properties
spark.scheduler.mode=FAIR
spark.locality.wait=3s
```

### 存储优化

1. **HDFS 访问优化**
```properties
spark.hadoop.dfs.client.read.shortcircuit=true
spark.hadoop.dfs.domain.socket.path=/var/lib/hadoop-hdfs/dn_socket
spark.hadoop.dfs.client.use.datanode.hostname=true
```

2. **缓存策略**
```properties
spark.sql.adaptive.cached.enabled=true
spark.sql.cache.serializer=org.apache.spark.sql.execution.columnar.DefaultCachedBatchSerializer
```

## 监控和调试

### Web UI 访问

- **Spark Master UI**: http://localhost:8080
- **Spark Worker UI**: http://localhost:8081
- **Spark History Server**: http://localhost:18080 (需要额外配置)

### 日志查看

```bash
# 查看 Spark Master 日志
docker logs spark-master

# 查看 Spark Worker 日志
docker logs spark-worker

# 查看应用日志
docker exec spark-master hdfs dfs -ls /spark-logs
```

### 性能监控

```bash
# 监控资源使用
docker stats

# 检查 HDFS 空间
docker exec namenode hdfs dfs -df -h
```

## 常见问题处理

### 1. 内存不足

**症状**: 应用运行缓慢或失败
**解决**: 调整 `spark.executor.memory` 和 `spark.driver.memory`

### 2. HDFS 连接失败

**症状**: `java.net.ConnectException: Connection refused`
**解决**: 检查 `spark.hadoop.fs.defaultFS` 配置和网络连接

### 3. 端口冲突

**症状**: 容器启动失败
**解决**: 检查端口映射，避免与现有服务冲突

### 4. 资源竞争

**症状**: CPU 或内存使用率过高
**解决**: 调整容器资源限制和 Spark 配置参数

## 迁移指南

### 从 MapReduce 迁移到 Spark

1. **数据格式兼容**: Spark 支持 HDFS 上的所有 Hadoop 文件格式
2. **API 转换**: MapReduce 作业需要重写为 Spark RDD/DataFrame API
3. **配置复用**: 大部分 Hadoop 配置可以直接在 Spark 中使用

### 混合部署策略

1. **逐步迁移**: 保持 MapReduce 和 Spark 并行运行
2. **资源隔离**: 使用不同的资源队列或时间段
3. **数据共享**: 通过 HDFS 实现数据共享

## 总结

通过 Standalone 模式集成 Spark 到现有 Hadoop 环境，可以：

1. **保持简单**: 无需复杂的 YARN 集成
2. **资源可控**: 独立管理 Spark 资源
3. **性能优化**: 充分利用内存计算优势
4. **易于维护**: 配置简单，问题排查容易

建议按照本设计方案逐步实施，先搭建基础环境，再进行性能调优和应用迁移。