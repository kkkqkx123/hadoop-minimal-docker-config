# Hadoop Docker配置优化总结

## 🚀 主要优化项

### 1. JDK镜像优化
- **原配置**: `eclipse-temurin:11-jdk-jammy`
- **优化后**: `openjdk:11-slim`
- **效果**: 减少镜像体积约200MB

### 2. 系统资源限制
- **Master节点**: 内存限制2G，CPU限制1.0核
- **Worker节点**: 内存限制1.5G，CPU限制0.8核
- **效果**: 防止容器占用过多系统资源

### 3. YARN资源管理优化
```xml
<!-- 节点资源限制 -->
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>1024</value>
</property>
<property>
  <name>yarn.nodemanager.resource.cpu-vcores</name>
  <value>1</value>
</property>

<!-- 容器资源限制 -->
<property>
  <name>yarn.scheduler.minimum-allocation-mb</name>
  <value>256</value>
</property>
<property>
  <name>yarn.scheduler.maximum-allocation-mb</name>
  <value>1024</value>
</property>
```

### 4. HDFS性能优化
```xml
<!-- NameNode优化 -->
<property>
  <name>dfs.namenode.handler.count</name>
  <value>10</value>
</property>

<!-- DataNode优化 -->
<property>
  <name>dfs.datanode.handler.count</name>
  <value>3</value>
</property>

<!-- 减少心跳和块报告频率 -->
<property>
  <name>dfs.heartbeat.interval</name>
  <value>30</value>
</property>
<property>
  <name>dfs.blockreport.intervalMsec</name>
  <value>300000</value>
</property>
```

### 5. MapReduce内存优化
```xml
<property>
  <name>mapreduce.map.memory.mb</name>
  <value>512</value>
</property>
<property>
  <name>mapreduce.reduce.memory.mb</name>
  <value>512</value>
</property>
<property>
  <name>mapreduce.map.java.opts</name>
  <value>-Xmx384m</value>
</property>
```

### 6. 系统工具精简
- **移除工具**: `net-tools`, `vim`, `less`
- **保留工具**: `openssh-server`, `rsync`, `curl`, `ca-certificates`, `procps`, `python3`
- **效果**: 进一步减少镜像大小

## 📊 资源节约效果

| 优化项 | 节约资源 | 影响 |
|--------|----------|------|
| JDK镜像优化 | ~200MB磁盘空间 | 镜像体积减小 |
| 系统资源限制 | 内存: 5G→3.5G | 防止资源过度占用 |
| YARN资源限制 | 内存使用可控 | 提高资源利用率 |
| 配置优化 | CPU/IO减少 | 提升性能 |

## ⚠️ 注意事项

1. **内存限制**: 当前配置适合开发/测试环境，生产环境需要增加内存分配
2. **CPU限制**: 限制了并发处理能力，适合轻量级数据处理
3. **块大小**: 设置为128MB，适合中等大小文件，小文件场景需要调整
4. **监控建议**: 建议监控容器资源使用情况，根据实际需求调整限制值

## 🔧 进一步优化建议

1. **使用Alpine Linux**: 可进一步减小镜像体积 ✅
2. **多阶段构建**: 分离构建和运行环境 ✅
3. **JVM参数优化**: 添加GC和内存分配优化参数 ✅
4. **网络优化**: 调整TCP缓冲区大小 ✅
5. **存储优化**: 使用更高效的存储驱动 ✅

## 📋 存储和网络优化 (已完成)

### 1. Docker守护进程配置
- **存储驱动**: 使用overlay2，性能更好
- **日志限制**: 日志文件最大10MB，保留3个文件
- **并发控制**: 限制同时下载/上传数为3
- **配置位置**: `daemon.json`
- **作用**: 配置Docker守护进程的运行参数，优化容器性能和资源使用
- **附加配置**:
  - 启用 `live-restore` 允许Docker守护进程重启时不中断运行中的容器
  - 禁用 `userland-proxy` 减少网络延迟
  - 启用 `no-new-privileges` 增强安全性

### 2. Docker网络优化
- **MTU优化**: 设置为1450，避免分片
- **绑定挂载**: 使用主机目录，提高IO性能
- **配置位置**: `docker-compose.yml`

### 3. 存储卷优化
- **绑定挂载**: 直接使用主机文件系统，避免额外的存储层
- **路径规划**: `/tmp/hadoop-volumes/`下统一管理
- **权限控制**: 通过主机文件系统权限管理

## 📋 已完成的高级优化

### 1. JVM参数优化 (已完成)
- **GC算法**: 使用G1垃圾收集器，减少停顿时间
- **堆内存**: NameNode 384MB, DataNode 256MB
- **内存管理**: 支持CGroup内存限制
- **配置位置**: `conf/hadoop-env.sh`

### 2. 网络优化 (已完成)
- **TCP优化**: 启用TCP_NODELAY，减少延迟
- **连接重试**: 最多重试3次，间隔1秒
- **监听队列**: 增大到128，提高并发能力
- **配置位置**: `conf/core-site.xml`

### 3. 多阶段构建 (已完成)
- **构建文件**: `Dockerfile.multistage`
- **优势**: 减少最终镜像大小，分离构建和运行环境
- **构建命令**: `docker build -f Dockerfile.multistage -t hadoop:multistage .`

### 4. Alpine Linux版本 (已完成)
- **构建文件**: `Dockerfile.alpine`
- **优势**: 基于Alpine Linux，镜像体积极小
- **注意**: 使用musl libc，需要测试兼容性
- **构建命令**: `docker build -f Dockerfile.alpine -t hadoop:alpine .`

## 🚀 使用不同优化的构建命令

### 标准优化版本
```bash
docker build -t hadoop:optimized .
```

### 多阶段构建版本
```bash
docker build -f Dockerfile.multistage -t hadoop:multistage .
```

### Alpine Linux版本
```bash
docker build -f Dockerfile.alpine -t hadoop:alpine .
```

### 镜像大小对比
| 版本 | 预估大小 | 特点 |
|------|----------|------|
| 标准优化版 | ~600MB | 平衡性能和大小 |
| 多阶段构建版 | ~580MB | 构建过程优化 |
| Alpine版 | ~400MB | 极致轻量，需验证兼容性 |

## 🎯 优化效果总结

### 资源节约
- **镜像大小**: 相比原始配置减少约200-400MB
- **内存使用**: 集群总内存限制从5G降至3.5G
- **CPU使用**: 通过资源限制避免过度占用
- **存储IO**: 使用绑定挂载提高性能

### 性能提升
- **JVM性能**: G1垃圾收集器减少停顿
- **网络性能**: TCP优化减少延迟
- **存储性能**: overlay2驱动提高效率
- **启动速度**: 多阶段构建优化镜像层

### 运维便利
- **资源可控**: 通过docker-compose限制资源
- **日志管理**: 自动轮转避免磁盘占满
- **网络调优**: MTU优化减少网络问题
- **存储管理**: 统一规划数据目录

## 📖 使用指南

详细的使用说明请参考 [README.md](README.md) 文件，包含：
- 快速开始指南
- 三种部署方案对比
- 集群架构说明
- 性能优化详情
- 监控调试方法
- 常见问题解答
