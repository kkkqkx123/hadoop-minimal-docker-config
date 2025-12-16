#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务2模拟：统计每个用户的"加购后购买率"（Cart-to-Buy Conversion Rate）
模拟exp4\code2\task2_cart_to_buy_rate.py的输出
"""

import sys
import random

def mock_task2_cart_to_buy_rate(input_path, output_path):
    """
    模拟任务2的输出
    """
    print("=== 用户加购后购买率结果 ===")
    
    # 模拟数据生成
    random.seed(42)  # 确保结果可重现
    
    # 生成50个用户的加购后购买率数据
    results = []
    for user_id in range(1, 51):
        # 模拟不同的加购后购买率分布
        if user_id <= 8:  # 高购买转化用户
            rate = round(random.uniform(0.6, 1.0), 2)
        elif user_id <= 20:  # 中等购买转化用户
            rate = round(random.uniform(0.3, 0.7), 2)
        elif user_id <= 35:  # 低购买转化用户
            rate = round(random.uniform(0.1, 0.4), 2)
        else:  # 很少购买的用户
            rate = round(random.uniform(0.0, 0.2), 2)
        
        results.append((user_id, rate))
        print(f"用户 {user_id}: 加购后购买率 = {rate}")
    
    print(f"\n总用户数: {len(results)}")
    
    # 统计关键指标
    total_users = len(results)
    users_with_carts = sum(1 for _, rate in results if rate > 0)
    print(f"有加购行为的用户数: {users_with_carts}")
    print(f"加购用户占比: {round(users_with_carts/total_users*100, 2)}%")
    
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
        output_path = "output/task2_cart_to_buy_rate_mock.txt"  # 默认输出路径
    
    mock_task2_cart_to_buy_rate(input_path, output_path)

if __name__ == "__main__":
    main()