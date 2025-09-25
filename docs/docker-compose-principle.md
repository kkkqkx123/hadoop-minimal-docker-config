# Docker Compose 部署原理

## 🎯 设计目标

Docker Compose 通过声明式配置管理多容器应用，实现 Hadoop 集群的一键部署、服务编排和资源管理，提供开发、测试、生产环境的一致性部署方案。

## 🏗️ 架构设计

### 集群架构
```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network (hadoop)                 │
│                    MTU: 1450, Driver: bridge               │
└─────────────────────┬───────────────────┬───────────────────┘
                      │                   │
          ┌───────────┴───────────┐ ┌──────┴───────────┐
          │   Hadoop Master       │ │  Hadoop Worker   │
          │   (NameNode + RM)     │ │  (DataNode + NM) │
          │                       │ │                  │
          │  Ports:               │ │  Ports:          │
          │  - 9870 (NameNode)    │ │  - 8042 (NM)     │
          │  - 8088 (ResourceMgr)  │ │  - 9864 (Data)   │
          │  - 9000  (IPC)        │ │  - 9866 (IPC)    │
          │                       │ │                  │
          │  Resources:           │ │  Resources:      │
          │  - Memory: 2GB         │ │  - Memory: 1.5GB│
          │  - CPU: 1.0            │ │  - CPU: 0.8      │
          │                       │ │                  │
          │  Volumes:             │ │  Volumes:        │
          │  - namenode            │ │  - datanode      │
          │  - yarnlogs            │ │  - yarnlogs      │
          └───────────────────────┘ └──────────────────┘
```

### 数据流设计
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Client App │    │  NameNode   │    │  DataNode   │
│             │───▶│   (Master)  │◀──▶│   (Worker)  │
│  HDFS API   │    │  Metadata   │    │  Block Data  │
└─────────────┘    └─────────────┘    └─────────────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Job Client │    │ ResourceMgr │    │ NodeManager │
│             │───▶│  (Master)   │◀──▶│  (Worker)   │
│  YARN API   │    │ Scheduling  │    │  Container  │
└─────────────┘    └─────────────┘    └─────────────┘
```

## ⚙️ 核心组件配置

### 1. 服务定义 (Services)

#### Master 服务配置
```yaml
services:
  master:
    image: hadoop:optimized
    container_name: hadoop-master
    hostname: master
    ports:
      - "9870:9870"  # NameNode Web UI
      - "8088:8088"  # ResourceManager Web UI
      - "9000:9000"  # HDFS IPC
    environment:
      - HADOOP_MASTER=true
    volumes:
      - namenode:/opt/hadoop/data/namenode
      - yarnlogs:/opt/hadoop/logs/yarn
    networks:
      - hadoop
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

**配置原理：**
- **端口映射**：暴露核心服务端口到宿主机
- **环境变量**：标识主节点角色
- **数据卷**：持久化 NameNode 元数据和日志
- **资源限制**：防止资源过度使用
- **网络配置**：连接到专用网络

#### Worker 服务配置
```yaml
  worker1:
    image: hadoop:optimized
    container_name: hadoop-worker1
    hostname: worker1
    ports:
      - "8042:8042"  # NodeManager Web UI
      - "9864:9864"  # DataNode Web UI
    environment:
      - HADOOP_MASTER=false
    volumes:
      - datanode1:/opt/hadoop/data/datanode
      - yarnlogs:/opt/hadoop/logs/yarn
    depends_on:
      - master
    networks:
      - hadoop
    deploy:
      resources:
        limits:
          memory: 1.5G
          cpus: '0.8'
```

**配置原理：**
- **依赖关系**：确保 Master 先启动
- **资源分配**：Worker 节点资源相对较少
- **数据存储**：独立的 DataNode 数据卷
- **服务发现**：通过容器名进行网络通信

### 2. 网络配置 (Networks)

```yaml
networks:
  hadoop:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1450
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

**网络优化：**
- **MTU 设置**：1450 字节，适配常见网络环境
- **子网规划**：专用网段避免冲突
- **Bridge 驱动**：容器间高效通信
- **DNS 解析**：自动服务发现

### 3. 存储配置 (Volumes)

```yaml
volumes:
  namenode:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /tmp/hadoop-volumes/namenode
  
  datanode1:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /tmp/hadoop-volumes/datanode1
```

**存储策略：**
- **绑定挂载**：宿主机目录直接映射
- **本地驱动**：高性能本地存储
- **数据隔离**：不同类型数据分离存储
- **权限管理**：宿主机权限控制

## 🔧 资源管理原理

### 1. 内存管理
```yaml
deploy:
  resources:
    limits:
      memory: 2G
    reservations:
      memory: 1G
```

**内存策略：**
- **硬性限制**：防止内存溢出
- **预留机制**：确保基本内存需求
- **OOM 处理**：Docker 自动终止超额容器
- **JVM 适配**：根据容器内存调整 JVM 参数

### 2. CPU 管理
```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
    reservations:
      cpus: '0.5'
```

**CPU 策略：**
- **配额限制**：相对 CPU 时间分配
- **调度策略**：CFS 调度器管理
- **负载均衡**：多核 CPU 间负载分布
- **性能隔离**：防止容器间干扰

### 3. 存储限制
```yaml
volumes:
  datanode1:
    driver: local
    driver_opts:
      type: none
      o: bind,size=10G
      device: /tmp/hadoop-volumes/datanode1
```

## 🚀 启动流程

### 1. 初始化阶段
```bash
# 1. 创建网络
docker network create hadoop

# 2. 创建数据卷
docker volume create namenode
docker volume create datanode1

# 3. 启动 Master
docker run -d --name master --network hadoop hadoop:optimized
```

### 2. 服务发现阶段
```bash
# Master 容器启动
- 启动 SSH 服务
- 格式化 NameNode (首次)
- 启动 HDFS 服务
- 启动 YARN 服务

# Worker 容器启动
- 等待 Master 就绪
- 通过容器名连接 Master
- 启动 DataNode
- 启动 NodeManager
```

### 3. 集群就绪验证
```bash
# HDFS 状态检查
hdfs dfsadmin -report

# YARN 节点检查
yarn node -list

# Web UI 访问测试
curl http://master:9870
curl http://master:8088
```

## 📊 性能优化配置

### 1. 网络优化
```yaml
networks:
  hadoop:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1450
      com.docker.network.bridge.name: hadoop-br
```

**优化原理：**
- **MTU 调优**：减少分片，提高吞吐量
- **网桥命名**：便于网络管理
- **DNS 缓存**：加速服务发现

### 2. 存储优化
```yaml
volumes:
  namenode:
    driver: local
    driver_opts:
      type: none
      o: bind,nodiratime
      device: /tmp/hadoop-volumes/namenode
```

**优化策略：**
- **绑定挂载**：避免额外的文件系统层
- **noatime**：减少元数据更新
- **本地存储**：SSD 优化存储路径

### 3. 资源调度优化
```yaml
services:
  master:
    deploy:
      placement:
        constraints:
          - node.role == manager
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
```

## 🔍 监控和调试

### 1. 日志管理
```yaml
services:
  master:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        labels: "hadoop,master"
```

### 2. 健康检查
```yaml
services:
  master:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9870"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

### 3. 性能监控
```bash
# 容器资源使用
docker stats

# 服务状态检查
docker-compose ps

# 日志查看
docker-compose logs -f master
```

## ⚠️ 注意事项

### 1. 端口冲突
```yaml
# 检查端口占用
netstat -tlnp | grep 9870

# 修改端口映射
ports:
  - "19870:9870"  # 宿主机:容器
```

### 2. 资源不足
```yaml
# 内存不足处理
deploy:
  resources:
    limits:
      memory: 1G  # 降低内存限制
    reservations:
      memory: 512M
```

### 3. 网络连通性
```bash
# 检查网络配置
docker network ls
docker network inspect hadoop

# 测试容器间通信
docker exec worker1 ping master
```

## 🎯 多环境适配

### 1. 开发环境
```yaml
# docker-compose.yml
version: '3.8'
services:
  master:
    ports:
      - "9870:9870"
      - "8088:8088"
    volumes:
      - ./data/namenode:/opt/hadoop/data/namenode
```

### 2. 测试环境
```yaml
# docker-compose-test.yml
version: '3.8'
services:
  master:
    deploy:
      replicas: 1
      resources:
        limits:
          memory: 1G
```

### 3. 生产环境
```yaml
# docker-compose-prod.yml
version: '3.8'
services:
  master:
    deploy:
      placement:
        constraints:
          - node.labels.hadoop == master
      restart_policy:
        condition: any
        delay: 10s
```

## 🔧 扩展配置

### 1. 多 Master 配置
```yaml
services:
  master1:
    image: hadoop:optimized
    environment:
      - HADOOP_HA_MODE=true
      - HADOOP_NAMENODE_ID=nn1
  
  master2:
    image: hadoop:optimized
    environment:
      - HADOOP_HA_MODE=true
      - HADOOP_NAMENODE_ID=nn2
```

### 2. 外部依赖集成
```yaml
services:
  zookeeper:
    image: zookeeper:3.8
    networks:
      - hadoop
  
  master:
    depends_on:
      - zookeeper
    environment:
      - ZK_QUORUM=zookeeper:2181
```

### 3. 配置中心集成
```yaml
services:
  master:
    configs:
      - source: hadoop_core_site
        target: /opt/hadoop/etc/hadoop/core-site.xml
      - source: hadoop_hdfs_site
        target: /opt/hadoop/etc/hadoop/hdfs-site.xml
```