# 在Hadoop-Docker上执行自定义代码指南

## 🎯 概述

本指南说明如何在当前Hadoop-Docker环境中执行自定义的MapReduce代码，包括Java程序、Python脚本以及其他类型的作业。

## 📋 前置条件

确保Hadoop集群已正常运行：
```bash
# 检查所有服务状态
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master jps"
```

应该看到以下进程：
- NameNode
- ResourceManager
- SecondaryNameNode
- JobHistoryServer

## 🚀 执行自定义Java MapReduce程序

### 1. 开发环境准备

#### 在本地开发
在Windows上创建Java项目，添加Hadoop依赖：

```xml
<!-- pom.xml 依赖配置 -->
<dependencies>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-client</artifactId>
        <version>3.3.6</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-common</artifactId>
        <version>3.3.6</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-mapreduce-client-core</artifactId>
        <version>3.3.6</version>
    </dependency>
</dependencies>
```

#### 示例WordCount程序

```java
package com.example;

import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCount {
    
    public static class TokenizerMapper extends Mapper<Object, Text, Text, IntWritable> {
        private final static IntWritable one = new IntWritable(1);
        private Text word = new Text();

        public void map(Object key, Text value, Context context) 
                throws IOException, InterruptedException {
            StringTokenizer itr = new StringTokenizer(value.toString());
            while (itr.hasMoreTokens()) {
                word.set(itr.nextToken());
                context.write(word, one);
            }
        }
    }

    public static class IntSumReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
        private IntWritable result = new IntWritable();

        public void reduce(Text key, Iterable<IntWritable> values, Context context)
                throws IOException, InterruptedException {
            int sum = 0;
            for (IntWritable val : values) {
                sum += val.get();
            }
            result.set(sum);
            context.write(key, result);
        }
    }

    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "word count");
        
        job.setJarByClass(WordCount.class);
        job.setMapperClass(TokenizerMapper.class);
        job.setCombinerClass(IntSumReducer.class);
        job.setReducerClass(IntSumReducer.class);
        
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
```

### 2. 在容器中执行

#### 方法1：将代码复制到容器

```bash
# 将JAR文件复制到master容器
wsl -e bash -cl "docker cp /mnt/d/your-project/target/wordcount.jar hadoop-master:/tmp/"

# 在容器中执行
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master hadoop jar /tmp/wordcount.jar com.example.WordCount /input /output"
```

#### 方法2：使用挂载目录

将代码放在挂载目录中：

```bash
# 创建测试数据
echo "Hello World Hello Hadoop" > test.txt
echo "Hadoop MapReduce Example" >> test.txt

# 上传到HDFS
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master hdfs dfs -mkdir -p /input"
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master hdfs dfs -put test.txt /input/"

# 执行WordCount
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input /output"

# 查看结果
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master hdfs dfs -cat /output/part-r-*"
```

## 🐍 执行Python MapReduce程序

### 使用Hadoop Streaming

#### 示例Mapper (mapper.py)

```python
#!/usr/bin/env python3
import sys
import re

# 读取标准输入
for line in sys.stdin:
    # 移除非字母字符并转换为小写
    line = re.sub(r'[^a-zA-Z\s]', '', line.lower())
    # 分割单词
    words = line.split()
    
    for word in words:
        if word:  # 确保单词不为空
            print(f"{word}\t1")
```

#### 示例Reducer (reducer.py)

```python
#!/usr/bin/env python3
import sys

current_word = None
current_count = 0

for line in sys.stdin:
    line = line.strip()
    word, count = line.split('\t', 1)
    
    try:
        count = int(count)
    except ValueError:
        continue
    
    if current_word == word:
        current_count += count
    else:
        if current_word:
            print(f"{current_word}\t{current_count}")
        current_word = word
        current_count = count

# 输出最后一个单词
if current_word == word:
    print(f"{current_word}\t{current_count}")
```

#### 执行Python MapReduce

```bash
# 上传Python脚本到HDFS
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master hdfs dfs -mkdir -p /scripts"
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker cp mapper.py hadoop-master:/tmp/"
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker cp reducer.py hadoop-master:/tmp/"

# 确保脚本有执行权限
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master chmod +x /tmp/mapper.py /tmp/reducer.py"

# 使用Hadoop Streaming执行
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \
  -files /tmp/mapper.py,/tmp/reducer.py \
  -mapper 'python3 /tmp/mapper.py' \
  -reducer 'python3 /tmp/reducer.py' \
  -input /input \
  -output /python-output"

# 查看结果
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master hdfs dfs -cat /python-output/part-*"
```

## 📊 资源调优建议

### 内存配置

当前集群配置（适合学习环境）：
- Map Task内存: 512MB
- Reduce Task内存: 512MB
- Application Master内存: 768MB

### 并发度设置

```xml
<!-- 在mapred-site.xml中 -->
<property>
  <name>mapreduce.job.maps</name>
  <value>2</value>  <!-- 小集群使用较少的map任务 -->
</property>

<property>
  <name>mapreduce.job.reduces</name>
  <value>1</value>  <!-- 小集群使用较少的reduce任务 -->
</property>
```

## 🔍 调试技巧

### 查看作业日志

```bash
# 查看ResourceManager日志
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose logs master | grep -i resourcemanager"

# 查看具体作业的日志
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master yarn logs -applicationId application_xxx"

# 查看NodeManager日志
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose logs worker1 | grep -i nodemanager"
```

### 常见问题排查

1. **连接拒绝错误**: 检查ResourceManager是否运行
2. **内存不足**: 调整mapreduce任务内存配置
3. **权限问题**: 确保HDFS目录权限正确
4. **类找不到**: 检查JAR包是否正确上传

## 📈 性能监控

### 使用YARN Web UI

访问 ResourceManager Web UI:
```
http://localhost:8088
```

### 使用JobHistory Web UI

访问 JobHistory Server:
```
http://localhost:19888
```

### 命令行监控

```bash
# 查看集群节点状态
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master yarn node -list"

# 查看运行中的应用
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master yarn application -list"

# 查看应用状态
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker-compose exec master yarn application -status application_id"
```

## 🚀 高级用法

### 自定义分区器

```java
public class CustomPartitioner extends Partitioner<Text, IntWritable> {
    @Override
    public int getPartition(Text key, IntWritable value, int numPartitions) {
        // 自定义分区逻辑
        return (key.hashCode() & Integer.MAX_VALUE) % numPartitions;
    }
}
```

### 自定义比较器

```java
public class CustomComparator extends WritableComparator {
    protected CustomComparator() {
        super(Text.class, true);
    }
    
    @Override
    public int compare(WritableComparable w1, WritableComparable w2) {
        Text t1 = (Text) w1;
        Text t2 = (Text) w2;
        // 自定义比较逻辑
        return t1.toString().compareTo(t2.toString());
    }
}
```

## 📚 参考资源

- [Hadoop官方文档](https://hadoop.apache.org/docs/)
- [MapReduce教程](https://hadoop.apache.org/docs/stable/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html)
- [Hadoop Streaming文档](https://hadoop.apache.org/docs/stable/hadoop-streaming/HadoopStreaming.html)

## 💡 最佳实践

1. **小文件处理**: 使用CombineFileInputFormat处理大量小文件
2. **内存调优**: 根据数据量调整map/reduce内存配置
3. **错误处理**: 添加适当的异常处理和日志记录
4. **测试**: 先在小数据集上测试，再处理大数据
5. **监控**: 使用Web UI和日志监控作业执行情况