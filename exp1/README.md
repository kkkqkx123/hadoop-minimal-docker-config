# 学生成绩Top10排序程序

基于Hadoop 3.3.6的MapReduce程序，实现学生成绩Top10排序功能。

## 功能要求

1. 输入格式：学号,语文成绩,数学成绩,英语成绩（均为数字）
2. 计算每个学生的总分，按总分从高到低排序
3. 总分相同则按数学成绩从高到低排序
4. 输出格式：学号 语文：X.0, 数学：Y.0, 英语：Z.0, 总分：W.0
5. 最终取前10名

## 程序结构

- `StudentScore.java` - 自定义WritableComparable类，实现排序逻辑
- `Top10Mapper.java` - Mapper类，解析输入数据并计算总分
- `Top10Reducer.java` - Reducer类，筛选Top10学生成绩
- `Top10Driver.java` - 主类，配置和运行MapReduce作业
- `SimpleTest.java` - 简单的本地测试程序

## 测试数据

- `test_data1.txt` - 高分段学生成绩测试数据
- `test_data2.txt` - 中分段学生成绩测试数据  
- `test_data3.txt` - 超高分段学生成绩测试数据
- `expected_output1.txt` - 测试数据1的预期输出
- `dataset/top10input.txt` - 原始数据集

## 运行步骤

### 1. 启动Hadoop集群

```bash
cd d:\项目\docker-compose\hadoop
docker-compose up -d
```

### 2. 将程序复制到容器中

```bash
docker cp exp1 hadoop-master:/opt/hadoop/exp1
```

### 3. 进入容器并运行测试

```bash
docker exec -it hadoop-master bash
cd /opt/hadoop/exp1

# 编译程序（如果需要在容器内重新编译）
javac -cp $(hadoop classpath) -d . *.java
jar cf top10.jar *.class

# 运行测试
./run_docker_test.sh
```

### 4. 或者使用本地简单测试

```bash
# 在Windows环境中运行简单测试
javac SimpleTest.java
java -cp . SimpleTest
```

## 排序逻辑验证

程序使用自定义的`StudentScore`类实现排序逻辑：

1. **主要排序**：总分从高到低（降序）
2. **次要排序**：总分相同时，数学成绩从高到低（降序）

## 输出示例

```
1004 语文：92.0, 数学：95.0, 英语：88.0, 总分：275.0
1006 语文：95.0, 数学：85.0, 英语：90.0, 总分：270.0
1002 语文：90.0, 数学：88.0, 英语：95.0, 总分：273.0
...
```

## 注意事项

- 程序需要在Hadoop Docker环境中运行
- 确保Hadoop集群正常运行
- 输入数据格式必须正确，每行包含学号和三个成绩
- 程序会自动跳过格式错误的行并继续处理