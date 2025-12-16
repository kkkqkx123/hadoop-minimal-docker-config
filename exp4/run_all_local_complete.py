#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
综合本地模拟运行脚本
整合所有三个任务的完整模拟，不使用Hadoop和Spark
"""

import os
import sys
import subprocess
from datetime import datetime


def run_task1(input_file, output_dir):
    """运行任务1：用户点击到购买转化率分析"""
    print("\n" + "="*60)
    print("任务1：用户点击到购买转化率分析")
    print("="*60)
    
    output_file = os.path.join(output_dir, "task1_conversion_rate_complete.txt")
    
    try:
        # 导入并运行任务1
        sys.path.append('.')
        from task1_local_complete import analyze_user_conversion_rate
        
        analyze_user_conversion_rate(input_file, output_file)
        return True
    except Exception as e:
        print(f"任务1执行失败: {e}")
        return False


def run_task2(input_file, output_dir):
    """运行任务2：用户加购后购买率分析"""
    print("\n" + "="*60)
    print("任务2：用户加购后购买率分析")
    print("="*60)
    
    output_file = os.path.join(output_dir, "task2_cart_to_buy_rate_complete.txt")
    
    try:
        # 导入并运行任务2
        sys.path.append('.')
        from task2_local_complete import analyze_cart_to_buy_rate
        
        analyze_cart_to_buy_rate(input_file, output_file)
        return True
    except Exception as e:
        print(f"任务2执行失败: {e}")
        return False


def run_task3(input_file, output_dir):
    """运行任务3：高曝光低加购商品分析"""
    print("\n" + "="*60)
    print("任务3：高曝光低加购商品分析")
    print("="*60)
    
    output_file = os.path.join(output_dir, "task3_high_click_low_cart_complete.txt")
    
    try:
        # 导入并运行任务3
        sys.path.append('.')
        from task3_local_complete import analyze_high_click_low_cart_items
        
        analyze_high_click_low_cart_items(input_file, output_file)
        return True
    except Exception as e:
        print(f"任务3执行失败: {e}")
        return False


def generate_comprehensive_report(output_dir, task_results):
    """生成综合分析报告"""
    print("\n" + "="*60)
    print("综合分析报告")
    print("="*60)
    
    report_file = os.path.join(output_dir, "comprehensive_report.txt")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("用户行为分析综合报告\n")
        f.write("="*60 + "\n")
        f.write(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        # 任务1结果
        if task_results[0]:
            f.write("任务1：用户点击到购买转化率分析 - 成功\n")
            if os.path.exists(os.path.join(output_dir, "task1_conversion_rate_complete.txt")):
                with open(os.path.join(output_dir, "task1_conversion_rate_complete.txt"), 'r') as task1_file:
                    lines = task1_file.readlines()
                    if len(lines) > 1:
                        # 读取最后几行统计信息
                        f.write("关键统计信息:\n")
                        for line in lines[-15:]:  # 读取最后15行统计信息
                            f.write(f"  {line}")
        else:
            f.write("任务1：用户点击到购买转化率分析 - 失败\n")
        
        f.write("\n" + "-"*40 + "\n\n")
        
        # 任务2结果
        if task_results[1]:
            f.write("任务2：用户加购后购买率分析 - 成功\n")
            if os.path.exists(os.path.join(output_dir, "task2_cart_to_buy_rate_complete.txt")):
                with open(os.path.join(output_dir, "task2_cart_to_buy_rate_complete.txt"), 'r') as task2_file:
                    lines = task2_file.readlines()
                    if len(lines) > 1:
                        # 读取最后几行统计信息
                        f.write("关键统计信息:\n")
                        for line in lines[-15:]:  # 读取最后15行统计信息
                            f.write(f"  {line}")
        else:
            f.write("任务2：用户加购后购买率分析 - 失败\n")
        
        f.write("\n" + "-"*40 + "\n\n")
        
        # 任务3结果
        if task_results[2]:
            f.write("任务3：高曝光低加购商品分析 - 成功\n")
            if os.path.exists(os.path.join(output_dir, "task3_high_click_low_cart_complete.txt")):
                with open(os.path.join(output_dir, "task3_high_click_low_cart_complete.txt"), 'r') as task3_file:
                    lines = task3_file.readlines()
                    if len(lines) > 1:
                        # 读取最后几行统计信息
                        f.write("关键统计信息:\n")
                        for line in lines[-15:]:  # 读取最后15行统计信息
                            f.write(f"  {line}")
        else:
            f.write("任务3：高曝光低加购商品分析 - 失败\n")
        
        f.write("\n" + "="*60 + "\n")
        f.write("分析完成\n")
    
    print(f"综合分析报告已生成: {report_file}")


def main():
    """主函数"""
    print("开始执行综合本地模拟分析...")
    print("="*60)
    
    # 默认参数
    input_file = "data/user_behavior_logs.csv"
    output_dir = "output"
    
    # 检查命令行参数
    if len(sys.argv) >= 2:
        input_file = sys.argv[1]
    if len(sys.argv) >= 3:
        output_dir = sys.argv[2]
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 如果输入文件不存在，生成一个大数据集
    if not os.path.exists(input_file):
        print(f"输入文件不存在，生成大数据集: {input_file}")
        from task1_local_complete import generate_large_dataset
        generate_large_dataset(input_file, 50000)
    
    # 记录开始时间
    start_time = datetime.now()
    
    # 运行所有任务
    task_results = [False, False, False]
    
    try:
        task_results[0] = run_task1(input_file, output_dir)
    except Exception as e:
        print(f"任务1异常: {e}")
    
    try:
        task_results[1] = run_task2(input_file, output_dir)
    except Exception as e:
        print(f"任务2异常: {e}")
    
    try:
        task_results[2] = run_task3(input_file, output_dir)
    except Exception as e:
        print(f"任务3异常: {e}")
    
    # 生成综合报告
    generate_comprehensive_report(output_dir, task_results)
    
    # 计算总耗时
    end_time = datetime.now()
    total_duration = (end_time - start_time).total_seconds()
    
    # 输出总结
    print("\n" + "="*60)
    print("综合本地模拟分析完成")
    print("="*60)
    print(f"总耗时: {total_duration:.2f}秒")
    print(f"成功任务数: {sum(task_results)}/3")
    print(f"输出目录: {output_dir}")
    print("\n生成文件:")
    if task_results[0]:
        print(f"  - {os.path.join(output_dir, 'task1_conversion_rate_complete.txt')}")
    if task_results[1]:
        print(f"  - {os.path.join(output_dir, 'task2_cart_to_buy_rate_complete.txt')}")
    if task_results[2]:
        print(f"  - {os.path.join(output_dir, 'task3_high_click_low_cart_complete.txt')}")
    print(f"  - {os.path.join(output_dir, 'comprehensive_report.txt')}")


if __name__ == "__main__":
    main()