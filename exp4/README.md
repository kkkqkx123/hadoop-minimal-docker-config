# PySpark RDD 实验项目

本项目实现了三个基于PySpark RDD的电商数据分析任务，用于深入了解Spark中数据抽象RDD的使用。

## 项目结构

```
exp4/
├── code1/                          # 任务1代码
│   ├── 设计文档.md                 # 任务1设计文档
│   └── task1_conversion_rate.py    # 用户点击到购买转化率计算
├── code2/                          # 任务2代码
│   ├── 设计文档.md                 # 任务2设计文档
│   └── task2_cart_to_buy_rate.py   # 用户加购后购买率统计
├── code3/                          # 任务3代码
│   ├── 设计文档.md                 # 任务3设计文档
│   └── task3_high_click_low_cart.py  # 高曝光低加购商品识别
├── generate_test_data.py           # 测试数据生成脚本
├── run_all_tasks.py               # 批量执行所有任务
└── README.md                      # 本文件
```

## 任务概述

### 任务1：用户点击到购买转化率
计算每个用户"从点击到购买"的转化率，仅考虑同商品的情况。
- **输入**：用户行为数据 (user_id, item_id, behavior, timestamp)
- **输出**：(user_id, conversion_rate)
- **说明**：转化率 = 有"点击→购买"路径的商品数 / 点击过的商品总数

### 任务2：用户加购后购买率
统计每个用户的"加购后购买率"，即加入购物车的商品中最终完成购买的比例。
- **输入**：用户行为数据 (user_id, item_id, behavior, timestamp)
- **输出**：(user_id, cart_to_buy_rate)
- **说明**：加购后购买率 = 有"加购→购买"路径的商品数 / 加购过的商品总数

### 任务3：高曝光低加购商品识别
找出被大量用户点击但极少被加入购物车的商品。
- **输入**：用户行为数据 (user_id, item_id, behavior, timestamp)
- **输出**：(item_id, click_count, cart_count, cart_conversion_rate)
- **筛选条件**：点击次数 ≥ 10 且 加购转化率 ≤ 20%

## 环境要求

- Python 3.6+
- PySpark
- Hadoop（可选，用于分布式运行）

## 快速开始

### 1. 使用默认数据集
项目默认使用 `data/user_behavior_logs.csv` 作为数据源，无需额外准备。

### 2. 运行单个任务

```bash
# 任务1：用户点击到购买转化率
cd code1
python task1_conversion_rate.py

# 任务2：用户加购后购买率
cd code2
python task2_cart_to_buy_rate.py

# 任务3：高曝光低加购商品识别
cd code3
python task3_high_click_low_cart.py
```

也可以指定自定义的数据路径：
```bash
python task1_conversion_rate.py 数据路径 输出路径
```

### 3. 批量运行所有任务

```bash
python run_all_tasks.py test_data.txt
```

## 数据格式说明

### 输入数据格式
CSV格式：
```csv
user_id,item_id,behavior,timestamp
```

- `user_id`：用户ID（整数）
- `item_id`：商品ID（整数）
- `behavior`：行为类型（"click", "cart", "buy"）
- `timestamp`：时间戳（毫秒级整数）

默认数据集路径：`data/user_behavior_logs.csv`

### 输出数据格式

#### 任务1输出
```
(user_id, conversion_rate)
```
conversion_rate保留2位小数，无点击行为的用户为0.0

#### 任务2输出
```
(user_id, cart_to_buy_rate)
```
cart_to_buy_rate保留2位小数，无加购行为的用户为0.0

#### 任务3输出
```
(item_id, click_count, cart_count, cart_conversion_rate)
```
cart_conversion_rate保留2位小数，按转化率升序排列

## 实现细节

### 使用的RDD算子
- `filter()`：筛选特定行为的数据
- `map()`：数据格式转换
- `reduceByKey()`：按键聚合统计
- `join()`：连接相关数据
- `leftOuterJoin()`/`fullOuterJoin()`：外连接确保数据完整性
- `sortBy()`：结果排序
- `groupByKey()`：按键分组

### 核心算法
1. **转化率计算**：使用连接操作找出满足时间顺序的行为序列
2. **购买率统计**：分别统计加购和购买行为，然后计算转化率
3. **商品筛选**：先聚合统计指标，再应用业务筛选条件

## 结果分析

运行完成后，可以在输出目录中查看结果：

```bash
# 查看任务1结果
cat output_task1/part-*

# 查看任务2结果
cat output_task2/part-*

# 查看任务3结果
cat output_task3/part-*
```

## 注意事项

1. 输出目录会在运行前自动清空，请确保不要覆盖重要数据
2. 每个任务的输出是一个目录，包含多个part-*文件
3. 运行批量脚本时会显示详细的执行进度和统计信息
4. 如遇到内存不足问题，可以调整spark-submit的内存参数

## 扩展功能

可以根据需要修改以下参数：
- 任务3中的筛选条件（`MIN_CLICKS`和`MAX_CART_RATE`）
- 测试数据的生成规则
- Spark运行参数（内存、并行度等）

## 问题排查

1. **Spark环境未配置**：确保PySpark已正确安装
2. **内存不足**：减少测试数据量或增加Spark内存配置
3. **输出目录已存在**：删除旧的输出目录或修改输出路径
4. **权限问题**：确保有读写文件的权限