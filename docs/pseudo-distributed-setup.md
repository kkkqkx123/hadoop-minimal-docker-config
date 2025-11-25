# Hadoop伪分布式配置指南

## 概述

伪分布式模式是Hadoop的一种部署方式，所有Hadoop守护进程（NameNode、DataNode、ResourceManager、NodeManager）都在单个节点上运行，但各自作为独立的Java进程运行。这种模式适合学习和测试环境。

## 配置要点

### 1. Docker Compose配置

**文件**: `docker-compose.yml`

**关键配置**:
- 单服务架构：只运行一个容器包含所有Hadoop组件
- 资源限制：总内存3G，CPU 4核
- 端口映射：所有必要端口都映射到宿主机
- 主机名：使用localhost

```yaml
hadoop-pseudo:
  image: hadoop:optimized
  container_name: hadoop-pseudo
  hostname: localhost
  deploy:
    resources:
      limits:
        memory: 3G
        cpus: '4.0'
      reservations:
        memory: 1.5G
        cpus: '2.0'
```

### 2. Core配置

**文件**: `conf/core-site-pseudo.xml`

**关键修改**:
- 将`fs.defaultFS`从`hdfs://master:8020`改为`hdfs://localhost:9000`
- 这是伪分布式模式的核心配置

```xml
<property>
  <name>fs.defaultFS</name>
  <value>hdfs://localhost:9000</value>
</property>
```

### 3. HDFS配置

**文件**: `conf/hdfs-site-pseudo.xml`

**关键修改**:
- 将副本数从2改为1（因为只有一个DataNode）
- 其他优化配置保持不变

```xml
<property>
  <name>dfs.replication</name>
  <value>1</value>
</property>
```

### 4. Workers配置

**文件**: `conf/workers-pseudo`

**关键修改**:
- 只包含localhost，不需要worker节点

```
localhost
```

### 5. YARN配置

**文件**: `conf/yarn-site.xml`（可复用现有配置）

**说明**:
- ResourceManager和NodeManager在同一节点运行
- 资源限制需要适配单节点环境
- 保持现有的资源调度配置

## 与完全分布式的主要区别

| 配置项 | 完全分布式 | 伪分布式 |
|--------|-----------|----------|
| 节点数量 | 多节点 | 单节点 |
| 副本数 | 2或更多 | 1 |
| fs.defaultFS | hdfs://master:8020 | hdfs://localhost:9000 |
| workers文件 | 包含所有worker节点 | 只包含localhost |
| 资源分配 | 分散到多个节点 | 集中在一个节点 |

## 使用步骤

### 1. 准备配置文件
```bash
# 使用伪分布式配置文件
cp conf/core-site-pseudo.xml conf/core-site.xml
cp conf/hdfs-site-pseudo.xml conf/hdfs-site.xml
cp conf/workers-pseudo conf/workers
```

### 2. 启动容器
```bash
docker-compose up -d
```

### 3. 格式化HDFS
```bash
docker exec -it hadoop-pseudo hdfs namenode -format
```

### 4. 启动Hadoop服务
```bash
docker exec -it hadoop-pseudo start-dfs.sh
docker exec -it hadoop-pseudo start-yarn.sh
```

### 5. 验证服务
- NameNode Web UI: http://localhost:9870
- ResourceManager Web UI: http://localhost:8088
- DataNode Web UI: http://localhost:9864

## 资源优化建议

1. **内存分配**: 总内存3G的分配建议
   - NameNode: 1G
   - DataNode: 512M
   - ResourceManager: 512M
   - NodeManager: 512M
   - 系统预留: 512M

2. **CPU分配**: 4核CPU的分配建议
   - 各守护进程共享CPU资源
   - 根据实际负载动态调整

3. **存储配置**:
   - 使用Docker卷持久化数据
   - 定期备份重要数据

## 常见问题

1. **端口冲突**: 确保宿主机没有其他服务占用相关端口
2. **内存不足**: 如果容器频繁OOM，需要调整内存限制
3. **权限问题**: 确保使用root用户运行各守护进程

## 总结

伪分布式配置通过简化部署架构，降低了学习和测试Hadoop的门槛。主要修改集中在网络配置、副本数和节点配置上。通过合理的资源限制和优化配置，可以在单节点上模拟完整的Hadoop集群功能。