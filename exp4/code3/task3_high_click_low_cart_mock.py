#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务3模拟：识别"高曝光低加购"商品（High-Click Low-Cart Items）
模拟exp4\code3\task3_high_click_low_cart.py的输出
"""

import sys
import random

def mock_task3_high_click_low_cart(input_path, output_path):
    """
    模拟任务3的输出
    """
    # 筛选条件常量
    MIN_CLICKS = 10      # 最少点击次数
    MAX_CART_RATE = 0.2  # 最大加购转化率
    
    print("=== 高曝光低加购商品分析结果 ===")
    print(f"筛选条件: 点击次数 ≥ {MIN_CLICKS}, 加购转化率 ≤ {MAX_CART_RATE}")
    
    # 模拟数据生成
    random.seed(42)  # 确保结果可重现
    
    # 生成符合条件的高曝光低加购商品
    results = []
    
    # 生成20个符合条件的商品
    for i in range(20):
        item_id = random.randint(100, 999)
        
        # 高点击次数（>=10）
        click_count = random.randint(15, 80)
        
        # 低加购次数，确保转化率 <= 0.2
        max_cart_count = int(click_count * MAX_CART_RATE)
        cart_count = random.randint(0, max_cart_count)
        
        # 计算转化率
        conversion_rate = round(cart_count / click_count, 2)
        
        results.append((item_id, click_count, cart_count, conversion_rate))
    
    # 按加购转化率升序排序
    results.sort(key=lambda x: x[3])
    
    print(f"找到 {len(results)} 个符合条件的商品\n")
    
    print("商品ID | 点击次数 | 加购次数 | 加购转化率")
    print("-" * 45)
    for item_id, click_count, cart_count, conversion_rate in results:
        print(f"{item_id:6d} | {click_count:8d} | {cart_count:8d} | {conversion_rate:10.2f}")
    
    # 统计信息
    if results:
        avg_click_count = sum(r[1] for r in results) / len(results)
        avg_cart_rate = sum(r[3] for r in results) / len(results)
        print(f"\n统计信息:")
        print(f"平均点击次数: {avg_click_count:.1f}")
        print(f"平均加购转化率: {avg_cart_rate:.3f}")
    
    # 保存结果到文件（模拟Spark输出格式）
    with open(output_path, 'w', encoding='utf-8') as f:
        for item_id, click_count, cart_count, conversion_rate in results:
            f.write(f"({item_id}, {click_count}, {cart_count}, {conversion_rate})\n")
    
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
        output_path = "output/task3_high_click_low_cart_mock.txt"  # 默认输出路径
    
    mock_task3_high_click_low_cart(input_path, output_path)

if __name__ == "__main__":
    main()