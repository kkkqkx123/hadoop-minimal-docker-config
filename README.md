# Docker Hadoop 集群部署项目

本项目提供了多种优化配置的 Docker 镜像和部署方案，用于快速搭建 Hadoop 集群环境。

## 🚀 快速开始

### 1. 环境要求

- Docker 20.10+
- Docker Compose 1.29+
- 至少 8GB 可用内存
- 20GB 可用磁盘空间

### 2. 一键部署

```bash
# 创建数据目录
mkdir -p /tmp/hadoop-volumes/{namenode,datanode1,datanode2,yarnlogs}

# 构建镜像并启动集群
docker-compose up -d
```

### 3. 验证集群状态

```bash
# 查看容器状态
docker-compose ps

# 访问 Hadoop Web UI
# NameNode: http://localhost:9870
# ResourceManager: http://localhost:8088
# NodeManager: http://localhost:8042
```

## 📋 部署方案对比

| 方案 | 镜像大小 | 内存需求 | 适用场景 |
|------|----------|----------|----------|
| 标准优化版 | ~600MB | 5GB | 通用场景，平衡性能和资源 |
| 多阶段构建版 | ~580MB | 5GB | 生产环境，最小化镜像大小 |
| ~~Alpine 轻量版~~ | ~400MB | 3.5GB | ~~开发测试，资源受限环境~~ ⚠️ **已弃用，存在兼容性问题** |

## 🔧 部署方案详情

### 方案一：标准优化版（推荐）

```bash
# 构建镜像
docker build -t hadoop:optimized .

# 启动集群
docker-compose up -d
```

**特点：**
- JVM 参数优化（G1GC、堆内存调优）
- 网络参数优化（TCP、IPC）
- 资源限制合理分配

### 方案二：多阶段构建版

```bash
# 构建镜像
docker build -f Dockerfile.multistage -t hadoop:multistage .

# 启动集群
docker-compose -f docker-compose-multistage.yml up -d
```

**特点：**
- 最小化镜像大小
- 构建过程优化
- 保持功能完整性

### 方案三：Alpine 轻量版 ⚠️ 已弃用

```bash
# 构建镜像
docker build -f Dockerfile.alpine -t hadoop:alpine .

# 启动集群
docker-compose -f docker-compose-alpine.yml up -d
```

**⚠️ 重要提醒：Alpine 版本存在兼容性问题，已弃用**

**已知问题：**
- DataNode JVM 崩溃（SIGSEGV 错误）
- Web UI 端口无法访问
- HDFS 文件操作失败
- MapReduce 作业执行异常

**问题原因：**
Alpine Linux 使用 musl libc 而非 glibc，与 Hadoop 本地库存在兼容性冲突，特别是 ShortCircuitRegistry 组件会导致段错误。

**解决方案：**
请使用标准优化版或多阶段构建版替代。

**历史特点：**
- 基于 Alpine Linux，镜像最小（~400MB）
- 内存占用最低（3.5GB）
- 仅适合资源极度受限环境（不推荐）

## 📊 集群架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Hadoop Master │    │  Hadoop Worker1 │    │  Hadoop Worker2 │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │ NameNode  │  │    │  │ DataNode  │  │    │  │ DataNode  │  │
│  │           │  │    │  │           │  │    │  │           │  │
│  │ Resource- │  │    │  │ Node-     │  │    │  │ Node-     │  │
│  │ Manager   │  │    │  │ Manager   │  │    │  │ Manager   │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│                 │    │                 │    │                 │
│  端口:          │    │  端口:          │    │  端口:          │
│  9870 (NameNode)│    │  8042           │    │  8042           │
│  8088 (Resource)│    │  9864           │    │  9864           │
│  9000           │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🛠️ 配置文件说明

### 核心配置文件

| 文件 | 作用 | 优化内容 |
|------|------|----------|
| `conf/hadoop-env.sh` | Hadoop环境配置 | JVM参数、堆内存设置 |
| `conf/core-site.xml` | 核心参数配置 | 缓冲区大小、网络优化 |
| `conf/hdfs-site.xml` | HDFS配置 | 副本因子、块大小 |
| `conf/yarn-site.xml` | YARN配置 | 内存分配、调度器设置 |
| `conf/mapred-site.xml` | MapReduce配置 | 任务内存限制 |

### Docker 相关文件

| 文件 | 作用 |
|------|------|
| `daemon.json` | Docker守护进程配置 |
| `docker-compose*.yml` | 集群部署配置 |
| `Dockerfile*` | 镜像构建文件 |

## 📈 性能优化

### JVM 优化
- 使用 G1GC 垃圾收集器
- 合理的堆内存分配
- GC 停顿时间优化

### 网络优化
- TCP 参数调优
- IPC 连接优化
- MTU 大小调整

### 存储优化
- Overlay2 存储驱动
- 日志大小限制
- 数据卷绑定挂载

## 🔍 监控和调试

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs master
docker-compose logs worker1
```

### 进入容器
```bash
# 进入主节点
docker-compose exec master bash

# 进入工作节点
docker-compose exec worker1 bash
```

### 常用命令
```bash
# 查看HDFS状态
hdfs dfsadmin -report

# 查看YARN节点状态
yarn node -list

# 运行测试作业
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 5
```

## 🚨 常见问题

### 1. 内存不足
- 调整 `docker-compose.yml` 中的内存限制
- ~~使用 Alpine 轻量版减少内存占用~~ ⚠️ Alpine 版本已弃用，请使用标准优化版或多阶段构建版

### 2. 端口冲突
- 检查端口占用情况
- 修改 `docker-compose.yml` 中的端口映射

### 3. 数据目录权限
- 确保数据目录有正确的权限
- 使用 `chmod` 命令设置权限

## 🎯 最佳实践

1. **生产环境**：使用多阶段构建版，平衡性能和资源
2. ~~**开发测试**：使用 Alpine 轻量版，节省资源~~ ⚠️ Alpine 版本已弃用，推荐使用标准优化版
3. **学习研究**：使用标准优化版，功能完整
4. **资源监控**：定期查看容器资源使用情况
5. **日志管理**：及时清理过期日志文件

## 📚 相关资源

- [Hadoop 官方文档](https://hadoop.apache.org/docs/)
- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)

## 📖 构建原理文档

详细的构建原理和技术实现请参考 `docs/` 目录：

- **[标准优化版构建原理](docs/standard-build-principle.md)** - 单阶段构建的完整流程和优化策略
- **[多阶段构建版原理](docs/multistage-build-principle.md)** - Docker 多阶段构建技术和镜像优化
- ~~**[Alpine 轻量版构建原理](docs/alpine-build-principle.md)** - 基于 Alpine Linux 的极致轻量化方案~~ ⚠️ **已弃用：存在兼容性问题**
- **[Docker Compose 部署原理](docs/docker-compose-principle.md)** - 多容器编排和服务管理
- **[构建方案对比总结](docs/build-comparison-summary.md)** - 三种方案的详细对比分析

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

WSL_TARGET=/home/docker-compose/hadoop