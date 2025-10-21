# Hadoop Docker 自定义代码执行文档

本目录包含在Hadoop Docker环境中执行自定义代码的完整文档和工具。

## 📚 文档列表

### 1. 在hadoop-docker上执行自定义代码指南.md
- **内容**：完整的自定义代码执行指南
- **涵盖**：Java MapReduce、Python Streaming、Shell脚本
- **特点**：详细的代码示例、编译步骤、执行方法

### 2. 快速开始指南.md
- **内容**：快速上手教程
- **涵盖**：环境验证、3种执行方式、监控调试
- **特点**：步骤简洁、示例丰富、常见问题解答

## 🛠️ 工具脚本

### test-scripts/test-custom-code.sh
- **功能**：环境验证和测试脚本
- **用法**：
  ```bash
  ./test-scripts/test-custom-code.sh              # 完整测试
  ./test-scripts/test-custom-code.sh --python-only  # 只测试Python
  ./test-scripts/test-custom-code.sh --java-only    # 只测试Java
  ./test-scripts/test-custom-code.sh --hdfs-only    # 只测试HDFS
  ```

### examples/wordcount/generate_wordcount.py
- **功能**：生成Python MapReduce词频统计示例
- **用法**：
  ```bash
  cd examples/wordcount
  python3 generate_wordcount.py  # 生成mapper.py和reducer.py
  ```

## 🚀 快速开始

### 步骤1：验证环境
```bash
cd /home/docker-compose/hadoop
./test-scripts/test-custom-code.sh
```

### 步骤2：尝试Python示例
```bash
# 生成示例
cd examples/wordcount
python3 generate_wordcount.py

# 复制到容器
docker cp mapper.py hadoop-master:/tmp/
docker cp reducer.py hadoop-master:/tmp/

# 创建测试数据
echo "hello world hello hadoop" | docker-compose exec -T master tee /tmp/input.txt

# 执行
docker-compose exec master hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \
    -files /tmp/mapper.py,/tmp/reducer.py \
    -mapper 'python3 /tmp/mapper.py' \
    -reducer 'python3 /tmp/reducer.py' \
    -input /wordcount/input \
    -output /wordcount/output
```

### 步骤3：查看结果
```bash
docker-compose exec master hdfs dfs -cat /wordcount/output/part-*
```

## 📖 学习路径

### 初学者
1. 阅读 `快速开始指南.md`
2. 运行测试脚本验证环境
3. 尝试Python Streaming示例
4. 学习HDFS基本操作

### 进阶用户
1. 阅读完整的 `在hadoop-docker上执行自定义代码指南.md`
2. 编写Java MapReduce程序
3. 学习资源调优和性能监控
4. 探索高级特性（自定义分区器、比较器等）

### 高级用户
1. 开发复杂的MapReduce应用
2. 集成外部数据源
3. 构建数据处理流水线
4. 性能调优和故障排查

## 🔧 环境信息

- **Hadoop版本**：3.3.6
- **容器配置**：1个master节点，2个worker节点
- **资源限制**：每节点512MB内存（适合学习测试）
- **HDFS容量**：约2TB（分布式存储）

## 📞 支持

如遇到问题：
1. 检查服务状态：`docker-compose exec master jps`
2. 查看日志：`docker-compose logs --tail=50 master`
3. 运行测试脚本：`./test-scripts/test-custom-code.sh`
4. 参考快速指南中的常见问题解答

## 🎯 下一步

掌握基本使用后，可以探索：
- Hive数据仓库
- Pig数据分析
- HBase分布式数据库
- Spark大数据处理
- 机器学习算法实现