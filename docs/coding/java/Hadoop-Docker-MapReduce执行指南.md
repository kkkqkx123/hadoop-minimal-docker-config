# Hadoop Docker MapReduce 任务执行指南

## 概述

本文档详细记录了在Hadoop Docker环境中成功执行MapReduce任务的完整流程，包括环境准备、代码编译、任务执行和结果验证。

## 环境准备

### 1. 检查Hadoop集群状态
```bash
# 检查容器运行状态
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose ps"

# 检查HDFS集群状态
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfsadmin -report"
```

### 2. 同步代码到容器
```bash
# 将本地代码目录同步到容器中
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker cp exp1 master:/home/"

# 验证同步结果
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master ls -la /home/exp1/"
```

## 代码编译

### 关键问题：Hadoop依赖库

**常见错误**：`NoClassDefFoundError: org/apache/hadoop/conf/Configuration`

**解决方案**：必须在容器内使用正确的Hadoop类路径进行编译

### 3. 在容器内重新编译Java代码
```bash
# 使用硬编码的Hadoop类路径编译（推荐）
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp1 && javac -cp /opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/* -d . *.java'"
```

**注意**：避免使用变量替换的复杂转义，直接使用硬编码路径更可靠。

### 4. 创建JAR包
```bash
# 在容器内创建JAR文件
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp1 && jar cf top10.jar *.class'"
```

## HDFS数据准备

### 5. 创建HDFS输入目录
```bash
# 创建输入目录
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -mkdir -p /input"
```

### 6. 上传测试数据
```bash
# 上传数据文件到HDFS
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp1 && hdfs dfs -put dataset/top10input.txt /input/'"
```

### 7. 清理输出目录（可选）
```bash
# 删除已存在的输出目录
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -test -d /output && docker exec master hdfs dfs -rm -r /output || echo 'Output directory does not exist'"
```

## MapReduce任务执行

### 8. 执行MapReduce任务
```bash
# 使用hadoop jar命令执行任务，并重定向日志
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp1 && hadoop jar top10.jar Top10Driver /input/top10input.txt /output' > /mnt/d/项目/docker-compose/hadoop/result/top10_sort_result4.log 2>&1"
```

**关键参数说明**：
- `hadoop jar`：Hadoop专用命令，自动处理类路径
- `top10.jar`：包含MapReduce程序的JAR文件
- `Top10Driver`：主类名
- `/input/top10input.txt`：HDFS输入路径
- `/output`：HDFS输出路径

## 结果验证

### 9. 检查任务执行状态
查看日志文件确认任务执行成功：
```bash
# 查看执行日志
cat /mnt/d/项目/docker-compose/hadoop/result/top10_sort_result4.log
```

**成功标志**：
- `Job job_xxxxxxxxxxxx_xxxx completed successfully`
- `map 100% reduce 100%`
- 完整的计数器信息

### 10. 查看HDFS输出结果
```bash
# 查看MapReduce输出结果
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -cat /output/part-r-00000"
```

## 常见问题与解决方案

### 问题1：类路径错误
**症状**：`NoClassDefFoundError: org/apache/hadoop/conf/Configuration`
**解决方案**：在容器内使用正确的Hadoop类路径重新编译

### 问题2：命令转义错误
**症状**：命令执行失败，提示语法错误
**解决方案**：使用硬编码路径避免复杂的转义问题

### 问题3：文件已存在
**症状**：`File exists`错误
**解决方案**：删除已存在的文件或目录

### 问题4：Hadoop命令不可用
**症状**：`hadoop: command not found`
**解决方案**：确保在Hadoop容器内执行命令

## 最佳实践

1. **编译环境**：始终在Hadoop容器内编译Java代码
2. **类路径**：使用硬编码的Hadoop类路径避免转义问题
3. **日志管理**：重定向输出到日志文件便于调试
4. **数据验证**：执行前后检查HDFS数据状态
5. **错误处理**：逐步执行并验证每个步骤

## 执行结果示例

### 成功执行统计
- **输入记录**：21条学生成绩数据
- **输出记录**：10条（Top10排序结果）
- **处理数据量**：输入480字节，输出730字节
- **执行时间**：约40秒完成

### 输出格式
```
75910133277 语文：86.0, 数学：96.0, 英语：92.0, 总分：274.0
85959002129 语文：93.0, 数学：90.0, 英语：91.0, 总分：274.0
28390173782 语文：96.0, 数学：84.0, 英语：94.0, 总分：274.0
...
```

## 总结

通过以上步骤，可以在Hadoop Docker环境中成功执行MapReduce任务。关键是要确保：

1. 在正确的环境中编译代码
2. 使用正确的类路径配置
3. 逐步验证每个执行步骤
4. 妥善处理错误和异常情况

这个流程可以应用于其他MapReduce任务的执行，只需替换相应的JAR文件、主类和数据路径即可。