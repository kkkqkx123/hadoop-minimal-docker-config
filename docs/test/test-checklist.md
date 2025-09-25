# Hadoop集群测试清单

这是一个简洁的测试清单，帮助您系统地验证Docker部署的Hadoop集群功能。

## 🔍 环境检查

### 容器状态
- [ ] 所有容器正常运行
  ```bash
  docker-compose ps
  ```
  - [ ] master状态为`Up`
  - [ ] worker1状态为`Up`
  - [ ] worker2状态为`Up`

### 资源检查
- [ ] 宿主机资源充足
  ```bash
  docker stats
  ```
  - [ ] 内存使用率 < 80%
  - [ ] CPU使用率 < 90%

## 🌐 Web UI访问测试

### NameNode Web UI
- [ ] 访问 http://localhost:9870
  - [ ] 页面正常加载
  - [ ] 显示集群概览信息
  - [ ] DataNode数量为2

### ResourceManager Web UI  
- [ ] 访问 http://localhost:8088
  - [ ] 页面正常加载
  - [ ] 显示集群节点信息
  - [ ] NodeManager数量为2

### DataNode Web UI
- [ ] 访问 http://localhost:9864 (worker1)
- [ ] 访问 http://localhost:9865 (worker2)
  - [ ] 页面正常加载
  - [ ] 显示DataNode状态

### NodeManager Web UI
- [ ] 访问 http://localhost:8042 (worker1)
- [ ] 访问 http://localhost:8043 (worker2)
  - [ ] 页面正常加载
  - [ ] 显示节点资源信息

## 📁 HDFS功能测试

### 基本命令测试
- [ ] 进入master容器
  ```bash
  docker exec -it master bash
  ```

- [ ] 检查HDFS状态
  ```bash
  hdfs dfsadmin -report
  ```
  - [ ] 显示2个Live DataNode
  - [ ] 显示磁盘容量信息

- [ ] 创建目录
  ```bash
  hdfs dfs -mkdir /test-dir
  ```

- [ ] 上传文件
  ```bash
  echo "test content" > /tmp/test.txt
  hdfs dfs -put /tmp/test.txt /test-dir/
  ```

- [ ] 读取文件
  ```bash
  hdfs dfs -cat /test-dir/test.txt
  ```

- [ ] 删除文件和目录
  ```bash
  hdfs dfs -rm /test-dir/test.txt
  hdfs dfs -rmdir /test-dir
  ```

## ⚙️ YARN功能测试

### 集群状态检查
- [ ] 检查节点状态
  ```bash
  yarn node -list
  ```
  - [ ] 显示2个NodeManager
  - [ ] 所有节点状态为`RUNNING`

- [ ] 检查集群资源
  ```bash
  yarn cluster -metrics
  ```

### 作业提交测试
- [ ] 准备测试数据
  ```bash
  echo "hello world hello hadoop" > /tmp/input.txt
  hdfs dfs -mkdir -p /test-input
  hdfs dfs -put /tmp/input.txt /test-input/
  ```

- [ ] 运行WordCount作业
  ```bash
  hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /test-input /test-output
  ```

- [ ] 验证输出结果
  ```bash
  hdfs dfs -cat /test-output/part-r-00000
  ```
  - [ ] 显示正确的词频统计结果

- [ ] 清理测试数据
  ```bash
  hdfs dfs -rm -r /test-input /test-output
  ```

## 🔧 进程检查

### Master节点进程
- [ ] 检查Java进程
  ```bash
  jps
  ```
  - [ ] NameNode
  - [ ] ResourceManager
  - [ ] SecondaryNameNode
  - [ ] JobHistoryServer

### Worker节点进程
- [ ] 检查worker1进程
  ```bash
  docker exec -it worker1 jps
  ```
  - [ ] DataNode
  - [ ] NodeManager

- [ ] 检查worker2进程
  ```bash
  docker exec -it worker2 jps
  ```
  - [ ] DataNode
  - [ ] NodeManager

## 📝 日志检查

### 检查关键日志
- [ ] NameNode日志
  ```bash
  docker exec master tail -n 50 $HADOOP_HOME/logs/hadoop-*-namenode-*.log
  ```
  - [ ] 无严重错误信息

- [ ] ResourceManager日志
  ```bash
  docker exec master tail -n 50 $HADOOP_HOME/logs/yarn-*-resourcemanager-*.log
  ```
  - [ ] 无严重错误信息

- [ ] DataNode日志（worker1）
  ```bash
  docker exec worker1 tail -n 50 $HADOOP_HOME/logs/hadoop-*-datanode-*.log
  ```
  - [ ] 无严重错误信息

## 🚀 高级测试（可选）

### 性能测试
- [ ] HDFS I/O性能测试
  ```bash
  hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-*.jar TestDFSIO -write -nrFiles 5 -fileSize 50MB
  ```

- [ ] TeraSort测试
  ```bash
  hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar teragen 100000 /terasort-input
  hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar terasort /terasort-input /terasort-output
  ```

### 容错测试
- [ ] 停止一个worker节点
  ```bash
  docker stop worker1
  ```
- [ ] 验证集群仍能正常工作
- [ ] 重新启动worker节点
  ```bash
  docker start worker1
  ```

## ✅ 测试完成确认

### 基础功能确认
- [ ] 所有容器正常运行
- [ ] Web UI全部可访问
- [ ] HDFS文件操作正常
- [ ] YARN作业执行成功
- [ ] 所有Java进程正常

### 清理工作
- [ ] 删除测试文件
  ```bash
  hdfs dfs -rm -r /test* /terasort* 2>/dev/null
  ```

- [ ] 清理本地临时文件
  ```bash
  rm -f /tmp/test.txt /tmp/input.txt
  ```

## 📊 测试结果记录

### 测试环境
- 测试日期: ___________
- 测试人员: ___________
- Docker版本: ___________
- Hadoop版本: ___________

### 测试结果
- 基础功能测试: ✅通过 / ❌失败
- Web UI测试: ✅通过 / ❌失败  
- HDFS测试: ✅通过 / ❌失败
- YARN测试: ✅通过 / ❌失败
- 进程检查: ✅通过 / ❌失败

### 问题记录
1. _________________________________
2. _________________________________
3. _________________________________

### 备注
_________________________________

---

## 🆘 故障快速排查

如果测试失败，请按以下顺序排查：

1. **检查容器状态**
   ```bash
   docker-compose ps
   docker-compose logs
   ```

2. **检查网络连接**
   ```bash
   docker exec master ping worker1
   docker exec master ping worker2
   ```

3. **检查资源使用**
   ```bash
   docker stats
   free -h
   ```

4. **检查配置文件**
   ```bash
   docker exec master cat $HADOOP_HOME/etc/hadoop/core-site.xml
   ```

5. **查看详细日志**
   ```bash
   docker exec master tail -f $HADOOP_HOME/logs/*.log
   ```

完成所有测试项目后，您的Docker Hadoop集群应该能够正常运行。如果所有测试都通过，恭喜您成功部署了一个功能完整的Hadoop集群！