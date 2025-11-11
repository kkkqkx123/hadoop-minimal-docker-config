# 天气数据分析MapReduce任务指南

## 概述

本文档详细记录了在Hadoop Docker环境中成功执行天气数据分析MapReduce任务的完整流程，包括环境准备、代码编译、任务执行和结果验证。

## 任务描述

**任务2**：分析天气数据，找出每个月的最高温度。

**输入数据**：`exp2/weather.txt` - 包含2015年全年的天气数据，格式为：`日期 时间 温度`

**输出结果**：每个月的最高温度及其对应的日期时间。

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
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker cp exp2 master:/home/"

# 验证同步结果
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master ls -la /home/exp2/"
```

## 代码编译

### 关键文件说明

1. **WeatherData.java** - 自定义WritableComparable类，存储天气数据
2. **WeatherMapper.java** - Mapper类，解析天气数据并提取月份
3. **WeatherReducer.java** - Reducer类，找出每个月的最高温度
4. **WeatherDriver.java** - 主类，配置和运行MapReduce作业

### 3. 在容器内编译Java代码
```bash
# 使用硬编码的Hadoop类路径编译（推荐）
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp2 && javac -cp /opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/yarn:/opt/hadoop/share/hadoop/yarn/lib/*:/opt/hadoop/share/hadoop/yarn/* -d . *.java'"
```

### 4. 创建JAR包
```bash
# 在容器内创建JAR文件
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp2 && jar cf weather-analysis.jar *.class'"
```

## HDFS数据准备

### 5. 创建HDFS输入目录
```bash
# 创建输入目录
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -mkdir -p /input"
```

### 6. 上传天气数据
```bash
# 上传数据文件到HDFS
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp2 && hdfs dfs -put weather.txt /input/'"
```

### 7. 清理输出目录（可选）
```bash
# 删除已存在的输出目录
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -test -d /output/weather && docker exec master hdfs dfs -rm -r /output/weather || echo 'Output directory does not exist'"
```

## MapReduce任务执行

### 8. 执行天气分析任务
```bash
# 使用hadoop jar命令执行任务，并重定向日志
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp2 && hadoop jar weather-analysis.jar WeatherDriver /input/weather.txt /output/weather' > /mnt/d/项目/docker-compose/hadoop/result/weather_analysis_result.log 2>&1"
```

**关键参数说明**：
- `hadoop jar`：Hadoop专用命令，自动处理类路径
- `weather-analysis.jar`：包含MapReduce程序的JAR文件
- `WeatherDriver`：主类名
- `/input/weather.txt`：HDFS输入路径
- `/output/weather`：HDFS输出路径

## 结果验证

### 9. 检查任务执行状态
查看日志文件确认任务执行成功：
```bash
# 查看执行日志
cat /mnt/d/项目/docker-compose/hadoop/result/weather_analysis_result.log
```

**成功标志**：
- `Job job_xxxxxxxxxxxx_xxxx completed successfully`
- `map 100% reduce 100%`
- 完整的计数器信息

### 10. 查看HDFS输出结果
```bash
# 查看MapReduce输出结果
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -cat /output/weather/part-r-*"
```

## 预期输出格式

```
2015-01: 最高温度: 13.2c (日期: 2015-01-22 20:49:58)
2015-02: 最高温度: 11.3c (日期: 2015-02-13 12:32:56)
2015-03: 最高温度: 19.8c (日期: 2015-03-14 07:17:32)
2015-04: 最高温度: 22.7c (日期: 2015-04-29 05:57:34)
2015-05: 最高温度: 29.8c (日期: 2015-05-28 19:14:40)
2015-06: 最高温度: 34.1c (日期: 2015-06-27 22:30:30)
2015-07: 最高温度: 32.9c (日期: 2015-07-06 22:04:35)
```

## 常见问题与解决方案

### 问题1：类路径错误
**症状**：`NoClassDefFoundError: org/apache/hadoop/conf/Configuration`
**解决方案**：在容器内使用正确的Hadoop类路径重新编译

### 问题2：日期解析错误
**症状**：`ParseException`或日期格式错误
**解决方案**：检查输入数据格式是否为`yyyy-MM-dd HH:mm:ss	X.Xc`

### 问题3：温度解析错误
**症状**：`NumberFormatException`解析温度时
**解决方案**：确保温度值格式正确，包含'c'后缀

### 问题4：文件已存在
**症状**：`File exists`错误
**解决方案**：删除已存在的文件或目录

## 使用脚本自动化执行

### 快速执行脚本
```bash
# 使用提供的脚本快速执行
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp2 && chmod +x run_weather_analysis.sh && ./run_weather_analysis.sh /output/weather$(date +%Y%m%d%H%M%S)'"
```

### Windows PowerShell脚本
```powershell
# 使用PowerShell脚本执行
.\run_weather_analysis.ps1 /output/weather$(Get-Date -Format "yyyyMMddHHmmss")
```

## 最佳实践

1. **编译环境**：始终在Hadoop容器内编译Java代码
2. **类路径**：使用硬编码的Hadoop类路径避免转义问题
3. **日志管理**：重定向输出到日志文件便于调试
4. **数据验证**：执行前后检查HDFS数据状态
5. **错误处理**：逐步执行并验证每个步骤
6. **时间戳输出**：使用不同的时间戳避免输出目录冲突

## 总结

通过以上步骤，可以在Hadoop Docker环境中成功执行天气数据分析MapReduce任务。关键是要确保：

1. 在正确的环境中编译代码
2. 使用正确的类路径配置
3. 理解天气数据的格式和解析逻辑
4. 妥善处理日期时间解析
5. 逐步验证每个执行步骤

这个流程可以应用于其他时间序列数据分析任务，只需调整相应的数据解析逻辑即可。