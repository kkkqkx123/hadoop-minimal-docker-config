# Hadoop + Spark 集成环境

本环境在现有 Hadoop 伪分布式基础上集成 Apache Spark，提供内存计算能力替代传统 MapReduce。

## 架构概述

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

## 快速开始

### 1. 启动基础 Hadoop 环境

```bash
# 启动 Hadoop 服务
docker-compose up -d

# 等待 Hadoop 完全启动（约 30-60 秒）
docker-compose logs -f namenode
```

### 2. 初始化 Spark HDFS 目录

```bash
# 运行初始化脚本
chmod +x scripts/init-spark-hdfs.sh
./scripts/init-spark-hdfs.sh
```

### 3. 启动 Spark 服务

```bash
# 启动 Spark 集群
docker-compose -f docker-compose-spark.yml up -d

# 等待 Spark 启动（约 30-60 秒）
docker-compose -f docker-compose-spark.yml logs -f spark-master
```

### 4. 验证集成

```bash
# 运行集成测试
chmod +x scripts/test-spark-integration.sh
./scripts/test-spark-integration.sh
```

## 服务访问

| 服务 | URL | 说明 |
|------|-----|------|
| Hadoop NameNode UI | http://localhost:9870 | HDFS 管理界面 |
| Hadoop ResourceManager UI | http://localhost:8088 | YARN 管理界面 |
| Spark Master UI | http://localhost:8080 | Spark 主节点管理 |
| Spark Worker UI | http://localhost:8081 | Spark 工作节点管理 |
| Spark History Server | http://localhost:18080 | Spark 历史记录 |
| Jupyter Lab (可选) | http://localhost:8888 | 交互式开发环境 |

## 资源配置

### 容器资源限制

| 服务 | 内存限制 | CPU限制 | 内存预留 | CPU预留 |
|------|----------|---------|----------|---------|
| Hadoop 容器 | 2.4G | 2.0 | 1.2G | 1.0 |
| Spark Master | 512M | 0.5 | 256M | 0.2 |
| Spark Worker | 1.5G | 1.5 | 1G | 1.0 |
| Spark History | 512M | 0.5 | 256M | 0.2 |
| Jupyter (可选) | 1G | 1.0 | 512M | 0.5 |

### Spark 配置参数

```properties
# 核心配置
spark.master=spark://spark-master:7077
spark.hadoop.fs.defaultFS=hdfs://namenode:9000

# 内存配置（适配容器限制）
spark.driver.memory=512m
spark.executor.memory=768m
spark.executor.cores=1
spark.executor.instances=1

# 性能优化
spark.sql.adaptive.enabled=true
spark.dynamicAllocation.enabled=true
spark.serializer=org.apache.spark.serializer.KryoSerializer
```

## 使用示例

### 1. 提交 Spark 应用

```bash
# 使用 spark-submit 提交应用
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  --executor-memory 768m \
  --total-executor-cores 1 \
  --class org.apache.spark.examples.SparkPi \
  /opt/spark/examples/jars/spark-examples_2.12-3.5.3.jar 10
```

### 2. PySpark 交互式使用

```bash
# 进入 PySpark shell
docker exec -it spark-master pyspark \
  --master spark://spark-master:7077 \
  --executor-memory 768m

# 在 PySpark 中测试 HDFS 连接
>>> text_file = spark.read.text("hdfs://namenode:9000/README.txt")
>>> text_file.count()
```

### 3. 数据处理示例

```python
# 创建测试脚本 test_wordcount.py
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("WordCount") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

# 读取 HDFS 文件
text_file = spark.sparkContext.textFile("hdfs://namenode:9000/README.txt")

# 执行 WordCount
counts = text_file.flatMap(lambda line: line.split()) \
                  .map(lambda word: (word, 1)) \
                  .reduceByKey(lambda a, b: a + b)

# 保存结果到 HDFS
counts.saveAsTextFile("hdfs://namenode:9000/wordcount-output")

spark.stop()
```

运行脚本：
```bash
docker exec spark-master spark-submit \
  --master spark://spark-master:7077 \
  test_wordcount.py
```

## 监控和调试

### 查看日志

```bash
# 查看 Spark Master 日志
docker logs spark-master

# 查看 Spark Worker 日志
docker logs spark-worker

# 实时查看日志
docker logs -f spark-master
```

### 性能监控

```bash
# 查看容器资源使用
docker stats

# 查看 HDFS 空间使用
docker exec namenode hdfs dfs -df -h

# 检查正在运行的应用
curl http://localhost:8080/json/
```

### 常见问题

#### 1. Spark 服务无法启动

**症状**: 容器启动后立即退出
**解决**: 
```bash
# 检查日志
docker logs spark-master

# 检查端口冲突
netstat -an | grep 8080
```

#### 2. HDFS 连接失败

**症状**: `java.net.ConnectException: Connection refused`
**解决**:
```bash
# 检查 Hadoop 服务状态
docker-compose ps

# 检查网络连接
docker exec spark-master ping namenode
```

#### 3. 内存不足

**症状**: 应用运行缓慢或失败
**解决**: 调整 `spark.executor.memory` 和容器资源限制

#### 4. 端口冲突

**症状**: 服务无法访问
**解决**: 修改 `docker-compose-spark.yml` 中的端口映射

## 扩展配置

### 添加更多 Worker 节点

编辑 `docker-compose-spark.yml`，添加更多 worker 服务：

```yaml
spark-worker-2:
  extends:
    file: docker-compose-spark.yml
    service: spark-worker
  container_name: spark-worker-2
  hostname: spark-worker-2
  ports:
    - "8082:8081"  # 不同的端口
```

### 启用 Spark History Server

```bash
# 启动包含 History Server 的配置
docker-compose -f docker-compose-spark.yml --profile history up -d
```

### 启用 Jupyter Lab

```bash
# 启动包含 Jupyter 的配置
docker-compose -f docker-compose-spark.yml --profile jupyter up -d

# 获取 Jupyter token
docker logs jupyter-spark | grep token
```

## 最佳实践

### 1. 资源管理
- 根据容器资源限制调整 Spark 内存配置
- 使用动态资源分配优化资源利用
- 监控资源使用情况，避免过度分配

### 2. 数据管理
- 合理设置 HDFS 副本数（伪分布式设为 1）
- 定期清理临时文件和日志
- 使用数据压缩减少存储空间

### 3. 性能优化
- 启用自适应查询执行
- 使用 Kryo 序列化提升性能
- 合理设置并行度和分区数

### 4. 安全配置
- 生产环境启用认证和加密
- 限制 Web UI 访问权限
- 定期更新容器镜像

## 故障排除

### 查看服务状态
```bash
# 查看所有服务状态
docker-compose ps
docker-compose -f docker-compose-spark.yml ps

# 重启服务
docker-compose restart namenode
docker-compose -f docker-compose-spark.yml restart spark-master
```

### 清理环境
```bash
# 停止所有服务
docker-compose -f docker-compose-spark.yml down
docker-compose down

# 清理数据卷（谨慎使用）
docker volume prune

# 重新初始化
./scripts/init-spark-hdfs.sh
```

## 相关文档

- [Spark 官方文档](https://spark.apache.org/docs/latest/)
- [Hadoop 官方文档](https://hadoop.apache.org/docs/)
- [Docker Compose 文档](https://docs.docker.com/compose/)

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个集成环境。