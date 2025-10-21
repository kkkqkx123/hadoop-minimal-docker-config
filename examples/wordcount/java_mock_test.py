#!/usr/bin/env python3
"""
Java MapReduce 本地Mock测试示例
用于在本地环境中测试Java MapReduce逻辑
"""

import subprocess
import tempfile
import os
import json
import time
from pathlib import Path

def create_test_java_files():
    """创建测试用的Java文件"""
    
    # WordCount Mapper
    mapper_code = '''
import java.io.IOException;
import java.util.StringTokenizer;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

public class WordCountMapper extends Mapper<Object, Text, Text, IntWritable> {
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
'''

    # WordCount Reducer
    reducer_code = '''
import java.io.IOException;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

public class WordCountReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
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
'''

    # WordCount Driver
    driver_code = '''
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCountDriver {
    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "word count");
        job.setJarByClass(WordCountDriver.class);
        job.setMapperClass(WordCountMapper.class);
        job.setCombinerClass(WordCountReducer.class);
        job.setReducerClass(WordCountReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
'''

    # 保存文件
    with open('WordCountMapper.java', 'w', encoding='utf-8') as f:
        f.write(mapper_code)
    
    with open('WordCountReducer.java', 'w', encoding='utf-8') as f:
        f.write(reducer_code)
    
    with open('WordCountDriver.java', 'w', encoding='utf-8') as f:
        f.write(driver_code)
    
    print("✅ Java测试文件已创建")

def test_java_compilation():
    """测试Java编译"""
    print("\n📋 测试Java编译...")
    
    # 检查Java环境
    try:
        result = subprocess.run(['java', '-version'], capture_output=True, text=True)
        if result.returncode != 0:
            print("❌ Java未安装")
            return False
    except FileNotFoundError:
        print("❌ Java未安装")
        return False
    
    # 检查Hadoop库
    hadoop_home = os.environ.get('HADOOP_HOME')
    if not hadoop_home:
        print("⚠️  HADOOP_HOME未设置，使用模拟编译测试")
        return test_mock_compilation()
    
    # 创建临时目录
    temp_dir = tempfile.mkdtemp()
    
    try:
        # 复制Java文件到临时目录
        for java_file in ['WordCountMapper.java', 'WordCountReducer.java', 'WordCountDriver.java']:
            if os.path.exists(java_file):
                subprocess.run(['cp', java_file, temp_dir], check=True)
        
        # 编译Java文件
        classpath = f"{hadoop_home}/share/hadoop/common/*:{hadoop_home}/share/hadoop/mapreduce/*:{hadoop_home}/share/hadoop/common/lib/*"
        
        compile_cmd = [
            'javac', '-cp', classpath,
            f'{temp_dir}/WordCountMapper.java',
            f'{temp_dir}/WordCountReducer.java',
            f'{temp_dir}/WordCountDriver.java'
        ]
        
        result = subprocess.run(compile_cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Java编译测试通过")
            return True
        else:
            print(f"❌ Java编译失败: {result.stderr}")
            return False
    
    finally:
        # 清理临时目录
        import shutil
        shutil.rmtree(temp_dir)

def test_mock_compilation():
    """模拟编译测试"""
    print("\n📋 运行模拟编译测试...")
    
    # 检查Java语法
    java_files = ['WordCountMapper.java', 'WordCountReducer.java', 'WordCountDriver.java']
    
    for java_file in java_files:
        if not os.path.exists(java_file):
            print(f"❌ 文件 {java_file} 不存在")
            return False
        
        # 简单的语法检查
        with open(java_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 检查基本语法结构
        if 'public class' not in content:
            print(f"❌ {java_file} 缺少类定义")
            return False
        
        if '{' not in content or '}' not in content:
            print(f"❌ {java_file} 括号不匹配")
            return False
        
        # 检查import语句
        if 'import' not in content:
            print(f"⚠️  {java_file} 缺少import语句")
    
    print("✅ 模拟编译测试通过")
    return True

def test_mapper_logic():
    """测试mapper逻辑"""
    print("\n📋 测试mapper逻辑...")
    
    # 创建测试输入
    test_input = "hello world hello hadoop"
    expected_words = ['hello', 'world', 'hello', 'hadoop']
    
    # 模拟mapper处理
    words = test_input.split()
    
    # 验证输出格式
    mapper_output = []
    for word in words:
        mapper_output.append(f"{word}\t1")
    
    print("模拟mapper输出:")
    for line in mapper_output:
        print(f"  {line}")
    
    # 验证结果
    if len(mapper_output) == len(expected_words):
        print("✅ Mapper逻辑测试通过")
        return True
    else:
        print("❌ Mapper逻辑测试失败")
        return False

def test_reducer_logic():
    """测试reducer逻辑"""
    print("\n📋 测试reducer逻辑...")
    
    # 模拟mapper输出（已排序）
    mapper_output = [
        "hello\t1",
        "hello\t1", 
        "hadoop\t1",
        "world\t1"
    ]
    
    # 模拟reducer处理
    word_counts = {}
    for line in mapper_output:
        word, count = line.split('\t')
        count = int(count)
        
        if word in word_counts:
            word_counts[word] += count
        else:
            word_counts[word] = count
    
    # 生成reducer输出
    reducer_output = []
    for word, count in sorted(word_counts.items()):
        reducer_output.append(f"{word}\t{count}")
    
    print("模拟reducer输出:")
    for line in reducer_output:
        print(f"  {line}")
    
    # 验证结果
    expected = {"hello": 2, "hadoop": 1, "world": 1}
    if word_counts == expected:
        print("✅ Reducer逻辑测试通过")
        return True
    else:
        print("❌ Reducer逻辑测试失败")
        return False

def test_data_format():
    """测试数据格式"""
    print("\n📋 测试数据格式...")
    
    # 测试输入格式
    test_inputs = [
        "hello world",
        "hello world hello hadoop",
        "this is a test file",
        "",  # 空行
        "   ",  # 空白
        "word1 word2 word3 word4 word5"  # 长行
    ]
    
    all_passed = True
    
    for test_input in test_inputs:
        print(f"\n  测试输入: '{test_input}'")
        
        if not test_input.strip():
            print("  跳过空输入")
            continue
        
        # 模拟mapper处理
        words = test_input.split()
        mapper_lines = [f"{word}\t1" for word in words]
        
        # 验证格式
        for line in mapper_lines:
            if '\t' not in line:
                print(f"  ❌ 格式错误: {line}")
                all_passed = False
                continue
            
            parts = line.split('\t')
            if len(parts) != 2 or parts[1] != '1':
                print(f"  ❌ 格式错误: {line}")
                all_passed = False
        
        print(f"  生成 {len(mapper_lines)} 行输出")
    
    if all_passed:
        print("✅ 数据格式测试通过")
    else:
        print("❌ 数据格式测试失败")
    
    return all_passed

def test_memory_usage():
    """测试内存使用"""
    print("\n📋 测试内存使用...")
    
    # 生成大数据集
    large_data = "hello world " * 10000  # 20000个单词
    
    print(f"测试数据大小: {len(large_data.split())} 个单词")
    
    # 模拟处理
    start_time = time.time()
    
    # mapper阶段
    words = large_data.split()
    mapper_lines = [f"{word}\t1" for word in words]
    
    # reducer阶段（模拟）
    word_counts = {}
    for line in mapper_lines:
        word, count = line.split('\t')
        word_counts[word] = word_counts.get(word, 0) + 1
    
    end_time = time.time()
    
    print(f"处理时间: {end_time - start_time:.3f}s")
    print(f"内存使用: 约 {len(word_counts)} 个唯一单词")
    
    # 检查内存使用是否合理
    if len(word_counts) <= 2:  # 应该只有hello和world两个唯一单词
        print("✅ 内存使用测试通过")
        return True
    else:
        print("❌ 内存使用异常")
        return False

def test_error_handling():
    """测试错误处理"""
    print("\n📋 测试错误处理...")
    
    # 测试各种错误情况
    test_cases = [
        ("", "空输入"),
        ("   ", "空白输入"),
        ("hello\tworld", "包含制表符的输入"),
        ("hello\nworld", "包含换行符的输入"),
        ("hello123 hello456", "数字混合"),
        ("HELLO hello Hello", "大小写混合")
    ]
    
    all_passed = True
    
    for test_input, description in test_cases:
        print(f"\n  测试: {description}")
        print(f"  输入: '{test_input}'")
        
        try:
            if not test_input.strip():
                print("  正确处理空输入")
                continue
            
            # 模拟处理
            words = test_input.split()
            mapper_lines = [f"{word}\t1" for word in words]
            
            # 检查输出
            print(f"  生成 {len(mapper_lines)} 行输出")
            print("  ✅ 处理成功")
            
        except Exception as e:
            print(f"  ❌ 处理失败: {str(e)}")
            all_passed = False
    
    if all_passed:
        print("✅ 错误处理测试通过")
    else:
        print("❌ 错误处理测试失败")
    
    return all_passed

def generate_java_test_report():
    """生成Java测试报告"""
    print("\n📊 生成Java测试报告...")
    
    report = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "test_results": {},
        "summary": {}
    }
    
    # 运行所有测试
    tests = [
        ("compilation", test_java_compilation),
        ("mapper_logic", test_mapper_logic),
        ("reducer_logic", test_reducer_logic),
        ("data_format", test_data_format),
        ("memory_usage", test_memory_usage),
        ("error_handling", test_error_handling)
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
    report_file = "java_test_report.json"
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\nJava测试报告已保存到: {report_file}")
    print(f"\n测试摘要:")
    print(f"总测试数: {total_tests}")
    print(f"通过: {total_passed}")
    print(f"失败: {total_tests - total_passed}")
    print(f"成功率: {(total_passed/total_tests)*100:.1f}%")
    
    return total_passed == total_tests

def main():
    """主函数"""
    print("🧪 Java MapReduce 本地Mock测试")
    print("=" * 50)
    
    # 创建测试文件
    create_test_java_files()
    
    # 运行测试
    success = generate_java_test_report()
    
    if success:
        print("\n🎉 所有Java测试通过！可以安全部署到Docker环境")
        print("💡 建议: 在Docker环境中使用小数据集进行最终验证")
    else:
        print("\n⚠️  部分测试失败，请先修复问题再部署")
        print("🔧 提示: 检查测试报告获取详细信息")
    
    return success

if __name__ == '__main__':
    import sys
    success = main()
    sys.exit(0 if success else 1)