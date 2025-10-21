# 本地Mock测试指南

## 🎯 概述

在Docker环境中调试MapReduce程序可能会遇到环境复杂、调试困难的问题。本指南介绍如何在本地环境中通过Mock测试来验证代码逻辑，避免在Docker上发现问题后难以调试的情况。

## 🧪 Mock测试策略

### 1. 单元测试（Unit Testing）

#### Python MapReduce Mock测试

**mapper_mock_test.py**
```python
#!/usr/bin/env python3
"""Mapper单元测试"""

import sys
import io
from unittest.mock import patch

def test_mapper():
    """测试mapper函数"""
    # Mock输入数据
    test_input = "hello world hello hadoop\nthis is a test"
    
    # 捕获输出
    output = io.StringIO()
    
    # 重定向stdin和stdout
    with patch('sys.stdin', io.StringIO(test_input)):
        with patch('sys.stdout', output):
            # 导入并执行mapper
            exec(open('mapper.py').read())
    
    # 验证输出
    result = output.getvalue().strip().split('\n')
    expected_words = ['hello', 'world', 'hello', 'hadoop', 'this', 'is', 'test']
    
    print("Mapper测试结果:")
    for line in result:
        word, count = line.split('\t')
        print(f"  {word}: {count}")
        assert word in expected_words, f"意外单词: {word}"
        assert count == '1', f"计数错误: {count}"
    
    print("✅ Mapper测试通过")

def test_reducer():
    """测试reducer函数"""
    # Mock输入数据（已排序）
    test_input = "hello\t1\nhello\t1\nhadoop\t1\nworld\t1"
    
    # 捕获输出
    output = io.StringIO()
    
    # 重定向stdin和stdout
    with patch('sys.stdin', io.StringIO(test_input)):
        with patch('sys.stdout', output):
            # 导入并执行reducer
            exec(open('reducer.py').read())
    
    # 验证输出
    result = output.getvalue().strip().split('\n')
    expected = {'hello': '2', 'hadoop': '1', 'world': '1'}
    
    print("\nReducer测试结果:")
    for line in result:
        word, count = line.split('\t')
        print(f"  {word}: {count}")
        assert word in expected, f"意外单词: {word}"
        assert count == expected[word], f"计数错误: {count}"
    
    print("✅ Reducer测试通过")

if __name__ == '__main__':
    test_mapper()
    test_reducer()
    print("\n🎉 所有单元测试通过！")
```

**使用方法：**
```bash
# 运行单元测试
python3 mapper_mock_test.py

# 集成到测试框架
python3 -m pytest mapper_mock_test.py -v
```

#### Java MapReduce Mock测试

**WordCountMapperTest.java**
```java
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.junit.Test;
import org.junit.Before;
import static org.mockito.Mockito.*;

public class WordCountMapperTest {
    
    private WordCountMapper mapper;
    private Mapper.Context mockContext;
    
    @Before
    public void setUp() {
        mapper = new WordCountMapper();
        mockContext = mock(Mapper.Context.class);
    }
    
    @Test
    public void testMap() throws Exception {
        // 测试输入
        Text inputKey = new Text("1");  // 行号
        Text inputValue = new Text("hello world hello hadoop");
        
        // 执行map函数
        mapper.map(inputKey, inputValue, mockContext);
        
        // 验证输出
        verify(mockContext, times(2)).write(new Text("hello"), new IntWritable(1));
        verify(mockContext, times(1)).write(new Text("world"), new IntWritable(1));
        verify(mockContext, times(1)).write(new Text("hadoop"), new IntWritable(1));
    }
    
    @Test
    public void testMapWithEmptyInput() throws Exception {
        Text inputKey = new Text("1");
        Text inputValue = new Text("");
        
        mapper.map(inputKey, inputValue, mockContext);
        
        // 验证没有输出
        verify(mockContext, never()).write(any(), any());
    }
}
```

### 2. 集成测试（Integration Testing）

#### 本地Pipeline测试

**local_pipeline_test.py**
```python
#!/usr/bin/env python3
"""本地Pipeline集成测试"""

import subprocess
import tempfile
import os

def run_local_pipeline(input_data, mapper_script, reducer_script):
    """在本地运行完整的MapReduce流程"""
    
    # 创建临时文件
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        f.write(input_data)
        input_file = f.name
    
    try:
        # 步骤1: 运行mapper
        with open(input_file, 'r') as infile:
            mapper_result = subprocess.run(
                ['python3', mapper_script],
                stdin=infile,
                capture_output=True,
                text=True
            )
        
        if mapper_result.returncode != 0:
            print(f"Mapper执行失败: {mapper_result.stderr}")
            return None
        
        # 步骤2: 排序（模拟shuffle阶段）
        sorted_output = '\n'.join(sorted(mapper_result.stdout.strip().split('\n')))
        
        # 步骤3: 运行reducer
        reducer_result = subprocess.run(
            ['python3', reducer_script],
            input=sorted_output,
            capture_output=True,
            text=True
        )
        
        if reducer_result.returncode != 0:
            print(f"Reducer执行失败: {reducer_result.stderr}")
            return None
        
        return reducer_result.stdout
        
    finally:
        # 清理临时文件
        os.unlink(input_file)

def test_wordcount_pipeline():
    """测试词频统计pipeline"""
    
    # 测试数据
    test_data = """hello world hello hadoop
this is a test file for word count
hadoop is great for big data processing
hello hadoop users"""
    
    # 运行本地pipeline
    result = run_local_pipeline(test_data, 'mapper.py', 'reducer.py')
    
    if result is None:
        print("❌ Pipeline测试失败")
        return False
    
    # 解析结果
    print("Pipeline测试结果:")
    word_counts = {}
    for line in result.strip().split('\n'):
        if line:
            word, count = line.split('\t')
            word_counts[word] = int(count)
            print(f"  {word}: {count}")
    
    # 验证结果
    expected = {
        'hello': 3,
        'hadoop': 3,
        'world': 1,
        'this': 1,
        'is': 2,
        'test': 1,
        'file': 1,
        'for': 1,
        'word': 1,
        'count': 1,
        'great': 1,
        'big': 1,
        'data': 1,
        'processing': 1,
        'users': 1
    }
    
    # 检查是否匹配
    if word_counts == expected:
        print("✅ Pipeline测试通过")
        return True
    else:
        print("❌ Pipeline结果不匹配")
        print("期望:", expected)
        print("实际:", word_counts)
        return False

def test_edge_cases():
    """测试边界情况"""
    
    test_cases = [
        ("", "空输入测试"),
        ("   \n  \n", "空白行测试"),
        ("HELLO Hello hello", "大小写测试"),
        ("test123 test!@# test...", "特殊字符测试"),
        ("a\nb\nc", "单字符测试")
    ]
    
    print("\n边界情况测试:")
    all_passed = True
    
    for test_data, description in test_cases:
        print(f"\n{description}:")
        result = run_local_pipeline(test_data, 'mapper.py', 'reducer.py')
        
        if result is not None:
            print(f"  结果: {result.strip()}")
            print("  ✅ 通过")
        else:
            print("  ❌ 失败")
            all_passed = False
    
    return all_passed

if __name__ == '__main__':
    print("🧪 本地Pipeline集成测试")
    print("=" * 40)
    
    # 运行测试
    pipeline_passed = test_wordcount_pipeline()
    edge_passed = test_edge_cases()
    
    if pipeline_passed and edge_passed:
        print("\n🎉 所有集成测试通过！")
    else:
        print("\n❌ 部分测试失败，请检查代码逻辑")
```

### 3. 数据验证测试

**data_validation_test.py**
```python
#!/usr/bin/env python3
"""数据验证测试"""

import json
import hashlib
from typing import Dict, List, Tuple

def validate_mapper_output(output_lines: List[str]) -> bool:
    """验证mapper输出格式"""
    
    print("验证mapper输出格式...")
    
    for line in output_lines:
        line = line.strip()
        if not line:
            continue
            
        # 检查格式：word\tcount
        parts = line.split('\t')
        if len(parts) != 2:
            print(f"❌ 格式错误: {line}")
            return False
        
        word, count = parts
        
        # 验证count是数字
        try:
            int(count)
        except ValueError:
            print(f"❌ 计数不是数字: {count}")
            return False
    
    print("✅ Mapper输出格式正确")
    return True

def validate_reducer_input(output_lines: List[str]) -> bool:
    """验证reducer输入格式（已排序）"""
    
    print("验证reducer输入格式...")
    
    current_word = None
    current_count = 0
    
    for line in output_lines:
        line = line.strip()
        if not line:
            continue
            
        parts = line.split('\t')
        if len(parts) != 2:
            print(f"❌ 格式错误: {line}")
            return False
        
        word, count = parts
        count = int(count)
        
        # 检查是否按单词分组
        if current_word is None:
            current_word = word
            current_count = count
        elif word == current_word:
            current_count += count
        else:
            # 新单词，验证前一个单词的完整性
            print(f"  单词 '{current_word}' 总计数: {current_count}")
            current_word = word
            current_count = count
    
    if current_word:
        print(f"  单词 '{current_word}' 总计数: {current_count}")
    
    print("✅ Reducer输入格式正确")
    return True

def generate_test_report(mapper_input: str, mapper_output: str, 
                        reducer_input: str, reducer_output: str) -> Dict:
    """生成测试报告"""
    
    report = {
        "input_stats": {
            "lines": len(mapper_input.strip().split('\n')),
            "characters": len(mapper_input),
            "words": len(mapper_input.split())
        },
        "mapper_stats": {
            "output_lines": len([l for l in mapper_output.split('\n') if l.strip()]),
            "unique_words": len(set(line.split('\t')[0] for line in mapper_output.split('\n') if line.strip() and '\t' in line))
        },
        "reducer_stats": {
            "output_lines": len([l for l in reducer_output.split('\n') if l.strip()]),
            "total_words": sum(int(line.split('\t')[1]) for line in reducer_output.split('\n') if line.strip() and '\t' in line)
        }
    }
    
    # 计算数据完整性检查
    mapper_total = sum(int(line.split('\t')[1]) for line in mapper_output.split('\n') 
                        if line.strip() and '\t' in line)
    reducer_total = sum(int(line.split('\t')[1]) for line in reducer_output.split('\n') 
                        if line.strip() and '\t' in line)
    
    report["data_integrity"] = {
        "mapper_total_count": mapper_total,
        "reducer_total_count": reducer_total,
        "counts_match": mapper_total == reducer_total
    }
    
    return report

def save_test_report(report: Dict, filename: str = "test_report.json"):
    """保存测试报告"""
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"测试报告已保存到: {filename}")

if __name__ == '__main__':
    print("📊 数据验证测试")
    print("=" * 30)
    
    # 示例数据
    sample_mapper_output = """hello\t1
world\t1
hello\t1
hadoop\t1"""
    
    sample_reducer_input = """hello\t1
hello\t1
hadoop\t1
world\t1"""
    
    # 运行验证
    validate_mapper_output(sample_mapper_output.split('\n'))
    validate_reducer_input(sample_reducer_input.split('\n'))
    
    print("\n🎉 数据验证完成")
```

## 🔧 测试环境搭建

### 安装依赖
```bash
# Python测试依赖
pip install pytest pytest-mock

# Java测试依赖（Maven项目）
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.13.2</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <version>4.6.1</version>
    <scope>test</scope>
</dependency>
```

### 测试目录结构建议
```
your-project/
├── src/
│   ├── main/
│   │   ├── java/          # Java源代码
│   │   └── python/        # Python脚本
│   └── test/
│       ├── java/          # Java单元测试
│       ├── python/        # Python单元测试
│       └── integration/   # 集成测试
├── scripts/
│   ├── mapper.py
│   ├── reducer.py
│   └── run_local_test.sh  # 本地测试脚本
└── test-reports/          # 测试报告输出目录
```

## 🚀 自动化测试流程

**run_local_test.sh**
```bash
#!/bin/bash
# 本地自动化测试脚本

set -e

echo "🚀 开始本地Mock测试"
echo "=================="

# 1. 单元测试
echo "📋 运行单元测试..."
python3 -m pytest test/ -v --tb=short

# 2. 集成测试
echo "🔗 运行集成测试..."
python3 test/python/local_pipeline_test.py

# 3. 数据验证
echo "🔍 运行数据验证..."
python3 test/python/data_validation_test.py

# 4. 生成本地pipeline测试报告
echo "📊 生成测试报告..."
python3 test/python/generate_test_report.py

echo "✅ 本地测试完成！"
echo "💡 现在可以安全地部署到Docker环境了"
```

## 💡 调试技巧

### 1. 逐步调试
```python
# 在关键位置添加调试输出
def mapper():
    for line in sys.stdin:
        print(f"DEBUG: 输入行: {line}", file=sys.stderr)
        # ... 处理逻辑
        print(f"DEBUG: 输出: {word}\t{count}", file=sys.stderr)
        print(f"{word}\t{count}")
```

### 2. 数据采样测试
```python
def test_with_sample_data():
    """使用小数据集快速验证"""
    sample_data = "hello world hello hadoop"
    
    # 本地运行mapper
    mapper_result = subprocess.run(['python3', 'mapper.py'], 
                                  input=sample_data, 
                                  capture_output=True, text=True)
    
    print("Mapper输出:")
    print(mapper_result.stdout)
    
    # 本地运行reducer
    reducer_result = subprocess.run(['python3', 'reducer.py'], 
                                   input=mapper_result.stdout, 
                                   capture_output=True, text=True)
    
    print("\nReducer输出:")
    print(reducer_result.stdout)
```

### 3. 对比测试
```python
def compare_with_expected(input_data, expected_output):
    """对比实际输出与期望输出"""
    
    # 运行本地pipeline
    actual_output = run_local_pipeline(input_data, 'mapper.py', 'reducer.py')
    
    # 对比结果
    actual_lines = set(actual_output.strip().split('\n'))
    expected_lines = set(expected_output.strip().split('\n'))
    
    if actual_lines == expected_lines:
        print("✅ 输出匹配期望结果")
    else:
        print("❌ 输出不匹配:")
        print("额外输出:", actual_lines - expected_lines)
        print("缺失输出:", expected_lines - actual_lines)
```

## 📊 测试报告生成

**generate_test_report.py**
```python
#!/usr/bin/env python3
"""生成详细的测试报告"""

import datetime
import json
import os
from local_pipeline_test import run_local_pipeline, test_wordcount_pipeline

def generate_comprehensive_report():
    """生成综合测试报告"""
    
    report = {
        "timestamp": datetime.datetime.now().isoformat(),
        "environment": {
            "python_version": "3.x",
            "test_framework": "pytest",
            "os": "Linux/MacOS/Windows"
        },
        "test_results": {},
        "recommendations": []
    }
    
    # 运行各种测试
    print("生成测试报告...")
    
    # 1. 基础功能测试
    try:
        test_wordcount_pipeline()
        report["test_results"]["basic_functionality"] = "PASSED"
    except Exception as e:
        report["test_results"]["basic_functionality"] = f"FAILED: {str(e)}"
        report["recommendations"].append("检查基础MapReduce逻辑")
    
    # 2. 性能测试（小数据集）
    import time
    test_data = "hello world " * 1000  # 2000个单词
    
    start_time = time.time()
    result = run_local_pipeline(test_data, 'mapper.py', 'reducer.py')
    end_time = time.time()
    
    if result:
        report["test_results"]["performance"] = {
            "status": "PASSED",
            "execution_time": f"{end_time - start_time:.3f}s",
            "data_size": len(test_data.split()),
            "throughput": f"{len(test_data.split()) / (end_time - start_time):.1f} words/s"
        }
    else:
        report["test_results"]["performance"] = "FAILED"
        report["recommendations"].append("检查性能瓶颈")
    
    # 3. 内存使用测试
    import psutil
    import os
    
    process = psutil.Process(os.getpid())
    memory_before = process.memory_info().rss / 1024 / 1024  # MB
    
    # 运行大数据集测试
    large_data = "test " * 10000  # 10000个单词
    run_local_pipeline(large_data, 'mapper.py', 'reducer.py')
    
    memory_after = process.memory_info().rss / 1024 / 1024  # MB
    memory_increase = memory_after - memory_before
    
    report["test_results"]["memory_usage"] = {
        "memory_increase_mb": f"{memory_increase:.2f}",
        "status": "PASSED" if memory_increase < 100 else "WARNING"
    }
    
    if memory_increase > 100:
        report["recommendations"].append("内存使用较高，考虑优化")
    
    # 保存报告
    report_file = "test_report.json"
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"测试报告已保存到: {report_file}")
    
    # 打印摘要
    print("\n" + "="*50)
    print("测试报告摘要:")
    print("="*50)
    
    for test_name, result in report["test_results"].items():
        if isinstance(result, dict):
            status = result.get("status", "UNKNOWN")
            print(f"{test_name}: {status}")
            for key, value in result.items():
                if key != "status":
                    print(f"  {key}: {value}")
        else:
            print(f"{test_name}: {result}")
    
    if report["recommendations"]:
        print("\n建议:")
        for rec in report["recommendations"]:
            print(f"  - {rec}")
    
    return report

if __name__ == '__main__':
    generate_comprehensive_report()
```

## 🎯 最佳实践

### 1. 测试驱动开发（TDD）
```
1. 先编写测试用例
2. 运行测试（应该失败）
3. 编写最小化的实现代码
4. 运行测试（应该通过）
5. 重构优化代码
6. 重复以上步骤
```

### 2. 测试分层
- **单元测试**：测试单个函数/方法
- **集成测试**：测试组件间的交互
- **端到端测试**：测试完整的数据处理流程

### 3. 持续集成
```yaml
# .github/workflows/test.yml
name: Local Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.8'
    - name: Install dependencies
      run: pip install pytest pytest-mock
    - name: Run tests
      run: |
        python3 test/python/local_pipeline_test.py
        python3 test/python/data_validation_test.py
```

### 4. 测试数据管理
```
test-data/
├── small/          # 小数据集（快速测试）
├── medium/         # 中等数据集（功能测试）
├── large/          # 大数据集（性能测试）
└── edge-cases/     # 边界情况数据
```

## 📋 测试检查清单

在部署到Docker环境前，确保完成以下检查：

- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 边界情况测试通过
- [ ] 数据格式验证通过
- [ ] 性能测试通过（小数据集）
- [ ] 内存使用合理
- [ ] 代码覆盖率达标
- [ ] 测试报告生成

## 🔍 常见调试场景

### 场景1：Mapper输出格式错误
```python
# 错误示例
print(word, count)  # 缺少制表符分隔

# 正确示例
print(f"{word}\t{count}")
```

### 场景2：Reducer无法正确处理分组
```python
# 错误：没有按单词分组
for line in sys.stdin:
    word, count = line.strip().split('\t')
    total += int(count)
print(f"{word}\t{total}")  # word变量可能未定义

# 正确：按单词分组统计
word_counts = defaultdict(int)
for line in sys.stdin:
    word, count = line.strip().split('\t')
    word_counts[word] += int(count)

for word, total in word_counts.items():
    print(f"{word}\t{total}")
```

### 场景3：内存使用过高
```python
# 优化：使用生成器而不是一次性加载所有数据
def process_large_file(filename):
    with open(filename, 'r') as f:
        for line in f:
            yield line.strip()
```

通过这套完整的本地Mock测试体系，你可以在部署到Docker环境之前充分验证代码的正确性，大大减少在分布式环境中调试的难度。