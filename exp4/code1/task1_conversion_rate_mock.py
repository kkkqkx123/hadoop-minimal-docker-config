#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务1模拟：计算每个用户"从点击到购买"的转化率
模拟exp4\code1\task1_conversion_rate.py的输出
"""

import sys
import random

def mock_task1_conversion_rate(input_path, output_path):
    """
    模拟任务1的输出
    """
    print("=== 用户点击到购买转化率结果 ===")
    
    # 模拟数据生成
    random.seed(42)  # 确保结果可重现
    
    # 生成50个用户的转化率数据
    results = []
    for user_id in range(1, 51):
        # 模拟不同的转化率分布
        if user_id <= 10:  # 前10个用户：高活跃用户，转化率高
            rate = round(random.uniform(0.3, 0.8), 2)
        elif user_id <= 25:  # 中等活跃用户
            rate = round(random.uniform(0.1, 0.4), 2)
        elif user_id <= 40:  # 低活跃用户
            rate = round(random.uniform(0.0, 0.2), 2)
        else:  # 新用户或极少活跃用户
            rate = round(random.uniform(0.0, 0.1), 2)
        
        results.append((user_id, rate))
        print(f"用户 {user_id}: 转化率 = {rate}")
    
    print(f"\n总用户数: {len(results)}")
    
    # 保存结果到文件（模拟Spark输出格式）
    with open(output_path, 'w', encoding='utf-8') as f:
        for user_id, rate in results:
            f.write(f"({user_id}, {rate})\n")
    
    print(f"\n结果已保存到: {output_path}")
    return results

def main():
    """主函数"""
    if len(sys.argv) >= 2:
        input_path = sys.argv[1]
    else:
        input_path = "data/user_behavior_logs.csv"  # 默认数据集路径
    
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        output_path = "output/task1_conversion_rate_mock.txt"  # 默认输出路径
    
    mock_task1_conversion_rate(input_path, output_path)

if __name__ == "__main__":
    main()