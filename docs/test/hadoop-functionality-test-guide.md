# Docker部署Hadoop功能测试指南

本文档详细说明如何测试Docker部署的Hadoop集群功能是否正常，包括HDFS、YARN、MapReduce等核心组件的验证方法。

## 测试前准备

### 1. 环境检查
确保Docker容器已正常启动：

```bash
# 在WSL中执行
docker-compose ps
```

预期输出应显示所有服务状态为`Up`：
- master
- worker1  
- worker2

### 2. 端口映射验证
确认以下端口在宿主机上可访问：
- NameNode Web UI: http://localhost:9870
- ResourceManager Web UI: http://localhost:8088
- DataNode Web UI (worker1): http://localhost:9864
- DataNode Web UI (worker2): http://localhost:9865
- NodeManager Web UI (worker1): http://localhost:8042
- NodeManager Web UI (worker2): http://localhost:8043

## 核心功能测试

### 1. HDFS功能测试

#### 1.1 进入Master容器
```bash
# 在WSL中执行
docker exec -it master bash
```

#### 1.2 检查HDFS状态
```bash
# 在Master容器内执行
hdfs dfsadmin -report
```

预期输出：
- 显示2个DataNode
- 每个DataNode状态为`Live`
- 显示磁盘容量信息

#### 1.3 文件系统操作测试
```bash
# 创建测试目录
hdfs dfs -mkdir /test

# 创建测试文件
echo "Hello Hadoop" > /tmp/test.txt

# 上传文件到HDFS
hdfs dfs -put /tmp/test.txt /test/

# 查看文件
hdfs dfs -ls /test/

# 读取文件内容
hdfs dfs -cat /test/test.txt

# 删除测试文件
hdfs dfs -rm /test/test.txt
hdfs dfs -rmdir /test
```

#### 1.4 Web UI验证
访问 http://localhost:9870
- 检查"Overview"页面显示集群状态正常
- 在"Datanodes"页面确认2个DataNode在线
- "Utilities" → "Browse the file system" 可以浏览HDFS文件

### 2. YARN功能测试

#### 2.1 检查YARN状态
```bash
# 在Master容器内执行
yarn node -list
```

预期输出：显示2个NodeManager节点，状态为`RUNNING`

#### 2.2 提交MapReduce作业
```bash
# 创建测试数据
mkdir -p /tmp/wordcount/input
echo "hello world hello hadoop" > /tmp/wordcount/input/file1.txt
echo "hadoop is great hadoop is fast" > /tmp/wordcount/input/file2.txt

# 上传数据到HDFS
hdfs dfs -mkdir -p /user/root/wordcount/input
hdfs dfs -put /tmp/wordcount/input/* /user/root/wordcount/input/

# 运行WordCount示例
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /user/root/wordcount/input /user/root/wordcount/output

# 查看结果
hdfs dfs -cat /user/root/wordcount/output/part-r-00000
```

#### 2.3 Web UI验证
访问 http://localhost:8088
- 检查集群节点信息
- 查看已完成的应用程序
- 验证资源使用情况

### 3. 集群健康检查

#### 3.1 进程状态检查
```bash
# 在Master容器内执行
jps
```

预期输出：
```
NameNode
ResourceManager
SecondaryNameNode
JobHistoryServer
Jps
```

```bash
# 在Worker容器内执行（worker1和worker2）
docker exec -it worker1 bash
jps
```

预期输出：
```
DataNode
NodeManager
Jps
```

#### 3.2 日志检查
```bash
# 查看NameNode日志
tail -f $HADOOP_HOME/logs/hadoop-*-namenode-*.log

# 查看ResourceManager日志
tail -f $HADOOP_HOME/logs/yarn-*-resourcemanager-*.log

# 查看DataNode日志（在worker容器中）
tail -f $HADOOP_HOME/logs/hadoop-*-datanode-*.log
```

### 4. 性能基准测试

#### 4.1 HDFS I/O性能测试
```bash
# 测试写性能
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -write -nrFiles 10 -fileSize 100MB

# 测试读性能
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -read -nrFiles 10 -fileSize 100MB

# 清理测试数据
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -clean
```

#### 4.2 MapReduce性能测试
```bash
# TeraSort基准测试
# 生成数据
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar teragen 10000000 /user/root/terasort-input

# 排序
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar terasort /user/root/terasort-input /user/root/terasort-output

# 验证结果
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar teravalidate /user/root/terasort-output /user/root/terasort-validate
```

## 故障排查

### 常见问题及解决方案

#### 1. Web UI无法访问
- **问题**: 端口未映射或防火墙阻止
- **解决**: 检查docker-compose.yml中的端口映射，确保端口未被占用

#### 2. DataNode无法连接NameNode
- **问题**: 网络配置或主机名解析问题
- **解决**: 
  ```bash
  # 检查网络连接
  docker network ls
  docker network inspect hadoop
  
  # 在容器内测试主机名解析
  docker exec -it worker1 ping master
  ```

#### 3. YARN作业提交失败
- **问题**: 资源不足或配置错误
- **解决**: 
  ```bash
  # 检查集群资源
  yarn cluster -metrics
  
  # 检查队列状态
  yarn queue -status default
  ```

#### 4. HDFS空间不足
- **问题**: 磁盘空间不足
- **解决**: 
  ```bash
  # 检查磁盘使用情况
  hdfs dfsadmin -report
  
  # 清理无用文件
  hdfs dfs -rm -r /tmp/*
  ```

### 日志收集
```bash
# 收集所有日志到宿主机
docker logs master > master.log 2>&1
docker logs worker1 > worker1.log 2>&1  
docker logs worker2 > worker2.log 2>&1

# 收集容器内Hadoop日志
docker exec master tar -czf /tmp/hadoop-logs.tar.gz $HADOOP_HOME/logs
docker cp master:/tmp/hadoop-logs.tar.gz ./
```

## 自动化测试脚本

创建自动化测试脚本`test-hadoop-cluster.sh`：

```bash
#!/bin/bash
set -e

echo "=== Hadoop集群功能测试 ==="

# 1. 检查容器状态
echo "1. 检查容器状态..."
docker-compose ps

# 2. 检查HDFS
echo "2. 检查HDFS状态..."
docker exec master hdfs dfsadmin -report

# 3. 检查YARN
echo "3. 检查YARN状态..."
docker exec master yarn node -list

# 4. 运行WordCount测试
echo "4. 运行WordCount测试..."
docker exec master bash -c "
  # 准备测试数据
  echo 'hello world hello hadoop' > /tmp/test.txt
  hdfs dfs -mkdir -p /test
  hdfs dfs -put /tmp/test.txt /test/
  
  # 运行作业
  hadoop jar \$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /test/test.txt /test-output
  
  # 检查结果
  hdfs dfs -cat /test-output/part-r-00000
  
  # 清理
  hdfs dfs -rm -r /test /test-output
"

echo "=== 测试完成 ==="
```

## 测试报告模板

测试完成后，建议生成测试报告，包含以下内容：

1. **测试环境信息**
   - Docker版本
   - Hadoop版本
   - 宿主机配置

2. **测试结果汇总**
   - 各组件状态检查结果
   - 功能测试通过率
   - 性能测试结果

3. **问题记录**
   - 发现的问题及解决方案
   - 性能瓶颈分析
   - 改进建议

4. **截图记录**
   - Web UI界面截图
   - 命令行输出截图
   - 错误信息截图

## 注意事项

1. **资源限制**: 确保宿主机有足够的CPU和内存资源
2. **网络配置**: 防火墙不要阻止Docker容器间的通信
3. **数据持久化**: 测试数据会保存在挂载的卷中，重启后仍然存在
4. **安全考虑**: 生产环境应配置适当的安全策略
5. **版本兼容性**: 确保Docker和Docker Compose版本兼容

通过以上测试步骤，可以全面验证Docker部署的Hadoop集群功能是否正常。建议定期进行这些测试以确保集群稳定运行。