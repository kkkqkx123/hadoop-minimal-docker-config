#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量执行三个PySpark任务的脚本
"""

import subprocess
import os
import sys
import time

def run_spark_job(script_path, input_path, output_path, task_name):
    """
    运行单个Spark任务
    
    Args:
        script_path: PySpark脚本路径
        input_path: 输入数据路径
        output_path: 输出路径
        task_name: 任务名称（用于显示）
    
    Returns:
        成功返回True，失败返回False
    """
    print(f"\n{'='*60}")
    print(f"开始执行任务: {task_name}")
    print(f"脚本: {script_path}")
    print(f"输入: {input_path}")
    print(f"输出: {output_path}")
    print(f"{'='*60}")
    
    try:
        # 构建spark-submit命令
        cmd = [
            "spark-submit",
            "--master", "local[*]",  # 使用本地模式，所有CPU核心
            "--driver-memory", "2g",  # 驱动程序内存
            "--executor-memory", "2g",  # 执行器内存
            script_path,
            input_path,
            output_path
        ]
        
        # 执行命令
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            print(f"✅ 任务 {task_name} 执行成功!")
            if result.stdout:
                print("输出信息:")
                print(result.stdout)
            return True
        else:
            print(f"❌ 任务 {task_name} 执行失败!")
            if result.stderr:
                print("错误信息:")
                print(result.stderr)
            return False
            
    except subprocess.TimeoutExpired:
        print(f"⏰ 任务 {task_name} 执行超时!")
        return False
    except Exception as e:
        print(f"💥 任务 {task_name} 执行异常: {str(e)}")
        return False

def main():
    """主函数"""
    
    # 检查参数
    if len(sys.argv) != 2:
        print("用法: python run_all_tasks.py <输入数据文件>")
        print("示例: python run_all_tasks.py test_data.txt")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # 检查输入文件是否存在
    if not os.path.exists(input_file):
        print(f"错误: 输入文件 {input_file} 不存在!")
        sys.exit(1)
    
    # 获取当前脚本所在目录
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 定义任务配置
    tasks = [
        {
            "name": "任务1：用户点击到购买转化率",
            "script": os.path.join(current_dir, "code1", "task1_conversion_rate.py"),
            "input": "data/user_behavior_logs.csv",
             "output": "output/task1_conversion_rate"
        },
        {
            "name": "任务2：用户加购后购买率",
            "script": os.path.join(current_dir, "code2", "task2_cart_to_buy_rate.py"),
             "input": "data/user_behavior_logs.csv",
             "output": "output/task2_cart_to_buy_rate"
        },
        {
            "name": "任务3：高曝光低加购商品识别",
            "script": os.path.join(current_dir, "code3", "task3_high_click_low_cart.py"),
             "input": "data/user_behavior_logs.csv",
             "output": "output/task3"
        }
    ]
    
    # 检查结果目录是否存在，如果存在则删除
    for task in tasks:
        if os.path.exists(task["output"]):
            import shutil
            shutil.rmtree(task["output"])
    
    print("🚀 开始执行所有PySpark任务...")
    print(f"输入数据文件: {input_file}")
    
    start_time = time.time()
    success_count = 0
    
    # 依次执行每个任务
    for i, task in enumerate(tasks, 1):
        print(f"\n📋 任务 {i}/3: {task['name']}")
        
        # 运行任务
        success = run_spark_job(task["script"], input_file, task["output"], task["name"])
        
        if success:
            success_count += 1
            print(f"✨ 任务 {i} 完成!")
        else:
            print(f"⚠️  任务 {i} 失败，继续执行下一个任务...")
        
        # 任务间稍作停顿
        time.sleep(2)
    
    end_time = time.time()
    total_time = end_time - start_time
    
    # 总结
    print(f"\n{'='*60}")
    print("📊 执行总结")
    print(f"{'='*60}")
    print(f"总任务数: {len(tasks)}")
    print(f"成功任务数: {success_count}")
    print(f"失败任务数: {len(tasks) - success_count}")
    print(f"总执行时间: {total_time:.2f} 秒")
    print(f"成功率: {success_count/len(tasks)*100:.1f}%")
    
    if success_count == len(tasks):
        print("\n🎉 所有任务执行成功!")
        print("\n输出结果目录:")
        for task in tasks:
            print(f"  - {task['name']}: {task['output']}")
    else:
        print(f"\n⚠️  有 {len(tasks) - success_count} 个任务执行失败，请检查错误信息")
    
    print(f"\n📁 结果文件说明:")
    print("每个任务的输出是一个目录，包含part-*文件，这些文件包含了计算结果")
    print("可以使用 'cat output_task*/part-*' 命令查看具体结果")

if __name__ == "__main__":
    main()