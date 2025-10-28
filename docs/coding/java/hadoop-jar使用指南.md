# Hadoop JAR包使用指南

本文档总结了在hadoop-docker环境中正确编译、打包和运行自定义MapReduce作业JAR包的完整流程，以及常见问题的解决方案。

## 1. 环境准备

### 1.1 目录结构
确保项目文件已同步到WSL目标目录：
```bash
# 同步文件到WSL
wsl.exe cp -r /mnt/d/项目/docker-compose/hadoop/exp1/* /home/docker-compose/hadoop/exp1/

# 同步到Docker容器
wsl -e bash -cl "docker cp /home/docker-compose/hadoop/exp1/ master:/home/exp1/"
```

### 1.2 验证环境
```bash
# 检查容器内文件
wsl -e bash -cl "docker exec master ls -la /home/exp1/"

# 检查HDFS状态
wsl -e bash -cl "docker exec master hdfs dfsadmin -report"
```

## 2. 正确编译流程

### 2.1 完整的Hadoop类路径
编译时必须包含完整的Hadoop依赖库：
```bash
# 正确的编译命令
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && javac -cp '/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/mapreduce/*:/opt/hadoop/share/hadoop/hdfs/*:/opt/hadoop/share/hadoop/yarn/*' *.java\""
```

### 2.2 关键依赖包
- `hadoop-common-*.jar` - 核心功能
- `hadoop-mapreduce-client-core-*.jar` - MapReduce框架
- `hadoop-hdfs-*.jar` - HDFS操作
- `hadoop-yarn-*.jar` - YARN资源管理

## 3. JAR包打包

### 3.1 创建manifest文件
```bash
# 创建manifest.txt
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && echo 'Main-Class: Top10Driver' > manifest.txt\""
```

### 3.2 打包JAR文件
```bash
# 打包所有class文件
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && jar cfm top10.jar manifest.txt *.class\""
```

### 3.3 验证JAR包
```bash
# 检查JAR内容
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && jar tf top10.jar\""

# 测试JAR可执行性
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && java -cp top10.jar Top10Driver\""
```

## 4. 运行MapReduce作业

### 4.1 准备数据
```bash
# 创建HDFS输入目录
wsl -e bash -cl "docker exec master bash -c \"hdfs dfs -mkdir -p /input\""

# 上传测试数据
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && hdfs dfs -put dataset/top10input.txt /input/\""
```

### 4.2 运行作业
```bash
# 使用yarn jar命令（推荐）
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && yarn jar top10.jar Top10Driver /input/top10input.txt /output\""

# 或者使用hadoop jar命令
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && hadoop jar top10.jar Top10Driver /input/top10input.txt /output\""
```

## 5. 常见问题及解决方案

### 5.1 编译错误

#### 问题1：找不到Hadoop类
**错误信息**：`error: package org.apache.hadoop.conf does not exist`

**解决方案**：
- 确保包含完整的类路径
- 检查import语句是否正确

```java
// 正确的import语句
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.WritableComparable; // 关键！
import org.apache.hadoop.mapreduce.Job;
```

#### 问题2：@Override注解错误
**错误信息**：`method does not override or implement a method from a supertype`

**解决方案**：
- 确保实现了正确的接口
- 检查WritableComparable接口的import

```java
// 正确的类声明
public class StudentScore implements WritableComparable<StudentScore> {
    // 必须实现的方法
    @Override
    public void write(DataOutput out) throws IOException { ... }
    
    @Override
    public void readFields(DataInput in) throws IOException { ... }
    
    @Override
    public int compareTo(StudentScore other) { ... }
}
```

### 5.2 运行时错误

#### 问题3：ClassNotFoundException
**错误信息**：`java.lang.ClassNotFoundException: com.ctc.wstx.io.InputBootstrapper`

**解决方案**：
- 使用Hadoop提供的完整类路径
- 不要手动拼接类路径，使用`hadoop classpath`命令

```bash
# 获取完整类路径
wsl -e bash -cl "docker exec master hadoop classpath"

# 使用完整类路径运行
wsl -e bash -cl "docker exec master bash -c \"cd /home/exp1 && CLASSPATH=\$(hadoop classpath):top10.jar java Top10Driver /input/top10input.txt /output\""
```

#### 问题4：参数传递错误
**错误信息**：`Usage: Top10Driver <input path> <output path>`

**解决方案**：
- 确保参数正确传递给main方法
- 使用正确的Hadoop命令语法

## 6. 最佳实践

### 6.1 代码规范
1. **完整的import语句**：确保所有Hadoop相关类都有正确的import
2. **接口实现**：正确实现WritableComparable接口的所有方法
3. **错误处理**：在main方法中添加参数验证

### 6.2 编译打包
1. **类路径管理**：使用完整的Hadoop类路径
2. **manifest配置**：正确设置Main-Class
3. **依赖检查**：确保所有依赖包都在类路径中

### 6.3 运行测试
1. **环境验证**：运行前检查HDFS和YARN状态
2. **数据准备**：确保输入数据已正确上传
3. **输出清理**：运行前清理旧的输出目录

## 7. 调试技巧

### 7.1 日志查看
```bash
# 查看容器日志
wsl -e bash -cl "docker logs master"

# 查看YARN应用日志
wsl -e bash -cl "docker exec master yarn logs -applicationId <app_id>"
```

### 7.2 环境检查
```bash
# 检查Java版本
wsl -e bash -cl "docker exec master java -version"

# 检查Hadoop版本
wsl -e bash -cl "docker exec master hadoop version"

# 检查类路径
wsl -e bash -cl "docker exec master hadoop classpath"
```

## 8. 总结

通过遵循上述流程和最佳实践，可以确保在hadoop-docker环境中成功编译、打包和运行自定义MapReduce作业。关键点包括：

1. **完整的类路径配置**
2. **正确的接口实现**
3. **规范的JAR打包**
4. **适当的运行命令**

遵循这些指导原则可以避免大多数常见的编译和运行时错误。