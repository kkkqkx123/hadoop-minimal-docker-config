#!/usr/bin/env python3
"""
Python MapReduce 示例 - 词频统计
用于Hadoop Streaming的mapper和reducer
"""

# mapper.py
mapper_code = '''#!/usr/bin/env python3
import sys
import re

# 读取标准输入
for line in sys.stdin:
    # 移除行尾换行符并转换为小写
    line = line.strip().lower()
    
    # 使用正则表达式分割单词，只保留字母和数字
    words = re.findall(r'\b[a-zA-Z]+\b', line)
    
    # 输出每个单词和计数1
    for word in words:
        if len(word) > 2:  # 过滤掉太短的单词
            print(f"{word}\t1")
'''

# reducer.py
reducer_code = '''#!/usr/bin/env python3
import sys
from collections import defaultdict

# 使用defaultdict来存储单词计数
word_count = defaultdict(int)

# 读取标准输入
for line in sys.stdin:
    # 移除行尾换行符
    line = line.strip()
    
    # 分割单词和计数
    try:
        word, count = line.split('\t', 1)
        word_count[word] += int(count)
    except ValueError:
        # 跳过格式不正确的行
        continue

# 按计数降序排序并输出前100个单词
sorted_words = sorted(word_count.items(), key=lambda x: x[1], reverse=True)

for word, count in sorted_words[:100]:
    print(f"{word}\t{count}")
'''

# 创建mapper文件
with open('mapper.py', 'w', encoding='utf-8') as f:
    f.write(mapper_code)

# 创建reducer文件
with open('reducer.py', 'w', encoding='utf-8') as f:
    f.write(reducer_code)

# 设置执行权限
import os
os.chmod('mapper.py', 0o755)
os.chmod('reducer.py', 0o755)

print("✅ 已创建 mapper.py 和 reducer.py 文件")
print("📖 使用方法:")
print("1. 将这两个文件复制到master容器中:")
print("   docker cp mapper.py hadoop-master:/tmp/")
print("   docker cp reducer.py hadoop-master:/tmp/")
print("")
print("2. 创建测试数据文件:")
print("   echo 'Hello World Hello Hadoop This is a test file for word count' > input.txt")
print("   docker cp input.txt hadoop-master:/tmp/")
print("")
print("3. 上传到HDFS:")
print("   docker-compose exec master hdfs dfs -mkdir -p /wordcount/input")
print("   docker-compose exec master hdfs dfs -put /tmp/input.txt /wordcount/input/")
print("")
print("4. 执行MapReduce作业:")
print("   docker-compose exec master hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \\")
print("       -files /tmp/mapper.py,/tmp/reducer.py \\")
print("       -mapper 'python3 /tmp/mapper.py' \\")
print("       -reducer 'python3 /tmp/reducer.py' \\")
print("       -input /wordcount/input \\")
print("       -output /wordcount/output")
print("")
print("5. 查看结果:")
print("   docker-compose exec master hdfs dfs -cat /wordcount/output/part-*")