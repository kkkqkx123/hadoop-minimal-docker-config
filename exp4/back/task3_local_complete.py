#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务3完整模拟：高曝光低加购商品分析（本地实现）
基于完整数据集进行精确计算，不简化数据
筛选条件：点击次数≥10且加购转化率≤0.2
"""

import csv
import os
from collections import defaultdict
from datetime import datetime


def analyze_high_click_low_cart_items(input_file, output_file):
    """
    分析高曝光低加购的商品
    
    Args:
        input_file: 输入数据文件路径
        output_file: 输出结果文件路径
    """
    print(f"开始分析高曝光低加购商品: {input_file}")
    start_time = datetime.now()
    
    # 读取数据并统计每个商品的行为
    item_behaviors = defaultdict(lambda: {'click': 0, 'buy': 0, 'cart': 0})
    total_records = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        for row in reader:
            total_records += 1
            item_id = row[1]
            behavior = row[2]
            
            item_behaviors[item_id][behavior] += 1
    
    print(f"处理完成: {total_records} 条记录, {len(item_behaviors)} 个商品")
    
    # 筛选符合条件的商品：点击次数≥10且加购转化率≤0.2
    qualified_items = []
    
    for item_id, behaviors in item_behaviors.items():
        clicks = behaviors['click']
        carts = behaviors['cart']
        
        if clicks >= 10:  # 高曝光条件
            cart_conversion_rate = carts / clicks if clicks > 0 else 0
            
            if cart_conversion_rate <= 0.2:  # 低加购转化率条件
                qualified_items.append({
                    'item_id': item_id,
                    'clicks': clicks,
                    'carts': carts,
                    'buys': behaviors['buy'],
                    'cart_conversion_rate': cart_conversion_rate
                })
    
    # 按加购转化率升序排序
    qualified_items.sort(key=lambda x: x['cart_conversion_rate'])
    
    # 写入结果文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("商品ID,点击次数,加购次数,购买次数,加购转化率\n")
        for item in qualified_items:
            f.write(f"{item['item_id']},{item['clicks']},{item['carts']},{item['buys']},{item['cart_conversion_rate']:.4f}\n")
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    # 计算统计信息
    if qualified_items:
        avg_clicks = sum(item['clicks'] for item in qualified_items) / len(qualified_items)
        avg_carts = sum(item['carts'] for item in qualified_items) / len(qualified_items)
        avg_buys = sum(item['buys'] for item in qualified_items) / len(qualified_items)
        avg_cart_rate = sum(item['cart_conversion_rate'] for item in qualified_items) / len(qualified_items)
    else:
        avg_clicks = avg_carts = avg_buys = avg_cart_rate = 0
    
    # 输出统计信息
    print(f"\n=== 任务3：高曝光低加购商品分析 ===")
    print(f"输入文件: {input_file}")
    print(f"输出文件: {output_file}")
    print(f"处理时间: {duration:.2f}秒")
    print(f"总记录数: {total_records}")
    print(f"总商品数: {len(item_behaviors)}")
    print(f"符合条件的商品数: {len(qualified_items)}")
    print(f"筛选条件: 点击次数≥10 且 加购转化率≤0.2")
    print(f"平均点击次数: {avg_clicks:.1f}")
    print(f"平均加购次数: {avg_carts:.1f}")
    print(f"平均购买次数: {avg_buys:.1f}")
    print(f"平均加购转化率: {avg_cart_rate:.4f}")
    
    # 显示前20名和后10名商品
    if qualified_items:
        print(f"\n加购转化率最低的10个商品:")
        for i, item in enumerate(qualified_items[:10]):
            print(f"  {i+1}. 商品{item['item_id']}: {item['cart_conversion_rate']:.4f} (点击:{item['clicks']}, 加购:{item['carts']})")
        
        if len(qualified_items) > 20:
            print(f"\n加购转化率最高的10个商品:")
            for i, item in enumerate(qualified_items[-10:]):
                print(f"  {i+1}. 商品{item['item_id']}: {item['cart_conversion_rate']:.4f} (点击:{item['clicks']}, 加购:{item['carts']})")
    else:
        print("\n没有符合条件的商品")
    
    # 商品曝光度分布统计
    high_exposure = 0
    medium_exposure = 0
    low_exposure = 0
    
    for item_id, behaviors in item_behaviors.items():
        clicks = behaviors['click']
        if clicks >= 50:
            high_exposure += 1
        elif clicks >= 20:
            medium_exposure += 1
        else:
            low_exposure += 1
    
    print(f"\n商品曝光度分布:")
    print(f"  高曝光(≥50点击): {high_exposure} 个")
    print(f"  中曝光(20-49点击): {medium_exposure} 个")
    print(f"  低曝光(<20点击): {low_exposure} 个")


def generate_large_dataset(output_file, num_records=50000):
    """
    生成更大的数据集用于完整测试，包含更多高曝光商品
    """
    print(f"生成大数据集: {num_records} 条记录")
    
    import random
    import time
    
    base_timestamp = int(time.time() * 1000)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        for i in range(num_records):
            user_id = random.randint(1, 1000)  # 1000个用户
            
            # 生成更多高曝光商品（商品ID 1-50为高曝光商品）
            if random.random() < 0.3:  # 30%概率选择高曝光商品
                item_id = random.randint(1, 50)  # 高曝光商品
            else:
                item_id = random.randint(51, 300)  # 普通商品
            
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
    output_file = "output/task3_high_click_low_cart_complete.txt"
    
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
        generate_large_dataset(input_file, 50000)
    
    # 执行分析
    analyze_high_click_low_cart_items(input_file, output_file)


if __name__ == "__main__":
    main()