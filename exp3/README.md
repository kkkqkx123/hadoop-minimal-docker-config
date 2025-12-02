# PageRank MapReduce实现

本目录包含使用Hadoop MapReduce实现的PageRank算法。

## 文件说明

### 核心Java文件
- **PageRankNode.java**: 自定义数据类型，用于存储页面节点信息（页面ID、PageRank值、出链列表）
- **PageRankMapper.java**: Mapper类，处理输入数据并输出页面节点信息和贡献值
- **PageRankReducer.java**: Reducer类，聚合贡献值并计算新的PageRank值
- **PageRankDriver.java**: 主驱动类，配置和运行PageRank迭代计算

### 脚本文件
- **compile.sh**: 编译Java程序并创建JAR包
- **run_pagerank.sh**: 在Hadoop环境中运行PageRank计算
- **prepare_data.sh**: 准备输入数据（将wiki-vertices.txt转换为PageRank格式）
- **prepare_test_data.sh**: 准备测试数据

### 数据文件
- **dataset/wiki-vertices.txt**: Wikipedia页面顶点数据
- **dataset/test_vertices.txt**: 测试用的页面顶点数据
- **dataset/test_edges.txt**: 测试用的页面边数据

## 使用方法

### 1. 编译程序
```bash
cd exp3
bash compile.sh
```

### 2. 准备数据
#### 使用真实数据（wiki-vertices.txt）
```bash
bash prepare_data.sh
```

#### 使用测试数据
```bash
bash prepare_test_data.sh
```

### 3. 运行PageRank计算
#### 使用真实数据
```bash
bash run_pagerank.sh processed/pagerank_input.txt /output/pagerank 10
```

#### 使用测试数据
```bash
bash run_pagerank.sh processed/test_pagerank_input.txt /output/pagerank_test 5
```

### 4. 查看结果
```bash
# 查看所有迭代的结果
docker-compose exec master hdfs dfs -cat /output/pagerank/iteration*/part-r-*

# 查看最后一次迭代的结果
docker-compose exec master hdfs dfs -cat /output/pagerank/iteration*/part-r-* | tail -20
```

## PageRank算法说明

### 核心公式
PR(A) = (1 - d) + d * Σ(PR(Ti)/C(Ti))

其中：
- PR(A): 页面A的PageRank值
- d: 阻尼系数（本实现中使用0.85）
- PR(Ti): 链接到页面A的页面Ti的PageRank值
- C(Ti): 页面Ti的出链数量

### 实现特点
1. **初始值**: 所有页面的初始PageRank值设为1.0
2. **收敛条件**: 当所有页面的PageRank值变化小于0.001时认为收敛
3. **迭代计算**: 支持最大迭代次数限制，防止无限循环
4. **阻尼系数**: 使用0.85的阻尼系数修正公式

### 数据格式

#### 输入格式
```
页面ID\tPageRank值\t出链列表（逗号分隔）
```

示例：
```
1\t1.0\t2,3
2\t1.0\t3
3\t1.0\t1
4\t1.0\t1,2
```

#### 输出格式
```
页面ID\t计算后的PageRank值\t出链列表（逗号分隔）
```

## 注意事项

1. 确保Hadoop集群已启动：
   ```bash
   docker-compose up -d
   ```

2. 程序会自动创建必要的HDFS目录

3. 如果输出目录已存在，程序会先删除旧的输出目录

4. 可以通过修改PageRankDriver.java中的参数调整收敛阈值和最大迭代次数

## 故障排除

### 常见问题
1. **ClassNotFoundException**: 确保已正确编译并创建JAR包
2. **Input path does not exist**: 检查输入文件路径是否正确
3. **Output directory already exists**: 程序会自动清理旧输出，如失败可手动删除

### 调试方法
1. 查看Hadoop日志：
   ```bash
   docker-compose exec master yarn logs -applicationId <application_id>
   ```

2. 检查HDFS文件：
   ```bash
   docker-compose exec master hdfs dfs -ls /output/pagerank/
   ```

3. 查看作业状态：
   - YARN Web UI: http://localhost:8088
   - JobHistory Web UI: http://localhost:19888