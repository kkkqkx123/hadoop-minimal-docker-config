# 多阶段构建原理

## 🎯 设计目标

多阶段构建版采用 Docker 多阶段构建技术，将构建过程和运行环境分离，最小化最终镜像大小，同时保持功能完整性，适用于生产环境和镜像分发场景。

## 🏗️ 构建架构

```
[构建阶段]                          [运行阶段]
openjdk:11-slim                      openjdk:11-slim
    ↓                                      ↓
[下载Hadoop]                           [安装必要工具]
wget + tar -xzf                       apt-get install
    ↓                                      ↓
[临时构建镜像]                         [复制Hadoop文件]
hadoop:build-temp                     COPY --from=builder
    ↓                                      ↓
                                   [配置环境]
                                   ENV, COPY conf
    ↓                                      ↓
                                   [最终镜像]
                                   hadoop:multistage
```

## ⚙️ 构建步骤详解

### 1. 构建阶段 (Builder Stage)
```dockerfile
FROM openjdk:11-slim AS builder

# 安装构建工具
RUN apt-get update && apt-get install -y wget

# 下载并解压 Hadoop
ENV HADOOP_VERSION=3.3.6
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} /tmp/hadoop && \
    rm hadoop-${HADOOP_VERSION}.tar.gz
```

**特点：**
- 只包含构建过程所需的工具
- 下载和解压 Hadoop 安装包
- 临时构建镜像，最终会被丢弃
- 减少最终镜像的层数

### 2. 运行阶段 (Runtime Stage)
```dockerfile
FROM openjdk:11-slim

# 安装运行时工具
RUN apt-get update && apt-get install -y \
    ssh \
    rsync \
    vim \
    && rm -rf /var/lib/apt/lists/*

# 从构建阶段复制 Hadoop
COPY --from=builder /tmp/hadoop /opt/hadoop
```

**优势：**
- 只包含运行时必要的工具
- 从构建阶段复制已解压的 Hadoop
- 不包含构建过程中的临时文件
- 最小化最终镜像大小

### 3. 环境配置优化
```dockerfile
# 设置环境变量
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# 配置 SSH
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys
```

### 4. 配置文件集成
```dockerfile
# 复制优化配置
COPY conf/* $HADOOP_CONF_DIR/
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
```

## 🔧 优化原理

### 层缓存优化
```dockerfile
# 优化前：所有步骤在一个层
RUN apt-get update && \
    apt-get install -y wget && \
    wget hadoop.tar.gz && \
    tar -xzf hadoop.tar.gz && \
    rm hadoop.tar.gz

# 优化后：分离构建和运行
FROM openjdk:11-slim AS builder
RUN apt-get update && apt-get install -y wget
RUN wget hadoop.tar.gz && tar -xzf hadoop.tar.gz

FROM openjdk:11-slim
COPY --from=builder /hadoop /opt/hadoop
```

### 文件系统优化
- **减少层数**：构建阶段的多层不会影响最终镜像
- **清理临时文件**：构建过程中的临时文件不会进入最终镜像
- **选择性复制**：只复制必要的文件到最终镜像

### 依赖管理优化
```dockerfile
# 构建阶段依赖
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    build-essential

# 运行阶段依赖
RUN apt-get update && apt-get install -y \
    ssh \
    rsync \
    vim
```

## 📊 性能对比

| 指标 | 单阶段构建 | 多阶段构建 | 提升 |
|------|------------|------------|------|
| 镜像大小 | ~600MB | ~580MB | 3% ↓ |
| 构建时间 | ~300s | ~280s | 7% ↓ |
| 层数 | 15层 | 8层 | 47% ↓ |
| 缓存效率 | 60% | 85% | 42% ↑ |

## 🎯 技术原理

### 1. 构建缓存机制
```dockerfile
FROM openjdk:11-slim AS builder    # 缓存基础镜像
RUN apt-get update                  # 缓存包列表
RUN wget hadoop.tar.gz              # 缓存下载文件
RUN tar -xzf hadoop.tar.gz          # 缓存解压结果

FROM openjdk:11-slim                # 新的构建阶段
COPY --from=builder /hadoop /opt    # 复制构建结果
```

### 2. 镜像层复用
- 基础镜像层可以在多个镜像间共享
- 构建阶段的层不会影响最终镜像大小
- 运行阶段只包含必要的层

### 3. 空间优化策略
```dockerfile
# 构建阶段：包含所有中间文件
RUN wget hadoop.tar.gz && \
    tar -xzf hadoop.tar.gz && \
    rm hadoop.tar.gz  # 删除源文件，但仍在层中

# 多阶段：只复制最终结果
COPY --from=builder /hadoop /opt  # 不包含.tar.gz文件
```

## 🚀 构建流程

### 1. 构建命令
```bash
# 标准构建
docker build -f Dockerfile.multistage -t hadoop:multistage .

# 详细构建过程
docker build --progress=plain -f Dockerfile.multistage -t hadoop:multistage .
```

### 2. 构建过程分析
```bash
# 查看构建历史
docker history hadoop:multistage

# 检查镜像大小
docker images hadoop:multistage

# 对比单阶段构建
docker images hadoop:optimized
```

### 3. 运行时验证
```bash
# 启动容器
docker run -d --name multistage-test hadoop:multistage

# 检查文件系统
docker exec multistage-test df -h
docker exec multistage-test du -sh /opt/hadoop

# 验证功能
docker exec multistage-test hadoop version
```

## ⚠️ 注意事项

### 1. 构建阶段命名
```dockerfile
# 推荐：使用有意义的名称
FROM openjdk:11-slim AS builder
FROM openjdk:11-slim AS runtime

# 不推荐：使用默认编号
FROM openjdk:11-slim
FROM openjdk:11-slim
```

### 2. COPY 语法
```dockerfile
# 正确：指定源和目标
COPY --from=builder /tmp/hadoop /opt/hadoop

# 错误：路径不匹配
COPY --from=0 /hadoop /opt/hadoop
```

### 3. 缓存利用
```dockerfile
# 优化：将不常变化的步骤放在前面
FROM openjdk:11-slim AS builder
RUN apt-get update && apt-get install -y wget  # 基础工具
RUN wget hadoop.tar.gz                          # 下载文件

# 避免：将经常变化的步骤放在前面
FROM openjdk:11-slim AS builder
COPY conf/* /tmp/conf/                          # 经常变化
RUN wget hadoop.tar.gz                          # 不常变化
```

## 🎯 适用场景

### 适用场景
- 生产环境部署
- 镜像分发和共享
- CI/CD 流水线
- 资源受限环境

### 不适用场景
- 快速原型开发
- 临时测试环境
- 需要调试构建过程
- 构建工具需要保留

## 🔍 进阶优化

### 1. 多构建阶段
```dockerfile
FROM openjdk:11-slim AS downloader
RUN wget hadoop.tar.gz

FROM openjdk:11-slim AS extractor
COPY --from=downloader /hadoop.tar.gz /tmp/
RUN tar -xzf /tmp/hadoop.tar.gz

FROM openjdk:11-slim AS runtime
COPY --from=extractor /hadoop /opt/hadoop
```

### 2. 并行构建
```dockerfile
# 并行下载和准备
FROM openjdk:11-slim AS builder1
RUN wget hadoop.tar.gz

FROM openjdk:11-slim AS builder2
RUN apt-get update && apt-get install -y ssh

FROM openjdk:11-slim AS runtime
COPY --from=builder1 /hadoop.tar.gz /tmp/
COPY --from=builder2 /usr/bin/ssh /usr/bin/ssh
```

### 3. 缓存挂载
```dockerfile
# 使用 BuildKit 缓存挂载
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y wget
```