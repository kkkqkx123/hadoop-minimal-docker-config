#!/usr/bin/env python3
"""
Python MapReduce 本地Mock测试示例
用于在本地环境中测试mapper和reducer逻辑
"""

import sys
import io
import subprocess
import tempfile
import os
from collections import defaultdict
from unittest.mock import patch

def run_local_pipeline(input_data, mapper_script, reducer_script):
    """
    在本地运行完整的MapReduce流程
    
    Args:
        input_data: 输入数据字符串
        mapper_script: mapper脚本路径
        reducer_script: reducer脚本路径
        
    Returns:
        reducer输出结果，失败返回None
    """
    
    # 创建临时文件存储输入数据
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        f.write(input_data)
        input_file = f.name
    
    try:
        # 步骤1: 运行mapper
        print("🔄 运行mapper...")
        with open(input_file, 'r') as infile:
            mapper_result = subprocess.run(
                ['python3', mapper_script],
                stdin=infile,
                capture_output=True,
                text=True
            )
        
        if mapper_result.returncode != 0:
            print(f"❌ Mapper执行失败: {mapper_result.stderr}")
            return None
        
        print(f"✅ Mapper输出 {len(mapper_result.stdout.strip().split(chr(10)))} 行")
        
        # 步骤2: 排序（模拟shuffle阶段）
        print("🔄 排序数据（模拟shuffle）...")
        lines = mapper_result.stdout.strip().split('\n')
        sorted_lines = sorted([line for line in lines if line.strip()])
        sorted_output = '\n'.join(sorted_lines)
        
        # 步骤3: 运行reducer
        print("🔄 运行reducer...")
        reducer_result = subprocess.run(
            ['python3', reducer_script],
            input=sorted_output,
            capture_output=True,
            text=True
        )
        
        if reducer_result.returncode != 0:
            print(f"❌ Reducer执行失败: {reducer_result.stderr}")
            return None
        
        print(f"✅ Reducer输出 {len(reducer_result.stdout.strip().split(chr(10)))} 行")
        return reducer_result.stdout
        
    finally:
        # 清理临时文件
        if os.path.exists(input_file):
            os.unlink(input_file)

def test_mapper_unit():
    """测试mapper单元功能"""
    print("\n📋 测试mapper单元功能...")
    
    # 测试输入
    test_input = "hello world hello hadoop\nthis is a test\n"
    expected_words = ['hello', 'world', 'hello', 'hadoop', 'this', 'is', 'test']
    
    # 捕获mapper输出
    output = io.StringIO()
    
    # 模拟标准输入输出
    with patch('sys.stdin', io.StringIO(test_input)):
        with patch('sys.stdout', output):
            # 执行mapper
            exec(open('mapper.py').read())
    
    # 验证输出
    result_lines = output.getvalue().strip().split('\n')
    result_words = []
    
    print("Mapper输出:")
    for line in result_lines:
        if line.strip():
            parts = line.split('\t')
            if len(parts) == 2:
                word, count = parts
                result_words.append(word)
                print(f"  '{word}' -> {count}")
                
                # 验证计数
                if count != '1':
                    print(f"❌ 错误：单词 '{word}' 的计数应该是1，实际是{count}")
                    return False
    
    # 验证单词列表
    if result_words == expected_words:
        print("✅ Mapper单元测试通过")
        return True
    else:
        print(f"❌ Mapper输出不匹配")
        print(f"期望: {expected_words}")
        print(f"实际: {result_words}")
        return False

def test_reducer_unit():
    """测试reducer单元功能"""
    print("\n📋 测试reducer单元功能...")
    
    # 模拟mapper输出（已排序）
    test_input = """hello\t1
hello\t1
hadoop\t1
world\t1
this\t1
is\t1
a\t1
test\t1"""
    
    expected_output = {
        'hello': 2, 'hadoop': 1, 'world': 1, 'this': 1, 
        'is': 1, 'a': 1, 'test': 1
    }
    
    # 捕获reducer输出
    output = io.StringIO()
    
    # 模拟标准输入输出
    with patch('sys.stdin', io.StringIO(test_input)):
        with patch('sys.stdout', output):
            # 执行reducer
            exec(open('reducer.py').read())
    
    # 验证输出
    result_lines = output.getvalue().strip().split('\n')
    result_counts = {}
    
    print("Reducer输出:")
    for line in result_lines:
        if line.strip():
            parts = line.split('\t')
            if len(parts) == 2:
                word, count = parts
                result_counts[word] = int(count)
                print(f"  '{word}' -> {count}")
    
    # 对比结果
    if result_counts == expected_output:
        print("✅ Reducer单元测试通过")
        return True
    else:
        print(f"❌ Reducer输出不匹配")
        print(f"期望: {expected_output}")
        print(f"实际: {result_counts}")
        return False

def test_wordcount_integration():
    """测试词频统计集成流程"""
    print("\n🔗 测试词频统计集成流程...")
    
    # 测试数据
    test_data = """hello world hello hadoop
this is a test file for word count
hadoop is great for big data processing
hello hadoop users welcome to hadoop world"""
    
    # 期望结果
    expected_counts = {
        'hello': 3, 'world': 2, 'hadoop': 4, 'this': 1,
        'is': 2, 'test': 1, 'file': 1, 'for': 1, 'word': 1,
        'count': 1, 'great': 1, 'big': 1, 'data': 1,
        'processing': 1, 'users': 1, 'welcome': 1, 'to': 1
    }
    
    # 运行本地pipeline
    result = run_local_pipeline(test_data, 'mapper.py', 'reducer.py')
    
    if result is None:
        print("❌ 集成测试失败")
        return False
    
    # 解析结果
    result_counts = {}
    result_lines = result.strip().split('\n')
    
    print("集成测试结果:")
    for line in result_lines:
        if line.strip():
            parts = line.split('\t')
            if len(parts) == 2:
                word, count = parts
                result_counts[word] = int(count)
                print(f"  '{word}' -> {count}")
    
    # 对比结果
    if result_counts == expected_counts:
        print("✅ 集成测试通过")
        return True
    else:
        print(f"❌ 集成测试结果不匹配")
        print(f"期望: {expected_counts}")
        print(f"实际: {result_counts}")
        
        # 显示差异
        missing = set(expected_counts.keys()) - set(result_counts.keys())
        extra = set(result_counts.keys()) - set(expected_counts.keys())
        different = {k for k in expected_counts if k in result_counts and expected_counts[k] != result_counts[k]}
        
        if missing:
            print(f"缺失的单词: {missing}")
        if extra:
            print(f"多余的单词: {extra}")
        if different:
            print(f"计数不同的单词: {different}")
        
        return False

def test_edge_cases():
    """测试边界情况"""
    print("\n⚠️ 测试边界情况...")
    
    test_cases = [
        ("", "空输入"),
        ("   \n  \n", "空白行"),
        ("HELLO Hello hello", "大小写混合"),
        ("test123 test!@# test...", "特殊字符"),
        ("a b c d e", "单字符单词"),
        ("verylongword anotherverylongword", "长单词"),
        ("中文 测试 中文测试", "中文字符"),
        ("it's don't can't", "缩写词")
    ]
    
    all_passed = True
    
    for test_data, description in test_cases:
        print(f"\n  测试: {description}")
        print(f"  输入: '{test_data}'")
        
        result = run_local_pipeline(test_data, 'mapper.py', 'reducer.py')
        
        if result is not None:
            print(f"  输出: '{result.strip()}'")
            print("  ✅ 通过")
        else:
            print("  ❌ 失败")
            all_passed = False
    
    return all_passed

def test_performance():
    """性能测试"""
    print("\n⚡ 性能测试...")
    
    import time
    
    # 生成测试数据
    test_data = "hello world " * 1000  # 2000个单词
    
    print(f"测试数据: {len(test_data.split())} 个单词")
    
    # 测试mapper性能
    start_time = time.time()
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        f.write(test_data)
        input_file = f.name
    
    try:
        with open(input_file, 'r') as infile:
            mapper_result = subprocess.run(
                ['python3', 'mapper.py'],
                stdin=infile,
                capture_output=True,
                text=True
            )
        
        mapper_time = time.time() - start_time
        mapper_lines = len(mapper_result.stdout.strip().split('\n'))
        
        print(f"Mapper: {mapper_time:.3f}s, {mapper_lines} 行输出")
        
        # 测试reducer性能
        start_time = time.time()
        reducer_result = subprocess.run(
            ['python3', 'reducer.py'],
            input=mapper_result.stdout,
            capture_output=True,
            text=True
        )
        
        reducer_time = time.time() - start_time
        reducer_lines = len(reducer_result.stdout.strip().split('\n'))
        
        print(f"Reducer: {reducer_time:.3f}s, {reducer_lines} 行输出")
        print(f"总时间: {mapper_time + reducer_time:.3f}s")
        
        # 性能指标
        total_words = len(test_data.split())
        throughput = total_words / (mapper_time + reducer_time)
        print(f"处理速度: {throughput:.1f} 单词/秒")
        
        # 性能要求（可根据需要调整）
        if throughput > 1000:  # 每秒处理1000个单词以上
            print("✅ 性能测试通过")
            return True
        else:
            print("⚠️  性能较低，建议优化")
            return False
            
    finally:
        if os.path.exists(input_file):
            os.unlink(input_file)

def generate_test_report():
    """生成测试报告"""
    print("\n📊 生成测试报告...")
    
    import json
    import datetime
    
    report = {
        "timestamp": datetime.datetime.now().isoformat(),
        "test_results": {},
        "summary": {}
    }
    
    # 运行所有测试
    tests = [
        ("unit_mapper", test_mapper_unit),
        ("unit_reducer", test_reducer_unit),
        ("integration", test_wordcount_integration),
        ("edge_cases", test_edge_cases),
        ("performance", test_performance)
    ]
    
    total_passed = 0
    total_tests = len(tests)
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            report["test_results"][test_name] = "PASSED" if result else "FAILED"
            if result:
                total_passed += 1
        except Exception as e:
            report["test_results"][test_name] = f"ERROR: {str(e)}"
            print(f"❌ {test_name} 测试出错: {str(e)}")
    
    # 生成摘要
    report["summary"] = {
        "total_tests": total_tests,
        "passed": total_passed,
        "failed": total_tests - total_passed,
        "success_rate": f"{(total_passed/total_tests)*100:.1f}%"
    }
    
    # 保存报告
    report_file = "local_test_report.json"
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n测试报告已保存到: {report_file}")
    print(f"\n测试摘要:")
    print(f"总测试数: {total_tests}")
    print(f"通过: {total_passed}")
    print(f"失败: {total_tests - total_passed}")
    print(f"成功率: {(total_passed/total_tests)*100:.1f}%")
    
    return total_passed == total_tests

def main():
    """主函数"""
    print("🧪 Python MapReduce 本地Mock测试")
    print("=" * 50)
    
    # 检查文件是否存在
    if not os.path.exists('mapper.py'):
        print("❌ 错误：mapper.py 文件不存在")
        print("请确保在包含mapper.py和reducer.py的目录中运行此脚本")
        return False
    
    if not os.path.exists('reducer.py'):
        print("❌ 错误：reducer.py 文件不存在")
        return False
    
    # 运行完整测试
    success = generate_test_report()
    
    if success:
        print("\n🎉 所有测试通过！可以安全部署到Docker环境")
        print("💡 建议: 在Docker环境中使用小数据集进行最终验证")
    else:
        print("\n⚠️  部分测试失败，请先修复问题再部署")
        print("🔧 提示: 检查测试报告获取详细信息")
    
    return success

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)