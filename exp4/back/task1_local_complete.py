#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务1完整模拟：用户点击到购买转化率分析（本地实现）
基于完整数据集进行精确计算，不简化数据
"""

import csv
import os
from collections import defaultdict
from datetime import datetime


def analyze_user_conversion_rate(input_file, output_file):
    """
    分析每个用户的点击到购买转化率
    
    Args:
        input_file: 输入数据文件路径
        output_file: 输出结果文件路径
    """
    print(f"开始分析用户转化率: {input_file}")
    start_time = datetime.now()
    
    # 读取数据并统计每个用户的行为
    user_behaviors = defaultdict(lambda: {'click': 0, 'buy': 0, 'cart': 0})
    total_records = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        for row in reader:
            total_records += 1
            user_id = row[0]
            behavior = row[2]
            
            user_behaviors[user_id][behavior] += 1
    
    print(f"处理完成: {total_records} 条记录, {len(user_behaviors)} 个用户")
    
    # 计算每个用户的转化率
    conversion_results = []
    users_with_clicks = 0
    total_clicks = 0
    total_buys = 0
    
    for user_id, behaviors in user_behaviors.items():
        clicks = behaviors['click']
        buys = behaviors['buy']
        
        if clicks > 0:
            conversion_rate = buys / clicks
            conversion_results.append((user_id, conversion_rate))
            users_with_clicks += 1
            total_clicks += clicks
            total_buys += buys
    
    # 按转化率降序排序
    conversion_results.sort(key=lambda x: x[1], reverse=True)
    
    # 写入结果文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("用户ID,点击次数,购买次数,转化率\n")
        for user_id, rate in conversion_results:
            behaviors = user_behaviors[user_id]
            f.write(f"{user_id},{behaviors['click']},{behaviors['buy']},{rate:.4f}\n")
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    # 输出统计信息
    print(f"\n=== 任务1：用户点击到购买转化率分析 ===")
    print(f"输入文件: {input_file}")
    print(f"输出文件: {output_file}")
    print(f"处理时间: {duration:.2f}秒")
    print(f"总记录数: {total_records}")
    print(f"总用户数: {len(user_behaviors)}")
    print(f"有点击行为的用户数: {users_with_clicks}")
    print(f"总点击次数: {total_clicks}")
    print(f"总购买次数: {total_buys}")
    print(f"整体转化率: {total_buys/total_clicks:.4f}")
    print(f"转化率范围: {conversion_results[-1][1]:.4f} - {conversion_results[0][1]:.4f}")
    print(f"平均转化率: {sum(rate for _, rate in conversion_results)/len(conversion_results):.4f}")
    
    # 显示前10名和后10名用户
    print(f"\n转化率最高的10个用户:")
    for i, (user_id, rate) in enumerate(conversion_results[:10]):
        behaviors = user_behaviors[user_id]
        print(f"  {i+1}. 用户{user_id}: {rate:.4f} (点击:{behaviors['click']}, 购买:{behaviors['buy']})")
    
    print(f"\n转化率最低的10个用户:")
    for i, (user_id, rate) in enumerate(conversion_results[-10:]):
        behaviors = user_behaviors[user_id]
        print(f"  {i+1}. 用户{user_id}: {rate:.4f} (点击:{behaviors['click']}, 购买:{behaviors['buy']})")


def generate_large_dataset(output_file, num_records=10000):
    """
    生成更大的数据集用于完整测试
    """
    print(f"生成大数据集: {num_records} 条记录")
    
    import random
    import time
    
    behaviors = ["click", "cart", "buy"]
    base_timestamp = int(time.time() * 1000)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        for i in range(num_records):
            user_id = random.randint(1, 500)  # 500个用户
            item_id = random.randint(1, 200)   # 200个商品
            
            # 更真实的行为概率分布
            rand = random.random()
            if rand < 0.75:  # 75% 点击
                behavior = "click"
            elif rand < 0.90:  # 15% 加购
                behavior = "cart"
            else:  # 10% 购买
                behavior = "buy"
            
            timestamp = base_timestamp + random.randint(0, 86400000)
            f.write(f"{user_id},{item_id},{behavior},{timestamp}\n")
    
    print(f"大数据集生成完成: {output_file}")


def main():
    """主函数"""
    import sys
    
    # 默认参数
    input_file = "data/user_behavior_logs.csv"
    output_file = "output/task1_conversion_rate_complete.txt"
    
    # 检查命令行参数
    if len(sys.argv) >= 2:
        input_file = sys.argv[1]
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    
    # 确保输出目录存在
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    # 如果输入文件不存在，生成一个大数据集
    if not os.path.exists(input_file):
        print(f"输入文件不存在，生成大数据集: {input_file}")
        generate_large_dataset(input_file, 10000)
    
    # 执行分析
    analyze_user_conversion_rate(input_file, output_file)


if __name__ == "__main__":
    main()